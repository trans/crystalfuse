# file_system.cr
require "./fuse_wrap"
require "./file_attr"

module Crystalfuse
  # Base class for a FUSE filesystem. Subclass it and override the operations
  # you care about; anything you leave alone returns a sensible default
  # (`-ENOENT` for lookups, `-ENOSYS` for write operations on a read-only fs).
  #
  # Reference it as `Crystalfuse::FileSystem`, or via the short alias
  # `Crystalfuse::FS`.
  #
  # Most operations come in two flavors: an ergonomic default that returns a
  # Crystal value (`FileAttr`, `Array(String)`, `Bytes`, …) and, where it
  # matters, a lower-level "escape hatch" overload that hands you the raw
  # buffer/pointer for zero-copy or full control. Override whichever you need;
  # the escape-hatch forms delegate to the friendly ones by default. Any
  # operation can also return a negative `Errno` value to signal failure,
  # e.g. `-Errno::ENOENT.value`.
  abstract class FileSystem
    # Called once when the filesystem is mounted, before any other operation.
    def init : Nil
    end

    # Called once when the filesystem is unmounted.
    def destroy : Nil
    end

    # Attributes for the file at *path* (the `stat(2)` of FUSE).
    def getattr(path : String) : FileAttr | Int32
      -Errno::ENOENT.value
    end

    # Raw escape hatch: fill the kernel's `struct stat` (*stat*) directly and
    # return 0, or a negative errno. Use this when you need a field `FileAttr`
    # doesn't model. By default it calls the friendly `FileAttr`-returning form
    # and marshals the result, so override one or the other.
    def getattr(path : String, stat : Pointer(LibC::Stat)) : Int32
      result = getattr(path)
      case result
      when FileAttr
        result.to_c(stat)
        0
      else
        result.as(Int32)
      end
    end

    # Entries contained in the directory at *path*. Include "." and "..".
    def readdir(path : String) : Array(String) | Int32
      -Errno::ENOENT.value
    end

    # Same as `readdir` but with the `FileInfo` (the handle set in `opendir`).
    def readdir(path : String, fi : FileInfo) : Array(String) | Int32
      readdir(path)
    end

    # Streaming escape hatch: push entries into *filler* (`filler << name`) as
    # you discover them and return 0, or a negative errno. Avoids materializing
    # the whole listing into an `Array(String)` — worth it for directories with
    # very many entries. By default it calls the `Array(String)`-returning form
    # and streams its result, so override one or the other.
    def readdir(path : String, filler : DirFiller, fi : FileInfo) : Int32
      result = readdir(path, fi)
      case result
      when Array(String)
        result.each { |name| filler << name }
        0
      else
        result.as(Int32)
      end
    end

    # Called when a directory is opened. Set `fi.fh` for a directory handle.
    def opendir(path : String, fi : FileInfo) : Int32
      0
    end

    # Called when a directory handle is released.
    def releasedir(path : String, fi : FileInfo) : Int32
      0
    end

    # Sync a directory. *datasync* true → flush data only, not metadata.
    def fsyncdir(path : String, datasync : Bool, fi : FileInfo) : Int32
      0
    end

    # Called when a file is opened. Return 0 for success.
    def open(path : String) : Int32
      0
    end

    # Same as `open` but with the `FileInfo` (open flags + a settable file
    # handle). Override this instead of `open` for handle/flag-aware behavior;
    # by default it just delegates to the path-only form.
    def open(path : String, fi : FileInfo) : Int32
      open(path)
    end

    # Called once when the last open reference to a file is released. Free any
    # handle/state you allocated in `open`/`create` here.
    def release(path : String, fi : FileInfo) : Int32
      0
    end

    # Called on each `close(2)` of a descriptor (may fire more than once, or
    # not at all). Return an error to surface it to `close`.
    def flush(path : String, fi : FileInfo) : Int32
      0
    end

    # Sync a file's contents to storage. *datasync* true → flush data only.
    def fsync(path : String, datasync : Bool, fi : FileInfo) : Int32
      0
    end

    # Read up to *size* bytes from *path* starting at *offset*.
    def read(path : String, size : Int32, offset : Int64) : Bytes | Int32
      -Errno::ENOENT.value
    end

    # Same as `read` but with the `FileInfo` (file handle set in `open`).
    def read(path : String, size : Int32, offset : Int64, fi : FileInfo) : Bytes | Int32
      read(path, size, offset)
    end

    # Buffer-filling escape hatch: write up to `buffer.size` bytes directly into
    # *buffer* (the kernel's own read buffer) starting at *offset*, and return
    # the number of bytes written, or a negative errno.
    #
    # This avoids the allocate-and-copy of the `Bytes`-returning form, which is
    # worth it for filesystems streaming large files. Override this *or* the
    # `Bytes` form — by default this one calls the `Bytes` form and copies its
    # result into *buffer*.
    def read(path : String, buffer : Bytes, offset : Int64, fi : FileInfo) : Int32
      result = read(path, buffer.size, offset, fi)
      case result
      when Bytes
        n = Math.min(result.size, buffer.size)
        buffer.copy_from(result.to_unsafe, n)
        n
      else
        result.as(Int32)
      end
    end

    # Write *data* to *path* at *offset*. Return the number of bytes written.
    def write(path : String, data : Bytes, offset : Int64) : Int32
      -Errno::ENOSYS.value
    end

    # Same as `write` but with the `FileInfo` (file handle set in `open`).
    def write(path : String, data : Bytes, offset : Int64, fi : FileInfo) : Int32
      write(path, data, offset)
    end

    # Create and open a new file at *path* with the given *mode*.
    def create(path : String, mode : Int32) : Int32
      -Errno::ENOSYS.value
    end

    # Same as `create` but with the `FileInfo` (settable file handle).
    def create(path : String, mode : Int32, fi : FileInfo) : Int32
      create(path, mode)
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

    # Create a filesystem node (regular file, FIFO, socket, device, …) at
    # *path*. *rdev* matters only for device nodes.
    def mknod(path : String, mode : Int32, rdev : UInt64) : Int32
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

    # Create a hard link at *link_path* referring to the existing file *target*.
    def link(target : String, link_path : String) : Int32
      -Errno::ENOSYS.value
    end

    # Set the access and/or modification times of *path*. Either may be `nil`,
    # meaning "leave that timestamp unchanged" (FUSE's `UTIME_OMIT`).
    def utimens(path : String, atime : Time?, mtime : Time?) : Int32
      -Errno::ENOSYS.value
    end

    # --- Extended attributes ---

    # Set extended attribute *name* to *value*. *flags* may be `XATTR_CREATE`
    # (1, fail if it exists) or `XATTR_REPLACE` (2, fail if it doesn't).
    def setxattr(path : String, name : String, value : Bytes, flags : Int32) : Int32
      -Errno::EOPNOTSUPP.value
    end

    # Return the value of extended attribute *name*, or a negative errno
    # (e.g. `-Errno::ENODATA.value` when it doesn't exist).
    def getxattr(path : String, name : String) : Bytes | Int32
      -Errno::EOPNOTSUPP.value
    end

    # Return the names of *path*'s extended attributes.
    def listxattr(path : String) : Array(String) | Int32
      -Errno::EOPNOTSUPP.value
    end

    # Remove extended attribute *name*.
    def removexattr(path : String, name : String) : Int32
      -Errno::EOPNOTSUPP.value
    end

    # Filesystem statistics for *path*. Return a `StatVFS`.
    def statfs(path : String) : StatVFS | Int32
      -Errno::ENOSYS.value
    end

    # Check access permissions for *path*. Return 0 to allow.
    def access(path : String, mask : Int32) : Int32
      0
    end

    # --- Advanced / less-common operations ---

    # Reposition the read/write offset; mainly SEEK_DATA/SEEK_HOLE for sparse
    # files. Return the resulting offset, or a negative errno.
    def lseek(path : String, offset : Int64, whence : Int32, fi : FileInfo) : Int64
      -Errno::ENOSYS.value.to_i64
    end

    # Preallocate or punch holes in a file's space (see fallocate(2) *mode*).
    def fallocate(path : String, mode : Int32, offset : Int64, length : Int64, fi : FileInfo) : Int32
      -Errno::ENOSYS.value
    end

    # Server-side copy of *size* bytes between two open files. Return the number
    # of bytes copied, or a negative errno.
    def copy_file_range(path_in : String, fi_in : FileInfo, offset_in : Int64,
                        path_out : String, fi_out : FileInfo, offset_out : Int64,
                        size : UInt64, flags : Int32) : Int64
      -Errno::ENOSYS.value.to_i64
    end

    # BSD-style whole-file advisory lock (*op* is LOCK_SH / LOCK_EX / LOCK_UN …).
    def flock(path : String, fi : FileInfo, op : Int32) : Int32
      -Errno::ENOSYS.value
    end

    # POSIX (fcntl) advisory lock. *cmd* is F_GETLK / F_SETLK / F_SETLKW; *lock*
    # points at a `LibC::Flock` to read and (for F_GETLK) write back.
    def lock(path : String, fi : FileInfo, cmd : Int32, lock : Pointer(LibC::Flock)) : Int32
      -Errno::ENOSYS.value
    end

    # Device-style ioctl; *arg*/*data* are raw pointers per the ioctl protocol.
    def ioctl(path : String, cmd : UInt32, arg : Pointer(Void),
              fi : FileInfo, flags : UInt32, data : Pointer(Void)) : Int32
      -Errno::ENOSYS.value
    end

    # Poll for I/O readiness; set the ready events into *reventsp*. *ph* is an
    # opaque poll handle for later notification.
    def poll(path : String, fi : FileInfo, ph : Pointer(Void), reventsp : Pointer(UInt32)) : Int32
      -Errno::ENOSYS.value
    end

    # Map a logical file block to a device block (for block-backed filesystems).
    # *idx* is in/out: the requested block in, the mapped block out.
    def bmap(path : String, blocksize : UInt64, idx : Pointer(UInt64)) : Int32
      -Errno::ENOSYS.value
    end

    # Mount this filesystem, handing *args* (argv-style) straight to libfuse.
    # Don't override this.
    def mount(args : Array(String)) : Int32
      Crystalfuse.mount(self, args)
    end
  end

  # Short alias for `FileSystem` — `class MyFS < Crystalfuse::FS`.
  alias FS = FileSystem
end
