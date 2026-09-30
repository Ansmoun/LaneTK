local ffi = require("bindings.cdef.xcb")
local bit = require("bit")

local xcb_core = ffi.load("xcb")
local xcb_util = ffi.load("libxcb-util.so.1")

local M = {}

M.CW = {
    BackPixmap       = 1,
    BackPixel        = 2,
    BorderPixmap     = 4,
    BorderPixel      = 8,
    BitGravity       = 16,
    WinGravity       = 32,
    BackingStore     = 64,
    BackingPlanes    = 128,
    BackingPixel     = 256,
    OverrideRedirect = 512,
    SaveUnder        = 1024,
    EventMask        = 2048,
    DontPropagate    = 4096,
    Colormap         = 8192,
    Cursor           = 16384,
}

M.CONFIG = {
    X       = 1,
    Y       = 2,
    Width   = 4,
    Height  = 8,
    Border  = 16,
    Sibling = 32,
    Stack   = 64,
}

M.PROP_MODE = {
    Replace = 0,
    Prepend = 1,
    Append  = 2,
}

M.EVENT_MASK = {
    KeyPress             = 1,
    KeyRelease           = 2,
    ButtonPress          = 4,
    ButtonRelease        = 8,
    EnterWindow          = 16,
    LeaveWindow          = 32,
    PointerMotion        = 64,
    Exposure             = 32768,
    VisibilityChange     = 65536,
    StructureNotify      = 131072,
    ResizeRedirect       = 262144,
    SubstructureNotify   = 524288,
    SubstructureRedirect = 1048576,
    FocusChange          = 2097152,
    PropertyChange       = 4194304,
    ColormapChange       = 8388608,
}

M.EVENT = {
    KeyPress         = 2,
    KeyRelease       = 3,
    ButtonPress      = 4,
    ButtonRelease    = 5,
    MotionNotify     = 6,
    EnterNotify      = 7,
    LeaveNotify      = 8,
    FocusIn          = 9,
    FocusOut         = 10,
    Expose           = 12,
    VisibilityNotify = 15,
    CreateNotify     = 16,
    DestroyNotify    = 17,
    UnmapNotify      = 18,
    MapNotify        = 19,
    MapRequest       = 20,
    ReparentNotify   = 21,
    ConfigureNotify  = 22,
    ConfigureRequest = 23,
    PropertyNotify   = 28,
    ClientMessage    = 33,
}

M.WIN_CLASS = {
    CopyFromParent = 0,
    InputOutput    = 1,
    InputOnly      = 2,
}

-- ICCCM flags (valores literales, sin depender del preprocesador)
M.ICCCM = {
    US_POSITION   = 1,
    US_SIZE       = 2,
    P_POSITION    = 4,
    P_SIZE        = 8,
    P_MIN_SIZE    = 16,
    P_MAX_SIZE    = 32,
    P_RESIZE_INC  = 64,
    P_ASPECT      = 128,
    BASE_SIZE     = 256,
    P_WIN_GRAVITY = 512,
    WM_HINT_INPUT = 1,
}

function M.connect(displayname)
    local screenp = ffi.new("int[1]")
    local conn = xcb_core.xcb_connect(displayname, screenp)
    if xcb_core.xcb_connection_has_error(conn) ~= 0 then
        error("xcb_connect failed")
    end
    return conn, screenp[0]
end

function M.disconnect(conn)
    xcb_core.xcb_disconnect(conn)
end

function M.flush(conn)
    xcb_core.xcb_flush(conn)
end

function M.generate_id(conn)
    return xcb_core.xcb_generate_id(conn)
end

function M.get_file_descriptor(conn)
    return xcb_core.xcb_get_file_descriptor(conn)
end

function M.get_screen(conn, idx)
    return xcb_util.xcb_aux_get_screen(conn, idx or 0)
end

function M.get_visualtype(conn, screen_idx, visual_id)
    local screen = M.get_screen(conn, screen_idx or 0)
    return xcb_util.xcb_aux_find_visual_by_id(screen, visual_id)
end

function M.intern_atom(conn, name, only_if_exists)
    local cookie = xcb_core.xcb_intern_atom(
        conn, only_if_exists and 1 or 0, #name, name
    )
    local reply = xcb_core.xcb_intern_atom_reply(conn, cookie, nil)
    if reply == nil then return 0 end
    local atom = reply.atom
    ffi.C.free(reply)
    return atom
