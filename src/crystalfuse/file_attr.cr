module Crystalfuse
  # A Crystal-friendly description of a file's attributes. Returned from
  # `FuseFS#getattr`; `#to_c` marshals it into a `struct stat` for libfuse.
  struct FileAttr
    property mode  : Int32 = 0o100644 # regular file, rw-r--r--
    property size  : Int64 = 0
    property nlink : Int32 = 1
    property atime : Time = Time.utc
    property mtime : Time = Time.utc
    property ctime : Time = Time.utc

    def initialize(@mode : Int32, @size : Int64, @nlink : Int32,
                   @atime : Time, @mtime : Time, @ctime : Time)
    end

    def to_c(stat : Pointer(LibC::Stat)) : Nil
      LibC.memset(stat.as(Void*), 0, sizeof(LibC::Stat))
      stat.value.st_mode  = LibC::ModeT.new(mode)
      stat.value.st_nlink = LibC::NlinkT.new(nlink)
      stat.value.st_size  = LibC::OffT.new(size)
      stat.value.st_atim  = to_timespec(atime)
      stat.value.st_mtim  = to_timespec(mtime)
      stat.value.st_ctim  = to_timespec(ctime)
    end

    private def to_timespec(time : Time) : LibC::Timespec
      LibC::Timespec.new(tv_sec: LibC::TimeT.new(time.to_unix),
                         tv_nsec: LibC::Long.new(time.nanosecond))
    end

    # Convenience constructor for a directory.
    def self.dir(nlink = 2, mode = 0o755, time = Time.utc) : self
      new((LibC::S_IFDIR | mode).to_i32, 0_i64, nlink, time, time, time)
    end

    # Convenience constructor for a regular file.
    def self.file(size : Int, mode = 0o644, time = Time.utc) : self
      new((LibC::S_IFREG | mode).to_i32, size.to_i64, 1, time, time, time)
    end

    # Convenience constructor for a symbolic link.
    def self.symlink(size : Int, mode = 0o777, time = Time.utc) : self
      new((LibC::S_IFLNK | mode).to_i32, size.to_i64, 1, time, time, time)
    end
  end
end
