module Fuse
  # Crystal-friendly filesystem statistics, returned from `FileSystem#statfs`.
  # The C shim marshals these into a `struct statvfs` (it owns the layout, which
  # differs across libc versions), so Crystal never touches that struct — this
  # struct *is* the "raw" escape hatch, covering every field you'd reach for.
  struct StatVFS
    property bsize : UInt64   # preferred I/O block size
    property frsize : UInt64  # fundamental block size
    property blocks : UInt64  # total data blocks (in frsize units)
    property bfree : UInt64   # free blocks
    property bavail : UInt64  # free blocks available to non-root
    property files : UInt64   # total inodes
    property ffree : UInt64   # free inodes
    property favail : UInt64  # free inodes available to non-root
    property namemax : UInt64 # maximum filename length
    property flag : UInt64    # mount flags (ST_RDONLY, ST_NOSUID, …)

    def initialize(@bsize : UInt64 = 4096, @frsize : UInt64 = 4096,
                   @blocks : UInt64 = 0, @bfree : UInt64 = 0, @bavail : UInt64 = 0,
                   @files : UInt64 = 0, @ffree : UInt64 = 0, @favail : UInt64 = 0,
                   @namemax : UInt64 = 255, @flag : UInt64 = 0)
    end
  end
end
