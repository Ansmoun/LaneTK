local ffi = require("ffi")

ffi.cdef[[
typedef struct xcb_connection_t xcb_connection_t;
typedef uint32_t xcb_window_t;
typedef uint32_t xcb_drawable_t;
typedef uint32_t xcb_visualid_t;
typedef uint32_t xcb_atom_t;
typedef uint32_t xcb_colormap_t;
typedef uint32_t xcb_timestamp_t;
typedef uint8_t  xcb_keycode_t;
typedef uint8_t  xcb_button_t;
typedef uint16_t xcb_keysym_t;

typedef struct xcb_screen_t {
    xcb_window_t   root;
    xcb_colormap_t default_colormap;
    uint32_t       white_pixel;
    uint32_t       black_pixel;
    uint32_t       current_input_masks;
    uint16_t       width_in_pixels;
    uint16_t       height_in_pixels;
    uint16_t       width_in_mm;
    uint16_t       height_in_mm;
    uint16_t       min_installed_maps;
    uint16_t       max_installed_maps;
    xcb_visualid_t root_visual;
    uint8_t        backing_stores;
    uint8_t        save_unders;
    uint8_t        root_depth;
    uint8_t        allowed_depths_len;
} xcb_screen_t;

typedef struct xcb_visualtype_t {
    xcb_visualid_t visual_id;
    uint8_t        _class;
    uint8_t        bits_per_rgb_value;
    uint16_t       colormap_entries;
    uint32_t       red_mask;
    uint32_t       green_mask;
    uint32_t       blue_mask;
    uint8_t        pad0[4];
} xcb_visualtype_t;

typedef struct {
    uint8_t      response_type;
    uint8_t      pad0;
    uint16_t     sequence;
} xcb_generic_event_t;

typedef struct {
    uint8_t      response_type;
    uint8_t      format;
    uint16_t     sequence;
    xcb_window_t window;
    xcb_atom_t   type;
    uint32_t     data[5];
} xcb_client_message_event_t;

typedef struct {
    uint8_t      response_type;
    uint8_t      pad0;
    uint16_t     sequence;
    xcb_window_t window;
    uint16_t     x;
    uint16_t     y;
    uint16_t     width;
    uint16_t     height;
    uint16_t     count;
    uint8_t      pad1[14];
} xcb_expose_event_t;

typedef struct {
    uint8_t      response_type;
    uint8_t      detail;
    uint16_t     sequence;
    uint32_t     time;
    xcb_window_t root;
    xcb_window_t event;
    xcb_window_t child;
    int16_t      root_x;
    int16_t      root_y;
    int16_t      event_x;
    int16_t      event_y;
    uint16_t     state;
    uint8_t      same_screen;
    uint8_t      pad0;
} xcb_key_press_event_t;

typedef struct {
    uint8_t      response_type;
    uint8_t      detail;
    uint16_t     sequence;
    uint32_t     time;
    xcb_window_t root;
    xcb_window_t event;
    xcb_window_t child;
    int16_t      root_x;
    int16_t      root_y;
    int16_t      event_x;
    int16_t      event_y;
    uint16_t     state;
    uint8_t      same_screen;
    uint8_t      pad0;
} xcb_button_press_event_t;

typedef struct {
    uint8_t      response_type;
    uint8_t      detail;
    uint16_t     sequence;
    uint32_t     time;
    xcb_window_t root;
    xcb_window_t event;
    xcb_window_t child;
    int16_t      root_x;
    int16_t      root_y;
    int16_t      event_x;
    int16_t      event_y;
    uint16_t     state;
    uint8_t      same_screen;
    uint8_t      pad0;
} xcb_motion_notify_event_t;

typedef struct {
    uint8_t      response_type;
    uint8_t      detail;
    uint16_t     sequence;
    uint32_t     time;
    xcb_window_t root;
    xcb_window_t event;
    xcb_window_t child;
    int16_t      root_x;
    int16_t      root_y;
    int16_t      event_x;
    int16_t      event_y;
    uint16_t     state;
    uint8_t      mode;
    uint8_t      same_screen_focus;
} xcb_enter_notify_event_t;


typedef struct {
    uint8_t      response_type;
    uint8_t      pad0;
    uint16_t     sequence;
    xcb_window_t event;
    xcb_window_t window;
    xcb_window_t above;
    int16_t      x;
    int16_t      y;
    uint16_t     width;
    uint16_t     height;
    uint16_t     border_width;
    uint8_t      override_redirect;
    uint8_t      pad1;
} xcb_configure_notify_event_t;

typedef struct {
    uint8_t      response_type;
    uint8_t      pad0;
    uint16_t     sequence;
    xcb_window_t event;
    xcb_window_t window;
} xcb_destroy_notify_event_t;

typedef struct {
    uint8_t      response_type;
    uint8_t      pad0;
    uint16_t     sequence;
    xcb_window_t event;
    xcb_window_t window;
    uint8_t      from_configure;
    uint8_t      pad1[3];
} xcb_unmap_notify_event_t;

typedef struct {
    uint8_t      response_type;
    uint8_t      pad0;
    uint16_t     sequence;
    xcb_window_t event;
    xcb_window_t window;
    uint8_t      override_redirect;
    uint8_t      pad1[3];
} xcb_map_notify_event_t;

typedef struct {
    uint8_t      response_type;
    uint8_t      pad0;
    uint16_t     sequence;
    xcb_window_t window;
    xcb_atom_t   atom;
    uint32_t     time;
    uint8_t      state;
    uint8_t      pad1[3];
} xcb_property_notify_event_t;

void free(void *ptr);

/* --- procesos y signalfd (para hot reload entre procesos) --- */
typedef int pid_t;
int kill(pid_t pid, int sig);
int getpid(void);

/* --- signalfd: señal como fd, sin handler Lua --- */
typedef struct {
    unsigned long __val[16];
} sigset_t;

typedef struct {
    uint32_t ssi_signo;
    int32_t  ssi_errno;
    int32_t  ssi_code;
    uint32_t ssi_pid;
    uint32_t ssi_uid;
    int32_t  ssi_fd;
    uint32_t ssi_tid;
    uint32_t ssi_band;
    uint32_t ssi_overrun;
    uint32_t ssi_trapno;
    int32_t  ssi_status;
    int32_t  ssi_int;
    uint64_t ssi_ptr;
    uint64_t ssi_utime;
    uint64_t ssi_stime;
    uint64_t ssi_addr;
    uint16_t ssi_addr_lsb;
    uint8_t  __pad2[46];
} signalfd_siginfo;

int sigemptyset(sigset_t *set);
int sigaddset(sigset_t *set, int signum);
int sigprocmask(int how, const sigset_t *set, sigset_t *oldset);
int signalfd(int fd, const sigset_t *mask, int flags);

typedef long ssize_t;
ssize_t read(int fd, void *buf, unsigned long count);

xcb_connection_t *xcb_connect(const char *displayname, int *screenp);
void              xcb_disconnect(xcb_connection_t *c);
int               xcb_connection_has_error(xcb_connection_t *c);
int               xcb_flush(xcb_connection_t *c);
uint32_t          xcb_generate_id(xcb_connection_t *c);
int               xcb_get_file_descriptor(xcb_connection_t *c);

xcb_screen_t     *xcb_aux_get_screen(xcb_connection_t *c, int screen);
xcb_visualtype_t *xcb_aux_find_visual_by_id(xcb_screen_t *screen, xcb_visualid_t id);

uint32_t xcb_intern_atom(
    xcb_connection_t *c, uint8_t only_if_exists, uint16_t name_len, const char *name
);

typedef struct {
    uint8_t    response_type;
    uint8_t    pad0;
    uint16_t   sequence;
    uint32_t   length;
    xcb_atom_t atom;
} xcb_intern_atom_reply_t;

xcb_intern_atom_reply_t *xcb_intern_atom_reply(
    xcb_connection_t *c, uint32_t cookie, void *e
);

uint32_t xcb_create_window(
    xcb_connection_t *c, uint8_t depth, xcb_window_t wid,
    xcb_window_t parent, int16_t x, int16_t y, uint16_t width, uint16_t height,
    uint16_t border_width, uint16_t _class, xcb_visualid_t visual,
    uint32_t value_mask, const uint32_t *value_list
);

uint32_t xcb_set_input_focus(xcb_connection_t *c, uint8_t revert_to, xcb_window_t focus, uint32_t time);
uint32_t xcb_map_window(xcb_connection_t *c, xcb_window_t window);
uint32_t xcb_unmap_window(xcb_connection_t *c, xcb_window_t window);
uint32_t xcb_destroy_window(xcb_connection_t *c, xcb_window_t window);
uint32_t xcb_configure_window(
    xcb_connection_t *c, xcb_window_t window, uint16_t value_mask,
    const uint32_t *value_list
);

uint32_t xcb_change_property(
    xcb_connection_t *c, uint8_t mode, xcb_window_t window,
    xcb_atom_t property, xcb_atom_t type, uint8_t format,
    uint32_t data_len, const void *data
);

typedef struct {
    uint8_t  response_type;
    uint8_t  error_code;
    uint16_t sequence;
    uint32_t resource_id;
    uint16_t minor_code;
    uint8_t  major_code;
    uint8_t  pad0;
} xcb_generic_error_t;

typedef struct {
    unsigned int sequence;
} xcb_void_cookie_t;

xcb_void_cookie_t xcb_create_window_checked(xcb_connection_t *c, uint8_t depth, xcb_window_t wid, xcb_window_t parent, int16_t x, int16_t y, uint16_t width, uint16_t height, uint16_t border_width, uint16_t _class, xcb_visualid_t visual, uint32_t value_mask, const uint32_t *value_list);
xcb_generic_error_t *xcb_request_check(xcb_connection_t *c, xcb_void_cookie_t cookie);
typedef struct {
    uint8_t      response_type;
    uint8_t      pad0;
    uint16_t     sequence;
    uint32_t     length;
    xcb_window_t focus;
} xcb_get_input_focus_reply_t;

uint32_t xcb_query_pointer(xcb_connection_t *c, xcb_window_t window);

typedef struct {
    uint8_t      response_type;
    uint8_t      same_screen;
    uint16_t     sequence;
    uint32_t     length;
    uint16_t     mask;
    uint16_t     pad0;
    xcb_window_t root;
    xcb_window_t child;
    int16_t      root_x;
    int16_t      root_y;
    int16_t      win_x;
    int16_t      win_y;
} xcb_query_pointer_reply_t;

xcb_query_pointer_reply_t *xcb_query_pointer_reply(
    xcb_connection_t *c, uint32_t cookie, void *e);

uint32_t xcb_get_input_focus(xcb_connection_t *c);
xcb_get_input_focus_reply_t *xcb_get_input_focus_reply(
    xcb_connection_t *c, uint32_t cookie, void *e);

uint32_t xcb_grab_pointer(
    xcb_connection_t *c,
    uint8_t           owner_events,
    xcb_window_t      grab_window,
    uint16_t          event_mask,
    uint8_t           pointer_mode,
    uint8_t           keyboard_mode,
    xcb_window_t      confine_to,
    uint32_t          cursor,
    uint32_t          time
);

void xcb_ungrab_pointer(xcb_connection_t *c, uint32_t time);

/* --- EWMH: lectura de propiedades y suscripcion al root --- */

uint32_t xcb_get_property(
    xcb_connection_t *c,
    uint8_t           delete,
    xcb_window_t      window,
    xcb_atom_t        property,
    xcb_atom_t        type,
    uint32_t          long_offset,
    uint32_t          long_length
);

typedef struct {
    uint8_t    response_type;
    uint8_t    format;
    uint16_t   sequence;
    uint32_t   length;
    xcb_atom_t type;
    uint32_t   bytes_after;
    uint32_t   value_len;
    uint8_t    pad0[12];
} xcb_get_property_reply_t;

xcb_get_property_reply_t *xcb_get_property_reply(
    xcb_connection_t *c, uint32_t cookie, void *e);

void *xcb_get_property_value(const xcb_get_property_reply_t *reply);
int   xcb_get_property_value_length(const xcb_get_property_reply_t *reply);

uint32_t xcb_change_window_attributes(
    xcb_connection_t *c,
    xcb_window_t      window,
    uint16_t          value_mask,
    const uint32_t   *value_list
);

xcb_generic_event_t *xcb_poll_for_event(xcb_connection_t *c);

/* --- Envio de client messages (EWMH de escritura) --- */

uint32_t xcb_send_event(
    xcb_connection_t *c,
    uint8_t           propagate,
    xcb_window_t      destination,
    uint32_t          event_mask,
    const char       *event
);

typedef struct {
    uint8_t      response_type;
    uint8_t      format;
    uint16_t     sequence;
    xcb_window_t window;
    xcb_atom_t   type;
    uint32_t     data[5];
} xcb_client_message_event_t;

typedef uint32_t xcb_pixmap_t;
typedef uint32_t xcb_gcontext_t;

/* --- Pixmap, GC, PutImage (para el wallpaper nativo) --- */
xcb_void_cookie_t xcb_create_pixmap(
    xcb_connection_t *c, uint8_t depth, xcb_pixmap_t pid,
    xcb_drawable_t drawable, uint16_t width, uint16_t height);
xcb_void_cookie_t xcb_create_pixmap_checked(
    xcb_connection_t *c, uint8_t depth, xcb_pixmap_t pid,
    xcb_drawable_t drawable, uint16_t width, uint16_t height);
xcb_void_cookie_t xcb_free_pixmap(xcb_connection_t *c, xcb_pixmap_t pixmap);
xcb_void_cookie_t xcb_free_pixmap_checked(xcb_connection_t *c, xcb_pixmap_t pixmap);
xcb_void_cookie_t xcb_create_gc(
    xcb_connection_t *c, xcb_gcontext_t cid, xcb_drawable_t drawable,
    uint32_t value_mask, const uint32_t *value_list);
xcb_void_cookie_t xcb_create_gc_checked(
    xcb_connection_t *c, xcb_gcontext_t cid, xcb_drawable_t drawable,
    uint32_t value_mask, const uint32_t *value_list);
xcb_void_cookie_t xcb_free_gc(xcb_connection_t *c, xcb_gcontext_t gc);
xcb_void_cookie_t xcb_free_gc_checked(xcb_connection_t *c, xcb_gcontext_t gc);
xcb_void_cookie_t xcb_put_image(
    xcb_connection_t *c, uint8_t format, xcb_drawable_t drawable,
    xcb_gcontext_t gc, uint16_t width, uint16_t height,
    int16_t dst_x, int16_t dst_y, uint8_t left_pad, uint8_t depth,
    uint32_t data_len, const uint8_t *data);
xcb_void_cookie_t xcb_put_image_checked(
    xcb_connection_t *c, uint8_t format, xcb_drawable_t drawable,
    xcb_gcontext_t gc, uint16_t width, uint16_t height,
    int16_t dst_x, int16_t dst_y, uint8_t left_pad, uint8_t depth,
    uint32_t data_len, const uint8_t *data);


/* --- XShape: mascara de recorte para ventanas no rectangulares --- */
typedef struct {
    int16_t  x;
    int16_t  y;
    uint16_t width;
    uint16_t height;
} xcb_rectangle_t;

uint32_t xcb_shape_rectangles(
    xcb_connection_t *c,
    uint8_t operation,
    uint8_t destination_kind,
    uint8_t ordering,
    xcb_window_t destination_window,
    int16_t x_offset,
    int16_t y_offset,
    uint32_t rectangles_len,
    const xcb_rectangle_t *rectangles);

typedef struct {
    uint8_t  response_type;
    uint8_t  pad0;
    uint16_t sequence;
    uint32_t length;
    uint8_t  keys[32];
} xcb_query_keymap_reply_t;

uint32_t xcb_query_keymap(xcb_connection_t *c);
xcb_query_keymap_reply_t *xcb_query_keymap_reply(
    xcb_connection_t *c, uint32_t cookie, void *e);

uint32_t xcb_shape_mask(
    xcb_connection_t *c, uint8_t operation, uint8_t destination_kind,
    xcb_window_t destination_window,
    int16_t x_offset, int16_t y_offset, xcb_pixmap_t source_bitmap);

uint32_t xcb_shape_combine(
    xcb_connection_t *c, uint8_t operation,
    uint8_t destination_kind, uint8_t source_kind,
    xcb_window_t destination_window,
    int16_t x_offset, int16_t y_offset,
    xcb_window_t source_window);

uint32_t xcb_shape_offset(
    xcb_connection_t *c, uint8_t destination_kind,
    xcb_window_t destination_window,
    int16_t x_offset, int16_t y_offset);

typedef long time_t;
typedef long suseconds_t;
struct timeval {
    time_t       tv_sec;
    suseconds_t  tv_usec;
};
int gettimeofday(struct timeval *tv, void *tz);
]]

return ffi
