# fuse_bridge.cr
require "./file_system"
require "./fuse_wrap"

module Crystalfuse
  # Bridges the raw C callbacks from the libfuse shim to the active `FileSystem`
  # instance. Each `_op` method translates C pointers/ints into Crystal types,
  # dispatches to the instance, and marshals the result back for libfuse.
  module FuseBridge
    # FUSE encodes these in a timespec's tv_nsec to mean "set to now" and
    # "leave unchanged" respectively (see utimensat(2)).
    UTIME_NOW  = (1_i64 << 30) - 1
    UTIME_OMIT = (1_i64 << 30) - 2

    @@instance : Crystalfuse::FileSystem? = nil

    def self.set_instance(fs : Crystalfuse::FileSystem)
      @@instance = fs
    end

    def self.instance : Crystalfuse::FileSystem
      @@instance.not_nil!
    end

    # Log an exception that escaped a user's filesystem method. Writes straight
    # to fd 2 rather than via STDERR — Crystal's buffered IO can reach into the
    # fiber scheduler, which isn't safe on a libfuse worker thread.
    def self.report(ex : Exception) : Nil
      msg = String.build do |io|
        io << "crystalfuse: uncaught " << ex.class << ": " << ex.message << '\n'
        ex.backtrace?.try(&.each { |line| io << "  " << line << '\n' })
      end
      LibC.write(2, msg.to_unsafe.as(Void*), LibC::SizeT.new(msg.bytesize))
    end

    # Run a bridge operation, turning any uncaught exception into -EIO. Without
    # this, an exception raised in a user's filesystem method would unwind into
    # C and abort the whole process (or wedge the mount). `yield` is inlined, so
    # the enclosing proc stays a plain C function pointer.
    def self.guard(& : -> Int32) : Int32
      FuseWrap.fusewrap_register_current_thread # make this worker thread GC-safe
      yield
    rescue ex
      report(ex)
      -Errno::EIO.value
    end

    # Like `guard`, for operations that return an off_t/ssize_t (Int64).
    def self.guard64(& : -> Int64) : Int64
      FuseWrap.fusewrap_register_current_thread
      yield
    rescue ex
      report(ex)
      -Errno::EIO.value.to_i64
    end

    def self._init : Nil
      instance.init
    rescue ex
      report(ex)
    end

    def self._destroy : Nil
      instance.destroy
    rescue ex
      report(ex)
    end

    def self._getattr(path_ptr, stat_ptr, fi) : Int32
      result = instance.getattr(String.new(path_ptr))
      case result
      when FileAttr
        result.to_c(stat_ptr)
        0
      else
        result.as(Int32)
      end
    end

    def self._readdir(path_ptr, buf, filler, offset, fi, flags) : Int32
      result = instance.readdir(String.new(path_ptr), FileInfo.new(fi))
      case result
      when Array(String)
        result.each do |entry|
          filler.call(buf, entry.to_unsafe, Pointer(LibC::Stat).null, 0_i64, 0_u32)
        end
        0
      else
        result.as(Int32)
      end
    end

    def self._open(path_ptr, fi) : Int32
      instance.open(String.new(path_ptr), FileInfo.new(fi))
    end

    def self._release(path_ptr, fi) : Int32
      instance.release(String.new(path_ptr), FileInfo.new(fi))
    end

    def self._flush(path_ptr, fi) : Int32
      instance.flush(String.new(path_ptr), FileInfo.new(fi))
    end

    def self._read(path_ptr, buf, size, offset, fi) : Int32
      # Hand the kernel's own buffer to the filesystem (buffer-filling form);
      # the default impl falls back to the Bytes-returning form with one copy.
      instance.read(String.new(path_ptr), Slice.new(buf, size.to_i32), offset, FileInfo.new(fi))
    end

    def self._write(path_ptr, buf, size, offset, fi) : Int32
      data = Slice.new(buf, size.to_i32)
      instance.write(String.new(path_ptr), data, offset, FileInfo.new(fi))
    end

    def self._create(path_ptr, mode, fi) : Int32
      instance.create(String.new(path_ptr), mode.to_i32, FileInfo.new(fi))
    end

    def self._truncate(path_ptr, size, fi) : Int32
      instance.truncate(String.new(path_ptr), size)
    end

    def self._unlink(path_ptr) : Int32
      instance.unlink(String.new(path_ptr))
    end

    def self._mkdir(path_ptr, mode) : Int32
      instance.mkdir(String.new(path_ptr), mode.to_i32)
    end

    def self._rmdir(path_ptr) : Int32
      instance.rmdir(String.new(path_ptr))
    end

    def self._rename(from_ptr, to_ptr, flags) : Int32
      instance.rename(String.new(from_ptr), String.new(to_ptr), flags)
    end

    def self._chmod(path_ptr, mode, fi) : Int32
      instance.chmod(String.new(path_ptr), mode.to_i32)
    end

    def self._chown(path_ptr, uid, gid, fi) : Int32
      instance.chown(String.new(path_ptr), uid.to_u32, gid.to_u32)
    end

    def self._readlink(path_ptr, buf, size) : Int32
      result = instance.readlink(String.new(path_ptr))
      case result
      when String
        # libfuse wants a NUL-terminated target written into buf (truncated to
        # the buffer size), and a 0 return.
        bytes = result.to_slice
        n = Math.min(bytes.size, size.to_i32 - 1)
        Slice.new(buf, n).copy_from(bytes.to_unsafe, n) if n > 0
        buf[n.clamp(0, size.to_i32 - 1)] = 0_u8
        0
      else
        result.as(Int32)
      end
    end

    def self._symlink(target_ptr, link_ptr) : Int32
      instance.symlink(String.new(target_ptr), String.new(link_ptr))
    end

    def self._utimens(path_ptr, tv_ptr, fi) : Int32
      instance.utimens(String.new(path_ptr),
        timespec_to_time(tv_ptr[0]),
        timespec_to_time(tv_ptr[1]))
    end

    # Decode a `struct timespec`, honoring FUSE's UTIME_NOW / UTIME_OMIT
    # sentinels (encoded in tv_nsec). Returns nil for "leave unchanged".
    def self.timespec_to_time(ts : LibC::Timespec) : Time?
      case ts.tv_nsec
      when UTIME_OMIT then nil
      when UTIME_NOW  then Time.utc
      else                 Time.unix(ts.tv_sec) + ts.tv_nsec.nanoseconds
      end
    end

    def self._statfs(path_ptr, st_ptr) : Int32
      result = instance.statfs(String.new(path_ptr))
      case result
      when StatVFS
        FuseWrap.fusewrap_fill_statvfs(st_ptr,
          result.bsize, result.frsize,
          result.blocks, result.bfree, result.bavail,
          result.files, result.ffree, result.namemax)
        0
      else
        result.as(Int32)
      end
    end

    def self._access(path_ptr, mask) : Int32
      instance.access(String.new(path_ptr), mask)
    end

    def self._fsync(path_ptr, datasync, fi) : Int32
      instance.fsync(String.new(path_ptr), datasync != 0, FileInfo.new(fi))
    end

    def self._fsyncdir(path_ptr, datasync, fi) : Int32
      instance.fsyncdir(String.new(path_ptr), datasync != 0, FileInfo.new(fi))
    end

    def self._opendir(path_ptr, fi) : Int32
      instance.opendir(String.new(path_ptr), FileInfo.new(fi))
    end

    def self._releasedir(path_ptr, fi) : Int32
      instance.releasedir(String.new(path_ptr), FileInfo.new(fi))
    end

    def self._mknod(path_ptr, mode, rdev) : Int32
      instance.mknod(String.new(path_ptr), mode.to_i32, rdev.to_u64)
    end

    def self._link(target_ptr, link_ptr) : Int32
      instance.link(String.new(target_ptr), String.new(link_ptr))
    end

    def self._setxattr(path_ptr, name_ptr, value_ptr, size, flags) : Int32
      value = Slice.new(value_ptr, size.to_i32)
      instance.setxattr(String.new(path_ptr), String.new(name_ptr), value, flags)
    end

    # getxattr/listxattr use a two-call protocol: when size is 0 the caller is
    # asking for the required buffer size; otherwise fill the buffer (or -ERANGE
    # if it's too small). The binding handles that here so the fs just returns
    # the value/names.
    def self._getxattr(path_ptr, name_ptr, value_ptr, size) : Int32
      result = instance.getxattr(String.new(path_ptr), String.new(name_ptr))
      case result
      when Bytes
        n = result.size
        return n if size == 0
        return -Errno::ERANGE.value if n.to_u64 > size
        Slice.new(value_ptr, n).copy_from(result.to_unsafe, n)
        n
      else
        result.as(Int32)
      end
    end

    def self._listxattr(path_ptr, list_ptr, size) : Int32
      result = instance.listxattr(String.new(path_ptr))
      case result
      when Array(String)
        total = 0
        result.each { |name| total += name.bytesize + 1 } # each name is NUL-terminated
        return total if size == 0
        return -Errno::ERANGE.value if total.to_u64 > size
        offset = 0
        result.each do |name|
          bytes = name.to_slice
          Slice.new(list_ptr + offset, bytes.size).copy_from(bytes.to_unsafe, bytes.size) if bytes.size > 0
          (list_ptr + offset + bytes.size).value = 0_u8
          offset += bytes.size + 1
        end
        total
      else
        result.as(Int32)
      end
    end

    def self._removexattr(path_ptr, name_ptr) : Int32
      instance.removexattr(String.new(path_ptr), String.new(name_ptr))
    end

    def self._lseek(path_ptr, offset, whence, fi) : Int64
      instance.lseek(String.new(path_ptr), offset, whence, FileInfo.new(fi))
    end

    def self._fallocate(path_ptr, mode, offset, length, fi) : Int32
      instance.fallocate(String.new(path_ptr), mode, offset, length, FileInfo.new(fi))
    end

    def self._copy_file_range(in_ptr, fi_in, off_in, out_ptr, fi_out, off_out, size, flags) : Int64
      instance.copy_file_range(String.new(in_ptr), FileInfo.new(fi_in), off_in,
        String.new(out_ptr), FileInfo.new(fi_out), off_out, size, flags)
    end

    def self._flock(path_ptr, fi, op) : Int32
      instance.flock(String.new(path_ptr), FileInfo.new(fi), op)
    end

    def self._lock(path_ptr, fi, cmd, lock_ptr) : Int32
      instance.lock(String.new(path_ptr), FileInfo.new(fi), cmd, lock_ptr)
    end

    def self._ioctl(path_ptr, cmd, arg, fi, flags, data) : Int32
      instance.ioctl(String.new(path_ptr), cmd, arg, FileInfo.new(fi), flags, data)
    end

    def self._poll(path_ptr, fi, ph, reventsp) : Int32
      instance.poll(String.new(path_ptr), FileInfo.new(fi), ph, reventsp)
    end

    def self._bmap(path_ptr, blocksize, idx) : Int32
      instance.bmap(String.new(path_ptr), blocksize, idx)
    end

    # Wire every C operation to the corresponding bridge method, each wrapped in
    # `guard`. The procs are closure-free (they reference only module methods),
    # so they convert to plain C function pointers.
    def self.register_callbacks
      FuseWrap.fusewrap_register_init ->{ _init }
      FuseWrap.fusewrap_register_destroy ->{ _destroy }
      FuseWrap.fusewrap_register_getattr ->(p : Pointer(UInt8), s : Pointer(LibC::Stat), fi : Pointer(FuseWrap::FileInfo)) { guard { _getattr(p, s, fi) } }
      FuseWrap.fusewrap_register_readdir ->(p : Pointer(UInt8), b : Void*, f : FuseWrap::FillDir, o : Int64, fi : Pointer(FuseWrap::FileInfo), fl : UInt32) { guard { _readdir(p, b, f, o, fi, fl) } }
      FuseWrap.fusewrap_register_open ->(p : Pointer(UInt8), fi : Pointer(FuseWrap::FileInfo)) { guard { _open(p, fi) } }
      FuseWrap.fusewrap_register_release ->(p : Pointer(UInt8), fi : Pointer(FuseWrap::FileInfo)) { guard { _release(p, fi) } }
      FuseWrap.fusewrap_register_flush ->(p : Pointer(UInt8), fi : Pointer(FuseWrap::FileInfo)) { guard { _flush(p, fi) } }
      FuseWrap.fusewrap_register_read ->(p : Pointer(UInt8), b : Pointer(UInt8), sz : LibC::SizeT, o : Int64, fi : Pointer(FuseWrap::FileInfo)) { guard { _read(p, b, sz, o, fi) } }
      FuseWrap.fusewrap_register_write ->(p : Pointer(UInt8), b : Pointer(UInt8), sz : LibC::SizeT, o : Int64, fi : Pointer(FuseWrap::FileInfo)) { guard { _write(p, b, sz, o, fi) } }
      FuseWrap.fusewrap_register_create ->(p : Pointer(UInt8), m : LibC::ModeT, fi : Pointer(FuseWrap::FileInfo)) { guard { _create(p, m, fi) } }
      FuseWrap.fusewrap_register_truncate ->(p : Pointer(UInt8), sz : Int64, fi : Pointer(FuseWrap::FileInfo)) { guard { _truncate(p, sz, fi) } }
      FuseWrap.fusewrap_register_unlink ->(p : Pointer(UInt8)) { guard { _unlink(p) } }
      FuseWrap.fusewrap_register_mkdir ->(p : Pointer(UInt8), m : LibC::ModeT) { guard { _mkdir(p, m) } }
      FuseWrap.fusewrap_register_rmdir ->(p : Pointer(UInt8)) { guard { _rmdir(p) } }
      FuseWrap.fusewrap_register_rename ->(f : Pointer(UInt8), t : Pointer(UInt8), fl : UInt32) { guard { _rename(f, t, fl) } }
      FuseWrap.fusewrap_register_chmod ->(p : Pointer(UInt8), m : LibC::ModeT, fi : Pointer(FuseWrap::FileInfo)) { guard { _chmod(p, m, fi) } }
      FuseWrap.fusewrap_register_chown ->(p : Pointer(UInt8), u : LibC::UidT, g : LibC::GidT, fi : Pointer(FuseWrap::FileInfo)) { guard { _chown(p, u, g, fi) } }
      FuseWrap.fusewrap_register_readlink ->(p : Pointer(UInt8), b : Pointer(UInt8), sz : LibC::SizeT) { guard { _readlink(p, b, sz) } }
      FuseWrap.fusewrap_register_symlink ->(t : Pointer(UInt8), l : Pointer(UInt8)) { guard { _symlink(t, l) } }
      FuseWrap.fusewrap_register_utimens ->(p : Pointer(UInt8), tv : Pointer(LibC::Timespec), fi : Pointer(FuseWrap::FileInfo)) { guard { _utimens(p, tv, fi) } }
      FuseWrap.fusewrap_register_statfs ->(p : Pointer(UInt8), st : Void*) { guard { _statfs(p, st) } }
      FuseWrap.fusewrap_register_access ->(p : Pointer(UInt8), m : Int32) { guard { _access(p, m) } }
      FuseWrap.fusewrap_register_fsync ->(p : Pointer(UInt8), ds : Int32, fi : Pointer(FuseWrap::FileInfo)) { guard { _fsync(p, ds, fi) } }
      FuseWrap.fusewrap_register_fsyncdir ->(p : Pointer(UInt8), ds : Int32, fi : Pointer(FuseWrap::FileInfo)) { guard { _fsyncdir(p, ds, fi) } }
      FuseWrap.fusewrap_register_opendir ->(p : Pointer(UInt8), fi : Pointer(FuseWrap::FileInfo)) { guard { _opendir(p, fi) } }
      FuseWrap.fusewrap_register_releasedir ->(p : Pointer(UInt8), fi : Pointer(FuseWrap::FileInfo)) { guard { _releasedir(p, fi) } }
      FuseWrap.fusewrap_register_mknod ->(p : Pointer(UInt8), m : LibC::ModeT, d : LibC::DevT) { guard { _mknod(p, m, d) } }
      FuseWrap.fusewrap_register_link ->(t : Pointer(UInt8), l : Pointer(UInt8)) { guard { _link(t, l) } }
      FuseWrap.fusewrap_register_setxattr ->(p : Pointer(UInt8), n : Pointer(UInt8), v : Pointer(UInt8), sz : LibC::SizeT, fl : Int32) { guard { _setxattr(p, n, v, sz, fl) } }
      FuseWrap.fusewrap_register_getxattr ->(p : Pointer(UInt8), n : Pointer(UInt8), v : Pointer(UInt8), sz : LibC::SizeT) { guard { _getxattr(p, n, v, sz) } }
      FuseWrap.fusewrap_register_listxattr ->(p : Pointer(UInt8), l : Pointer(UInt8), sz : LibC::SizeT) { guard { _listxattr(p, l, sz) } }
      FuseWrap.fusewrap_register_removexattr ->(p : Pointer(UInt8), n : Pointer(UInt8)) { guard { _removexattr(p, n) } }
      FuseWrap.fusewrap_register_lseek ->(p : Pointer(UInt8), o : Int64, w : Int32, fi : Pointer(FuseWrap::FileInfo)) { guard64 { _lseek(p, o, w, fi) } }
      FuseWrap.fusewrap_register_fallocate ->(p : Pointer(UInt8), m : Int32, o : Int64, l : Int64, fi : Pointer(FuseWrap::FileInfo)) { guard { _fallocate(p, m, o, l, fi) } }
      FuseWrap.fusewrap_register_copy_file_range ->(pi : Pointer(UInt8), fii : Pointer(FuseWrap::FileInfo), oi : Int64, po : Pointer(UInt8), fio : Pointer(FuseWrap::FileInfo), oo : Int64, sz : LibC::SizeT, fl : Int32) { guard64 { _copy_file_range(pi, fii, oi, po, fio, oo, sz, fl) } }
      FuseWrap.fusewrap_register_flock ->(p : Pointer(UInt8), fi : Pointer(FuseWrap::FileInfo), op : Int32) { guard { _flock(p, fi, op) } }
      FuseWrap.fusewrap_register_lock ->(p : Pointer(UInt8), fi : Pointer(FuseWrap::FileInfo), cmd : Int32, lk : Pointer(LibC::Flock)) { guard { _lock(p, fi, cmd, lk) } }
      FuseWrap.fusewrap_register_ioctl ->(p : Pointer(UInt8), cmd : UInt32, arg : Void*, fi : Pointer(FuseWrap::FileInfo), fl : UInt32, data : Void*) { guard { _ioctl(p, cmd, arg, fi, fl, data) } }
      FuseWrap.fusewrap_register_poll ->(p : Pointer(UInt8), fi : Pointer(FuseWrap::FileInfo), ph : Void*, rev : Pointer(UInt32)) { guard { _poll(p, fi, ph, rev) } }
      FuseWrap.fusewrap_register_bmap ->(p : Pointer(UInt8), bs : LibC::SizeT, idx : Pointer(UInt64)) { guard { _bmap(p, bs, idx) } }
    end
  end
end
