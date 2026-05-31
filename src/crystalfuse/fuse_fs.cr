# fuse_fs.cr
require "./fuse_wrap"
require "./file_attr"

module Crystalfuse
  # Base class for a FUSE filesystem. Subclass it and override the operations
  # you care about; anything you leave alone returns a sensible default
  # (`-ENOENT` for lookups, `-ENOSYS` for write operations on a read-only fs).
  #
  # Operation methods return either a meaningful value (e.g. `FileAttr`,
  # `Array(String)`, `Bytes`) or a negative `Errno` value to signal failure,
  # e.g. `-Errno::ENOENT.value`.
  abstract class FuseFS
    # Attributes for the file at *path* (the `stat(2)` of FUSE).
    def getattr(path : String) : FileAttr | Int32
      -Errno::ENOENT.value
    end

    # Entries contained in the directory at *path*. Include "." and "..".
    def readdir(path : String) : Array(String) | Int32
      -Errno::ENOENT.value
    end

    # Called when a file is opened. Return 0 for success.
    def open(path : String) : Int32
      0
    end

    # Read up to *size* bytes from *path* starting at *offset*.
    def read(path : String, size : Int32, offset : Int64) : Bytes | Int32
      -Errno::ENOENT.value
    end

    # Write *data* to *path* at *offset*. Return the number of bytes written.
    def write(path : String, data : Bytes, offset : Int64) : Int32
      -Errno::ENOSYS.value
    end

    # Create and open a new file at *path* with the given *mode*.
    def create(path : String, mode : Int32) : Int32
      -Errno::ENOSYS.value
    end

    # Change the size of the file at *path*.
    def truncate(path : String, size : Int64) : Int32
      -Errno::ENOSYS.value
    end

    # Remove the file at *path*.
    def unlink(path : String) : Int32
      -Errno::ENOSYS.value
    end

    # Create a directory at *path*.
    def mkdir(path : String, mode : Int32) : Int32
      -Errno::ENOSYS.value
    end

    # Remove the directory at *path*.
    def rmdir(path : String) : Int32
      -Errno::ENOSYS.value
    end

    # Rename/move *path* to *new_path*.
    def rename(path : String, new_path : String, flags : UInt32) : Int32
      -Errno::ENOSYS.value
    end

    # Change the permission bits of *path*.
    def chmod(path : String, mode : Int32) : Int32
      -Errno::ENOSYS.value
    end

    # Change ownership of *path*.
    def chown(path : String, uid : UInt32, gid : UInt32) : Int32
      -Errno::ENOSYS.value
    end

    # Resolve the target of the symbolic link at *path*.
    def readlink(path : String) : String | Int32
      -Errno::ENOSYS.value
    end

    # Create a symbolic link at *link_path* pointing to *target*.
    def symlink(target : String, link_path : String) : Int32
      -Errno::ENOSYS.value
    end

    # Set the access and/or modification times of *path*. Either may be `nil`,
    # meaning "leave that timestamp unchanged" (FUSE's `UTIME_OMIT`).
    def utimens(path : String, atime : Time?, mtime : Time?) : Int32
      -Errno::ENOSYS.value
    end

    # Filesystem statistics for *path*. Return a `StatVFS`.
    def statfs(path : String) : StatVFS | Int32
      -Errno::ENOSYS.value
    end

    # Check access permissions for *path*. Return 0 to allow.
    def access(path : String, mask : Int32) : Int32
      0
    end

    # Mount this filesystem, handing *args* (argv-style) straight to libfuse.
    # Don't override this.
    def mount(args : Array(String)) : Int32
      Crystalfuse.mount(self, args)
    end
  end
end
