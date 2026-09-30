require("bindings.cdef.xcb")

local ffi = require("ffi")

ffi.cdef[[
typedef int cairo_status_t;
typedef int cairo_operator_t;
typedef int cairo_format_t;

typedef struct _cairo cairo_t;
typedef struct _cairo_surface cairo_surface_t;
typedef struct _cairo_pattern cairo_pattern_t;

enum {
    CAIRO_FORMAT_INVALID   = -1,
    CAIRO_FORMAT_ARGB32    = 0,
    CAIRO_FORMAT_RGB24     = 1,
    CAIRO_FORMAT_A8        = 2,
    CAIRO_FORMAT_A1        = 3,
    CAIRO_FORMAT_RGB16_565 = 4,
    CAIRO_FORMAT_RGB30     = 5
};

cairo_surface_t *cairo_xcb_surface_create(
    xcb_connection_t *connection,
    xcb_drawable_t    drawable,
    xcb_visualtype_t *visual,
    int               width,
    int               height
);

cairo_surface_t *cairo_image_surface_create(int format, int width, int height);

cairo_status_t cairo_surface_status(cairo_surface_t *surface);
void           cairo_surface_flush(cairo_surface_t *surface);
void           cairo_surface_destroy(cairo_surface_t *surface);
void           cairo_surface_mark_dirty(cairo_surface_t *surface);

cairo_t *cairo_create(cairo_surface_t *target);
void     cairo_destroy(cairo_t *cr);
cairo_status_t cairo_status(cairo_t *cr);

void cairo_set_source_rgb(cairo_t *cr, double r, double g, double b);
void cairo_set_source_rgba(cairo_t *cr, double r, double g, double b, double a);
void cairo_set_line_width(cairo_t *cr, double width);
void cairo_set_operator(cairo_t *cr, cairo_operator_t op);

cairo_surface_t *cairo_image_surface_create_from_png(const char *filename);
cairo_surface_t *cairo_surface_create_similar(cairo_surface_t *other, int content, int width, int height);
void cairo_mask(cairo_t *cr, cairo_pattern_t *pattern);
void cairo_mask_surface(cairo_t *cr, cairo_surface_t *surface, double surface_x, double surface_y);
void cairo_scale(cairo_t *cr, double sx, double sy);
cairo_pattern_t *cairo_pattern_create_for_surface(cairo_surface_t *surface);
void cairo_pattern_set_filter(cairo_pattern_t *pattern, int filter);
void cairo_pattern_destroy(cairo_pattern_t *pattern);
int cairo_surface_get_type(cairo_surface_t *surface);
int cairo_image_surface_get_width(cairo_surface_t *surface);
int cairo_image_surface_get_height(cairo_surface_t *surface);
unsigned char *cairo_image_surface_get_data(cairo_surface_t *surface);
int cairo_image_surface_get_stride(cairo_surface_t *surface);
cairo_status_t cairo_surface_write_to_png(cairo_surface_t *surface, const char *filename);
void cairo_paint(cairo_t *cr);
void cairo_paint_with_alpha(cairo_t *cr, double alpha);

void cairo_new_sub_path(cairo_t *cr);
void cairo_save(cairo_t *cr);
void cairo_restore(cairo_t *cr);
void cairo_clip(cairo_t *cr);
void cairo_clip_preserve(cairo_t *cr);
void cairo_new_path(cairo_t *cr);
void cairo_set_source_surface(cairo_t *cr, cairo_surface_t *surface, double x, double y);
void cairo_translate(cairo_t *cr, double tx, double ty);
void cairo_move_to(cairo_t *cr, double x, double y);
void cairo_line_to(cairo_t *cr, double x, double y);
void cairo_rectangle(cairo_t *cr, double x, double y, double w, double h);
void cairo_arc(cairo_t *cr, double xc, double yc, double radius,
               double angle1, double angle2);
void cairo_close_path(cairo_t *cr);

void cairo_fill(cairo_t *cr);
void cairo_stroke(cairo_t *cr);
void cairo_fill_preserve(cairo_t *cr);
void cairo_stroke_preserve(cairo_t *cr);
]]

return ffi
