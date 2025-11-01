#require "./wrapper"

module Crystalfuse

  class FS

    # call back
    def fuse_getattr(path : Pointer(UInt8), st : Pointer(LibC::Stat), fi : Pointer(Void)) : Int32
      0
    end

    def run!
      Crystalfuse.register_callbacks

      # --- Build argv ---
      args = ["crystalfuse", "-f", "-d", "./tmp/mnt"]
      argv = args.map(&.to_unsafe).to_a
      argv_data = Pointer(Pointer(UInt8)).malloc(argv.size)
      argv.each_with_index { |ptr, i| argv_data[i] = ptr }

      # --- Call the wrapper ---
      status = Crystalfuse::FuseWrap.fusewrap_main(argv.size, argv_data)
      puts "fusewrap_main exited with #{status}"

      # --- Clean up ---
      # (not strictly necessary here but good form)
      #argv_data.free
    end

  end

  def self.register_callbacks
    cb = ->(path : Pointer(UInt8), st : Pointer(LibC::Stat), fi : Pointer(FuseWrap::FileInfo)) : Int32 {
      name = String.new(path)
      puts "Crystal getattr called for #{name}"

      LibC.memset(st.as(Void*), 0, sizeof(LibC::Stat))
      if name == "/" || name == "/hello.txt"
        st.value.st_mode = name == "/" ? LibC::S_IFDIR | 0o755 : LibC::S_IFREG | 0o444
        st.value.st_nlink = 1
        st.value.st_size = 22
        0
      else
        -LibC::ENOENT
      end
    }

    FuseWrap.fusewrap_register_getattr(cb)
  end

end
