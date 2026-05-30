# Paths
C_SRC := c/fuse_wrapper.c
C_HDR := c/fuse_wrapper.h
C_OBJ := c/fuse_wrapper.o
C_LIB := c/libfusewrap.a

CRYSTAL_SRC := eg/hello/hello.cr
CRYSTAL_BIN := run

# Compiler & flags
CC     := gcc
CFLAGS := -O2 -Wall -Wextra -fPIC $(shell pkg-config fuse3 --cflags)

.PHONY: all clean unmount spec

all: $(CRYSTAL_BIN)

# Crystal build. Link flags (the static shim + libfuse3) are declared in
# src/crystalfuse/fuse_wrap.cr via @[Link], so nothing is needed here.
$(CRYSTAL_BIN): $(C_LIB) $(CRYSTAL_SRC)
	crystal build $(CRYSTAL_SRC) -o $(CRYSTAL_BIN)

# C wrapper static library
$(C_LIB): $(C_OBJ)
	ar rcs $(C_LIB) $<

# C wrapper compilation
$(C_OBJ): $(C_SRC) $(C_HDR)
	$(CC) $(CFLAGS) -c -o $@ $<

# Run the spec suite (depends on the C shim being built first)
spec: $(C_LIB)
	crystal spec

clean:
	rm -f c/*.o c/*.so c/*.a $(CRYSTAL_BIN)

unmount:
	fusermount3 -u ./tmp/mnt
