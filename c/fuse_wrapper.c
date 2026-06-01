// fuse_wrapper.c
//
// A thin C shim over libfuse3. It owns the `struct fuse_operations` table (so
// the C compiler, not Crystal, is responsible for getting the struct layout
// right) and forwards each operation to a callback registered from Crystal.
//
// Every wrapper returns -ENOSYS when no callback has been registered, which is
// how libfuse expects an unimplemented operation to behave.

#define FUSE_USE_VERSION 35
#include <fuse3/fuse.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include "fuse_wrapper.h"

// --- Registered callbacks ---
static getattr_cb_t  cb_getattr  = NULL;
static readdir_cb_t  cb_readdir  = NULL;
static open_cb_t     cb_open     = NULL;
static read_cb_t     cb_read     = NULL;
static write_cb_t    cb_write    = NULL;
static create_cb_t   cb_create   = NULL;
static truncate_cb_t cb_truncate = NULL;
static unlink_cb_t   cb_unlink   = NULL;
static mkdir_cb_t    cb_mkdir    = NULL;
static rmdir_cb_t    cb_rmdir    = NULL;
static rename_cb_t   cb_rename   = NULL;
static chmod_cb_t    cb_chmod    = NULL;
static chown_cb_t    cb_chown    = NULL;
static readlink_cb_t cb_readlink = NULL;
static symlink_cb_t  cb_symlink  = NULL;
static statfs_cb_t   cb_statfs   = NULL;
static access_cb_t   cb_access   = NULL;
static utimens_cb_t  cb_utimens  = NULL;
static release_cb_t  cb_release  = NULL;
static flush_cb_t    cb_flush    = NULL;
static init_cb_t     cb_init     = NULL;
static destroy_cb_t  cb_destroy  = NULL;
static fsync_cb_t       cb_fsync       = NULL;
static fsyncdir_cb_t    cb_fsyncdir    = NULL;
static opendir_cb_t     cb_opendir     = NULL;
static releasedir_cb_t  cb_releasedir  = NULL;
static mknod_cb_t       cb_mknod       = NULL;
static link_cb_t        cb_link        = NULL;
static setxattr_cb_t    cb_setxattr    = NULL;
static getxattr_cb_t    cb_getxattr    = NULL;
static listxattr_cb_t   cb_listxattr   = NULL;
static removexattr_cb_t cb_removexattr = NULL;
static lseek_cb_t           cb_lseek           = NULL;
static fallocate_cb_t       cb_fallocate       = NULL;
static copy_file_range_cb_t cb_copy_file_range = NULL;
static flock_cb_t           cb_flock           = NULL;
static lock_cb_t            cb_lock            = NULL;
static ioctl_cb_t           cb_ioctl           = NULL;
static poll_cb_t            cb_poll            = NULL;
static bmap_cb_t            cb_bmap            = NULL;

