require "./fuse_fs"
require "./fuse_wrap"

module Crystalfuse
  # FuseBridge contains the logic for bridging a FuseFS instance
  # to the underlying libfuse wrapper.
  module FuseBridge
    @@instance : Crystalfuse::FuseFS? = nil

    def self.set_instance(fs : Crystalfuse::FuseFS)
      @@instance = fs
    end

    def self.instance : Crystalfuse::FuseFS
      @@instance.not_nil!
    end

    def self._getattr(path_ptr, stat_ptr, fi_ptr) : Int32
      path = String.new(path_ptr)
      info = FileInfo.new(fi_ptr)  # Optional — for future use
      result = instance.getattr(path)

      case result
      when FileAttr
        stat = out_ptr.value
        stat.st_mode = result.mode
        stat.st_nlink = result.nlink
        stat.st_size = result.size

        stat.st_atim.tv_sec = result.atime.to_unix
        stat.st_atim.tv_nsec = result.atime.nanosecond

        stat.st_mtim.tv_sec = result.mtime.to_unix
        stat.st_mtim.tv_nsec = result.mtime.nanosecond

        stat.st_ctim.tv_sec = result.ctime.to_unix
        stat.st_ctim.tv_nsec = result.ctime.nanosecond

        0
      when Int32
        result
      else
        -Errno::EIO.value
      end
    end

    def self._readdir(path_ptr, buf, filler, offset, fi, flags) : Int32
      path = String.new(path_ptr)
      result = instance.readdir(path)
      case result
      when Array(String)
        result.each do |entry|
          filler.call(buf, entry.to_unsafe, Pointer(Void).null, 0_i64, 0_u32)
        end
        0
      when Int32
        result
      else
        -Errno::EIO
      end
    end

    def self._open(path_ptr, fi) : Int32
      path = String.new(path_ptr)
      instance.open(path)
    end

    def self._read(path_ptr, buf, size, offset, fi) : Int32
      path = String.new(path_ptr)
      result = instance.read(path, size, offset)
      case result
      when Bytes
        Slice.new(buf, result.size).copy_from(result)
        result.size
      when Int32
        result
      else
        -Errno::EIO
      end
    end

    def self._statfs(path_ptr, st_ptr) : Int32
      path = String.new(path_ptr)
      result = instance.statfs(path)
      case result
      when LibC::Statvfs
        st_ptr.value = result
        0
      when Int32
        result
      else
        -Errno::EIO
      end
    end

    def self._access(path_ptr, mask) : Int32
      path = String.new(path_ptr)
      instance.access(path, mask)
    end

    def self.register_callbacks
      FuseWrap.fusewrap_register_getattr_bridge ->(path, stat, fi) { _getattr(path, stat, fi) }
      FuseWrap.fusewrap_register_readdir_bridge ->(path, buf, filler, offset, fi, flags) { _readdir(path, buf, filler, offset, fi, flags) }
      FuseWrap.fusewrap_register_open_bridge ->(path, fi) { _open(path, fi) }
      FuseWrap.fusewrap_register_read_bridge ->(path, buf, size, offset, fi) { _read(path, buf, size, offset, fi) }
      FuseWrap.fusewrap_register_statfs_bridge ->(path, st) { _statfs(path, st) }
      FuseWrap.fusewrap_register_access_bridge ->(path, mask) { _access(path, mask) }
    end
  end
end
