local ffi = require("ffi")

ffi.cdef[[
typedef long time_t;

struct timespec {
    time_t tv_sec;
    long   tv_nsec;
};

int clock_gettime(int clk_id, struct timespec *tp);

enum {
    CLOCK_REALTIME  = 0,
    CLOCK_MONOTONIC = 1
};
]]

return ffi
