# handlefs.cr
#
# A read-only filesystem that uses file handles instead of looking up by path
# on every read. `open` snapshots the file's contents into a Handle, stashes it
# via `fi.fh` (using the optional HandleTable), `read` serves from that handle,
# and `release` frees it. It also rejects writes by inspecting the open flags.
#
#   make
#   crystal run eg/handlefs/handlefs.cr -- -f ./tmp/mnt
#   cat ./tmp/mnt/hello.txt
#   fusermount3 -u ./tmp/mnt
require "../../src/crystalfuse"
require "../../src/crystalfuse/handle_table" # optional helper, opt-in

class HandleFS < Crystalfuse::FS
  FILES = {
    "/hello.txt" => "Hello from an open file handle!\n",
    "/world.txt" => "A second file, served the same way.\n",
  }

  # One open file: a snapshot of the content taken at open() time.
  class Handle
    getter data : Bytes

    def initialize(content : String)
      @data = content.to_slice.dup
    end
  end

  def initialize
    @open = Crystalfuse::HandleTable(Handle).new
  end

  def getattr(path : String) : Crystalfuse::FileAttr | Int32
    if path == "/"
      Crystalfuse::FileAttr.dir
    elsif content = FILES[path]?
      Crystalfuse::FileAttr.file(size: content.bytesize, mode: 0o444)
    else
      -Errno::ENOENT.value
    end
  end

  def readdir(path : String) : Array(String) | Int32
    return -Errno::ENOENT.value unless path == "/"
    [".", ".."] + FILES.keys.map(&.lchop('/'))
  end

  # Open the file: reject writes (read-only fs), then register a handle and
  # hand its id back through fi.fh.
  def open(path : String, fi : Crystalfuse::FileInfo) : Int32
    content = FILES[path]?
    return -Errno::ENOENT.value unless content
    return -Errno::EACCES.value if fi.writable?
    fi.fh = @open.add(Handle.new(content))
    0
  end

  # Serve from the open handle rather than re-resolving the path.
  def read(path : String, size : Int32, offset : Int64, fi : Crystalfuse::FileInfo) : Bytes | Int32
    handle = @open[fi.fh]?
    return -Errno::EBADF.value unless handle
    data = handle.data
    o = offset.to_i32
    return Bytes.empty if o >= data.size
    data[o, Math.min(size, data.size - o)]
  end

  # Last close of this open file: free the handle.
  def release(path : String, fi : Crystalfuse::FileInfo) : Int32
    @open.delete(fi.fh)
    0
  end
end

exit_code = HandleFS.new.mount(["handlefs", "-s"] + ARGV)
exit(exit_code)
