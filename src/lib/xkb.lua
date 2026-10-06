local ffi = require("bindings.cdef.xkb")
local log = require("lib.log")

local lib = ffi.load("libxkbcommon.so.0")

local M = {}

M.KEY_UP   = 0
M.KEY_DOWN = 1

-- Mascaras X11 (las que vienen en el campo `state` del evento)
M.X11_MOD = {
    SHIFT = 1,      -- 1 << 0
    LOCK  = 2,      -- 1 << 1
    CTRL  = 4,      -- 1 << 2
    MOD1  = 8,      -- 1 << 3 (tipicamente Alt)
    MOD2  = 16,     -- 1 << 4 (tipicamente NumLock)
    MOD3  = 32,     -- 1 << 5
    MOD4  = 64,     -- 1 << 6 (tipicamente Super)
    MOD5  = 128,    -- 1 << 7
}

-- Tabla de keysyms conocidos, para binds por nombre y para logs
-- legibles. No hace falta exhaustividad: si no esta, se llama a
-- xkb_keysym_get_name en runtime.
M.SYM = {
    RETURN     = 0xff0d,
    ESCAPE     = 0xff1b,
    BACKSPACE  = 0xff08,
    TAB        = 0xff09,
    SPACE      = 0x0020,
    DELETE     = 0xffff,
    HOME       = 0xff50,
    END        = 0xff57,
    PAGE_UP    = 0xff55,
    PAGE_DOWN  = 0xff56,
    LEFT       = 0xff51,
    UP         = 0xff52,
    RIGHT      = 0xff53,
    DOWN       = 0xff54,
    F1         = 0xffbe,
    F2         = 0xffbf,
    F3         = 0xffc0,
    F4         = 0xffc1,
    F5         = 0xffc2,
    F6         = 0xffc3,
    F7         = 0xffc4,
    F8         = 0xffc5,
    F9         = 0xffc6,
    F10        = 0xffc7,
    F11        = 0xffc8,
    F12        = 0xffc9,
}

-- Estado encapsulado en una tabla Lua. El userdata real vive en
-- self.ctx / self.keymap / self.state.
local State = {}
State.__index = State

-- State.new(names)
--   names puede ser nil (usa env vars o defaults), o una tabla con
--   campos rules, model, layout, variant, options.
function M.new_state(names)
    local self = setmetatable({}, State)

    self.ctx = lib.xkb_context_new(0)
    if self.ctx == nil then
        error("xkb_context_new fallo")
    end

    local names_ptr = nil
    local names_buf = nil

    if names then
        names_buf = ffi.new("xkb_rule_names")
        if names.rules   then names_buf.rules   = names.rules   end
        if names.model   then names_buf.model   = names.model   end
        if names.layout  then names_buf.layout  = names.layout  end
        if names.variant then names_buf.variant = names.variant end
        if names.options then names_buf.options = names.options end
        names_ptr = names_buf
    else
        -- Orden de resolución:
        --   1. Variables XKB_DEFAULT_* (override manual del usuario)
        --   2. setxkbmap -query (layout actual del servidor X11)
        --   3. nil -> xkbcommon usa su default (us)
        --
        -- El paso 2 es importante: X11 tiene su propio layout
        -- configurado por xorg.conf o setxkbmap, y xkbcommon no
        -- lo consulta por su cuenta. Sin esto, un sistema con
        -- layout latam, es o fr termina interpretando las teclas
        -- como si fueran us.
        local function env(name) return os.getenv(name) end
        local r, m, l, v, o =
            env("XKB_DEFAULT_RULES"),
            env("XKB_DEFAULT_MODEL"),
            env("XKB_DEFAULT_LAYOUT"),
            env("XKB_DEFAULT_VARIANT"),
            env("XKB_DEFAULT_OPTIONS")

        -- Si no hay env vars, consultar el servidor X.
        if not (r or m or l or v or o) then
            local h = io.popen("setxkbmap -query 2>/dev/null")
            if h then
                for line in h:lines() do
                    local k, val = line:match("^([%w]+):%s*(.+)$")
                    if k == "rules"   then r = val
                    elseif k == "model"   then m = val
                    elseif k == "layout"  then l = val
                    elseif k == "variant" then v = val
                    elseif k == "options" then o = val
                    end
                end
                h:close()
            end
        end

        if r or m or l or v or o then
            names_buf = ffi.new("xkb_rule_names")
            if r then names_buf.rules   = r end
            if m then names_buf.model   = m end
            if l then names_buf.layout  = l end
            if v then names_buf.variant = v end
            if o then names_buf.options = o end
            names_ptr = names_buf
        end
    end

    self.keymap = lib.xkb_keymap_new_from_names(self.ctx, names_ptr, 0)
    if self.keymap == nil then
        lib.xkb_context_unref(self.ctx)
        error("xkb_keymap_new_from_names fallo (revisa XKB_DEFAULT_LAYOUT?)")
    end

    self.state = lib.xkb_state_new(self.keymap)
    if self.state == nil then
        lib.xkb_keymap_unref(self.keymap)
        lib.xkb_context_unref(self.ctx)
        error("xkb_state_new fallo")
    end

    -- Buffer reutilizable para xkb_state_key_get_utf8 y
    -- xkb_keysym_get_name. 32 bytes sobra.
    self.buf = ffi.new("char[32]")
    self.buf_size = 32

    log.info("xkb", "estado creado (layout=%s, variant=%s)",
        (names and names.layout) or os.getenv("XKB_DEFAULT_LAYOUT") or "?",
        (names and names.variant) or os.getenv("XKB_DEFAULT_VARIANT") or "")
    return self
