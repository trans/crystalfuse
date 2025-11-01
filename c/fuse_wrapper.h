// fuse_wrapper.h

#ifndef FUSEWRAP_H
#define FUSEWRAP_H

#include <fuse3/fuse.h>
#include <sys/statvfs.h>

#ifdef __cplusplus
extern "C" {
#endif

// --- Callback typedefs ---
typedef int (*getattr_cb_t)(const char *, struct stat *, struct fuse_file_info *);
typedef int (*readdir_cb_t)(const char *, void *, fuse_fill_dir_t, off_t, struct fuse_file_info *, enum fuse_readdir_flags);
typedef int (*open_cb_t)(const char *, struct fuse_file_info *);
typedef int (*read_cb_t)(const char *, char *, size_t, off_t, struct fuse_file_info *);
typedef int (*statfs_cb_t)(const char *, struct statvfs *);
typedef int (*access_cb_t)(const char *, int);

// --- Registration functions ---
void fusewrap_register_getattr(getattr_cb_t cb);
void fusewrap_register_readdir(readdir_cb_t cb);
void fusewrap_register_open(open_cb_t cb);
void fusewrap_register_read(read_cb_t cb);
void fusewrap_register_statfs(statfs_cb_t cb);
void fusewrap_register_access(access_cb_t cb);

// --- FUSE main entry ---
int fusewrap_main(int argc, char **argv);

#ifdef __cplusplus
}
#endif

#endif // FUSEWRAP_H
