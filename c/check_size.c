#define FUSE_USE_VERSION 35
#include <fuse3/fuse.h>
#include <stddef.h>
#include <stdio.h>

#define OFF(x) printf("%-20s = %zu\n", #x, offsetof(struct fuse_operations, x));

int main() {
    printf("sizeof(fuse_operations): %zu\n", sizeof(struct fuse_operations));
    printf("sizeof(fuse_conn_info): %zu\n", sizeof(struct fuse_conn_info));
    printf("sizeof(fuse_config):    %zu\n", sizeof(struct fuse_config));
    printf("sizeof(fuse_context):    %zu\n", sizeof(struct fuse_context));
    printf("sizeof(fuse_file_info):    %zu\n", sizeof(struct fuse_file_info));
    return 0;
}

int print_op_pointers() {
    OFF(getattr);
    OFF(readlink);
    OFF(mknod);
    OFF(mkdir);
    OFF(unlink);
    OFF(rmdir);
    OFF(symlink);
    OFF(rename);
    OFF(link);
    OFF(chmod);
    OFF(chown);
    OFF(truncate);
    OFF(open);
    OFF(read);
    OFF(write);
    OFF(statfs);
    OFF(flush);
    OFF(release);
    OFF(fsync);
    OFF(setxattr);
    OFF(getxattr);
    OFF(listxattr);
    OFF(removexattr);
    OFF(opendir);
    OFF(readdir);
    OFF(releasedir);
    OFF(fsyncdir);
    OFF(init);
    OFF(destroy);
    OFF(access);
    OFF(create);
    OFF(lock);
    OFF(utimens);
    OFF(bmap);
    OFF(ioctl);
    OFF(poll);
    OFF(write_buf);
    OFF(read_buf);
    OFF(flock);
    OFF(fallocate);
    OFF(copy_file_range);
    OFF(lseek);
    return 0;
}
