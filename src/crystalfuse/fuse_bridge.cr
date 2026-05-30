# fuse_bridge.cr
require "./fuse_fs"
require "./fuse_wrap"

module Crystalfuse
  # Bridges the raw C callbacks from the libfuse shim to the active `FuseFS`
  # instance. Each `_op` method translates C pointers/ints into Crystal types,
  # dispatches to the instance, and marshals the result back for libfuse.
  module FuseBridge
    @@instance : Crystalfuse::FuseFS? = nil

    def self.set_instance(fs : Crystalfuse::FuseFS)
      @@instance = fs
    end

    def self.instance : Crystalfuse::FuseFS
      @@instance.not_nil!
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
      result = instance.readdir(String.new(path_ptr))
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
      instance.open(String.new(path_ptr))
    end

    def self._read(path_ptr, buf, size, offset, fi) : Int32
      result = instance.read(String.new(path_ptr), size.to_i32, offset)
      case result
      when Bytes
        n = Math.min(result.size, size.to_i32)
        Slice.new(buf, n).copy_from(result.to_unsafe, n)
        n
      else
        result.as(Int32)
      end
    end

    def self._write(path_ptr, buf, size, offset, fi) : Int32
      data = Slice.new(buf, size.to_i32)
      instance.write(String.new(path_ptr), data, offset)
    end

    def self._create(path_ptr, mode, fi) : Int32
      instance.create(String.new(path_ptr), mode.to_i32)
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

    # Wire every C operation to the corresponding bridge method. The procs are
    # closure-free (they reference only module methods), so they convert to
    # plain C function pointers.
    def self.register_callbacks
      FuseWrap.fusewrap_register_getattr ->(p : Pointer(UInt8), s : Pointer(LibC::Stat), fi : Pointer(FuseWrap::FileInfo)) { _getattr(p, s, fi) }
      FuseWrap.fusewrap_register_readdir ->(p : Pointer(UInt8), b : Void*, f : FuseWrap::FillDir, o : Int64, fi : Pointer(FuseWrap::FileInfo), fl : UInt32) { _readdir(p, b, f, o, fi, fl) }
      FuseWrap.fusewrap_register_open ->(p : Pointer(UInt8), fi : Pointer(FuseWrap::FileInfo)) { _open(p, fi) }
      FuseWrap.fusewrap_register_read ->(p : Pointer(UInt8), b : Pointer(UInt8), sz : LibC::SizeT, o : Int64, fi : Pointer(FuseWrap::FileInfo)) { _read(p, b, sz, o, fi) }
      FuseWrap.fusewrap_register_write ->(p : Pointer(UInt8), b : Pointer(UInt8), sz : LibC::SizeT, o : Int64, fi : Pointer(FuseWrap::FileInfo)) { _write(p, b, sz, o, fi) }
      FuseWrap.fusewrap_register_create ->(p : Pointer(UInt8), m : LibC::ModeT, fi : Pointer(FuseWrap::FileInfo)) { _create(p, m, fi) }
      FuseWrap.fusewrap_register_truncate ->(p : Pointer(UInt8), sz : Int64, fi : Pointer(FuseWrap::FileInfo)) { _truncate(p, sz, fi) }
      FuseWrap.fusewrap_register_unlink ->(p : Pointer(UInt8)) { _unlink(p) }
      FuseWrap.fusewrap_register_mkdir ->(p : Pointer(UInt8), m : LibC::ModeT) { _mkdir(p, m) }
      FuseWrap.fusewrap_register_rmdir ->(p : Pointer(UInt8)) { _rmdir(p) }
      FuseWrap.fusewrap_register_rename ->(f : Pointer(UInt8), t : Pointer(UInt8), fl : UInt32) { _rename(f, t, fl) }
      FuseWrap.fusewrap_register_chmod ->(p : Pointer(UInt8), m : LibC::ModeT, fi : Pointer(FuseWrap::FileInfo)) { _chmod(p, m, fi) }
      FuseWrap.fusewrap_register_chown ->(p : Pointer(UInt8), u : LibC::UidT, g : LibC::GidT, fi : Pointer(FuseWrap::FileInfo)) { _chown(p, u, g, fi) }
      FuseWrap.fusewrap_register_readlink ->(p : Pointer(UInt8), b : Pointer(UInt8), sz : LibC::SizeT) { _readlink(p, b, sz) }
      FuseWrap.fusewrap_register_symlink ->(t : Pointer(UInt8), l : Pointer(UInt8)) { _symlink(t, l) }
      FuseWrap.fusewrap_register_statfs ->(p : Pointer(UInt8), st : Void*) { _statfs(p, st) }
      FuseWrap.fusewrap_register_access ->(p : Pointer(UInt8), m : Int32) { _access(p, m) }
    end
  end
end
