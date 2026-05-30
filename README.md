# crystalfuse

Crystal bindings to [libFUSE](https://github.com/libfuse/libfuse) (FUSE 3.x),
letting you write a userspace filesystem in Crystal.

Internally a thin C shim (`c/fuse_wrapper.c`) owns the `struct fuse_operations`
table — so the C compiler, not Crystal, is responsible for the struct layout —
and forwards every operation to a callback implemented in Crystal.

## Requirements

- Crystal 1.16+
- `libfuse3` and its development headers (`pkg-config fuse3` must work)
- `gcc` / `make` to build the C shim

On Arch: `pacman -S fuse3`. On Debian/Ubuntu: `apt install libfuse3-dev`.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  crystalfuse:
    github: trans/crystalfuse
```

The C shim is built with `make` (it produces the static archive
`c/libfusewrap.a`, which the Crystal bindings link against via `@[Link]`).

## Usage

Subclass `Crystalfuse::FuseFS`, override the operations you need, and call
`#mount`. Anything you don't override returns a sensible default (`-ENOENT`
for lookups, `-ENOSYS` for write operations).

```crystal
require "crystalfuse"

class HelloFS < Crystalfuse::FuseFS
  CONTENT = "Hello from Crystal!\n"

  def getattr(path : String) : Crystalfuse::FileAttr | Int32
    case path
    when "/"          then Crystalfuse::FileAttr.dir
    when "/hello.txt" then Crystalfuse::FileAttr.file(size: CONTENT.bytesize, mode: 0o444)
    else                   -Errno::ENOENT.value
    end
  end

  def readdir(path : String) : Array(String) | Int32
    return -Errno::ENOENT.value unless path == "/"
    [".", "..", "hello.txt"]
  end

  def read(path : String, size : Int32, offset : Int64) : Bytes | Int32
    return -Errno::ENOENT.value unless path == "/hello.txt"
    content = CONTENT.to_slice
    return Bytes.empty if offset >= content.size
    content[offset.to_i32, Math.min(size, content.size - offset.to_i32)]
  end
end

# argv-style: program name plus libfuse options (e.g. "-f" for foreground)
HelloFS.new.mount(["hello"] + ARGV)
```

Build the shim, then run it against a mountpoint:

```sh
make                                # builds c/libfusewrap.a
crystal run eg/hello/hello.cr -- -f ./tmp/mnt
cat ./tmp/mnt/hello.txt             # => Hello from Crystal!
fusermount3 -u ./tmp/mnt            # unmount (or `make unmount`)
```

`make` on its own builds the example into `./run`; `make spec` runs the tests.

For a fully writable filesystem (create/write/mkdir/rename/chmod/truncate/…),
see `eg/memfs/memfs.cr` — a small in-memory fs:

```sh
crystal run eg/memfs/memfs.cr -- -f ./tmp/mnt
echo hi > ./tmp/mnt/note.txt && cat ./tmp/mnt/note.txt
```

The examples mount single-threaded (`-s`). libfuse's multi-threaded mode runs
callbacks on worker threads that Crystal's runtime/GC don't manage, so keep the
loop single-threaded for now.

## Supported operations

`getattr`, `readdir`, `open`, `read`, `write`, `create`, `truncate`, `unlink`,
`mkdir`, `rmdir`, `rename`, `chmod`, `chown`, `readlink`, `symlink`, `statfs`,
`access`.

Each `FuseFS` operation returns either a meaningful Crystal value
(`FileAttr`, `Array(String)`, `Bytes`, `String`, …) or a negative errno value
to signal failure, e.g. `-Errno::ENOENT.value`.

## Contributing

1. Fork it ( https://github.com/trans/crystalfuse/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [trans](https://github.com/trans) Thomas Sawyer
- [Papierkorb](https://github.com/Papierkorb) Stefan Merettig — original creator
