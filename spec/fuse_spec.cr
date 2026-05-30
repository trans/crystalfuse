require "./spec_helper"

# A tiny read-only filesystem used to exercise the FuseFS API and the bridge
# without actually mounting anything.
private class TestFS < Crystalfuse::FuseFS
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