// --- Registration ---
void fusewrap_register_getattr(getattr_cb_t cb)   { cb_getattr  = cb; }
void fusewrap_register_readdir(readdir_cb_t cb)   { cb_readdir  = cb; }
void fusewrap_register_open(open_cb_t cb)         { cb_open     = cb; }
void fusewrap_register_read(read_cb_t cb)         { cb_read     = cb; }
void fusewrap_register_write(write_cb_t cb)       { cb_write    = cb; }
void fusewrap_register_create(create_cb_t cb)     { cb_create   = cb; }
void fusewrap_register_truncate(truncate_cb_t cb) { cb_truncate = cb; }
void fusewrap_register_unlink(unlink_cb_t cb)     { cb_unlink   = cb; }
void fusewrap_register_mkdir(mkdir_cb_t cb)       { cb_mkdir    = cb; }
void fusewrap_register_rmdir(rmdir_cb_t cb)       { cb_rmdir    = cb; }
void fusewrap_register_rename(rename_cb_t cb)     { cb_rename   = cb; }
void fusewrap_register_chmod(chmod_cb_t cb)       { cb_chmod    = cb; }
void fusewrap_register_chown(chown_cb_t cb)       { cb_chown    = cb; }
void fusewrap_register_readlink(readlink_cb_t cb) { cb_readlink = cb; }
void fusewrap_register_symlink(symlink_cb_t cb)   { cb_symlink  = cb; }
void fusewrap_register_statfs(statfs_cb_t cb)     { cb_statfs   = cb; }
void fusewrap_register_access(access_cb_t cb)     { cb_access   = cb; }
void fusewrap_register_utimens(utimens_cb_t cb)   { cb_utimens  = cb; }
void fusewrap_register_release(release_cb_t cb)   { cb_release  = cb; }
void fusewrap_register_flush(flush_cb_t cb)       { cb_flush    = cb; }
void fusewrap_register_init(init_cb_t cb)         { cb_init     = cb; }
void fusewrap_register_destroy(destroy_cb_t cb)   { cb_destroy  = cb; }
void fusewrap_register_fsync(fsync_cb_t cb)             { cb_fsync       = cb; }
void fusewrap_register_fsyncdir(fsyncdir_cb_t cb)       { cb_fsyncdir    = cb; }
void fusewrap_register_opendir(opendir_cb_t cb)         { cb_opendir     = cb; }
void fusewrap_register_releasedir(releasedir_cb_t cb)   { cb_releasedir  = cb; }
void fusewrap_register_mknod(mknod_cb_t cb)             { cb_mknod       = cb; }
void fusewrap_register_link(link_cb_t cb)               { cb_link        = cb; }
void fusewrap_register_setxattr(setxattr_cb_t cb)       { cb_setxattr    = cb; }
void fusewrap_register_getxattr(getxattr_cb_t cb)       { cb_getxattr    = cb; }
void fusewrap_register_listxattr(listxattr_cb_t cb)     { cb_listxattr   = cb; }
void fusewrap_register_removexattr(removexattr_cb_t cb) { cb_removexattr = cb; }
void fusewrap_register_lseek(lseek_cb_t cb)                     { cb_lseek           = cb; }
void fusewrap_register_fallocate(fallocate_cb_t cb)             { cb_fallocate       = cb; }
void fusewrap_register_copy_file_range(copy_file_range_cb_t cb) { cb_copy_file_range = cb; }
void fusewrap_register_flock(flock_cb_t cb)                     { cb_flock           = cb; }
void fusewrap_register_lock(lock_cb_t cb)                       { cb_lock            = cb; }
void fusewrap_register_ioctl(ioctl_cb_t cb)                     { cb_ioctl           = cb; }
void fusewrap_register_poll(poll_cb_t cb)                       { cb_poll            = cb; }
void fusewrap_register_bmap(bmap_cb_t cb)                       { cb_bmap            = cb; }

// --- Operation wrappers ---
static int wrapper_getattr(const char *path, struct stat *stbuf, struct fuse_file_info *fi) {
    if (!cb_getattr) return -ENOSYS;
    memset(stbuf, 0, sizeof(struct stat));
    return cb_getattr(path, stbuf, fi);
}

static int wrapper_readdir(const char *path, void *buf, fuse_fill_dir_t filler,
                           off_t offset, struct fuse_file_info *fi,
                           enum fuse_readdir_flags flags) {
    if (!cb_readdir) return -ENOSYS;
    return cb_readdir(path, buf, filler, offset, fi, flags);
}

static int wrapper_open(const char *path, struct fuse_file_info *fi) {
    if (!cb_open) return -ENOSYS;
    return cb_open(path, fi);
}

static int wrapper_read(const char *path, char *buf, size_t size, off_t offset, struct fuse_file_info *fi) {
    if (!cb_read) return -ENOSYS;
    return cb_read(path, buf, size, offset, fi);
}

static int wrapper_write(const char *path, const char *buf, size_t size, off_t offset, struct fuse_file_info *fi) {
    if (!cb_write) return -ENOSYS;
    return cb_write(path, buf, size, offset, fi);
}

static int wrapper_create(const char *path, mode_t mode, struct fuse_file_info *fi) {
    if (!cb_create) return -ENOSYS;
    return cb_create(path, mode, fi);
}

static int wrapper_truncate(const char *path, off_t size, struct fuse_file_info *fi) {
    if (!cb_truncate) return -ENOSYS;
    return cb_truncate(path, size, fi);
}

static int wrapper_unlink(const char *path) {
    if (!cb_unlink) return -ENOSYS;
    return cb_unlink(path);
}

static int wrapper_mkdir(const char *path, mode_t mode) {
    if (!cb_mkdir) return -ENOSYS;
    return cb_mkdir(path, mode);
}

