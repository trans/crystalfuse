require "./fuse/*"
require "./crystalfuse/*"

# THIS GOT MESSED DUP SOMEHOW!

# Bindings for FUSE
module Fuse

  def Crystalfuse.mount(fs : FuseFS, args : Array(String)) : Int32
    FuseBridge.set_instance(fs)
    FuseBridge.register_callbacks

    argv = args.map(&.to_unsafe).to_a
    argv_data = Pointer(Pointer(UInt8)).malloc(argv.size)
  argv.each_with_index { |ptr, i| argv_data[i] = ptr }

    FuseWrap.fusewrap_main(argv.size, argv_data)
  end

end

