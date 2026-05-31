# fuse_wrap.cr
#
# Low-level bindings to the C shim in `c/fuse_wrapper.c`. The shim owns the
# `struct fuse_operations` table and forwards each operation to the callbacks
# registered here. The static archive `c/libfusewrap.a` (built by `make`) is
# linked in alongside libfuse3.
require "./libc"

module Crystalfuse
  @[Link(ldflags: "#{__DIR__}/../../c/libfusewrap.a -lfuse3 -lpthread")]
  lib FuseWrap
    # The fuse_fill_dir_t callback handed to readdir.
    alias FillDir = (Void*, Pointer(UInt8), Pointer(LibC::Stat), Int64, UInt32) -> Int32

    alias GetattrCallback  = (Pointer(UInt8), Pointer(LibC::Stat), Pointer(FileInfo)) -> Int32
    alias ReaddirCallback  = (Pointer(UInt8), Void*, FillDir, Int64, Pointer(FileInfo), UInt32) -> Int32
    alias OpenCallback     = (Pointer(UInt8), Pointer(FileInfo)) -> Int32
    alias ReleaseCallback  = (Pointer(UInt8), Pointer(FileInfo)) -> Int32
    alias FlushCallback    = (Pointer(UInt8), Pointer(FileInfo)) -> Int32
    alias ReadCallback     = (Pointer(UInt8), Pointer(UInt8), LibC::SizeT, Int64, Pointer(FileInfo)) -> Int32
    alias WriteCallback    = (Pointer(UInt8), Pointer(UInt8), LibC::SizeT, Int64, Pointer(FileInfo)) -> Int32
    alias CreateCallback   = (Pointer(UInt8), LibC::ModeT, Pointer(FileInfo)) -> Int32
    alias TruncateCallback = (Pointer(UInt8), Int64, Pointer(FileInfo)) -> Int32
    alias UnlinkCallback   = (Pointer(UInt8)) -> Int32
    alias MkdirCallback    = (Pointer(UInt8), LibC::ModeT) -> Int32
    alias RmdirCallback    = (Pointer(UInt8)) -> Int32
    alias RenameCallback   = (Pointer(UInt8), Pointer(UInt8), UInt32) -> Int32
    alias ChmodCallback    = (Pointer(UInt8), LibC::ModeT, Pointer(FileInfo)) -> Int32
    alias ChownCallback    = (Pointer(UInt8), LibC::UidT, LibC::GidT, Pointer(FileInfo)) -> Int32
    alias ReadlinkCallback = (Pointer(UInt8), Pointer(UInt8), LibC::SizeT) -> Int32
    alias SymlinkCallback  = (Pointer(UInt8), Pointer(UInt8)) -> Int32
    alias StatfsCallback   = (Pointer(UInt8), Void*) -> Int32
    alias AccessCallback   = (Pointer(UInt8), Int32) -> Int32
    alias InitCallback     = -> Void
    alias DestroyCallback  = -> Void
    alias FsyncCallback       = (Pointer(UInt8), Int32, Pointer(FileInfo)) -> Int32
    alias FsyncdirCallback    = (Pointer(UInt8), Int32, Pointer(FileInfo)) -> Int32
    alias OpendirCallback     = (Pointer(UInt8), Pointer(FileInfo)) -> Int32
    alias ReleasedirCallback  = (Pointer(UInt8), Pointer(FileInfo)) -> Int32
    alias MknodCallback       = (Pointer(UInt8), LibC::ModeT, LibC::DevT) -> Int32
    alias LinkCallback        = (Pointer(UInt8), Pointer(UInt8)) -> Int32
    alias SetxattrCallback    = (Pointer(UInt8), Pointer(UInt8), Pointer(UInt8), LibC::SizeT, Int32) -> Int32
    alias GetxattrCallback    = (Pointer(UInt8), Pointer(UInt8), Pointer(UInt8), LibC::SizeT) -> Int32
    alias ListxattrCallback   = (Pointer(UInt8), Pointer(UInt8), LibC::SizeT) -> Int32
    alias RemovexattrCallback = (Pointer(UInt8), Pointer(UInt8)) -> Int32
    # tv is a `struct timespec[2]` — [0] = atime, [1] = mtime — which decays to a pointer.
    alias UtimensCallback  = (Pointer(UInt8), Pointer(LibC::Timespec), Pointer(FileInfo)) -> Int32

    fun fusewrap_register_getattr(cb : GetattrCallback) : Void
    fun fusewrap_register_readdir(cb : ReaddirCallback) : Void
    fun fusewrap_register_open(cb : OpenCallback) : Void
    fun fusewrap_register_release(cb : ReleaseCallback) : Void
    fun fusewrap_register_flush(cb : FlushCallback) : Void
    fun fusewrap_register_read(cb : ReadCallback) : Void
    fun fusewrap_register_write(cb : WriteCallback) : Void
    fun fusewrap_register_create(cb : CreateCallback) : Void
    fun fusewrap_register_truncate(cb : TruncateCallback) : Void
    fun fusewrap_register_unlink(cb : UnlinkCallback) : Void
    fun fusewrap_register_mkdir(cb : MkdirCallback) : Void
    fun fusewrap_register_rmdir(cb : RmdirCallback) : Void
    fun fusewrap_register_rename(cb : RenameCallback) : Void
    fun fusewrap_register_chmod(cb : ChmodCallback) : Void
    fun fusewrap_register_chown(cb : ChownCallback) : Void
    fun fusewrap_register_readlink(cb : ReadlinkCallback) : Void
    fun fusewrap_register_symlink(cb : SymlinkCallback) : Void
    fun fusewrap_register_statfs(cb : StatfsCallback) : Void
    fun fusewrap_register_access(cb : AccessCallback) : Void
    fun fusewrap_register_utimens(cb : UtimensCallback) : Void
    fun fusewrap_register_init(cb : InitCallback) : Void
    fun fusewrap_register_destroy(cb : DestroyCallback) : Void
    fun fusewrap_register_fsync(cb : FsyncCallback) : Void
    fun fusewrap_register_fsyncdir(cb : FsyncdirCallback) : Void
    fun fusewrap_register_opendir(cb : OpendirCallback) : Void
    fun fusewrap_register_releasedir(cb : ReleasedirCallback) : Void
    fun fusewrap_register_mknod(cb : MknodCallback) : Void
    fun fusewrap_register_link(cb : LinkCallback) : Void
    fun fusewrap_register_setxattr(cb : SetxattrCallback) : Void
    fun fusewrap_register_getxattr(cb : GetxattrCallback) : Void
    fun fusewrap_register_listxattr(cb : ListxattrCallback) : Void
    fun fusewrap_register_removexattr(cb : RemovexattrCallback) : Void

    fun fusewrap_main(argc : Int32, argv : Pointer(Pointer(UInt8))) : Int32

    fun fusewrap_fill_statvfs(st : Void*,
                              bsize : LibC::ULong, frsize : LibC::ULong,
                              blocks : LibC::ULong, bfree : LibC::ULong, bavail : LibC::ULong,
                              files : LibC::ULong, ffree : LibC::ULong, namemax : LibC::ULong) : Void

    # Mirrors struct fuse_file_info from fuse3. We only ever read a few fields
    # (notably `flags` and `fh`); the bitfield is collapsed into one word.
    @[Extern]
    struct FileInfo
      flags        : LibC::Int      # 4 bytes
      bitfield     : LibC::UInt     # collapses all the :1 bitfields (4 bytes)
      padding2     : LibC::UInt
      padding3     : LibC::UInt
      fh           : UInt64         # 8 bytes
      lock_owner   : UInt64         # 8 bytes
      poll_events  : LibC::UInt     # 4 bytes
      backing_id   : LibC::Int      # 4 bytes
      compat_flags : UInt64         # 8 bytes
      reserved     : StaticArray(UInt64, 2) # 16 bytes
    end
  end
end
