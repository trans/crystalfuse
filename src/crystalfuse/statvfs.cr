module Crystalfuse
  # Crystal-friendly filesystem statistics, returned from `FileSystem#statfs`. The
  # C shim marshals these into a `struct statvfs` (it owns the layout, which
  # differs across libc versions), so Crystal never touches that struct.
  struct StatVFS
    property bsize   : UInt64 # preferred I/O block size
    property frsize  : UInt64 # fundamental block size
    property blocks  : UInt64 # total data blocks (in frsize units)
    property bfree   : UInt64 # free blocks
    property bavail  : UInt64 # free blocks available to non-root
    property files   : UInt64 # total inodes
    property ffree   : UInt64 # free inodes
    property namemax : UInt64 # maximum filename length

    def initialize(@bsize : UInt64 = 4096, @frsize : UInt64 = 4096,
                   @blocks : UInt64 = 0, @bfree : UInt64 = 0, @bavail : UInt64 = 0,
                   @files : UInt64 = 0, @ffree : UInt64 = 0, @namemax : UInt64 = 255)
    end
  end
end
