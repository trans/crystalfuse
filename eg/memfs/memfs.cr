# memfs.cr
#
# A small but fully writable in-memory filesystem. It demonstrates the
# write-path operations: create, write, truncate, unlink, mkdir, rmdir,
# rename and chmod (read-path ops too, of course).
#
# Build the C shim first (`make` from the project root), then:
#   crystal run eg/memfs/memfs.cr -- -f ./tmp/mnt
# and poke at it from another shell:
#   echo "hi there" > ./tmp/mnt/note.txt
#   cat ./tmp/mnt/note.txt
#   mkdir ./tmp/mnt/sub
#   mv ./tmp/mnt/note.txt ./tmp/mnt/sub/
#   ls -lR ./tmp/mnt
# Unmount with `fusermount3 -u ./tmp/mnt` (or `make unmount`).
#
# NOTE: the example mounts single-threaded (`-s`). libfuse's multi-threaded
# mode runs callbacks on worker threads that Crystal's runtime/GC doesn't know
# about, which isn't safe; `-s` keeps every callback on the main thread.
require "../../src/crystalfuse"

class MemFS < Crystalfuse::FuseFS
  # A node in the tree: either a directory or a regular file.
  abstract class Node
    property perms : Int32
    property uid : UInt32 = Crystalfuse::FileAttr::DEFAULT_UID
    property gid : UInt32 = Crystalfuse::FileAttr::DEFAULT_GID
    property mtime : Time

    def initialize(@perms : Int32, @mtime : Time = Time.utc)
    end
  end

  class DirNode < Node
  end

  class FileNode < Node
    property data : Bytes = Bytes.empty

    def size : Int32
      @data.size
    end

    def read_at(size : Int32, offset : Int32) : Bytes
      return Bytes.empty if offset >= @data.size
      @data[offset, Math.min(size, @data.size - offset)]
    end

    def write_at(bytes : Bytes, offset : Int32) : Int32
      ensure_size(offset + bytes.size)
      bytes.copy_to(@data[offset, bytes.size]) unless bytes.empty?
      @mtime = Time.utc
      bytes.size
    end

    def truncate_to(new_size : Int32) : Nil
      grown = Bytes.new(new_size)
      @data.copy_to(grown) if @data.size <= new_size
      @data[0, new_size].copy_to(grown) if @data.size > new_size
      @data = grown
      @mtime = Time.utc
    end

    # Grow the backing buffer (zero-filled) to at least *n* bytes.
    private def ensure_size(n : Int32) : Nil
      return if @data.size >= n
      grown = Bytes.new(n)
      @data.copy_to(grown)
      @data = grown
    end
  end

  def initialize
    @nodes = {} of String => Node
    @nodes["/"] = DirNode.new(0o755)
  end

  def getattr(path : String) : Crystalfuse::FileAttr | Int32
    node = @nodes[path]?
    return -Errno::ENOENT.value unless node
    case node
    when DirNode  then Crystalfuse::FileAttr.dir(mode: node.perms, time: node.mtime, uid: node.uid, gid: node.gid)
    when FileNode then Crystalfuse::FileAttr.file(size: node.size, mode: node.perms, time: node.mtime, uid: node.uid, gid: node.gid)
    else               -Errno::EIO.value
    end
  end

  def readdir(path : String) : Array(String) | Int32
    return -Errno::ENOENT.value unless @nodes[path]?.is_a?(DirNode)
    entries = [".", ".."]
    children(path).each { |key| entries << basename(key) }
    entries
  end

  def open(path : String) : Int32
    @nodes.has_key?(path) ? 0 : -Errno::ENOENT.value
  end

  def read(path : String, size : Int32, offset : Int64) : Bytes | Int32
    node = @nodes[path]?
    return -Errno::ENOENT.value unless node
    return -Errno::EISDIR.value unless node.is_a?(FileNode)
    node.read_at(size, offset.to_i32)
  end

  def write(path : String, data : Bytes, offset : Int64) : Int32
    node = @nodes[path]?
    return -Errno::ENOENT.value unless node
    return -Errno::EISDIR.value unless node.is_a?(FileNode)
    node.write_at(data, offset.to_i32)
  end

  def create(path : String, mode : Int32) : Int32
    return -Errno::ENOENT.value unless @nodes[dirname(path)]?.is_a?(DirNode)
    return -Errno::EEXIST.value if @nodes.has_key?(path)
    @nodes[path] = FileNode.new(mode & 0o777)
    touch(dirname(path))
    0
  end

  def truncate(path : String, size : Int64) : Int32
    node = @nodes[path]?
    return -Errno::ENOENT.value unless node
    return -Errno::EISDIR.value unless node.is_a?(FileNode)
    node.truncate_to(size.to_i32)
    0
  end

  def unlink(path : String) : Int32
    node = @nodes[path]?
    return -Errno::ENOENT.value unless node
    return -Errno::EISDIR.value if node.is_a?(DirNode)
    @nodes.delete(path)
    touch(dirname(path))
    0
  end

  def mkdir(path : String, mode : Int32) : Int32
    return -Errno::ENOENT.value unless @nodes[dirname(path)]?.is_a?(DirNode)
    return -Errno::EEXIST.value if @nodes.has_key?(path)
    @nodes[path] = DirNode.new(mode & 0o777)
    touch(dirname(path))
    0
  end

  def rmdir(path : String) : Int32
    node = @nodes[path]?
    return -Errno::ENOENT.value unless node
    return -Errno::ENOTDIR.value unless node.is_a?(DirNode)
    return -Errno::ENOTEMPTY.value unless children(path).empty?
    @nodes.delete(path)
    touch(dirname(path))
    0
  end

  def rename(path : String, new_path : String, flags : UInt32) : Int32
    return -Errno::ENOENT.value unless @nodes.has_key?(path)
    # RENAME_NOREPLACE
    return -Errno::EEXIST.value if flags == 1_u32 && @nodes.has_key?(new_path)
    # Move the node and, if it's a directory, all of its descendants.
    moving = @nodes.keys.select { |key| key == path || key.starts_with?("#{path}/") }
    moving.each do |key|
      @nodes[new_path + key[path.size..]] = @nodes.delete(key).not_nil!
    end
    touch(dirname(path))
    touch(dirname(new_path))
    0
  end

  def chmod(path : String, mode : Int32) : Int32
    node = @nodes[path]?
    return -Errno::ENOENT.value unless node
    node.perms = mode & 0o777
    0
  end

  # Update ownership. FUSE passes (uid_t)-1 / (gid_t)-1 to mean "leave unchanged".
  def chown(path : String, uid : UInt32, gid : UInt32) : Int32
    node = @nodes[path]?
    return -Errno::ENOENT.value unless node
    node.uid = uid unless uid == UInt32::MAX
    node.gid = gid unless gid == UInt32::MAX
    0
  end

  # nil for either time means "leave unchanged" (UTIME_OMIT). We only track a
  # single mtime, so prefer the modification time when both are supplied.
  def utimens(path : String, atime : Time?, mtime : Time?) : Int32
    node = @nodes[path]?
    return -Errno::ENOENT.value unless node
    if t = mtime || atime
      node.mtime = t
    end
    0
  end

  def statfs(path : String) : Crystalfuse::StatVFS | Int32
    Crystalfuse::StatVFS.new(
      bsize: 4096, frsize: 4096,
      blocks: 262144, bfree: 262144, bavail: 262144, # pretend we have 1 GiB
      files: 100000, ffree: (100000 - @nodes.size).to_u64,
      namemax: 255
    )
  end

  # --- helpers ---

  private def children(path : String) : Array(String)
    @nodes.keys.select { |key| key != path && dirname(key) == path }
  end

  private def touch(path : String) : Nil
    if node = @nodes[path]?
      node.mtime = Time.utc
    end
  end

  private def dirname(path : String) : String
    idx = path.rindex('/')
    return "/" unless idx
    idx == 0 ? "/" : path[0, idx]
  end

  private def basename(path : String) : String
    idx = path.rindex('/')
    idx ? path[(idx + 1)..] : path
  end
end

# Mount single-threaded (-s); see the note at the top of this file.
exit_code = MemFS.new.mount(["memfs", "-s"] + ARGV)
exit(exit_code)