end

function State:update_key(keycode, direction)
    lib.xkb_state_update_key(self.state, keycode, direction)
end

-- Devuelve el caracter UTF-8 (string) que produce la tecla, o ""
-- si es una tecla que no produce texto (Shift, F1, etc.).
function State:key_utf8(keycode)
    local n = lib.xkb_state_key_get_utf8(self.state, keycode,
                                          self.buf, self.buf_size)
    if n <= 0 then return "" end
    return ffi.string(self.buf, n)
end

-- Devuelve el keysym numerico (0 si no mapeado).
function State:key_sym(keycode)
    return lib.xkb_state_key_get_one_sym(self.state, keycode)
end

-- Devuelve el nombre del keysym ("Return", "Escape", "F1", "a"...).
function State:key_name(keycode)
    local sym = self:key_sym(keycode)
    if sym == 0 then return "" end
    local n = lib.xkb_keysym_get_name(sym, self.buf, self.buf_size)
    if n <= 0 then return "" end
    return ffi.string(self.buf, n)
end

-- Decodifica el campo `state` de un evento X11 a una tabla de
-- modificadores. Los Mod1/Mod4 se mapean a alt/super por convencion.
function State:decode_mods(x11_state)
    local m = M.X11_MOD
    return {
        shift = (bit.band(x11_state, m.SHIFT) ~= 0),
        lock  = (bit.band(x11_state, m.LOCK)  ~= 0),
        ctrl  = (bit.band(x11_state, m.CTRL)  ~= 0),
        alt   = (bit.band(x11_state, m.MOD1)  ~= 0),
        num   = (bit.band(x11_state, m.MOD2)  ~= 0),
        mod3  = (bit.band(x11_state, m.MOD3)  ~= 0),
        super = (bit.band(x11_state, m.MOD4)  ~= 0),
        mod5  = (bit.band(x11_state, m.MOD5)  ~= 0),
    }
end

-- Crea un "evento de tecla" listo para pasar al usuario en on_key.
-- keycode es el campo `detail` del evento KeyPress/KeyRelease.
-- x11_state es el campo `state` del evento. `pressed` es true para
-- KeyPress y false para KeyRelease.
function State:make_event(keycode, x11_state, pressed)
    -- Actualizar el estado interno con esta tecla antes de leer el
    -- caracter, para que Shift+a produzca "A", etc.
    self:update_key(keycode, pressed and M.KEY_DOWN or M.KEY_UP)

    local sym  = self:key_sym(keycode)
    local name = self:key_name(keycode)
    local text = self:key_utf8(keycode)
    local mods = self:decode_mods(x11_state)

    return {
        keycode = keycode,
        sym     = sym,
        name    = name,
        text    = text,
        mods    = mods,
        raw_mods = x11_state,
        pressed = pressed,
    }
end

function State:destroy()
    if self.state  then lib.xkb_state_unref(self.state);   self.state  = nil end
    if self.keymap then lib.xkb_keymap_unref(self.keymap); self.keymap = nil end
    if self.ctx    then lib.xkb_context_unref(self.ctx);   self.ctx    = nil end
end

-- Azucar: convert a keysym name to numeric. Util para configurar
-- atajos como { sym = xkb.from_name("Return") }.
function M.from_name(name)
    return lib.xkb_keysym_from_name(name, 0)
end

return M
