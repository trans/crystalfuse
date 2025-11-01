# Paths
C_SRC := c/fuse_wrapper.c
C_HDR := c/fuse_wrapper.h
C_OBJ := c/fuse_wrapper.so
C_LIB := c/libfusewrap.a

CRYSTAL_SRC := src/run.cr
CRYSTAL_BIN := run

# full path to it (needed for Crystal static linking)
C_LIB_ABS=$(realpath $(C_LIB))

# Compiler & flags
CC := gcc
CFLAGS := -O2 -Wall -Wextra -fPIC -I/usr/include/fuse3
#LDFLAGS := "$(LIBFUSEWRAP) -lfuse3

.PHONY: all clean

all: $(CRYSTAL_BIN)

# Crystal build
$(CRYSTAL_BIN): $(C_LIB) $(CRYSTAL_SRC)
	crystal build $(CRYSTAL_SRC) --link-flags="$(C_LIB_ABS) -lfuse3"

# C wrapper object
$(C_LIB): $(C_OBJ)
	ar rcs $(C_LIB) $<

# C wrapper compilation
$(C_OBJ): $(C_SRC) $(C_HDR)
	$(CC) -O2 -Wall -Wextra -fPIC -I/usr/include/fuse3 -c -o $@ $<

clean:
	rm -f c/*.so c/*.a $(CRYSTAL_BIN)

unmount:
	fusermount3 -u ./tmp/mnt
