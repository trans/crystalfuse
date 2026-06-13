require "./fuse_wrap"

module Fuse
  # Streaming directory filler, passed to the escape-hatch form of `readdir`.
  # Push entries as you discover them with `<<` (or `add`), so a directory with
  # a huge number of entries needn't be materialized into an `Array(String)`
  # first.
  #
  #     def readdir(path : String, filler : Fuse::DirFiller, fi) : Int32
  #       filler << "." << ".."
  #       each_entry(path) { |name| filler << name }
  #       0
  #     end
  struct DirFiller
    def initialize(@buf : Void*, @filler : Wrap::FillDir)
    end

    # Add one directory entry by name. Returns self so calls can be chained.
    def add(name : String) : self
      @filler.call(@buf, name.to_unsafe, Pointer(LibC::Stat).null, 0_i64, 0_u32)
      self
    end

    # :ditto:
    def <<(name : String) : self
      add(name)
    end
  end
end
