@[Link("c")]
lib LibC
  fun memset(dest : Void*, c : Int32, n : LibC::SizeT) : Void*

  struct Statvfs
    f_bsize : LibC::ULong
    f_frsize : LibC::ULong
    f_blocks : LibC::ULong
    f_bfree : LibC::ULong
    f_bavail : LibC::ULong
    f_files : LibC::ULong
    f_ffree : LibC::ULong
    f_favail : LibC::ULong
    f_fsid : LibC::ULong
    f_flag : LibC::ULong
    f_namemax : LibC::ULong
    __f_spare : LibC::ULong[6]
  end
end

@[Link("fuse3")]
lib Fuse
  type Session = Void

  #@[Extern]
  struct Config
    set_gid             : Int32
    gid                 : UInt32
    set_uid             : Int32
    uid                 : UInt32
    set_mode            : Int32
    umask               : UInt32
    entry_timeout       : Float64
    negative_timeout    : Float64
    attr_timeout        : Float64
    intr                : Int32
    intr_signal         : Int32
    remember            : Int32
    hard_remove         : Int32
    use_ino             : Int32
    readdir_ino         : Int32
    direct_io           : Int32
    kernel_cache        : Int32
    auto_cache          : Int32
    ac_attr_timeout_set : Int32
    ac_attr_timeout     : Float64
    nullpath_ok         : Int32  # <- this is the field we care about
    show_help           : Int32
    modules             : Void*  # technically char*, but we don't use it
    debug               : Int32
    fmask               : UInt32
    dmask               : UInt32
    no_rofd_flush       : Int32
    parallel_direct_writes : Int32
    flags               : UInt32
    reserved            : UInt64[48]  # filler padding for future options
  end

  struct Context
    fuse : Void*
    uid : LibC::UidT
    gid : LibC::GidT
    pid : LibC::PidT
    private_data : Void*
    umask : LibC::ModeT
  end

  struct FileInfo
    flags : LibC::Int
    writepage : LibC::Int
    direct_io : LibC::UInt
    keep_cache : LibC::UInt
    flush : LibC::UInt
    nonseekable : LibC::UInt
    fh : LibC::UInt64T
    lock_owner : LibC::UInt64T
  end

  @[CallingConvention("C")]
  alias GetAttr         = LibC::Char*, LibC::Stat*, Fuse::FileInfo* -> LibC::Int
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
  alias Chmod           = LibC::Char*, LibC::ModeT, Fuse::FileInfo* -> LibC::Int
  @[CallingConvention("C")]
  alias Chown           = LibC::Char*, LibC::UidT, LibC::GidT, Fuse::FileInfo* -> LibC::Int
  @[CallingConvention("C")]
  alias Truncate        = LibC::Char*, LibC::OffT, Fuse::FileInfo* -> LibC::Int
  @[CallingConvention("C")]
  alias Open            = LibC::Char*, Fuse::FileInfo* -> LibC::Int
  @[CallingConvention("C")]
  alias Read            = LibC::Char*, LibC::Char*, LibC::SizeT, LibC::OffT, Fuse::FileInfo* -> LibC::Int
  @[CallingConvention("C")]
  alias Write           = LibC::Char*, LibC::Char*, LibC::SizeT, LibC::OffT, Fuse::FileInfo* -> LibC::Int
  @[CallingConvention("C")]
  alias Statfs          = LibC::Char*, LibC::Statvfs* -> LibC::Int
  @[CallingConvention("C")]
  alias Flush           = LibC::Char*, Fuse::FileInfo* -> LibC::Int
  @[CallingConvention("C")]
  alias Release         = LibC::Char*, Fuse::FileInfo* -> LibC::Int
  @[CallingConvention("C")]
  alias Fsync           = LibC::Char*, LibC::Int, Fuse::FileInfo* -> LibC::Int
  @[CallingConvention("C")]
  alias Setxattr        = LibC::Char*, LibC::Char*, LibC::Char*, LibC::SizeT, LibC::Int -> LibC::Int
  @[CallingConvention("C")]
  alias Getxattr        = LibC::Char*, LibC::Char*, LibC::Char*, LibC::SizeT -> LibC::Int
  @[CallingConvention("C")]
  alias Listxattr       = LibC::Char*, LibC::Char*, LibC::SizeT -> LibC::Int
  @[CallingConvention("C")]
  alias Removexattr     = LibC::Char*, LibC::Char* -> LibC::Int
  @[CallingConvention("C")]
  alias Opendir         = LibC::Char*, Fuse::FileInfo* -> LibC::Int
  @[CallingConvention("C")]
  alias FillDir         = Void*, LibC::Char*, LibC::Stat*, LibC::OffT, LibC::UInt -> LibC::Int
  @[CallingConvention("C")]
  alias Readdir         = LibC::Char*, Void*, FillDir, LibC::OffT, Fuse::FileInfo*, LibC::UInt -> LibC::Int
  @[CallingConvention("C")]
  alias Releasedir      = LibC::Char*, Fuse::FileInfo* -> LibC::Int
  @[CallingConvention("C")]
  alias Fsyncdir        = LibC::Char*, LibC::Int, Fuse::FileInfo* -> LibC::Int
  @[CallingConvention("C")]
  alias Init            = Void*, Void* -> Void*
  @[CallingConvention("C")]
  alias Destroy         = Void* -> Void
  @[CallingConvention("C")]
  alias Access          = LibC::Char*, LibC::Int -> LibC::Int
  @[CallingConvention("C")]
  alias Create          = LibC::Char*, LibC::ModeT, Fuse::FileInfo* -> LibC::Int
  @[CallingConvention("C")]
  alias Lock            = LibC::Char*, Fuse::FileInfo*, LibC::Int, LibC::Flock* -> LibC::Int
  @[CallingConvention("C")]
  alias Utimens         = LibC::Char*, LibC::Timespec[2], Fuse::FileInfo* -> LibC::Int
  @[CallingConvention("C")]
  alias Bmap            = LibC::Char*, LibC::SizeT, UInt64* -> LibC::Int
  @[CallingConvention("C")]
  alias Ioctl           = LibC::Char*, LibC::UInt, Void*, Fuse::FileInfo*, LibC::UInt, Void* -> LibC::Int
  @[CallingConvention("C")]
  alias Poll            = LibC::Char*, Fuse::FileInfo*, Void*, LibC::UInt* -> LibC::Int
  @[CallingConvention("C")]
  alias WriteBuf        = LibC::Char*, Void*, LibC::OffT, Fuse::FileInfo* -> LibC::Int
  @[CallingConvention("C")]
  alias ReadBuf         = LibC::Char*, Void**, LibC::SizeT, LibC::OffT, Fuse::FileInfo* -> LibC::Int
  @[CallingConvention("C")]
  alias Flock           = LibC::Char*, Fuse::FileInfo*, LibC::Int -> LibC::Int
  @[CallingConvention("C")]
  alias Fallocate       = LibC::Char*, LibC::Int, LibC::OffT, LibC::OffT, Fuse::FileInfo* -> LibC::Int
  @[CallingConvention("C")]
  alias CopyFileRange   = LibC::Char*, Fuse::FileInfo*, LibC::OffT, LibC::Char*, Fuse::FileInfo*, LibC::OffT, LibC::SizeT, LibC::Int -> LibC::SSizeT
  @[CallingConvention("C")]
  alias Lseek           = LibC::Char*, LibC::OffT, LibC::Int, Fuse::FileInfo* -> LibC::OffT

  @[Packed]
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

  struct Args
    argc : LibC::Int
    argv : Pointer(Pointer(LibC::Char))
    allocated : LibC::Int
  end

  fun get_context = fuse_get_context : Context*
  fun session_new = fuse_session_new(args : Args*, op : Operations*, op_size : LibC::SizeT, user_data : Void*) : Session*
  fun session_mount = fuse_session_mount(se : Session*, mountpoint : LibC::Char*) : LibC::Int
  fun session_unmount = fuse_session_unmount(se : Session*) : Void
  fun session_destroy = fuse_session_destroy(se : Session*) : Void
  fun session_loop = fuse_session_loop(se : Session*) : LibC::Int

  fun main = fuse_main(
    argc : LibC::Int,
    argv : Pointer(Pointer(LibC::Char)),
    op : Operations*,
    user_data : Void*
  ) : LibC::Int
