// fuse_wrapper.h

#ifndef FUSEWRAP_H
#define FUSEWRAP_H

#define FUSE_USE_VERSION 35
#include <fuse3/fuse.h>
#include <sys/statvfs.h>
#include <time.h>

#ifdef __cplusplus
extern "C" {
#endif

// --- Callback typedefs ---
// These mirror the relevant fields of struct fuse_operations. Each registered
// callback is invoked by the matching static wrapper below, which is what is
// actually stored in the fuse_operations table handed to libfuse.
typedef int (*getattr_cb_t)(const char *, struct stat *, struct fuse_file_info *);
typedef int (*readdir_cb_t)(const char *, void *, fuse_fill_dir_t, off_t, struct fuse_file_info *, enum fuse_readdir_flags);
typedef int (*open_cb_t)(const char *, struct fuse_file_info *);
typedef int (*read_cb_t)(const char *, char *, size_t, off_t, struct fuse_file_info *);
typedef int (*write_cb_t)(const char *, const char *, size_t, off_t, struct fuse_file_info *);
typedef int (*create_cb_t)(const char *, mode_t, struct fuse_file_info *);
typedef int (*truncate_cb_t)(const char *, off_t, struct fuse_file_info *);
typedef int (*unlink_cb_t)(const char *);
typedef int (*mkdir_cb_t)(const char *, mode_t);
typedef int (*rmdir_cb_t)(const char *);
typedef int (*rename_cb_t)(const char *, const char *, unsigned int);
typedef int (*chmod_cb_t)(const char *, mode_t, struct fuse_file_info *);
typedef int (*chown_cb_t)(const char *, uid_t, gid_t, struct fuse_file_info *);
typedef int (*readlink_cb_t)(const char *, char *, size_t);
typedef int (*symlink_cb_t)(const char *, const char *);
typedef int (*statfs_cb_t)(const char *, struct statvfs *);
typedef int (*access_cb_t)(const char *, int);
typedef int (*utimens_cb_t)(const char *, const struct timespec[2], struct fuse_file_info *);
typedef int (*release_cb_t)(const char *, struct fuse_file_info *);
typedef int (*flush_cb_t)(const char *, struct fuse_file_info *);

// --- Registration functions ---
void fusewrap_register_getattr(getattr_cb_t cb);
void fusewrap_register_readdir(readdir_cb_t cb);
void fusewrap_register_open(open_cb_t cb);
void fusewrap_register_read(read_cb_t cb);
void fusewrap_register_write(write_cb_t cb);
void fusewrap_register_create(create_cb_t cb);
void fusewrap_register_truncate(truncate_cb_t cb);
void fusewrap_register_unlink(unlink_cb_t cb);
void fusewrap_register_mkdir(mkdir_cb_t cb);
void fusewrap_register_rmdir(rmdir_cb_t cb);
void fusewrap_register_rename(rename_cb_t cb);
void fusewrap_register_chmod(chmod_cb_t cb);
void fusewrap_register_chown(chown_cb_t cb);
void fusewrap_register_readlink(readlink_cb_t cb);
void fusewrap_register_symlink(symlink_cb_t cb);
void fusewrap_register_statfs(statfs_cb_t cb);
void fusewrap_register_access(access_cb_t cb);
void fusewrap_register_utimens(utimens_cb_t cb);
void fusewrap_register_release(release_cb_t cb);
void fusewrap_register_flush(flush_cb_t cb);

// Populate a `struct statvfs` from Crystal. The C compiler owns the struct
// layout here, so Crystal never has to know it (which varies by libc version).
void fusewrap_fill_statvfs(struct statvfs *st,
    unsigned long bsize, unsigned long frsize,
    unsigned long blocks, unsigned long bfree, unsigned long bavail,
    unsigned long files, unsigned long ffree, unsigned long namemax);

// --- FUSE main entry ---
int fusewrap_main(int argc, char **argv);

#ifdef __cplusplus
}
#endif

#endif // FUSEWRAP_H
