# src/fuse_fs.cr
require "./fuse_wrap"
require "./file_attr"
require "./file_info"

module Crystalfuse

  abstract class FuseFS
    # Called when the kernel requests attributes for a file
    def getattr(path : String) : FileAttr | Int32
      # Return -Errno if not found
      -Errno::ENOENT.value
    end
    #abstract def getattr(path : String, out : FileInfoBridge) : Int32

    # Called when a directory is opened and its contents listed
    def readdir(path : String) : Array(String) | Int32
      -Errno::ENOENT.value
    end

    # Called when a file is opened
    def open(path : String) : Int32
      0  # return 0 for success
    end

    # Called to read data from an open file
    def read(path : String, size : Int32, offset : Int64) : Bytes | Int32
      -Errno::ENOENT
    end

    def statfs(path : String) : LibC::Statvfs | Int32
      -Errno::ENOENT
    end

    def access(path : String, mask : Int32) : Int32
      0
    end

    # Don't override this method.
    def mount(args : Array(String)) : Int32
      Crystalfuse.mount self, args
    end

    # Start the filesystem (bootstraps C wrapper)
    #
    # TODO: rename run -or- mount ?
    # TODO: should we control the arguments, instead of just passing them to libfuse?

    #def run(args : Array(String))
    #  FuseBridge.register_callbacks
    #
    #  argv = args.map(&.to_unsafe).to_a
    #  argv_data = Pointer(Pointer(UInt8)).malloc(argv.size)
    #  argv.each_with_index { |ptr, i| argv_data[i] = ptr }
    #
    #  FuseWrap.fusewrap_main(argv.size, argv_data)
    #end

    #def mount(mountpoint : String)
    #  argv = ["crystalfuse", mountpoint]
    #  argv_data = Pointer(Pointer(UInt8)).malloc(argv_ptrs.size)
    #  argv_ptrs.each_with_index { |ptr, i| argv_data[i] = ptr }
    #
    #  FuseFS.register(self)
    #  FuseWrap.fusewrap_main(argv.size, argv_data)
    #end

  end

end