end

function M.change_property(conn, win, prop, ptype, format, data_len, data)
    xcb_core.xcb_change_property(
        conn, M.PROP_MODE.Replace, win, prop, ptype, format, data_len, data
    )
end

-- Lee una propiedad de una ventana. Devuelve:
--   { type = atom, format = bits, data = <tabla o string> } o nil.
--
-- El tipo de retorno depende de `format` (8, 16 o 32 bits) y del
-- atom esperado. El wrapper NO interpreta; devuelve los bytes crudos
-- (format=8) o un array de uint32 (format=32). El consumidor decide
-- como parsearlo segun el atom.
function M.get_property(conn, win, prop, ptype, long_length)
    ptype = ptype or 0   -- 0 = AnyPropertyType
    long_length = long_length or 1024
    local cookie = xcb_core.xcb_get_property(
        conn, 0, win, prop, ptype, 0, long_length
    )
    local reply = xcb_core.xcb_get_property_reply(conn, cookie, nil)
    if reply == nil then return nil end
    local fmt = reply.format
    local n = reply.value_len
    if fmt == 0 or n == 0 then
        ffi.C.free(reply)
        return { type = reply.type, format = fmt, data = nil }
    end
    local ptr = xcb_core.xcb_get_property_value(reply)
    local out
    if fmt == 8 then
        out = ffi.string(ptr, n)
    elseif fmt == 16 then
        local arr = ffi.cast("uint16_t*", ptr)
        out = {}
        for i = 0, n - 1 do out[i + 1] = arr[i] end
    else  -- fmt == 32
        local arr = ffi.cast("uint32_t*", ptr)
        out = {}
        for i = 0, n - 1 do out[i + 1] = arr[i] end
    end
    local rtype = reply.type
    ffi.C.free(reply)
    return { type = rtype, format = fmt, data = out }
end

-- Suscribe eventos de una ventana (util para el root y PropertyNotify).
-- `mask` es un OR de bits de EVENT_MASK (por ejemplo
-- bit.bor(EVENT_MASK.PropertyChange, EVENT_MASK.SubstructureNotify)).
function M.change_window_attributes(conn, win, mask)
    local arr = ffi.new("uint32_t[1]", mask)
    xcb_core.xcb_change_window_attributes(conn, win, M.CW.EventMask, arr)
end

-- Envia un ClientMessage al servidor. `ev` es una tabla con los
-- campos del evento:
--   window   -- xcb_window_t destino (root o el wid de la ventana)
--   type     -- atom del message_type (por ejemplo _NET_ACTIVE_WINDOW)
--   format   -- 8, 16 o 32 (EWMH siempre usa 32)
--   data     -- array de hasta 5 numeros (los campos data.l[])
--
-- `dest` y `event_mask` controlan el destino en X11:
--   - Para enviar al root: dest = root, mask = SubstructureRedirect | SubstructureNotify
--   - Para enviar a una ventana: dest = wid, mask = 0
-- El consumidor normalmente usa la constante EVENT_MASK.SubstructureRedirect
-- y combina con SubstructureNotify.
function M.send_event(conn, dest, event_mask, ev)
    local cev = ffi.new("xcb_client_message_event_t")
    cev.response_type = M.EVENT.ClientMessage
    cev.format = ev.format or 32
    cev.window = ev.window
    cev.type = ev.type
    local data = ev.data or {}
    for i = 0, 4 do
        cev.data[i] = data[i + 1] or 0
    end
    xcb_core.xcb_send_event(conn, 0, dest, event_mask,
        ffi.cast("const char*", cev))
end

-- Atajo: envia un ClientMessage al root con la mascara estandar de
-- EWMH (SubstructureRedirect | SubstructureNotify). Es lo que usan
-- casi todos los client messages globales (_NET_CURRENT_DESKTOP,
-- _NET_ACTIVE_WINDOW, _NET_CLOSE_WINDOW).
function M.send_client_message_root(conn, root, ev)
    local mask = bit.bor(
        M.EVENT_MASK.SubstructureRedirect,
        M.EVENT_MASK.SubstructureNotify)
    M.send_event(conn, root, mask, ev)