static int wrapper_rmdir(const char *path) {
    if (!cb_rmdir) return -ENOSYS;
    return cb_rmdir(path);
}

static int wrapper_rename(const char *from, const char *to, unsigned int flags) {
    if (!cb_rename) return -ENOSYS;
    return cb_rename(from, to, flags);
}

static int wrapper_chmod(const char *path, mode_t mode, struct fuse_file_info *fi) {
    if (!cb_chmod) return -ENOSYS;
    return cb_chmod(path, mode, fi);
}

static int wrapper_chown(const char *path, uid_t uid, gid_t gid, struct fuse_file_info *fi) {
    if (!cb_chown) return -ENOSYS;
    return cb_chown(path, uid, gid, fi);
}

static int wrapper_readlink(const char *path, char *buf, size_t size) {
    if (!cb_readlink) return -ENOSYS;
    return cb_readlink(path, buf, size);
}

static int wrapper_symlink(const char *target, const char *linkpath) {
    if (!cb_symlink) return -ENOSYS;
    return cb_symlink(target, linkpath);
}

static int wrapper_statfs(const char *path, struct statvfs *stbuf) {
    if (!cb_statfs) return -ENOSYS;
    memset(stbuf, 0, sizeof(struct statvfs));
    return cb_statfs(path, stbuf);
}

static int wrapper_access(const char *path, int mask) {
    if (!cb_access) return -ENOSYS;
    return cb_access(path, mask);
}

static int wrapper_utimens(const char *path, const struct timespec tv[2], struct fuse_file_info *fi) {
    if (!cb_utimens) return -ENOSYS;
    return cb_utimens(path, tv, fi);
}

static int wrapper_release(const char *path, struct fuse_file_info *fi) {
    if (!cb_release) return -ENOSYS;
    return cb_release(path, fi);
}

static int wrapper_flush(const char *path, struct fuse_file_info *fi) {
    if (!cb_flush) return -ENOSYS;
    return cb_flush(path, fi);
}

// init returns a private_data pointer; we don't use one (state lives in the
// Crystal singleton), so return NULL. conn/cfg are ignored for now.
static void *wrapper_init(struct fuse_conn_info *conn, struct fuse_config *cfg) {
    (void) conn;
    (void) cfg;
    if (cb_init) cb_init();
    return NULL;
}

static void wrapper_destroy(void *private_data) {
    (void) private_data;
    if (cb_destroy) cb_destroy();
}

static int wrapper_fsync(const char *path, int datasync, struct fuse_file_info *fi) {
    if (!cb_fsync) return -ENOSYS;
    return cb_fsync(path, datasync, fi);
}

static int wrapper_fsyncdir(const char *path, int datasync, struct fuse_file_info *fi) {
    if (!cb_fsyncdir) return -ENOSYS;
    return cb_fsyncdir(path, datasync, fi);
}

static int wrapper_opendir(const char *path, struct fuse_file_info *fi) {
    if (!cb_opendir) return -ENOSYS;
    return cb_opendir(path, fi);
}

static int wrapper_releasedir(const char *path, struct fuse_file_info *fi) {
    if (!cb_releasedir) return -ENOSYS;
    return cb_releasedir(path, fi);
}

static int wrapper_mknod(const char *path, mode_t mode, dev_t rdev) {
    if (!cb_mknod) return -ENOSYS;
    return cb_mknod(path, mode, rdev);
}

static int wrapper_link(const char *from, const char *to) {
    if (!cb_link) return -ENOSYS;
    return cb_link(from, to);
}

static int wrapper_setxattr(const char *path, const char *name, const char *value, size_t size, int flags) {
    if (!cb_setxattr) return -ENOSYS;
    return cb_setxattr(path, name, value, size, flags);
}

static int wrapper_getxattr(const char *path, const char *name, char *value, size_t size) {
    if (!cb_getxattr) return -ENOSYS;
    return cb_getxattr(path, name, value, size);
}

static int wrapper_listxattr(const char *path, char *list, size_t size) {
    if (!cb_listxattr) return -ENOSYS;
    return cb_listxattr(path, list, size);
}

static int wrapper_removexattr(const char *path, const char *name) {
    if (!cb_removexattr) return -ENOSYS;
    return cb_removexattr(path, name);
}

static off_t wrapper_lseek(const char *path, off_t off, int whence, struct fuse_file_info *fi) {
    if (!cb_lseek) return -ENOSYS;
    return cb_lseek(path, off, whence, fi);
}

