# wrapper.cr
require "./libc"

module Crystalfuse
  lib FuseWrap
    alias GetattrCallback  = (Pointer(UInt8), Pointer(LibC::Stat), Pointer(FileInfo)) -> Int32
    alias ReaddirCallback  = (Pointer(UInt8), Void*, (Void*, Pointer(UInt8), Pointer(LibC::Stat), Int64, UInt32) -> Int32, Int64, Pointer(Void), UInt32) -> Int32
    alias OpenCallback  = (Pointer(UInt8), Pointer(FileInfo)) -> Int32
    alias ReadCallback  = (Pointer(UInt8), Pointer(UInt8), LibC::SizeT, Int64, Pointer(FileInfo)) -> Int32
    alias StatfsCallback   = (Pointer(UInt8), Pointer(LibC::Statvfs)) -> Int32
    alias AccessCallback   = (Pointer(UInt8), Int32) -> Int32

    fun fusewrap_register_getattr_bridge(cb : GetattrCallback) : Void
    fun fusewrap_register_readdir_bridge(cb : ReaddirCallback) : Void
    fun fusewrap_register_open_bridge(cb : OpenCallback) : Void
    fun fusewrap_register_read_bridge(cb : ReadCallback) : Void
    fun fusewrap_register_statfs_bridge(cb : StatfsCallback) : Void
    fun fusewrap_register_access_bridge(cb : AccessCallback) : Void

    fun fusewrap_main(argc : Int32, argv : Pointer(Pointer(UInt8))) : Int32

    @[Extern]
    struct FileInfo
      flags                  : LibC::Int32T      # 4 bytes
      bitfield               : LibC::UInt32T     # emulates all bitfield flags (4 bytes)
      padding2               : LibC::UInt32T
      padding3               : LibC::UInt32T
      fh                     : LibC::UInt64T     # 8 bytes
      lock_owner             : LibC::UInt64T     # 8 bytes
      poll_events            : LibC::UInt32T     # 4 bytes
      backing_id             : LibC::Int32T      # 4 bytes
      compat_flags           : LibC::UInt64T     # 8 bytes
      reserved               : StaticArray(LibC::UInt64T, 2) # 16 bytes
    end
  end

end
