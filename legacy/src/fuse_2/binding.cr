require "./libc"

module Crystalfuse
  @[Link("fuse3")]
  lib Binding
    fun fuse_lowlevel_version : LibC::Int

    # --- Aliases ---
    @[CallingConvention("C")]
    alias GetAttr         = LibC::Char*, LibC::Stat*, Binding::FileInfo* -> LibC::Int
    @[CallingConvention("C")]
    alias Readlink        = LibC::Char*, LibC::Char*, LibC::SizeT -> LibC::Int
    @[CallingConvention("C")]
    alias Mknod           = LibC::Char*, LibC::ModeT, LibC::DevT -> LibC::Int
    @[CallingConvention("C")]
    alias Mkdir           = LibC::Char*, LibC::ModeT -> LibC::Int
    @[CallingConvention("C")]
    alias Unlink          = LibC::Char* -> LibC::Int
    @[CallingConvention("C")]
    alias Rmdir           = LibC::Char* -> LibC::Int
    @[CallingConvention("C")]
    alias Symlink         = LibC::Char*, LibC::Char* -> LibC::Int
    @[CallingConvention("C")]
    alias Rename          = LibC::Char*, LibC::Char*, LibC::UInt -> LibC::Int
    @[CallingConvention("C")]
    alias Link            = LibC::Char*, LibC::Char* -> LibC::Int
    @[CallingConvention("C")]
    alias Chmod           = LibC::Char*, LibC::ModeT, Binding::FileInfo* -> LibC::Int
    @[CallingConvention("C")]
    alias Chown           = LibC::Char*, LibC::UidT, LibC::GidT, Binding::FileInfo* -> LibC::Int
    @[CallingConvention("C")]
    alias Truncate        = LibC::Char*, LibC::OffT, Binding::FileInfo* -> LibC::Int
    @[CallingConvention("C")]
    alias Open            = LibC::Char*, Binding::FileInfo* -> LibC::Int
    @[CallingConvention("C")]
    alias Read            = LibC::Char*, LibC::Char*, LibC::SizeT, LibC::OffT, Binding::FileInfo* -> LibC::Int
    @[CallingConvention("C")]
    alias Write           = LibC::Char*, LibC::Char*, LibC::SizeT, LibC::OffT, Binding::FileInfo* -> LibC::Int
    @[CallingConvention("C")]
    alias Statfs          = LibC::Char*, LibC::Statvfs* -> LibC::Int
    @[CallingConvention("C")]
    alias Flush           = LibC::Char*, Binding::FileInfo* -> LibC::Int
    @[CallingConvention("C")]
    alias Release         = LibC::Char*, Binding::FileInfo* -> LibC::Int
    @[CallingConvention("C")]
    alias Fsync           = LibC::Char*, LibC::Int, Binding::FileInfo* -> LibC::Int
    @[CallingConvention("C")]
    alias Setxattr        = LibC::Char*, LibC::Char*, LibC::Char*, LibC::SizeT, LibC::Int -> LibC::Int
    @[CallingConvention("C")]
    alias Getxattr        = LibC::Char*, LibC::Char*, LibC::Char*, LibC::SizeT -> LibC::Int
    @[CallingConvention("C")]
    alias Listxattr       = LibC::Char*, LibC::Char*, LibC::SizeT -> LibC::Int
    @[CallingConvention("C")]
    alias Removexattr     = LibC::Char*, LibC::Char* -> LibC::Int
    @[CallingConvention("C")]
    alias Opendir         = LibC::Char*, Binding::FileInfo* -> LibC::Int
    @[CallingConvention("C")]
    alias FillDir         = Void*, LibC::Char*, LibC::Stat*, LibC::OffT, LibC::UInt -> LibC::Int
    @[CallingConvention("C")]
    alias Readdir         = LibC::Char*, Void*, FillDir, LibC::OffT, Binding::FileInfo*, LibC::UInt -> LibC::Int
    @[CallingConvention("C")]
    alias Releasedir      = LibC::Char*, Binding::FileInfo* -> LibC::Int
    @[CallingConvention("C")]
    alias Fsyncdir        = LibC::Char*, LibC::Int, Binding::FileInfo* -> LibC::Int
    @[CallingConvention("C")]
    alias Init = Binding::ConnInfo*, Binding::Config* -> Void*
    @[CallingConvention("C")]
    alias Destroy         = Void* -> Void
    @[CallingConvention("C")]
    alias Access          = LibC::Char*, LibC::Int -> LibC::Int
    @[CallingConvention("C")]
    alias Create          = LibC::Char*, LibC::ModeT, Binding::FileInfo* -> LibC::Int
    @[CallingConvention("C")]
    alias Lock            = LibC::Char*, Binding::FileInfo*, LibC::Int, LibC::Flock* -> LibC::Int
    @[CallingConvention("C")]
    alias Utimens         = LibC::Char*, LibC::Timespec[2], Binding::FileInfo* -> LibC::Int
    @[CallingConvention("C")]
    alias Bmap            = LibC::Char*, LibC::SizeT, UInt64* -> LibC::Int  # TODO: Should this be UInt64T ?
    @[CallingConvention("C")]
    alias Ioctl           = LibC::Char*, LibC::UInt, Void*, Binding::FileInfo*, LibC::UInt, Void* -> LibC::Int
    @[CallingConvention("C")]
    alias Poll            = LibC::Char*, Binding::FileInfo*, Void*, LibC::UInt* -> LibC::Int
    @[CallingConvention("C")]
    alias WriteBuf        = LibC::Char*, Void*, LibC::OffT, FileInfo* -> LibC::Int
    @[CallingConvention("C")]
    alias ReadBuf         = LibC::Char*, Void**, LibC::SizeT, LibC::OffT, Binding::FileInfo* -> LibC::Int
    @[CallingConvention("C")]
    alias Flock           = LibC::Char*, Binding::FileInfo*, LibC::Int -> LibC::Int
    @[CallingConvention("C")]
    alias Fallocate       = LibC::Char*, LibC::Int, LibC::OffT, LibC::OffT, Binding::FileInfo* -> LibC::Int
    @[CallingConvention("C")]
    alias CopyFileRange   = LibC::Char*, Binding::FileInfo*, LibC::OffT, LibC::Char*, Binding::FileInfo*, LibC::OffT, LibC::SizeT, LibC::Int -> LibC::SSizeT
    @[CallingConvention("C")]
    alias Lseek           = LibC::Char*, LibC::OffT, LibC::Int, Binding::FileInfo* -> LibC::OffT

    # --- Types ---
    type Session = Void

    @[Extern]
    struct Operations
      getattr         : GetAttr
      readlink        : Readlink
      mknod           : Mknod
      mkdir           : Mkdir
      unlink          : Unlink
      rmdir           : Rmdir
      symlink         : Symlink
      rename          : Rename
      link            : Link
      chmod           : Chmod
      chown           : Chown
      truncate        : Truncate
      open            : Open
      read            : Read
      write           : Write
      statfs          : Statfs
      flush           : Flush
      release         : Release
      fsync           : Fsync
      setxattr        : Setxattr
      getxattr        : Getxattr
      listxattr       : Listxattr
      removexattr     : Removexattr
      opendir         : Opendir
      readdir         : Readdir
      releasedir      : Releasedir
      fsyncdir        : Fsyncdir
      init            : Init
      destroy         : Destroy
      access          : Access
      create          : Create
      lock            : Lock
      utimens         : Utimens
      bmap            : Bmap
      ioctl           : Ioctl
      poll            : Poll
      write_buf       : WriteBuf
      read_buf        : ReadBuf
      flock           : Flock
      fallocate       : Fallocate
      copy_file_range : CopyFileRange
      lseek           : Lseek
    end

    @[Extern]
    struct Args
      argc      : LibC::Int
      argv      : Pointer(Pointer(LibC::Char))
      allocated : LibC::Int
    end

    @[Extern]
    struct Config
      set_gid             : LibC::Int32T
      gid                 : LibC::UInt32T
      set_uid             : LibC::Int32T
      uid                 : LibC::UInt32T
      set_mode            : LibC::Int32T
      umask               : LibC::UInt32T
      entry_timeout       : Float64
      negative_timeout    : Float64
      attr_timeout        : Float64
      intr                : LibC::Int32T
      intr_signal         : LibC::Int32T
      remember            : LibC::Int32T
      hard_remove         : LibC::Int32T
      use_ino             : LibC::Int32T
      readdir_ino         : LibC::Int32T
      direct_io           : LibC::Int32T
      kernel_cache        : LibC::Int32T
      auto_cache          : LibC::Int32T
      ac_attr_timeout_set : LibC::Int32T
      ac_attr_timeout     : Float64
      nullpath_ok         : LibC::Int32T
      show_help           : LibC::Int32T
      modules             : Pointer(LibC::Char)
      debug               : LibC::Int32T
      fmask               : LibC::UInt32T
      dmask               : LibC::UInt32T
      no_rofd_flush       : LibC::Int32T
      parallel_direct_writes : LibC::Int32T
      flags               : LibC::UInt32T
      reserved            : StaticArray(UInt64, 48)
    end

    @[Extern]
    struct Context
      fuse : Void*
      uid : LibC::UidT
      gid : LibC::GidT
      pid : LibC::PidT
      private_data : Void*
      umask : LibC::ModeT
    end

    #@[Extern]
    #struct FileInfo
    #  flags                   : LibC::Int32T
    #  writepage               : LibC::UInt
    #  direct_io               : LibC::UInt
    #  keep_cache              : LibC::UInt
    #  flush                   : LibC::UInt
    #  nonseekable             : LibC::UInt
    #  flock_release           : LibC::UInt
    #  cache_readdir           : LibC::UInt
    #  noflush                 : LibC::UInt
    #  parallel_direct_writes  : LibC::UInt
    #  padding                 : LibC::UInt
    #  padding2                : LibC::UInt
    #  padding3                : LibC::UInt
    #  fh                      : LibC::UInt64T
    #  lock_owner              : LibC::UInt64T
    #  poll_events             : LibC::UInt
    #  backing_id              : LibC::Int
    #  compat_flags            : LibC::UInt64T
    #  reserved                : StaticArray(LibC::UInt64T, 2)
    #end

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

    @[Extern]
    struct ConnInfo
      proto_major    : LibC::UInt32T
      proto_minor    : LibC::UInt32T
      async_read     : LibC::UInt32T
      max_write      : LibC::UInt32T
      max_readahead  : LibC::UInt32T
      capable        : LibC::UInt32T
      want           : LibC::UInt32T
      max_background : LibC::UInt32T
      congestion_threshold : LibC::UInt32T
      time_gran      : LibC::UInt32T
      reserved       : StaticArray(LibC::UInt32T, 22)
    end

    @[Extern]
    struct LibfuseVersion
      major   : LibC::UInt32T
      minor   : LibC::UInt32T
      hotfix  : LibC::UInt32T
      padding : LibC::UInt32T
    end

    # --- Functions ---
    fun get_context = fuse_get_context : Context*
    fun opt_free_args = fuse_opt_free_args(args : Args*) : Void

    fun fuse_main_real_versioned(
      argc : LibC::Int,
      argv : Pointer(Pointer(LibC::Char)),
      ops : Crystalfuse::Binding::Operations*,
      op_size : LibC::SizeT,
      version : Crystalfuse::Binding::LibfuseVersion*,
      user_data : Void*
    ) : LibC::Int

    # --- Low-Level, not using stuff below here.

    fun fuse_mount(fuse : Void*, mountpoint : LibC::Char*) : LibC::Int
    fun fuse_loop(fuse : Void*) : LibC::Int
    fun fuse_destroy(fuse : Void*) : Void

    fun session_new = fuse_session_new(
      args : Args*,
      op : Operations*,
      op_size : LibC::SizeT,
      user_data : Void*
    ) : Session*

    fun session_mount = fuse_session_mount(
      se : Session*,
      mountpoint : LibC::Char*
    ) : LibC::Int

    fun session_unmount = fuse_session_unmount(
      se : Session*
    ) : Void

    fun session_destroy = fuse_session_destroy(
      se : Session*
    ) : Void

    fun session_loop = fuse_session_loop(
      se : Session*
    ) : LibC::Int

  end
end
