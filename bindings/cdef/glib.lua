-- cdef minimo para libglib-2.0.so.0. Solo lo que necesitamos:
-- checksum MD5 para hashear URIs (freedesktop thumbnail spec) y
-- g_free para liberar el string que devuelve GLib.
--
-- GLib ya esta en el proceso porque libgdk-pixbuf-2.0.so.0 depende
-- de el. Cargarlo de nuevo es gratis (dlopen devuelve el handle
-- existente).

local ffi = require("ffi")

ffi.cdef[[
typedef enum {
    G_CHECKSUM_MD5    = 0,
    G_CHECKSUM_SHA1   = 1,
    G_CHECKSUM_SHA256 = 2,
    G_CHECKSUM_SHA512 = 3,
    G_CHECKSUM_SHA384 = 4
} GChecksumType;

/* Devuelve un string recien asignado. Liberar con g_free. */
char *g_compute_checksum_for_string(GChecksumType checksum_type,
                                    const char   *str,
                                    long          length);

void  g_free(void *mem);
]]

return ffi
