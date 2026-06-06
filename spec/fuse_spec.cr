require "./spec_helper"

# A tiny read-only filesystem used to exercise the FileSystem API and the bridge
# without actually mounting anything.
private class TestFS < Crystalfuse::FS
  CONTENT = "hello\n"

  def getattr(path : String) : Crystalfuse::FileAttr | Int32
    case path
    when "/"          then Crystalfuse::FileAttr.dir
    when "/hello.txt" then Crystalfuse::FileAttr.file(size: CONTENT.bytesize, mode: 0o444)
    else                   -Errno::ENOENT.value
    end
  end

  def readdir(path : String) : Array(String) | Int32
    return -Errno::ENOENT.value unless path == "/"
    [".", "..", "hello.txt"]
  end

  def read(path : String, size : Int32, offset : Int64) : Bytes | Int32
    return -Errno::ENOENT.value unless path == "/hello.txt"
    CONTENT.to_slice[offset.to_i32, Math.min(size, CONTENT.bytesize - offset.to_i32)]
  end
end

# A filesystem whose operations blow up, to exercise the bridge's guard.
private class RaisingFS < Crystalfuse::FS
  def getattr(path : String) : Crystalfuse::FileAttr | Int32
    raise "boom"
  end
end

# Records what it sees through the FileInfo, to verify fh/flag plumbing.
private class HandleEchoFS < Crystalfuse::FS
  property seen_fh : UInt64 = 0_u64
  property seen_writable : Bool = false

  def open(path : String, fi : Crystalfuse::FileInfo) : Int32
    @seen_writable = fi.writable?
    fi.fh = 0xCAFE_u64
    0
  end

  def read(path : String, size : Int32, offset : Int64, fi : Crystalfuse::FileInfo) : Bytes | Int32
    @seen_fh = fi.fh
    Bytes.empty
  end
end

# Two filesystems for the read paths: one uses the friendly Bytes-returning
# form, the other fills the kernel buffer directly (the zero-copy escape hatch).
private class BytesReadFS < Crystalfuse::FS
  def read(path : String, size : Int32, offset : Int64) : Bytes | Int32
    "abcdef".to_slice[offset.to_i32, Math.min(size, 6 - offset.to_i32)]
  end
end

private class BufferReadFS < Crystalfuse::FS
  def read(path : String, buffer : Bytes, offset : Int64, fi : Crystalfuse::FileInfo) : Int32
    src = "ABCDEF".to_slice
    n = Math.min(buffer.size, src.size - offset.to_i32)
    buffer.copy_from(src.to_unsafe + offset.to_i32, n)
    n
  end
end

# Records the lifecycle callbacks.
private class LifecycleFS < Crystalfuse::FS
  property inited = false
  property destroyed = false

  def init : Nil
    @inited = true
  end

  def destroy : Nil
    @destroyed = true
  end
end

