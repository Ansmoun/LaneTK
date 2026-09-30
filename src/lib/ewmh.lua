-- ewmh.lua: lectura de propiedades EWMH del root y de las ventanas.
--
-- Solo lectura por ahora. No hay funciones que modifiquen el estado
-- del WM (_NET_CURRENT_DESKTOP, _NET_ACTIVE_WINDOW, etc.). Esas se
-- agregaran cuando haga falta.
--
-- La instancia cachea los atomos EWMH por conexion. Cada instancia
-- esta atada a un Server. Si se abre una segunda conexion X, hay que
-- crear una instancia nueva.
--
-- Uso:
--   local ewmh = require("lib.ewmh").new(srv)
--   print(ewmh:wm_name())
--   for _, wid in ipairs(ewmh:client_list()) do ... end
--   ewmh:subscribe(function(prop_atom, wid)
--       -- se llama en cada PropertyNotify del root
--   end)

local xcb = require("lib.xcb")
local bit = require("bit")
local ffi = require("ffi")
local log = require("lib.log")

local M = {}

local EWMH = {}
EWMH.__index = EWMH

-- Lista de atomos EWMH que el modulo internara al construirse.
local ATOMS = {
    "_NET_SUPPORTED",
    "_NET_SUPPORTING_WM_CHECK",
    "_NET_WM_NAME",
    "_NET_CLIENT_LIST",
    "_NET_CLIENT_LIST_STACKING",
    "_NET_ACTIVE_WINDOW",
    "_NET_NUMBER_OF_DESKTOPS",
    "_NET_CURRENT_DESKTOP",
    "_NET_DESKTOP_NAMES",
    "_NET_DESKTOP_GEOMETRY",
    "_NET_DESKTOP_VIEWPORT",
    "_NET_WORKAREA",
    "_NET_WM_DESKTOP",
    "_NET_WM_STATE",
    "_NET_WM_STATE_MAXIMIZED_VERT",
    "_NET_WM_STATE_MAXIMIZED_HORZ",
    "_NET_WM_STATE_HIDDEN",
    "_NET_WM_STATE_FULLSCREEN",
    "_NET_WM_STATE_STICKY",
    "_NET_WM_STATE_ABOVE",
    "_NET_WM_STATE_BELOW",
    "_NET_WM_STATE_DEMANDS_ATTENTION",
    "_NET_WM_PID",
    "_NET_WM_WINDOW_TYPE",
    "_NET_WM_WINDOW_TYPE_NORMAL",
    "_NET_WM_WINDOW_TYPE_DIALOG",
    "_NET_WM_WINDOW_TYPE_DOCK",
    "_NET_WM_WINDOW_TYPE_MENU",
    "_NET_WM_WINDOW_TYPE_UTILITY",
    "_NET_WM_WINDOW_TYPE_SPLASH",
    "_NET_CLOSE_WINDOW",
    "UTF8_STRING",
    "STRING",
}

function M.new(srv)
    local self = setmetatable({}, EWMH)
    self.srv = srv
    self.conn = srv.conn
    self.root = srv.screen.root

    self.atoms = {}
    for _, name in ipairs(ATOMS) do
        self.atoms[name] = xcb.intern_atom(self.conn, name)
    end

    self._sub_id = nil
    return self
end

-- ── Lectura cruda ─────────────────────────────────────────────────

-- Devuelve el nombre del WM activo (string) o nil si no hay ninguno.
-- Un WM que respeta EWMH publica _NET_SUPPORTING_WM_CHECK en el root
-- apuntando a una ventana child; esa ventana tiene _NET_WM_NAME con
-- el nombre del WM.
function EWMH:wm_name()
    local check = xcb.get_property(self.conn, self.root,
        self.atoms._NET_SUPPORTING_WM_CHECK, 0, 1)
    if not check or not check.data or #check.data < 1 then
        return nil
    end
    local wm_win = check.data[1]
    if wm_win == 0 then return nil end
    local name = xcb.get_property(self.conn, wm_win,
        self.atoms._NET_WM_NAME, self.atoms.UTF8_STRING, 32)
    if not name or not name.data then return nil end
    return tostring(name.data)
