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
};

// Main call to mount!
int fusewrap_main(int argc, char *argv[]) {
    return fuse_main(argc, argv, &wrapper_ops, NULL);
}
