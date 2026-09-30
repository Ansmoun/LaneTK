require("bindings.cdef.xcb")

local ffi = require("ffi")

ffi.cdef[[
typedef struct {
    uint32_t flags;
    int32_t  x, y;
    int32_t  width, height;
    int32_t  min_width, min_height;
    int32_t  max_width, max_height;
    int32_t  width_inc, height_inc;
    int32_t  min_aspect_num, min_aspect_den;
    int32_t  max_aspect_num, max_aspect_den;
    int32_t  base_width, base_height;
    uint32_t win_gravity;
} xcb_size_hints_t;

typedef struct {
    uint32_t flags;
    uint8_t  input;
    uint8_t  initial_state;
    int32_t  icon_pixmap;
    int32_t  icon_window;
    int32_t  icon_x, icon_y;
    int32_t  icon_mask;
    int32_t  window_group;
} xcb_wm_hints_t;

void xcb_icccm_set_wm_normal_hints(
    xcb_connection_t *c, xcb_window_t window, xcb_size_hints_t *hints
);

void xcb_icccm_set_wm_hints(
    xcb_connection_t *c, xcb_window_t window, xcb_wm_hints_t *hints
);
]]

return ffi
