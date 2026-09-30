local ffi = require("ffi")

ffi.cdef[[
typedef unsigned long nfds_t;

struct pollfd {
    int   fd;
    short events;
    short revents;
};

int poll(struct pollfd *fds, nfds_t nfds, int timeout_ms);
int access(const char *pathname, int mode);
]]

return ffi
