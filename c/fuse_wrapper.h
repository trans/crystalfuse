// fuse_wrapper.h

#ifndef FUSEWRAP_H
#define FUSEWRAP_H

#define FUSE_USE_VERSION 35
#include <fuse3/fuse.h>
#include <sys/statvfs.h>
#include <time.h>
#include <fcntl.h>
#include <stdint.h>

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
typedef void (*init_cb_t)(void);
typedef void (*destroy_cb_t)(void);
typedef int (*fsync_cb_t)(const char *, int, struct fuse_file_info *);
typedef int (*fsyncdir_cb_t)(const char *, int, struct fuse_file_info *);
typedef int (*opendir_cb_t)(const char *, struct fuse_file_info *);
typedef int (*releasedir_cb_t)(const char *, struct fuse_file_info *);
typedef int (*mknod_cb_t)(const char *, mode_t, dev_t);
typedef int (*link_cb_t)(const char *, const char *);
typedef int (*setxattr_cb_t)(const char *, const char *, const char *, size_t, int);
typedef int (*getxattr_cb_t)(const char *, const char *, char *, size_t);
typedef int (*listxattr_cb_t)(const char *, char *, size_t);
typedef int (*removexattr_cb_t)(const char *, const char *);
typedef off_t (*lseek_cb_t)(const char *, off_t, int, struct fuse_file_info *);
typedef int (*fallocate_cb_t)(const char *, int, off_t, off_t, struct fuse_file_info *);
typedef ssize_t (*copy_file_range_cb_t)(const char *, struct fuse_file_info *, off_t, const char *, struct fuse_file_info *, off_t, size_t, int);
typedef int (*flock_cb_t)(const char *, struct fuse_file_info *, int);
typedef int (*lock_cb_t)(const char *, struct fuse_file_info *, int, struct flock *);
typedef int (*ioctl_cb_t)(const char *, unsigned int, void *, struct fuse_file_info *, unsigned int, void *);
typedef int (*poll_cb_t)(const char *, struct fuse_file_info *, struct fuse_pollhandle *, unsigned int *);
typedef int (*bmap_cb_t)(const char *, size_t, uint64_t *);

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
void fusewrap_register_init(init_cb_t cb);
void fusewrap_register_destroy(destroy_cb_t cb);
void fusewrap_register_fsync(fsync_cb_t cb);
void fusewrap_register_fsyncdir(fsyncdir_cb_t cb);
void fusewrap_register_opendir(opendir_cb_t cb);
void fusewrap_register_releasedir(releasedir_cb_t cb);
void fusewrap_register_mknod(mknod_cb_t cb);
void fusewrap_register_link(link_cb_t cb);
void fusewrap_register_setxattr(setxattr_cb_t cb);
void fusewrap_register_getxattr(getxattr_cb_t cb);
void fusewrap_register_listxattr(listxattr_cb_t cb);
void fusewrap_register_removexattr(removexattr_cb_t cb);
void fusewrap_register_lseek(lseek_cb_t cb);
void fusewrap_register_fallocate(fallocate_cb_t cb);
void fusewrap_register_copy_file_range(copy_file_range_cb_t cb);
void fusewrap_register_flock(flock_cb_t cb);
void fusewrap_register_lock(lock_cb_t cb);
void fusewrap_register_ioctl(ioctl_cb_t cb);
void fusewrap_register_poll(poll_cb_t cb);
void fusewrap_register_bmap(bmap_cb_t cb);

// Populate a `struct statvfs` from Crystal. The C compiler owns the struct
// layout here, so Crystal never has to know it (which varies by libc version).
void fusewrap_fill_statvfs(struct statvfs *st,
    unsigned long bsize, unsigned long frsize,
    unsigned long blocks, unsigned long bfree, unsigned long bavail,
    unsigned long files, unsigned long ffree, unsigned long favail,
    unsigned long namemax, unsigned long flag);

// Register the calling thread with the GC (see fuse_wrapper.c). Safe to call
// repeatedly; only the first call per thread does work.
void fusewrap_register_current_thread(void);

// --- FUSE main entry ---
int fusewrap_main(int argc, char **argv);

#ifdef __cplusplus
}
#endif

#endif // FUSEWRAP_H