static int wrapper_fallocate(const char *path, int mode, off_t offset, off_t length, struct fuse_file_info *fi) {
    if (!cb_fallocate) return -ENOSYS;
    return cb_fallocate(path, mode, offset, length, fi);
}

static ssize_t wrapper_copy_file_range(const char *path_in, struct fuse_file_info *fi_in, off_t off_in,
                                       const char *path_out, struct fuse_file_info *fi_out, off_t off_out,
                                       size_t size, int flags) {
    if (!cb_copy_file_range) return -ENOSYS;
    return cb_copy_file_range(path_in, fi_in, off_in, path_out, fi_out, off_out, size, flags);
}

static int wrapper_flock(const char *path, struct fuse_file_info *fi, int op) {
    if (!cb_flock) return -ENOSYS;
    return cb_flock(path, fi, op);
}

static int wrapper_lock(const char *path, struct fuse_file_info *fi, int cmd, struct flock *lk) {
    if (!cb_lock) return -ENOSYS;
    return cb_lock(path, fi, cmd, lk);
}

static int wrapper_ioctl(const char *path, unsigned int cmd, void *arg,
                         struct fuse_file_info *fi, unsigned int flags, void *data) {
    if (!cb_ioctl) return -ENOSYS;
    return cb_ioctl(path, cmd, arg, fi, flags, data);
}

static int wrapper_poll(const char *path, struct fuse_file_info *fi,
                        struct fuse_pollhandle *ph, unsigned int *reventsp) {
    if (!cb_poll) return -ENOSYS;
    return cb_poll(path, fi, ph, reventsp);
}

static int wrapper_bmap(const char *path, size_t blocksize, uint64_t *idx) {
    if (!cb_bmap) return -ENOSYS;
    return cb_bmap(path, blocksize, idx);
}

void fusewrap_fill_statvfs(struct statvfs *st,
    unsigned long bsize, unsigned long frsize,
    unsigned long blocks, unsigned long bfree, unsigned long bavail,
    unsigned long files, unsigned long ffree, unsigned long namemax) {
    st->f_bsize   = bsize;
    st->f_frsize  = frsize;
    st->f_blocks  = blocks;
    st->f_bfree   = bfree;
    st->f_bavail  = bavail;
    st->f_files   = files;
    st->f_ffree   = ffree;
    st->f_favail  = bavail;
    st->f_namemax = namemax;
}

static struct fuse_operations wrapper_ops = {
    .getattr  = wrapper_getattr,
    .readlink = wrapper_readlink,
    .mkdir    = wrapper_mkdir,
    .unlink   = wrapper_unlink,
    .rmdir    = wrapper_rmdir,
    .symlink  = wrapper_symlink,
    .rename   = wrapper_rename,
    .chmod    = wrapper_chmod,
    .chown    = wrapper_chown,
    .truncate = wrapper_truncate,
    .open     = wrapper_open,
    .read     = wrapper_read,
    .write    = wrapper_write,
    .statfs   = wrapper_statfs,
    .readdir  = wrapper_readdir,
    .access   = wrapper_access,
    .create   = wrapper_create,
    .utimens  = wrapper_utimens,
    .release  = wrapper_release,
    .flush    = wrapper_flush,
    .init     = wrapper_init,
    .destroy  = wrapper_destroy,
    .fsync       = wrapper_fsync,
    .fsyncdir    = wrapper_fsyncdir,
    .opendir     = wrapper_opendir,
    .releasedir  = wrapper_releasedir,
    .mknod       = wrapper_mknod,
    .link        = wrapper_link,
    .setxattr    = wrapper_setxattr,
    .getxattr    = wrapper_getxattr,
    .listxattr   = wrapper_listxattr,
    .removexattr = wrapper_removexattr,
    .lseek           = wrapper_lseek,
    .fallocate       = wrapper_fallocate,
    .copy_file_range = wrapper_copy_file_range,
    .flock           = wrapper_flock,
    .lock            = wrapper_lock,
    .ioctl           = wrapper_ioctl,
    .poll            = wrapper_poll,
    .bmap            = wrapper_bmap,
};

// Main call to mount!
int fusewrap_main(int argc, char *argv[]) {
    return fuse_main(argc, argv, &wrapper_ops, NULL);
}
