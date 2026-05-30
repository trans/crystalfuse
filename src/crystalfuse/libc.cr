# libc.cr
#
# The one libc function the binding needs that isn't already declared in
# Crystal's stdlib `LibC` for our use here.
@[Link("c")]
lib LibC
  fun memset(dest : Void*, c : Int32, n : LibC::SizeT) : Void*
end
