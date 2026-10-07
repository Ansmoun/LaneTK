-- cdef minimo para libc: struct stat en x86_64 Linux (glibc).
-- Solo lo que necesitamos de stat(): st_mode (S_ISDIR), st_mtime,
-- st_size. El layout de struct stat es ABI estable del kernel para
-- una arquitectura dada; este es el de x86_64.
--
-- No incluimos stat() variadico viejo (__xstat); usamos la version
-- moderna, exportada como simbolo T desde glibc 2.33+. Void usa
-- glibc reciente.

local ffi = require("ffi")

ffi.cdef[[
struct lanetk_stat {
    unsigned long st_dev;
    unsigned long st_ino;
    unsigned long st_nlink;

    unsigned int  st_mode;
    unsigned int  st_uid;
    unsigned int  st_gid;
    unsigned int  __pad0;

    unsigned long st_rdev;
    long          st_size;
    long          st_blksize;
    long          st_blocks;

    long st_atime_sec;
    long st_atime_nsec;
    long st_mtime_sec;
    long st_mtime_nsec;
    long st_ctime_sec;
    long st_ctime_nsec;

    long __reserved[3];
};

int stat(const char *path, struct lanetk_stat *buf);

/* Bits de st_mode que usamos. */
enum {
    S_IFMT_  = 0170000,
    S_IFDIR_ = 0040000,
    S_IFREG_ = 0100000
};
]]

return ffi
