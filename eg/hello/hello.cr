# hello.cr
#
# A minimal read-only filesystem exposing a single file, /hello.txt.
#
# Build the C shim first (`make` from the project root), then:
#   crystal run eg/hello/hello.cr -- -f ./mnt
# and read it with `cat ./mnt/hello.txt`. Unmount with `fusermount3 -u ./mnt`.
require "../../src/crystalfuse"

class HelloFS < Fuse::FS
  CONTENT = "Hello from Crystal!\n"

  def getattr(path : String) : Fuse::FileAttr | Int32
    case path
    when "/"
      Fuse::FileAttr.dir
    when "/hello.txt"
      Fuse::FileAttr.file(size: CONTENT.bytesize, mode: 0o444)
    else
      -Errno::ENOENT.value
    end
  end

  def readdir(path : String) : Array(String) | Int32
    return -Errno::ENOENT.value unless path == "/"
    [".", "..", "hello.txt"]
  end

  def open(path : String) : Int32
    path == "/hello.txt" ? 0 : -Errno::ENOENT.value
  end

  def read(path : String, size : Int32, offset : Int64) : Bytes | Int32
    return -Errno::ENOENT.value unless path == "/hello.txt"
    content = CONTENT.to_slice
    offset_i = offset.to_i32
    return Bytes.empty if offset_i >= content.size
    to_read = Math.min(size, content.size - offset_i)
    content[offset_i, to_read]
  end
end

# Pass through argv: the program name plus whatever the user supplied
# (e.g. `-f /mountpoint`).
exit_code = HelloFS.new.mount(["hello"] + ARGV)
exit(exit_code)
