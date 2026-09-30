-- cdef para resvg 0.48 (libresvg.so.0). Reemplaza al cdef de
-- librsvg que estaba aca antes. Solo se declaran los tipos y
-- funciones que usa src/lib/svg.lua.

local ffi = require("ffi")

ffi.cdef[[
typedef struct resvg_options resvg_options;
typedef struct resvg_render_tree resvg_render_tree;

typedef struct {
    float a, b, c, d, e, f;
} resvg_transform;

typedef struct {
    float width, height;
} resvg_size;

typedef struct {
    float x, y, width, height;
} resvg_rect;

resvg_options *resvg_options_create(void);
void           resvg_options_destroy(resvg_options *opt);
void           resvg_options_set_dpi(resvg_options *opt, float dpi);
void           resvg_options_set_font_family(resvg_options *opt,
                                             const char *family);
void           resvg_options_set_serif_family(resvg_options *opt,
                                              const char *family);
void           resvg_options_set_sans_serif_family(resvg_options *opt,
                                                   const char *family);
void           resvg_options_set_monospace_family(resvg_options *opt,
                                                  const char *family);
int32_t        resvg_options_load_font_file(resvg_options *opt,
                                            const char *file_path);
void           resvg_options_load_system_fonts(resvg_options *opt);

int32_t        resvg_parse_tree_from_file(const char *file_path,
                                          const resvg_options *opt,
                                          resvg_render_tree **tree);
int32_t        resvg_parse_tree_from_data(const char *data,
                                          size_t len,
                                          const resvg_options *opt,
                                          resvg_render_tree **tree);

resvg_size     resvg_get_image_size(const resvg_render_tree *tree);
bool           resvg_is_image_empty(const resvg_render_tree *tree);
resvg_transform resvg_transform_identity(void);
void           resvg_render(const resvg_render_tree *tree,
                            resvg_transform transform,
                            uint32_t width,
                            uint32_t height,
                            char *pixmap);
void           resvg_tree_destroy(resvg_render_tree *tree);
]]

return ffi
