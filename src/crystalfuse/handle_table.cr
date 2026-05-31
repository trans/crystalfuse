# handle_table.cr
#
# OPTIONAL helper — not loaded by `require "crystalfuse"`. Pull it in explicitly
# with `require "crystalfuse/handle_table"` if you want a ready-made registry
# for file handles.
#
# Typical use from a FuseFS:
#
#     @open = Crystalfuse::HandleTable(MyOpenFile).new
#
#     def open(path : String, fi : Crystalfuse::FileInfo) : Int32
#       fi.fh = @open.add(MyOpenFile.new(path))
#       0
#     end
#
#     def read(path, size, offset, fi : Crystalfuse::FileInfo) : Bytes | Int32
#       (f = @open[fi.fh]?) ? f.read(size, offset) : -Errno::EBADF.value
#     end
#
#     def release(path, fi : Crystalfuse::FileInfo) : Int32
#       @open.delete(fi.fh)
#       0
#     end
module Crystalfuse
  # Maps FUSE file handles (`fh`, a `UInt64`) to arbitrary open-file state of
  # type *T*. Handles are minted from a monotonically increasing counter
  # starting at 1 (0 is left as a "no handle" sentinel).
  class HandleTable(T)
    def initialize
      @next = 1_u64
      @entries = {} of UInt64 => T
    end

    # Register *value* and return a fresh handle for it.
    def add(value : T) : UInt64
      fh = @next
      @next &+= 1
      @entries[fh] = value
      fh
    end

    # The value for *fh*, or raise (`KeyError`) if unknown.
    def [](fh : UInt64) : T
      @entries[fh]
    end

    # The value for *fh*, or `nil` if unknown.
    def []?(fh : UInt64) : T?
      @entries[fh]?
    end

    # Forget *fh*, returning the value it held (or `nil`).
    def delete(fh : UInt64) : T?
      @entries.delete(fh)
    end

    # Number of currently-open handles.
    def size : Int32
      @entries.size
    end
  end
end
