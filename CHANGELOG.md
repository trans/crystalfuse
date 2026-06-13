# Changelog

All notable changes to this project are documented here.

## [0.3.0]

### Changed
- **Namespace renamed `Crystalfuse` → `Fuse`.** `Crystalfuse::FS` is now
  `Fuse::FS`, `Crystalfuse::FileAttr` is `Fuse::FileAttr`, and so on — the
  redundant "crystal" prefix on a Crystal library is gone. The shard is still
  named `crystalfuse`, so `require "crystalfuse"` and the dependency entry are
  unchanged; only the module name differs. (Breaking: replace `Crystalfuse::`
  with `Fuse::` in your code.)

## [0.2.0]

The release that makes crystalfuse a complete, usable FUSE 3 binding.

### Added
- **Complete `fuse_operations` table** — read/write, directories, links, the
  xattr family, locks (`flock`/`lock`), `lseek`, `fallocate`, `copy_file_range`,
  `ioctl`, `poll`, `bmap`, lifecycle hooks (`init`/`destroy`), and more.
- **File handles** — `FileInfo` exposes the open flags and a settable `fh`;
  `open`/`create`/`read`/`write`/`release`/`flush` have handle-aware forms.
  Optional `Fuse::HandleTable(T)` registry (`require` it explicitly).
- **Exception safety** — an exception escaping an operation is caught, logged,
  and returned to the kernel as `-EIO` instead of crashing the mount.
- **Multithreaded mounts** — libfuse worker threads are registered with the GC,
  so the full worker pool is safe (no longer `-s`-only at the binding level).
- **`FileAttr`** ownership (`uid`/`gid`, defaulting to the mounting process) and
  full stat metadata (`ino`, `rdev`, `blocks`, `blksize`).
- **Ergonomic + escape-hatch API** — buffer-filling `read`, raw
  `getattr(path, stat)`, streaming `readdir` via `DirFiller`, and a `StatVFS`
  that models every `statvfs` field.
- **Examples** — `hello`, `memfs` (writable, in-memory), `handlefs` (file
  handles), `passthrough` (loopback over a real directory).
- **`postinstall` hook** builds the C shim automatically on `shards install`.
- **CI** via GitHub Actions (build, specs, format check, example compilation).

### Changed
- Base class renamed `FuseFS` → **`FileSystem`**, with the short alias **`FS`**
  (under the `Crystalfuse` namespace in this release; see 0.3.0 for the
  namespace rename). Breaking: update your subclass declaration.

## [0.1.0]

Initial bindings — partial operation set, single-threaded only.