end

-- Tabla de atomos EWMH soportados por el WM. Vacía si no hay EWMH.
function EWMH:supported()
    local r = xcb.get_property(self.conn, self.root,
        self.atoms._NET_SUPPORTED, 0, 1024)
    if not r or not r.data then return {} end
    return r.data
end

function EWMH:client_list()
    local r = xcb.get_property(self.conn, self.root,
        self.atoms._NET_CLIENT_LIST, 0, 1024)
    if not r or not r.data then return {} end
    return r.data
end

function EWMH:client_list_stacking()
    local r = xcb.get_property(self.conn, self.root,
        self.atoms._NET_CLIENT_LIST_STACKING, 0, 1024)
    if not r or not r.data then return {} end
    return r.data
end

function EWMH:active_window()
    local r = xcb.get_property(self.conn, self.root,
        self.atoms._NET_ACTIVE_WINDOW, 0, 1)
    if not r or not r.data or #r.data < 1 then return nil end
    return r.data[1]
end

function EWMH:current_desktop()
    local r = xcb.get_property(self.conn, self.root,
        self.atoms._NET_CURRENT_DESKTOP, 0, 1)
    if not r or not r.data or #r.data < 1 then return nil end
    return r.data[1]
end

function EWMH:desktop_count()
    local r = xcb.get_property(self.conn, self.root,
        self.atoms._NET_NUMBER_OF_DESKTOPS, 0, 1)
    if not r or not r.data or #r.data < 1 then return nil end
    return r.data[1]
end