describe Crystalfuse::FileAttr do
  it "builds a regular file attr with the right mode and size" do
    attr = Crystalfuse::FileAttr.file(size: 5, mode: 0o444)
    (attr.mode & LibC::S_IFMT).should eq(LibC::S_IFREG)
    (attr.mode & 0o777).should eq(0o444)
    attr.size.should eq(5)
    attr.nlink.should eq(1)
  end

  it "builds a directory attr" do
    attr = Crystalfuse::FileAttr.dir
    (attr.mode & LibC::S_IFMT).should eq(LibC::S_IFDIR)
    (attr.mode & 0o777).should eq(0o755)
    attr.nlink.should eq(2)
  end

  it "marshals into a struct stat via #to_c" do
    stat = LibC::Stat.new
    attr = Crystalfuse::FileAttr.file(size: 42, mode: 0o444)
    attr.to_c(pointerof(stat))

    stat.st_size.should eq(42)
    (stat.st_mode.to_i32 & LibC::S_IFMT).should eq(LibC::S_IFREG)
    (stat.st_mode.to_i32 & 0o777).should eq(0o444)
    stat.st_nlink.should eq(1)
  end

  it "defaults ownership to the mounting process" do
    attr = Crystalfuse::FileAttr.file(size: 0)
    attr.uid.should eq(LibC.getuid)
    attr.gid.should eq(LibC.getgid)
  end

  it "marshals explicit uid/gid into the struct stat" do
    stat = LibC::Stat.new
    Crystalfuse::FileAttr.file(size: 0, uid: 1234, gid: 5678).to_c(pointerof(stat))
    stat.st_uid.should eq(1234)
    stat.st_gid.should eq(5678)
  end

  it "derives block count and marshals ino/rdev/blksize" do
    attr = Crystalfuse::FileAttr.file(size: 5000)
    attr.blocks.should eq((5000 + 511) // 512) # 10 (512-byte units)
    attr.blksize.should eq(4096)

    attr.ino = 1234_u64
    stat = LibC::Stat.new
    attr.to_c(pointerof(stat))
    stat.st_ino.should eq(1234)
    stat.st_blocks.should eq(10)
    stat.st_blksize.should eq(4096)
  end
end

describe "FuseBridge.guard" do
  it "turns an uncaught exception into -EIO instead of crashing" do
    Crystalfuse::FuseBridge.set_instance(RaisingFS.new)
    stat = LibC::Stat.new
    rc = Crystalfuse::FuseBridge.guard do
      Crystalfuse::FuseBridge._getattr(
        "/x".to_unsafe, pointerof(stat),
        Pointer(Crystalfuse::FuseWrap::FileInfo).null
      )
    end
    rc.should eq(-Errno::EIO.value)
  end
end

describe "FuseBridge.timespec_to_time" do
  it "decodes a normal timespec" do
    ts = LibC::Timespec.new(tv_sec: 1_000_000_000, tv_nsec: 0)
    Crystalfuse::FuseBridge.timespec_to_time(ts).should eq(Time.unix(1_000_000_000))
  end

  it "returns nil for UTIME_OMIT (leave unchanged)" do
    ts = LibC::Timespec.new(tv_sec: 0, tv_nsec: Crystalfuse::FuseBridge::UTIME_OMIT)
    Crystalfuse::FuseBridge.timespec_to_time(ts).should be_nil
  end
end

describe Crystalfuse::FileInfo do
  it "decodes access-mode flags and gets/sets fh" do
    cfi = Crystalfuse::FuseWrap::FileInfo.new
    cfi.flags = LibC::O_RDWR | LibC::O_APPEND
    info = Crystalfuse::FileInfo.new(pointerof(cfi))

    info.read_write?.should be_true
    info.writable?.should be_true
    info.read_only?.should be_false
    info.append?.should be_true

    info.fh = 9_u64
    cfi.fh.should eq(9)
  end
end

describe "file handles" do
  it "round-trips fh from open to read and exposes the open flags" do
    fs = HandleEchoFS.new
    Crystalfuse::FuseBridge.set_instance(fs)

    cfi = Crystalfuse::FuseWrap::FileInfo.new
    cfi.flags = LibC::O_WRONLY
    Crystalfuse::FuseBridge._open("/f".to_unsafe, pointerof(cfi)).should eq(0)
    fs.seen_writable.should be_true
    cfi.fh.should eq(0xCAFE) # the handle the fs stashed survives in the C struct

    buf = Bytes.new(4)
    Crystalfuse::FuseBridge._read("/f".to_unsafe, buf.to_unsafe, LibC::SizeT.new(4), 0_i64, pointerof(cfi))
    fs.seen_fh.should eq(0xCAFE) # ...and is handed back on read
  end
end

describe "read paths" do
  it "fills the kernel buffer via the friendly Bytes-returning form" do
    Crystalfuse::FuseBridge.set_instance(BytesReadFS.new)
    cfi = Crystalfuse::FuseWrap::FileInfo.new
    buf = Bytes.new(6)
    n = Crystalfuse::FuseBridge._read("/f".to_unsafe, buf.to_unsafe, LibC::SizeT.new(6), 0_i64, pointerof(cfi))
    n.should eq(6)
    String.new(buf).should eq("abcdef")
  end

  it "fills the kernel buffer directly via the buffer-filling escape hatch" do
    Crystalfuse::FuseBridge.set_instance(BufferReadFS.new)
    cfi = Crystalfuse::FuseWrap::FileInfo.new
    buf = Bytes.new(3)
    n = Crystalfuse::FuseBridge._read("/f".to_unsafe, buf.to_unsafe, LibC::SizeT.new(3), 2_i64, pointerof(cfi))
    n.should eq(3)
    String.new(buf).should eq("CDE") # offset 2 into "ABCDEF"
  end
end

describe "lifecycle hooks" do
  it "dispatches init and destroy" do
    fs = LifecycleFS.new
    Crystalfuse::FuseBridge.set_instance(fs)
    Crystalfuse::FuseBridge._init
    Crystalfuse::FuseBridge._destroy
    fs.inited.should be_true
    fs.destroyed.should be_true
  end
end

# In-memory xattrs plus recorders for mknod/link, to exercise those bridges.
private class XattrFS < Crystalfuse::FS
  @attrs = {} of String => Bytes
  property last_mknod : Tuple(String, Int32, UInt64)? = nil
  property linked : Tuple(String, String)? = nil

  def setxattr(path : String, name : String, value : Bytes, flags : Int32) : Int32
    @attrs[name] = value.dup
    0
  end

  def getxattr(path : String, name : String) : Bytes | Int32
    @attrs[name]? || -Errno::ENODATA.value
  end

  def listxattr(path : String) : Array(String) | Int32
    @attrs.keys
  end

  def mknod(path : String, mode : Int32, rdev : UInt64) : Int32
    @last_mknod = {path, mode, rdev}
    0
  end

  def link(target : String, link_path : String) : Int32
    @linked = {target, link_path}
    0
  end
end

describe "xattr bridge (two-call size protocol)" do
  it "stores, size-probes, and reads back a value" do
    Crystalfuse::FuseBridge.set_instance(XattrFS.new)
    v = "bar".to_slice
    Crystalfuse::FuseBridge._setxattr("/f".to_unsafe, "user.foo".to_unsafe,
      v.to_unsafe, LibC::SizeT.new(v.size), 0).should eq(0)

    # size 0 → required length, buffer untouched (pass null)
    Crystalfuse::FuseBridge._getxattr("/f".to_unsafe, "user.foo".to_unsafe,
      Pointer(UInt8).null, LibC::SizeT.new(0)).should eq(3)

    buf = Bytes.new(8)
    n = Crystalfuse::FuseBridge._getxattr("/f".to_unsafe, "user.foo".to_unsafe,
      buf.to_unsafe, LibC::SizeT.new(8))
    n.should eq(3)
    String.new(buf[0, 3]).should eq("bar")
  end

  it "returns -ERANGE when the buffer is too small" do
    Crystalfuse::FuseBridge.set_instance(XattrFS.new)
    v = "abcdef".to_slice
    Crystalfuse::FuseBridge._setxattr("/f".to_unsafe, "user.k".to_unsafe,
      v.to_unsafe, LibC::SizeT.new(v.size), 0)
    buf = Bytes.new(2)
    Crystalfuse::FuseBridge._getxattr("/f".to_unsafe, "user.k".to_unsafe,
      buf.to_unsafe, LibC::SizeT.new(2)).should eq(-Errno::ERANGE.value)
  end

  it "serializes the name list NUL-separated" do
    Crystalfuse::FuseBridge.set_instance(XattrFS.new)
    one = "1".to_slice
    Crystalfuse::FuseBridge._setxattr("/f".to_unsafe, "user.a".to_unsafe, one.to_unsafe, LibC::SizeT.new(1), 0)
    Crystalfuse::FuseBridge._setxattr("/f".to_unsafe, "user.bb".to_unsafe, one.to_unsafe, LibC::SizeT.new(1), 0)

    total = Crystalfuse::FuseBridge._listxattr("/f".to_unsafe, Pointer(UInt8).null, LibC::SizeT.new(0))
    total.should eq(("user.a".bytesize + 1) + ("user.bb".bytesize + 1))

    buf = Bytes.new(total)
    Crystalfuse::FuseBridge._listxattr("/f".to_unsafe, buf.to_unsafe, LibC::SizeT.new(total)).should eq(total)
    String.new(buf).split('\0', remove_empty: true).sort.should eq(["user.a", "user.bb"])
  end
end

describe "mknod / link bridge" do
  it "dispatches mknod and link with their arguments" do
    fs = XattrFS.new
    Crystalfuse::FuseBridge.set_instance(fs)

    Crystalfuse::FuseBridge._mknod("/n".to_unsafe, LibC::ModeT.new(0o100644), LibC::DevT.new(0)).should eq(0)
    fs.last_mknod.should eq({"/n", 0o100644, 0_u64})

    Crystalfuse::FuseBridge._link("/a".to_unsafe, "/b".to_unsafe).should eq(0)
    fs.linked.should eq({"/a", "/b"})
  end
end

# Exercises the advanced ops, including an Int64 return and a pointer out-param.
private class OpsFS < Crystalfuse::FS
  def lseek(path : String, offset : Int64, whence : Int32, fi : Crystalfuse::FileInfo) : Int64
    offset + 100
  end

  def fallocate(path : String, mode : Int32, offset : Int64, length : Int64, fi : Crystalfuse::FileInfo) : Int32
    mode + 1
  end

  def bmap(path : String, blocksize : UInt64, idx : Pointer(UInt64)) : Int32
    idx.value = idx.value + 1 # prove the in/out index round-trips
    0
  end
end

describe "advanced ops bridge" do
  it "dispatches lseek and returns an Int64 offset" do
    Crystalfuse::FuseBridge.set_instance(OpsFS.new)
    cfi = Crystalfuse::FuseWrap::FileInfo.new
    Crystalfuse::FuseBridge._lseek("/f".to_unsafe, 50_i64, 0, pointerof(cfi)).should eq(150_i64)
  end

  it "dispatches fallocate" do
    Crystalfuse::FuseBridge.set_instance(OpsFS.new)
    cfi = Crystalfuse::FuseWrap::FileInfo.new
    Crystalfuse::FuseBridge._fallocate("/f".to_unsafe, 7, 0_i64, 4096_i64, pointerof(cfi)).should eq(8)
  end

  it "dispatches bmap with an in/out block index" do
    Crystalfuse::FuseBridge.set_instance(OpsFS.new)
    idx = 41_u64
    Crystalfuse::FuseBridge._bmap("/f".to_unsafe, LibC::SizeT.new(512), pointerof(idx)).should eq(0)
    idx.should eq(42)
  end

  it "guard64 converts an exception into -EIO" do
    Crystalfuse::FuseBridge.guard64 { raise "boom" }.should eq(-Errno::EIO.value.to_i64)
  end
end

describe Crystalfuse::FuseBridge do
  it "dispatches getattr through the bridge and fills the stat buffer" do
    Crystalfuse::FuseBridge.set_instance(TestFS.new)

    stat = LibC::Stat.new
    rc = Crystalfuse::FuseBridge._getattr(
      "/hello.txt".to_unsafe,
      pointerof(stat),
      Pointer(Crystalfuse::FuseWrap::FileInfo).null
    )

    rc.should eq(0)
    stat.st_size.should eq(TestFS::CONTENT.bytesize)
  end

  it "returns -ENOENT for unknown paths" do
    Crystalfuse::FuseBridge.set_instance(TestFS.new)

    stat = LibC::Stat.new
    rc = Crystalfuse::FuseBridge._getattr(
      "/nope".to_unsafe,
      pointerof(stat),
      Pointer(Crystalfuse::FuseWrap::FileInfo).null
    )

    rc.should eq(-Errno::ENOENT.value)
  end
end
