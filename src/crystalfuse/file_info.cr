module Crystalfuse

  class FileInfo
    getter mode : LibC::ModeT = 0
    getter nlink : LibC::NlinkT = 0
    getter size : LibC::OffT = 0

    def initialize
      @flags = 0
      @bitfield = 0
      @padding2 = 0
      @padding3 = 0
      @fh = 0_u64
      @lock_owner = 0_u64
      @poll_events = 0
      @backing_id = 0
      @compat_flags = 0_u64
      @reserved = StaticArray(UInt64, 2).new(0_u64)
    end

    def to_c(stat_ptr : Pointer(LibC::Stat))
      LibC.memset(stat_ptr.as(Void*), 0, sizeof(LibC::Stat))
      stat_ptr.value.st_mode = mode
      stat_ptr.value.st_nlink = nlink
      stat_ptr.value.st_size = size
    end

    def mode=(val : Int32); @mode = val; end
    def nlink=(val : Int32); @nlink = val; end
    def size=(val : Int32); @size = val; end
  end

end
