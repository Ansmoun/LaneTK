require("bindings.cdef.cairo")

local ffi = require("ffi")

ffi.cdef[[
int FcInit(void);

typedef struct _PangoLayout PangoLayout;
typedef struct _PangoFontDescription PangoFontDescription;
typedef struct _PangoContext PangoContext;
typedef struct _PangoFontMap PangoFontMap;

typedef int PangoAlignment;
enum {
    PANGO_ALIGN_LEFT   = 0,
    PANGO_ALIGN_CENTER = 1,
    PANGO_ALIGN_RIGHT  = 2
};

typedef int PangoWrapMode;
enum {
    PANGO_WRAP_WORD      = 0,
    PANGO_WRAP_CHAR      = 1,
    PANGO_WRAP_WORD_CHAR = 2
};

PangoFontDescription *pango_font_description_from_string(const char *str);
void                  pango_font_description_free(PangoFontDescription *desc);

PangoLayout *pango_cairo_create_layout(cairo_t *cr);
void         pango_cairo_update_layout(cairo_t *cr, PangoLayout *layout);
void         pango_cairo_show_layout(cairo_t *cr, PangoLayout *layout);

void pango_layout_set_text(PangoLayout *layout, const char *text, int length);
void pango_layout_set_markup(PangoLayout *layout, const char *markup, int length);
void pango_layout_set_font_description(PangoLayout *layout, PangoFontDescription *desc);
void pango_layout_set_width(PangoLayout *layout, int width);
void pango_layout_set_alignment(PangoLayout *layout, PangoAlignment alignment);
void pango_layout_set_wrap(PangoLayout *layout, PangoWrapMode mode);
void pango_layout_set_spacing(PangoLayout *layout, int spacing);

void pango_layout_get_pixel_size(PangoLayout *layout, int *width, int *height);
int  pango_layout_get_baseline(PangoLayout *layout);

void g_object_unref(void *object);
]]

return ffi
