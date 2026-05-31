require "./fuse_wrap"

module Crystalfuse
  # Wraps libfuse's `fuse_file_info`, handed to the open-file lifecycle
  # operations (`open`, `create`, `read`, `write`, `flush`, `release`).
  #
  # A filesystem can read the open `flags` and get/set the file handle `fh` —
  # an arbitrary `UInt64` it owns (e.g. an index into its own open-file table).
  # Set `fh` in `open`/`create`; the kernel hands the same value back on every
  # subsequent operation for that open file. See the optional
  # `Crystalfuse::HandleTable` (`require "crystalfuse/handle_table"`) for a
  # ready-made registry.
  struct FileInfo
    # libc's O_ACCMODE isn't exposed by Crystal's stdlib; it's the low 2 bits.
    O_ACCMODE = 0o3

    def initialize(@ptr : Pointer(FuseWrap::FileInfo))
    end

    # Raw `open(2)` flags (`O_RDONLY`, `O_WRONLY`, `O_RDWR`, `O_APPEND`, …).
    def flags : Int32
      @ptr.value.flags
    end

    def read_only? : Bool
      (flags & O_ACCMODE) == LibC::O_RDONLY
    end

    def write_only? : Bool
      (flags & O_ACCMODE) == LibC::O_WRONLY
    end

    def read_write? : Bool
      (flags & O_ACCMODE) == LibC::O_RDWR
    end

    # Opened for writing (either write-only or read-write).
    def writable? : Bool
      write_only? || read_write?
    end

    def append? : Bool
      (flags & LibC::O_APPEND) != 0
    end

    def truncate? : Bool
      (flags & LibC::O_TRUNC) != 0
    end

    # The file handle. Set it in `open`/`create`; read it back in
    # `read`/`write`/`flush`/`release`.
    def fh : UInt64
      @ptr.value.fh
    end

    def fh=(value : UInt64) : UInt64
      @ptr.value.fh = value
      value
    end
  end
end
