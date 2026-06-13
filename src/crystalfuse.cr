# crystalfuse.cr
#
# Crystal bindings to libFUSE (FUSE 3.x), via a thin C shim that owns the
# `struct fuse_operations` table. Subclass `Fuse::FS`, override the
# operations you need, and call `#mount`.
require "./crystalfuse/version"
require "./crystalfuse/libc"
require "./crystalfuse/file_attr"
require "./crystalfuse/statvfs"
require "./crystalfuse/fuse_wrap"
require "./crystalfuse/file_info"
require "./crystalfuse/dir_filler"
require "./crystalfuse/file_system"
require "./crystalfuse/fuse_bridge"

module Fuse
  # Mount *fs*, passing *args* (an argv-style array, e.g.
  # `["myfs", "-f", "/mnt/point"]`) straight through to libfuse. Blocks until
  # the filesystem is unmounted. Returns libfuse's exit status.
  def self.mount(fs : FileSystem, args : Array(String)) : Int32
    Bridge.set_instance(fs)
    Bridge.register_callbacks

    # Build a C argv from the Crystal strings (which stay alive via *args*).
    argv = args.map(&.to_unsafe)
    argv_data = Pointer(Pointer(UInt8)).malloc(argv.size)
    argv.each_with_index { |ptr, i| argv_data[i] = ptr }

    Wrap.fusewrap_main(argv.size, argv_data)
  end
end