end

function M.configure_window(conn, win, mask, values)
    local arr = ffi.new("uint32_t[7]")
    local i = 0
    if values.x       ~= nil then arr[i] = values.x;       i = i + 1 end
    if values.y       ~= nil then arr[i] = values.y;       i = i + 1 end
    if values.width   ~= nil then arr[i] = values.width;   i = i + 1 end
    if values.height  ~= nil then arr[i] = values.height;  i = i + 1 end
    if values.border  ~= nil then arr[i] = values.border;  i = i + 1 end
    if values.sibling ~= nil then arr[i] = values.sibling; i = i + 1 end
    if values.stack   ~= nil then arr[i] = values.stack;   i = i + 1 end
    xcb_core.xcb_configure_window(conn, win, mask, arr)
end

function M.create_window(conn, opts)
    opts = opts or {}
    local screen = M.get_screen(conn, opts.screen or 0)
    local wid = M.generate_id(conn)

    -- El value_list de xcb_create_window debe ir en el orden de los
    -- bits del value_mask, segun el protocolo X11:
    --   BackPixmap < BackPixel < BorderPixmap < BorderPixel
    --   < BitGravity < WinGravity < BackingStore < BackingPlanes
    --   < BackingPixel < OverrideRedirect < SaveUnder
    --   < EventMask < DontPropagate < Colormap < Cursor
    -- Si el orden no coincide, el servidor lee valores cruzados.
    -- En ventanas top-level suele pasar desapercibido, pero en child
    -- windows valida y devuelve BadValue.
    local mask = 0
    local values = {}

    if opts.background_pixel ~= nil then
        mask = bit.bor(mask, M.CW.BackPixel)
        values[#values + 1] = opts.background_pixel
    end
    if opts.border_pixel ~= nil then
        mask = bit.bor(mask, M.CW.BorderPixel)
        values[#values + 1] = opts.border_pixel
    end
    if opts.override_redirect then
        mask = bit.bor(mask, M.CW.OverrideRedirect)
        values[#values + 1] = 1
    end
    if opts.event_mask then
        mask = bit.bor(mask, M.CW.EventMask)
        values[#values + 1] = opts.event_mask
    end

    local vlist
    if #values > 0 then
        vlist = ffi.new("uint32_t[?]", #values)
        for i = 1, #values do vlist[i - 1] = values[i] end
    else
        vlist = nil
    end

    local cookie = xcb_core.xcb_create_window_checked(
        conn,
        opts.depth or screen.root_depth,
        wid,
        opts.parent or screen.root,
        opts.x or 0, opts.y or 0,
        opts.width or 400, opts.height or 300,
        opts.border_width or 0,
        opts.class or M.WIN_CLASS.InputOutput,
        opts.visual or screen.root_visual,
        mask,
        vlist
    )

    -- Sincronizar y verificar si el servidor rechazo la creacion.
    local err = xcb_core.xcb_request_check(conn, cookie)
    if err ~= nil then
        local code = err.error_code
        local major = err.major_code
        local minor = err.minor_code
        ffi.C.free(err)
        return nil, screen, string.format(
            "xcb_create_window fallo: error_code=%d major=%d minor=%d",
            code, major, minor)
    end

    return wid, screen
end

function M.map_window(conn, wid)
    xcb_core.xcb_map_window(conn, wid)
    xcb_core.xcb_flush(conn)
end

function M.unmap_window(conn, wid)
    xcb_core.xcb_unmap_window(conn, wid)
end

function M.destroy_window(conn, wid)
    xcb_core.xcb_destroy_window(conn, wid)
end

function M.wait_event(conn)
    return xcb_core.xcb_wait_for_event(conn)
end

function M.poll_event(conn)
    return xcb_core.xcb_poll_for_event(conn)
end

local icccm_lib = nil
local function icccm()
    if not icccm_lib then
        require("bindings.cdef.xcb_icccm")
        icccm_lib = ffi.load("libxcb-icccm.so.4")
    end
    return icccm_lib
end

function M.set_wm_normal_hints(conn, win, hints)
    local lib = icccm()
    local h = ffi.new("xcb_size_hints_t")
    h.flags = hints.flags or 0
    if hints.x then h.x = hints.x end
    if hints.y then h.y = hints.y end
    if hints.width then h.width = hints.width end
    if hints.height then h.height = hints.height end
    if hints.min_width then h.min_width = hints.min_width end
    if hints.min_height then h.min_height = hints.min_height end
    if hints.max_width then h.max_width = hints.max_width end
    if hints.max_height then h.max_height = hints.max_height end
    if hints.width_inc then h.width_inc = hints.width_inc end
    if hints.height_inc then h.height_inc = hints.height_inc end
    if hints.min_aspect_num then h.min_aspect_num = hints.min_aspect_num end
    if hints.min_aspect_den then h.min_aspect_den = hints.min_aspect_den end
    if hints.max_aspect_num then h.max_aspect_num = hints.max_aspect_num end
    if hints.max_aspect_den then h.max_aspect_den = hints.max_aspect_den end
    if hints.base_width then h.base_width = hints.base_width end
    if hints.base_height then h.base_height = hints.base_height end
    lib.xcb_icccm_set_wm_normal_hints(conn, win, h)
end

function M.set_wm_hints(conn, win, hints)
    local lib = icccm()
    local h = ffi.new("xcb_wm_hints_t")
    h.flags = hints.flags or 0
    if hints.input ~= nil then h.input = hints.input and 1 or 0 end
    lib.xcb_icccm_set_wm_hints(conn, win, h)
end

function M.set_input_focus(conn, wid, revert_to)
    -- revert_to: 0=None, 1=PointerRoot, 2=Parent. Default Parent.
    -- time=0 significa CurrentTime.
    xcb_core.xcb_set_input_focus(conn, revert_to or 2, wid, 0)
    xcb_core.xcb_flush(conn)
end

-- Fuerza un round-trip al servidor X. Util despues de operaciones
-- asincronas (map_window, configure_window) para asegurar que el
-- servidor las ha procesado.
function M.sync(conn)
    local cookie = xcb_core.xcb_get_input_focus(conn)
    local reply = xcb_core.xcb_get_input_focus_reply(conn, cookie, nil)
    if reply ~= nil then
        ffi.C.free(reply)
    end
end

function M.query_pointer(conn)
    -- El primer argumento es una ventana válida. Usamos el root.
    local screen = M.get_screen(conn, 0)
    local cookie = xcb_core.xcb_query_pointer(conn, screen.root)
    local reply = xcb_core.xcb_query_pointer_reply(conn, cookie, nil)
    if reply == nil then return nil, nil end
    local x, y = tonumber(reply.root_x), tonumber(reply.root_y)
    ffi.C.free(reply)
    return x, y
end

-- Devuelve el window id que tiene el foco de teclado X11, o 0.
function M.get_input_focus(conn)
    local cookie = xcb_core.xcb_get_input_focus(conn)
    local reply = xcb_core.xcb_get_input_focus_reply(conn, cookie, nil)
    if reply == nil then return 0 end
    local focus = tonumber(reply.focus)
    ffi.C.free(reply)
    return focus
end

-- Devuelve el foco al root (RevertToParent). Util como fallback
-- cuando no se guardo la ventana previa.
function M.set_input_focus_revert(conn)
    -- RevertToParent = 2
    xcb_core.xcb_set_input_focus(conn, 2, 1, 0)  -- 1 = PointerRoot
    xcb_core.xcb_flush(conn)
end

-- Captura todos los clicks para el grab_window. Los eventos de
-- boton (press/release/motion) llegaran al grab_window con
-- event_x/event_y relativos al window. Usado por ContextMenu para
-- detectar clicks fuera de su rect.
function M.grab_pointer(conn, window)
    -- owner_events=0 (todos los eventos al grab_window)
    -- event_mask = ButtonPress|ButtonRelease|PointerMotion
    -- pointer_mode=1 (async), keyboard_mode=1 (async)
    xcb_core.xcb_grab_pointer(conn, 0, window,
        4 + 8 + 64,  -- ButtonPress|ButtonRelease|PointerMotion
        1, 1, 0, 0, 0)
    xcb_core.xcb_flush(conn)
end

function M.ungrab_pointer(conn)
    xcb_core.xcb_ungrab_pointer(conn, 0)
    xcb_core.xcb_flush(conn)
end

return M
