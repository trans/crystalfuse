module Crystalfuse

  # Crystal-friendly bridge struct for file attributes
  struct FileAttr
    property mode  : Int32 = 0o100644  # Default regular file with rw-r--r--
    property size  : Int64 = 0
    property nlink : Int32 = 1
    property atime : Time = Time.utc
    property mtime : Time = Time.utc
    property ctime : Time = Time.utc

    def initialize(@mode : Int32, @size : Int64, @nlink : Int32, @atime : Time, @mtime : Time, @ctime : Time)
    end

    def to_c(stat : Pointer(LibC::Stat))
      stat.value.st_mode  = mode.to_u32    # if LibC::ModeT is UInt32
      stat.value.st_size  = size
      stat.value.st_nlink = nlink
      stat.value.st_atime = atime.to_unix
      stat.value.st_mtime = mtime.to_unix
      stat.value.st_ctime = ctime.to_unix
    end

    def self.dir(nlink = 2, time = Time.utc) : self
      new((LibC::S_IFDIR | 0o755).as(Int32), 0_i64, nlink, time, time, time)
    end

    def self.file(size : Int64, mode = 0o444, time = Time.utc) : self
      new((LibC::S_IFREG | mode).as(Int32), size, 1, time, time, time)
    end
  end

end
