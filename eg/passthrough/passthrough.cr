# passthrough.cr
#
# A passthrough (loopback) filesystem: it mirrors a real directory tree, so
# every operation is forwarded to the underlying filesystem via raw libc calls.
# This is the most complete example — it exercises nearly the whole operation
# table against real filesystem semantics, and it shows off file handles by
# stashing a real backing file descriptor in `fi.fh`.
#
#   make
#   mkdir -p /tmp/pt.src /tmp/pt.mnt
#   echo hi > /tmp/pt.src/hello.txt
#   crystal run eg/passthrough/passthrough.cr -- /tmp/pt.src -f /tmp/pt.mnt
#   cat /tmp/pt.mnt/hello.txt        # => hi  (read from /tmp/pt.src)
#   echo more > /tmp/pt.mnt/new.txt  # writes through to /tmp/pt.src/new.txt
#   fusermount3 -u /tmp/pt.mnt
#
# Unlike the other examples this is data-race-free at the binding level (all
# state lives in the kernel / backing fs), so it runs multithreaded.
require "../../src/crystalfuse"

# The few libc calls not already declared in Crystal's stdlib LibC.
lib LibCExtra
  fun pwrite(fd : LibC::Int, buf : Void*, count : LibC::SizeT, offset : LibC::OffT) : LibC::SSizeT
  fun truncate(path : LibC::Char*, length : LibC::OffT) : LibC::Int
end

class PassthroughFS < Crystalfuse::FuseFS
  def initialize(@root : String)
  end

  # Map a FUSE path ("/a/b") onto the backing tree ("<root>/a/b").
  private def real(path : String) : String
    path == "/" ? @root : @root + path
  end

  # Negative errno from the most recent failed syscall.
  private def err : Int32
    -Errno.value.value
  end

  def getattr(path : String) : Crystalfuse::FileAttr | Int32
    st = uninitialized LibC::Stat
    return err if LibC.lstat(real(path), pointerof(st)) != 0
    attr = Crystalfuse::FileAttr.new(
      mode: st.st_mode.to_i32, size: st.st_size.to_i64, nlink: st.st_nlink.to_i32,
      atime: Time.unix(st.st_atim.tv_sec), mtime: Time.unix(st.st_mtim.tv_sec),
      ctime: Time.unix(st.st_ctim.tv_sec), uid: st.st_uid, gid: st.st_gid)
    attr.ino = st.st_ino
    attr.rdev = st.st_rdev
    attr.blocks = st.st_blocks.to_i64
    attr.blksize = st.st_blksize.to_i64
    attr
  end

  def readdir(path : String) : Array(String) | Int32
    dir = LibC.opendir(real(path))
    return err if dir.null?
    entries = [] of String
    while (ent = LibC.readdir(dir)) && !ent.null?
      entries << String.new(ent.value.d_name.to_unsafe)
    end
    LibC.closedir(dir)
    entries
  end

  # --- file handles: stash the real backing fd in fi.fh ---

  def open(path : String, fi : Crystalfuse::FileInfo) : Int32
    fd = LibC.open(real(path), fi.flags)
    return err if fd < 0
    fi.fh = fd.to_u64
    0
  end

  def create(path : String, mode : Int32, fi : Crystalfuse::FileInfo) : Int32
    fd = LibC.open(real(path), LibC::O_CREAT | LibC::O_WRONLY | LibC::O_TRUNC, LibC::ModeT.new(mode))
    return err if fd < 0
    fi.fh = fd.to_u64
    0
  end

  def read(path : String, size : Int32, offset : Int64, fi : Crystalfuse::FileInfo) : Bytes | Int32
    buf = Bytes.new(size)
    n = LibC.pread(fi.fh.to_i32, buf.to_unsafe.as(Void*), LibC::SizeT.new(size), LibC::OffT.new(offset))
    return err if n < 0
    buf[0, n.to_i32]
  end

  def write(path : String, data : Bytes, offset : Int64, fi : Crystalfuse::FileInfo) : Int32
    n = LibCExtra.pwrite(fi.fh.to_i32, data.to_unsafe.as(Void*), LibC::SizeT.new(data.size), LibC::OffT.new(offset))
    n < 0 ? err : n.to_i32
  end

  def release(path : String, fi : Crystalfuse::FileInfo) : Int32
    LibC.close(fi.fh.to_i32)
    0
  end

  # --- mutating ops, forwarded straight through ---

  def truncate(path : String, size : Int64) : Int32
    LibCExtra.truncate(real(path), LibC::OffT.new(size)) != 0 ? err : 0
  end

  def unlink(path : String) : Int32
    LibC.unlink(real(path)) != 0 ? err : 0
  end

  def mkdir(path : String, mode : Int32) : Int32
    LibC.mkdir(real(path), LibC::ModeT.new(mode)) != 0 ? err : 0
  end

  def rmdir(path : String) : Int32
    LibC.rmdir(real(path)) != 0 ? err : 0
  end

  def rename(path : String, new_path : String, flags : UInt32) : Int32
    LibC.rename(real(path), real(new_path)) != 0 ? err : 0
  end

  def chmod(path : String, mode : Int32) : Int32
    LibC.chmod(real(path), LibC::ModeT.new(mode)) != 0 ? err : 0
  end

  def chown(path : String, uid : UInt32, gid : UInt32) : Int32
    LibC.lchown(real(path), uid, gid) != 0 ? err : 0
  end

  def symlink(target : String, link_path : String) : Int32
    LibC.symlink(target, real(link_path)) != 0 ? err : 0
  end

  def readlink(path : String) : String | Int32
    buf = Bytes.new(4096)
    n = LibC.readlink(real(path), buf.to_unsafe.as(LibC::Char*), LibC::SizeT.new(buf.size))
    n < 0 ? err : String.new(buf[0, n.to_i32])
  end

  def link(target : String, link_path : String) : Int32
    LibC.link(real(target), real(link_path)) != 0 ? err : 0
  end

  def access(path : String, mask : Int32) : Int32
    LibC.access(real(path), mask) != 0 ? err : 0
  end

  # NOTE: statfs is intentionally left at the default. Forwarding it would mean
  # marshaling a `struct statvfs`, whose layout varies by libc — exactly the
  # trap the binding avoids by filling that struct on the C side. A faithful
  # implementation would add a small statvfs helper to the C shim.
end

# First positional arg is the directory to mirror; the rest pass to libfuse.
root = ARGV.shift? || abort("usage: passthrough <source-dir> [fuse-opts] <mountpoint>")
source = File.expand_path(root)
abort("source directory does not exist: #{source}") unless Dir.exists?(source)

exit_code = PassthroughFS.new(source).mount(["passthrough"] + ARGV)
exit(exit_code)
