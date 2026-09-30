local ffi = require("ffi")

ffi.cdef[[
typedef uint32_t xkb_keycode_t;
typedef uint32_t xkb_keysym_t;
typedef uint32_t xkb_mod_mask_t;
typedef uint32_t xkb_layout_index_t;
typedef uint32_t xkb_layout_mask_t;

typedef struct xkb_context xkb_context;
typedef struct xkb_keymap  xkb_keymap;
typedef struct xkb_state   xkb_state;

typedef struct {
    const char *rules;
    const char *model;
    const char *layout;
    const char *variant;
    const char *options;
} xkb_rule_names;

enum {
    XKB_CONTEXT_NO_FLAGS              = 0,
    XKB_CONTEXT_NO_DEFAULT_INCLUDES   = 1 << 0,
    XKB_CONTEXT_NO_ENVIRONMENT_NAMES  = 1 << 1
};

enum {
    XKB_KEYMAP_COMPILE_NO_FLAGS = 0
};

enum {
    XKB_KEY_UP   = 0,
    XKB_KEY_DOWN = 1
};

enum {
    XKB_KEYSYM_NO_FLAGS          = 0,
    XKB_KEYSYM_CASE_INSENSITIVE  = 1 << 0
};

xkb_context *xkb_context_new(int flags);
void         xkb_context_unref(xkb_context *context);

xkb_keymap *xkb_keymap_new_from_names(
    xkb_context *context,
    const xkb_rule_names *names,
    int flags
);
void xkb_keymap_unref(xkb_keymap *keymap);

xkb_state *xkb_state_new(xkb_keymap *keymap);
xkb_state *xkb_state_ref(xkb_state *state);
void       xkb_state_unref(xkb_state *state);

int          xkb_state_update_key(xkb_state *state, xkb_keycode_t key, int direction);
int          xkb_state_key_get_utf8(xkb_state *state, xkb_keycode_t key, char *buffer, size_t size);
xkb_keysym_t xkb_state_key_get_one_sym(xkb_state *state, xkb_keycode_t key);

int          xkb_keysym_get_name(xkb_keysym_t keysym, char *buffer, size_t size);
xkb_keysym_t xkb_keysym_from_name(const char *name, int flags);
]]

return ffi