end

class MyFS
  @ops : Fuse::Operations
  #@args : Fuse::Args?
  #@session : Fuse::Session*

  def initialize
    puts "sizeof(Operations) = #{sizeof(Fuse::Operations)}"

    @ops = Fuse::Operations.new

    @ops.init = ->(conn : Void*, cfg : Void*) : Void* {
      puts "[init] setting nullpath_ok = 0"
      config = cfg.as(Fuse::Config*)
      config.value.nullpath_ok = 0
      Pointer(Void).null
    }

    @ops.statfs = ->(path : LibC::Char*, st : LibC::Statvfs*) : LibC::Int {
      return -LibC::EINVAL if path.null? || st.null?
      LibC.memset(st.as(Void*), 0, sizeof(LibC::Statvfs))
      0
    }

    @ops.getattr = ->(path : LibC::Char*, st : LibC::Stat*, fi : Fuse::FileInfo*) : LibC::Int {
      if path.null?
        puts "getattr received NULL path"
        #return -LibC::EINVAL
      end

      name = path ? String.new(path) : "".to_unsafe
      LibC.memset(st.as(Void*), 0, sizeof(LibC::Stat))
      if name == "/" || name == "/hello.txt"
        st.value.st_mode = name == "/" ? LibC::S_IFDIR | 0o755 : LibC::S_IFREG | 0o444
        st.value.st_nlink = 1
        st.value.st_size = (name == "/hello.txt" ? 13 : 0)
        0
      else
        -LibC::ENOENT
      end
    }

    @ops.open = ->(path : LibC::Char*, fi : Fuse::FileInfo*) : LibC::Int {
      return -LibC::EINVAL if path.null? || fi.null?
      0
    }

    @ops.readdir = ->(path : LibC::Char*, buf : Void*, filler : Fuse::FillDir, offset : LibC::OffT, fi : Fuse::FileInfo*, flags : LibC::UInt) : LibC::Int {
      puts "[readdir] called"
      puts "path is NULL" if path.null?
      return -LibC::EINVAL if path.null?
      name = String.new(path)
      return -LibC::ENOENT unless name == "/"
      filler.call(buf, ".".to_unsafe, Pointer(LibC::Stat).null, 0_i64, 0_u32)
      filler.call(buf, "..".to_unsafe, Pointer(LibC::Stat).null, 0_i64, 0_u32)
      filler.call(buf, "hello.txt".to_unsafe, Pointer(LibC::Stat).null, 0_i64, 0_u32)
      0
    }

    @ops.opendir = ->(path : LibC::Char*, fi : Fuse::FileInfo*) : LibC::Int {
      puts "[opendir]"
      return -LibC::EINVAL if path.null? || fi.null?
      fi.value.fh = 12345_u64  # Just a non-zero placeholder
      puts "[opendir] ok for path #{String.new(path)}"
      0
    }

    @ops.releasedir = ->(path : LibC::Char*, fi : Fuse::FileInfo*) : LibC::Int {
      return -LibC::EINVAL if path.null? || fi.null?
      0
    }
  end

  def mount(mountpoint : String)
    argv = ["myfs"]
    argv_ptrs = argv.map(&.to_unsafe).to_a
    argv_buf = Pointer(Pointer(LibC::Char)).malloc(argv_ptrs.size)
    argv_ptrs.each_with_index { |ptr, i| argv_buf[i] = ptr }

    args = Fuse::Args.new(argc: argv.size, argv: argv_buf, allocated: 0)

    #puts "getattr ptr: #{@ops.getattr}"
    #puts "readdir ptr: #{@ops.readdir}"
    #puts "opendir ptr: #{@ops.opendir}"
    #puts "releasedir ptr: #{@ops.releasedir}"

    raw_ptr = pointerof(@ops).as(Void*).as(UInt64*)[24]
    puts "opendir ptr: 0x#{raw_ptr.to_s(16)}"

    raw_ptr = pointerof(@ops).as(Void*).as(UInt64*)[25]
    puts "readdir ptr: 0x#{raw_ptr.to_s(16)}"

    session = Fuse.session_new(pointerof(args), pointerof(@ops), sizeof(Fuse::Operations), self.as(Void*))
    #session = Fuse.session_new(pointerof(args), pointerof(@ops), sizeof(Fuse::Operations), Pointer(Void).null)
    raise "session_new failed" if session.null?

    raise "mount failed" if Fuse.session_mount(session, mountpoint) != 0
    Fuse.session_loop(session)
    Fuse.session_unmount(session)
    Fuse.session_destroy(session)
  end

end
