require "./binding"

module Crystalfuse
  class FS
    # Hardcoded demo files
    FILES = ["hello.txt"]

    @ops : Binding::Operations
    @session : Binding::Session*
    @args : Binding::Args
    @config : Pointer(Binding::Config)

    def initialize
      @session = Pointer(Binding::Session).null

      @args = Binding::Args.new(
        argc: 0,
        argv: Pointer(Pointer(LibC::Char)).null,
        allocated: 0
      )

      @config = Pointer(Binding::Config).null

      puts "sizeof(Config): #{sizeof(Binding::Config)}"

      @ops = Binding::Operations.new
      LibC.memset(pointerof(@ops).as(Void*), 0, sizeof(Binding::Operations))

      @ops.getattr = ->(path : LibC::Char*, st : LibC::Stat*, fi : Binding::FileInfo*) : LibC::Int {
        puts "[getattr]"
        puts "path is not NULL" if !path.null?
        puts "path is NULL" if path.null?

        context = Binding.get_context()
        puts "context: #{context}"
        puts "private_data: #{context.value.private_data}"
        puts "getattr path ptr: #{path.address.to_s(16)}"

        #context = Binding.get_context()
        #raise "null context!" if context.null?
        #fs_ptr = context.value.private_data
        #raise "null private_data!" if fs_ptr.null?
        #fs = fs_ptr.as(FS*)
        #puts "about to call fs.value.getattr"
        #fs.value.getattr(path, st)

        name = path.null? ? "/" : String.new(path)
        puts name
        name = "/"

        LibC.memset(st.as(Void*), 0, sizeof(LibC::Stat))

        if name == "/" || name == "/hello.txt"
          st.value.st_mode = name == "/" ? LibC::S_IFDIR | 0o755 : LibC::S_IFREG | 0o444
          st.value.st_nlink = 1
          st.value.st_size = (name == "/hello.txt" ? 13 : 0)
          0
        else
           puts "ERROR -ENOENT"
          -LibC::ENOENT
        end
      }
      @ops.readlink = ->(path : LibC::Char*, buf : LibC::Char*, size : LibC::SizeT) : LibC::Int {
        puts "[readlink]"
        0
      }
      @ops.mknod = ->(path : LibC::Char*, mode : LibC::ModeT, rdev : LibC::DevT) : LibC::Int {
        puts "mknod"
        0
      }
      @ops.mkdir = ->(path : LibC::Char*, mode : LibC::ModeT) : LibC::Int {
        puts "mkdir"
        0
      }
      @ops.unlink = ->(path : LibC::Char*) : LibC::Int {
        puts "unlink"
        0
      }
      @ops.rmdir = ->(path : LibC::Char*) : LibC::Int {
        puts "rmdir"
        0
      }
      @ops.symlink = ->(target : LibC::Char*, linkpath : LibC::Char*) : LibC::Int {
        puts "symlink"
        0
      }
      @ops.rename = ->(from : LibC::Char*, to : LibC::Char*, flags : LibC::UInt) : LibC::Int {
        puts "rename"
        0
      }
      @ops.link = ->(from : LibC::Char*, to : LibC::Char*) : LibC::Int {
        puts "link"
        0
      }
      @ops.chmod = ->(path : LibC::Char*, mode : LibC::ModeT, fi : Binding::FileInfo*) : LibC::Int {
        puts "chmod"
        0
      }
      @ops.chown = ->(path : LibC::Char*, uid : LibC::UidT, gid : LibC::GidT, fi : Binding::FileInfo*) : LibC::Int {
        puts "chown"
        0
      }
      @ops.truncate = ->(path : LibC::Char*, size : LibC::OffT, fi : Binding::FileInfo*) : LibC::Int {
        puts "truncate"
        0
      }
      @ops.open = ->(path : LibC::Char*, fi : Binding::FileInfo*) : LibC::Int {
        puts "[open]"
        return -LibC::EINVAL if path.null? || fi.null?
        0
      }
      @ops.read = ->(path : LibC::Char*, buf : LibC::Char*, size : LibC::SizeT, offset : LibC::OffT, fi : Binding::FileInfo*) : LibC::Int {
        puts "read"
        name = String.new(path)
        return -LibC::ENOENT unless name == "/hello.txt"

        content = "Hello, world!\n"
        length = content.bytesize.to_u64
        return 0 if offset >= length

        to_read = Math.min(size, length - offset)
        Slice.new(buf, to_read).copy_from(content.to_slice[offset, to_read])
        to_read.to_i
      }
      @ops.write = ->(path : LibC::Char*, buf : LibC::Char*, size : LibC::SizeT, offset : LibC::OffT, fi : Binding::FileInfo*) : LibC::Int {
        puts "write"
        0
      }
      @ops.statfs = ->(path : LibC::Char*, st : LibC::Statvfs*) : LibC::Int {
        puts "[statfs]"
        return -LibC::EINVAL if path.null? || st.null?
        LibC.memset(st.as(Void*), 0, sizeof(LibC::Statvfs))
        0
      }
      @ops.flush = ->(path : LibC::Char*, fi : Binding::FileInfo*) : LibC::Int {
        puts "flush"
        0
      }
      @ops.release = ->(path : LibC::Char*, fi : Binding::FileInfo*) : LibC::Int {
        puts "release"
        0
      }
      @ops.fsync = ->(path : LibC::Char*, datasync : LibC::Int, fi : Binding::FileInfo*) : LibC::Int {
        puts "fsync"
        0
      }
      @ops.setxattr = ->(path : LibC::Char*, name : LibC::Char*, value : LibC::Char*, size : LibC::SizeT, flags : LibC::Int) : LibC::Int {
        puts "setxattr"
        0
      }
      @ops.getxattr = ->(path : LibC::Char*, name : LibC::Char*, value : LibC::Char*, size : LibC::SizeT) : LibC::Int {
        puts "getxattr"
        0
      }
      @ops.listxattr = ->(path : LibC::Char*, list : LibC::Char*, size : LibC::SizeT) : LibC::Int {
        puts "listxattr"
        0
      }
      @ops.removexattr = ->(path : LibC::Char*, name : LibC::Char*) : LibC::Int {
        puts "removexattr"
        0
      }
      @ops.opendir = ->(path : LibC::Char*, fi : Binding::FileInfo*) : LibC::Int {
        puts "[opendir]"
        return -LibC::EINVAL if path.null? || fi.null?
        fi.value.fh = 12345_u64  # Just a non-zero placeholder
        puts "[opendir] ok for path #{String.new(path)}"
        0
      }
      @ops.readdir = ->(path : LibC::Char*, buf : Void*, filler : Binding::FillDir, offset : LibC::OffT, fi : Binding::FileInfo*, flags : LibC::UInt) : LibC::Int {
        puts "[readdir]"
        puts "path is NULL" if path.null?
        return -LibC::EINVAL if path.null?
        name = String.new(path)
        return -LibC::ENOENT unless name == "/"
        filler.call(buf, ".".to_unsafe, Pointer(LibC::Stat).null, 0_i64, 0_u32)
        filler.call(buf, "..".to_unsafe, Pointer(LibC::Stat).null, 0_i64, 0_u32)
        filler.call(buf, "hello.txt".to_unsafe, Pointer(LibC::Stat).null, 0_i64, 0_u32)
        0
      }
      @ops.releasedir = ->(path : LibC::Char*, fi : Binding::FileInfo*) : LibC::Int {
        puts "[releasedir]"
        #return -LibC::EINVAL if path.null? || fi.null?
        0
      }
      @ops.fsyncdir = ->(path : LibC::Char*, datasync : LibC::Int, fi : Binding::FileInfo*) : LibC::Int {
        puts "fsyncdir"
        0
      }
      #@ops.init = ->(conn : Binding::ConnInfo*, cfg : Binding::Config*) : Void* {
      #  puts "[init]"
      #  Pointer(Void).null
      #}
      #@ops.init = ->(conn : Void*, cfg : Void*) : Void* {
      #  puts "[init]"
      #  #config = cfg.as(Binding::Config*)
      #  #LibC.memset(config.as(Void*), 0, sizeof(Binding::Config))
      #  #config.value.nullpath_ok = 0
      #  Pointer(Void).null
      #}
      @ops.destroy = ->(private_data : Void*) {  # : Void {
        puts "destroy"
        return
      }
      @ops.access = ->(path : LibC::Char*, mask : LibC::Int) : LibC::Int {
        puts "access"
        0
      }
      @ops.create = ->(path : LibC::Char*, mode : LibC::ModeT, fi : Binding::FileInfo*) : LibC::Int {
        puts "create"
        0
      }
      @ops.lock = ->(path : LibC::Char*, fi : Binding::FileInfo*, cmd : LibC::Int, lock : LibC::Flock*) : LibC::Int {
        puts "lock"
        0
      }
      @ops.utimens = ->(path : LibC::Char*, ts : LibC::Timespec[2], fi : Binding::FileInfo*) : LibC::Int {
        puts "utimens"
        0
      }
      @ops.bmap = ->(path : LibC::Char*, blocksize : LibC::SizeT, idx : UInt64*) : LibC::Int {
        puts "bmap"
        0
      }
      @ops.ioctl = ->(path : LibC::Char*, cmd : LibC::UInt, arg : Void*, fi : Binding::FileInfo*, flags : LibC::UInt, data : Void*) : LibC::Int {
        puts "ioctl"
        0
      }
      @ops.poll = ->(path : LibC::Char*, fi : Binding::FileInfo*, ph : Void*, reventsp : LibC::UInt*) : LibC::Int {
        puts "poll"
        0
      }
      @ops.write_buf = ->(path : LibC::Char*, bufv : Void*, offset : LibC::OffT, fi : Binding::FileInfo*) : LibC::Int {
        puts "write_buf"
        0
      }
      @ops.read_buf = ->(path : LibC::Char*, bufp : Void**, size : LibC::SizeT, offset : LibC::OffT, fi : Binding::FileInfo*) : LibC::Int {
        puts "read_buf"
        0
      }
      @ops.flock = ->(path : LibC::Char*, fi : Binding::FileInfo*, op : LibC::Int) : LibC::Int {
        puts "flock"
        0
      }
      @ops.fallocate = ->(path : LibC::Char*, mode : LibC::Int, offset : LibC::OffT, length : LibC::OffT, fi : Binding::FileInfo*) : LibC::Int {
        puts "fallocate"
        0
      }
      @ops.copy_file_range = ->(path_in : LibC::Char*, fi_in : Binding::FileInfo*, off_in : LibC::OffT, path_out : LibC::Char*, fi_out : Binding::FileInfo*, off_out : LibC::OffT, len : LibC::SizeT, flags : LibC::Int) : LibC::SSizeT {
        puts "copy_file_range"
        0_i64
      }
      @ops.lseek = ->(path : LibC::Char*, off : LibC::OffT, whence : LibC::Int, fi : Binding::FileInfo*) : LibC::OffT {
        puts "lseek"
        0_i64
      }

      #@ops.readdir = ->(path : LibC::Char*, buf : Void*, filler : Binding::FillDir, offset : LibC::OffT, fi : Binding::FileInfo*) : LibC::Int {
      #  context = Binding.get_context()
      #  fs = context.value.private_data.as(FS*)
      #  fs.value.readdir(path, buf, filler, offset, fi)
      #}
    end

    def mount(mountpoint : String)
      puts "libfuse version: #{Binding.fuse_lowlevel_version}"

      @config = Pointer(Binding::Config).malloc(1)
      LibC.memset(@config.as(Void*), 0, sizeof(Binding::Config))

      #argv = ["crystalfuse", mountpoint]
      argv = ["crystalfuse"] + ARGV
      argv_ptrs = argv.map(&.to_unsafe).to_a
      argv_data = Pointer(Pointer(LibC::Char)).malloc(argv_ptrs.size)
      argv_ptrs.each_with_index { |ptr, i| argv_data[i] = ptr }

      # TODO: local variable?
      @args = Binding::Args.new(
        argc: argv.size,
        argv: argv_data,
        allocated: 0
      )
      version = Binding::LibfuseVersion.new(
        major: 3_u32,
        minor: 17_u32,   # or whatever `fuse_lowlevel_version >> 16` gives you
        hotfix: 1_u32,
        padding: 0_u32
      )

      debug_info(@ops)

      status = Binding.fuse_main_real_versioned(
        @args.argc,
        @args.argv,
        pointerof(@ops),
        sizeof(Binding::Operations),
        pointerof(version),
        Pointer(Void).null
      )

      #Binding.opt_free_args(pointerof(@args))

      puts "fuse_main exited with #{status}"

    end

    # low-level wrong API!
      #if Binding.fuse_mount(fuse, mountpoint) != 0
      #  raise "fuse_mount failed"
      #end

      #Binding.fuse_loop(fuse)
      #Binding.fuse_destroy(fuse)
      #Binding.opt_free_args(pointerof(@args))

      #@session = Binding.session_new(
      #  pointerof(@args),
      #  pointerof(@ops),
      #  sizeof(Binding::Operations),
      #  Pointer(Void).null
      #)

      #raise "Failed to create FUSE session" if @session.null?

      #if Binding.session_mount(@session, mountpoint) != 0
      #  raise "Failed to mount filesystem"
      #end

      #Binding.session_loop(@session)
      #Binding.session_unmount(@session)
      #Binding.session_destroy(@session)
      #Binding.opt_free_args(pointerof(@args))


    def debug_info(ops)
      puts "sizeof(Operations): #{sizeof(Binding::Operations)}"
      puts "sizeof(ConnInfo): #{sizeof(Binding::ConnInfo)}"
      puts "sizeof(Config): #{sizeof(Binding::Config)}"
      puts "sizeof(Context): #{sizeof(Binding::Context)}"
      puts "sizeof(FileInfo): #{sizeof(Binding::FileInfo)}"

      puts "ops_ptr: 0x#{pointerof(ops).address.to_s(16)}"

      ops_ptr = pointerof(ops).as(Void*).as(UInt64*)
      puts "init ptr:        0x#{ops_ptr[27].to_s(16)}"
      puts "getattr ptr:     0x#{ops_ptr[0].to_s(16)}"
      puts "readlink ptr:    0x#{ops_ptr[1].to_s(16)}"
      puts "opendir ptr:     0x#{ops_ptr[24].to_s(16)}"
      puts "readdir ptr:     0x#{ops_ptr[25].to_s(16)}"
      puts "releasedir ptr:  0x#{ops_ptr[26].to_s(16)}"
    end

    # --- TODO: Will be Actual FUSE Callbacks? ---
    def getattr(path : Pointer(LibC::Char), st : Pointer(LibC::Stat)) : LibC::Int
      LibC.memset(st.as(Void*), 0, sizeof(LibC::Stat))
      name = String.new(path)
      if name == "/" || name == "/hello.txt"
        st.value.st_mode = name == "/" ? LibC::S_IFDIR | 0o755 : LibC::S_IFREG | 0o444
        st.value.st_nlink = 1
        st.value.st_size = name == "/hello.txt" ? 13 : 0
        return 0
      end
      return -LibC::ENOENT
    end

    def readdir(path, buf, filler, offset, fi)
      name = String.new(path)
      return -LibC::ENOENT unless name == "/"

      filler.call(buf, ".".to_unsafe, Pointer(LibC::Stat).null, LibC::OffT.new(0))
      filler.call(buf, "..".to_unsafe, Pointer(LibC::Stat).null, LibC::OffT.new(0))
      FILES.each do |file|
        filler.call(buf, file.to_unsafe, Pointer(LibC::Stat).null, LibC::OffT.new(0))
      end
      0
    end

  end

end