-- Devuelve un array de strings (los nombres de los escritorios).
function EWMH:desktop_names()
    local r = xcb.get_property(self.conn, self.root,
        self.atoms._NET_DESKTOP_NAMES, self.atoms.UTF8_STRING, 1024)
    if not r or not r.data then return {} end
    local raw = r.data
    -- _NET_DESKTOP_NAMES viene como strings UTF-8 separados por \0.
    local names = {}
    for s in raw:gmatch("([^%z]+)") do
        names[#names + 1] = s
    end
    return names
end

-- ── Nombre de una ventana ─────────────────────────────────────────

-- Nombre de una ventana dado su id. Prueba _NET_WM_NAME (UTF-8)
-- y cae a WM_NAME (STRING) si no existe.
function EWMH:window_name(wid)
    local n = xcb.get_property(self.conn, wid,
        self.atoms._NET_WM_NAME, self.atoms.UTF8_STRING, 256)
    if n and n.data and n.data ~= "" then return tostring(n.data) end
    local w = xcb.get_property(self.conn, wid,
        self.atoms.STRING and self.atoms.STRING or 39, self.atoms.STRING, 256)
    if w and w.data and w.data ~= "" then return tostring(w.data) end
    return nil
end

-- ── Escritura (client messages) ───────────────────────────────────
--
-- Los client messages son la forma estandar de pedirle cosas al WM:
-- cambiar de escritorio, activar una ventana, cerrar una ventana,
-- cambiar el estado de una ventana. Se envian con xcb.send_event al
-- root con una mascara especifica. El WM los recibe y actua si
-- soporta la accion (ver supported()).

-- Cambia el escritorio activo. `n` es el indice 0-based (EWMH usa
-- 0 para el primer escritorio). Devuelve true si se envio.
function EWMH:set_current_desktop(n)
    local ev = {
        window = self.root,
        type   = self.atoms._NET_CURRENT_DESKTOP,
        format = 32,
        data   = { n, 0 },
    }
    xcb.send_client_message_root(self.conn, self.root, ev)
    xcb.flush(self.conn)
    return true
end

-- Pide al WM que active (levante y enfoque) una ventana. `wid` es el
-- window id. `source` puede ser 0 (cualquier fuente) o 1 (pager, etc).
function EWMH:activate_window(wid, source)
    local ev = {
        window = wid,
        type   = self.atoms._NET_ACTIVE_WINDOW,
        format = 32,
        data   = { source or 0, 0, 0 },
    }
    xcb.send_client_message_root(self.conn, self.root, ev)
    xcb.flush(self.conn)
    return true
end

-- Pide al WM que cierre una ventana con la semantica normal
-- (equivalente a click en la X). No la mata: el cliente puede
-- cancelar el cierre.
function EWMH:close_window(wid)
    local ev = {
        window = wid,
        type   = self.atoms._NET_CLOSE_WINDOW,
        format = 32,
        data   = { 0, 0 },
    }
    xcb.send_client_message_root(self.conn, self.root, ev)
    xcb.flush(self.conn)
    return true
end

-- Devuelve el indice de escritorio EWMH de una ventana (0-based),
-- o nil si no tiene la propiedad.
function EWMH:window_desktop(wid)
    local r = xcb.get_property(self.conn, wid,
        self.atoms._NET_WM_DESKTOP, 0, 1)
    if not r or not r.data or #r.data < 1 then return nil end
    -- EWMH define 0xFFFFFFFF como "todos los escritorios" (sticky).
    if r.data[1] == 0xFFFFFFFF then return nil end
    return r.data[1]
end

-- Mueve una ventana a un escritorio. `n` es el indice 0-based.
-- Nota: el WM decide si acepta el pedido; algunos WMs lo ignoran.
function EWMH:move_window_to_desktop(wid, n)
    -- _NET_WM_DESKTOP es una propiedad de la ventana. Se cambia con
    -- change_property, no con client message.
    local arr = ffi.new("uint32_t[1]", n)
    xcb.change_property(self.conn, wid,
        self.atoms._NET_WM_DESKTOP, self.atoms.CARDINAL or 6, 32, 1, arr)
    xcb.flush(self.conn)
    return true
end

-- Cambia el estado de una ventana. `action` es:
--   0 = REMOVE, 1 = ADD, 2 = TOGGLE
-- `state1` y `state2` son atomos de _NET_WM_STATE_*.
function EWMH:wm_state(wid, action, state1, state2)
    local ev = {
        window = wid,
        type   = self.atoms._NET_WM_STATE,
        format = 32,
        data   = { action, state1 or 0, state2 or 0, 1 },
    }
    xcb.send_client_message_root(self.conn, self.root, ev)
    xcb.flush(self.conn)
    return true
end

-- ── Suscripcion a eventos ─────────────────────────────────────────

-- Se suscribe a PropertyNotify del root. Llama `cb(property_atom, wid)`
-- en cada evento. El segundo argumento es siempre el root (los eventos
-- del root son globales).
--
-- Solo admite un suscriptor a la vez. Llamar subscribe dos veces
-- reemplaza el callback anterior.
function EWMH:subscribe(cb)
    self._sub_cb = cb
    if self._sub_id then return end
    local mask = bit.bor(
        xcb.EVENT_MASK.PropertyChange,
        xcb.EVENT_MASK.SubstructureNotify)
    xcb.change_window_attributes(self.conn, self.root, mask)
    xcb.flush(self.conn)
    -- Registrar el handler con el Server para que enrute eventos del
    -- root al callback. El Server ya maneja eventos de ventanas
    -- registradas; para eventos del root hay que exponer un hook.
    if self.srv.on_root_event then
        log.warn("ewmh", "srv.on_root_event ya estaba definido; sobreescribiendo")
    end
    self.srv.on_root_event = function(etype, ev)
        return self:_handle_event(etype, ev)
    end
    self._sub_id = true
end

function EWMH:unsubscribe()
    self._sub_cb = nil
    self._sub_id = nil
    self.srv.on_root_event = nil
end

function EWMH:_handle_event(etype, ev)
    if etype ~= xcb.EVENT.PropertyNotify then return end
    if not self._sub_cb then return end
    local pev = ffi.cast("xcb_property_notify_event_t*", ev)
    self._sub_cb(pev.atom, pev.window)
end

return M
