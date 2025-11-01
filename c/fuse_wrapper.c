// fuse_wrapper.c
#define FUSE_USE_VERSION 35
#include <fuse3/fuse.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include "fuse_wrapper.h"

static const char *demo_str = "Hello from C wrapper!\n";
static const char *demo_path = "/hello.txt";

static getattr_cb_t cb_getattr = NULL;

void fusewrap_register_getattr(getattr_cb_t cb) {
    cb_getattr = cb;
}

static int wrapper_getattr(const char *path, struct stat *stbuf, struct fuse_file_info *fi) {
    if (!cb_getattr) return -ENOENT;
    return cb_getattr(path, stbuf, fi);
}

/*
static int wrapper_getattr(const char *path, struct stat *stbuf, struct fuse_file_info *fi) {
    (void) fi;
    memset(stbuf, 0, sizeof(struct stat));
    if (strcmp(path, "/") == 0) {
        stbuf->st_mode = S_IFDIR | 0755;
        stbuf->st_nlink = 2;
    } else if (strcmp(path, demo_path) == 0) {
        stbuf->st_mode = S_IFREG | 0444;
        stbuf->st_nlink = 1;
        stbuf->st_size = strlen(demo_str);
    } else {
        return -ENOENT;
    }
    return 0;
}
*/

static int wrapper_readdir(const char *path, void *buf, fuse_fill_dir_t filler,
                           off_t offset, struct fuse_file_info *fi,
                           enum fuse_readdir_flags flags) {
    (void) offset;
    (void) fi;
    (void) flags;
    if (strcmp(path, "/") != 0)
        return -ENOENT;

    filler(buf, ".", NULL, 0, 0);
    filler(buf, "..", NULL, 0, 0);
    filler(buf, demo_path + 1, NULL, 0, 0);
    return 0;
}

static int wrapper_open(const char *path, struct fuse_file_info *fi) {
    if (strcmp(path, demo_path) != 0)
        return -ENOENT;
    if ((fi->flags & O_ACCMODE) != O_RDONLY)
        return -EACCES;
    return 0;
}

static int wrapper_read(const char *path, char *buf, size_t size, off_t offset, struct fuse_file_info *fi) {
    (void) fi;
    size_t len;
    if (strcmp(path, demo_path) != 0)
        return -ENOENT;

    len = strlen(demo_str);
    if (offset >= 0 && (size_t)offset < len) {
        if ((size_t)offset + size > len)
            size = len - (size_t)offset;
        memcpy(buf, demo_str + offset, size);
    } else {
        size = 0;
    }

    return (int)size;
}

static struct fuse_operations wrapper_ops = {
    .getattr = wrapper_getattr,
    .readdir = wrapper_readdir,
    .open    = wrapper_open,
    .read    = wrapper_read,
};

// Main call to mount!
int fusewrap_main(int argc, char *argv[]) {
    return fuse_main(argc, argv, &wrapper_ops, NULL);
}
