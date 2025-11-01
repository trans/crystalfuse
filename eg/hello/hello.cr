# hello.cr
require "../../src/crystalfuse"

class HelloFS < Crystalfuse::FuseFS
  def getattr(path : String) : Crystalfuse::FileAttr | Int32
    if path == "/"
      Crystalfuse::FileAttr.dir
    elsif path == "/hello.txt"
      Crystalfuse::FileAttr.file(
        size: "Hello from Crystal!\n".bytesize,
        mode: 0o444
      )
    else
      -Errno::ENOENT.value
    end
  end

  def readdir(path : String) : Array(String) | Int32
    return -Errno::ENOENT unless path == "/"
    [".", "..", "hello.txt"]
  end

  def open(path : String) : Int32
    path == "/hello.txt" ? 0 : -Errno::ENOENT
  end

  def read(path : String, size : Int32, offset : Int64) : Bytes | Int32
    return -Errno::ENOENT unless path == "/hello.txt"
    content = "Hello from Crystal!\n".to_slice
    offset_i = offset.to_i
    return Bytes.empty if offset_i >= content.size
    to_read = Math.min(size, content.size - offset_i)
    content[offset_i, to_read]
  end
end

# Run it!
fs = HelloFS.new
Crystalfuse.mount(fs, ["hello", "-f", "-d", "./mnt"])
