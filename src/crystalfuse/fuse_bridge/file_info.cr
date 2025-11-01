module Crystalfuse::FuseBridge

  class FileInfoBridge
    @ptr : Pointer(FuseWrap::FileInfo)

    def initialize(ptr : Pointer(Void))
      @ptr = ptr.as(Pointer(FuseWrap::FileInfo))
    end

    # Raw struct access
    def raw : FuseWrap::FileInfo
      @ptr.value
    end

    # --- Accessors ---

    def flags : Int32
      @ptr.value.flags
    end

    def fh : UInt64
      @ptr.value.fh
    end

    def fh=(val : UInt64)
      @ptr.value.fh = val
    end

    def lock_owner : UInt64
      @ptr.value.lock_owner
    end

    def poll_events : UInt32
      @ptr.value.poll_events
    end

    def backing_id : Int32
      @ptr.value.backing_id
    end

    def compat_flags : UInt64
      @ptr.value.compat_flags
    end

    # --- Bitfield flags ---

    def writepage? : Bool
      @ptr.value.bitfield & 0b1 != 0
    end

    def direct_io? : Bool
      @ptr.value.bitfield & 0b10 != 0
    end

    def keep_cache? : Bool
      @ptr.value.bitfield & 0b100 != 0
    end

    def flush? : Bool
      @ptr.value.bitfield & 0b1000 != 0
    end

    def nonseekable? : Bool
      @ptr.value.bitfield & 0b1_0000 != 0
    end

    def flock_release? : Bool
      @ptr.value.bitfield & 0b10_0000 != 0
    end

    def cache_readdir? : Bool
      @ptr.value.bitfield & 0b100_0000 != 0
    end

    def noflush? : Bool
      @ptr.value.bitfield & 0b1000_0000 != 0
    end

    def parallel_direct_writes? : Bool
      @ptr.value.bitfield & 0b1_0000_0000 != 0
    end
  end
end
