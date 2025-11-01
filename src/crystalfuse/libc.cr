@[Link("c")]
lib LibC

  fun memset(dest : Void*, c : Int32, n : LibC::SizeT) : Void*

  struct Statvfs
    f_bsize   : LibC::ULong
    f_frsize  : LibC::ULong
    f_blocks  : LibC::ULong
    f_bfree   : LibC::ULong
    f_bavail  : LibC::ULong
    f_files   : LibC::ULong
    f_ffree   : LibC::ULong
    f_favail  : LibC::ULong
    f_fsid    : LibC::ULong
    f_flag    : LibC::ULong
    f_namemax : LibC::ULong
    __f_spare : LibC::ULong[6]
  end

  fun return_void : Void

end
