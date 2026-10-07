-- cdef para gdk-pixbuf 2.0 (libgdk_pixbuf-2.0.so.0).
-- Solo se declaran los tipos y funciones que usa src/lib/gdk_pixbuf.lua.
-- gdk-pixbuf decodifica PNG, JPEG, GIF, WEBP, TIFF, BMP, etc. via
-- loaders registrados automaticamente al primer uso (lee el cache
-- en /usr/lib/*/gdk-pixbuf-2.0/2.10.0/loaders.cache).

local ffi = require("ffi")

ffi.cdef[[
typedef int gboolean;
typedef unsigned char guchar;
typedef void* gpointer;

typedef struct _GdkPixbuf GdkPixbuf;

typedef struct {
    uint32_t domain;
    int      code;
    char    *message;
} GError;

GdkPixbuf *gdk_pixbuf_new_from_file(const char *filename,
                                    GError **error);

GdkPixbuf *gdk_pixbuf_new_from_file_at_scale(const char *filename,
                                             int width,
                                             int height,
                                             gboolean preserve_aspect_ratio,
                                             GError **error);

int      gdk_pixbuf_get_width(const GdkPixbuf *pixbuf);
int      gdk_pixbuf_get_height(const GdkPixbuf *pixbuf);
guchar  *gdk_pixbuf_get_pixels(const GdkPixbuf *pixbuf);
int      gdk_pixbuf_get_rowstride(const GdkPixbuf *pixbuf);
int      gdk_pixbuf_get_n_channels(const GdkPixbuf *pixbuf);
gboolean gdk_pixbuf_get_has_alpha(const GdkPixbuf *pixbuf);

void g_object_unref(gpointer object);
void g_error_free(GError *error);

/* gdk_pixbuf_get_file_info lee solo la cabecera del archivo para
   obtener ancho/alto. Mucho mas rapido que decodificar entero. */
typedef struct _GdkPixbufFormat GdkPixbufFormat;
GdkPixbufFormat *gdk_pixbuf_get_file_info(const char *filename,
                                          int *width,
                                          int *height);
]]

return ffi
