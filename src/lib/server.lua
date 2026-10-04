local ffi = require("ffi")
local bit = require("bit")
local xcb   = require("lib.xcb")
local log   = require("lib.log")
local poll  = require("lib.poll")
local timer = require("lib.timer")

local Server = {}
Server.__index = Server

local function atoms_for(conn)
    return {
        WM_PROTOCOLS                 = xcb.intern_atom(conn, "WM_PROTOCOLS"),
        WM_DELETE_WINDOW             = xcb.intern_atom(conn, "WM_DELETE_WINDOW"),
        WM_NORMAL_HINTS              = xcb.intern_atom(conn, "WM_NORMAL_HINTS"),
        WM_CLASS                     = xcb.intern_atom(conn, "WM_CLASS"),
        WM_NAME                      = xcb.intern_atom(conn, "WM_NAME"),
        _NET_WM_NAME                 = xcb.intern_atom(conn, "_NET_WM_NAME"),
        _NET_WM_WINDOW_TYPE          = xcb.intern_atom(conn, "_NET_WM_WINDOW_TYPE"),
        _NET_WM_WINDOW_TYPE_NORMAL   = xcb.intern_atom(conn, "_NET_WM_WINDOW_TYPE_NORMAL"),
        _NET_WM_WINDOW_TYPE_DOCK     = xcb.intern_atom(conn, "_NET_WM_WINDOW_TYPE_DOCK"),
        _NET_WM_WINDOW_TYPE_DIALOG   = xcb.intern_atom(conn, "_NET_WM_WINDOW_TYPE_DIALOG"),
        _NET_WM_WINDOW_TYPE_MENU     = xcb.intern_atom(conn, "_NET_WM_WINDOW_TYPE_MENU"),
        _NET_WM_WINDOW_TYPE_DESKTOP  = xcb.intern_atom(conn, "_NET_WM_WINDOW_TYPE_DESKTOP"),
        _NET_WM_STRUT                = xcb.intern_atom(conn, "_NET_WM_STRUT"),
        _NET_WM_STRUT_PARTIAL        = xcb.intern_atom(conn, "_NET_WM_STRUT_PARTIAL"),
        UTF8_STRING                  = xcb.intern_atom(conn, "UTF8_STRING"),
        STRING                       = xcb.intern_atom(conn, "STRING"),
    }
end

local function read_u32(ev, offset_bytes)
    return ffi.cast("uint32_t*", ffi.cast("uint8_t*", ev) + offset_bytes)[0]
end

local function extract_window_id(etype, ev)
    local id
    if etype == xcb.EVENT.Expose
       or etype == xcb.EVENT.ConfigureNotify
       or etype == xcb.EVENT.DestroyNotify
       or etype == xcb.EVENT.UnmapNotify
       or etype == xcb.EVENT.MapNotify
       or etype == xcb.EVENT.ReparentNotify
       or etype == xcb.EVENT.PropertyNotify
       or etype == xcb.EVENT.ClientMessage
       or etype == xcb.EVENT.VisibilityNotify then
        id = read_u32(ev, 4)
    elseif etype == xcb.EVENT.KeyPress
        or etype == xcb.EVENT.KeyRelease
        or etype == xcb.EVENT.ButtonPress
        or etype == xcb.EVENT.ButtonRelease
        or etype == xcb.EVENT.MotionNotify
        or etype == xcb.EVENT.EnterNotify
        or etype == xcb.EVENT.LeaveNotify
        or etype == xcb.EVENT.FocusIn
        or etype == xcb.EVENT.FocusOut then
        id = read_u32(ev, 12)
    end
    if id == nil then return nil end
    return tonumber(id)
end

function Server.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Server)

    self.conn, self.screen_num = xcb.connect(opts.displayname)
    self.screen = xcb.get_screen(self.conn, self.screen_num)
    self.visualtype = xcb.get_visualtype(self.conn, self.screen_num,
                                         self.screen.root_visual)
    self.atoms = atoms_for(self.conn)
    self.fd = xcb.get_file_descriptor(self.conn)

    self.windows = {}
    self.running = true
    self.exit_on_empty = opts.exit_on_empty
    if self.exit_on_empty == nil then self.exit_on_empty = true end

    self.timers = {}

    -- Trigger file opcional (para el toggle del panel). Se mira
    -- cada 200ms cuando esta activo. Mientras no haya trigger ni
    -- timers ni ventanas, el loop bloquea indefinidamente.
    self.trigger_path = nil
    self.trigger_callback = nil

    log.info("server", "conexion ok. screen=%d, root=0x%x, fd=%d",
        self.screen_num, tonumber(self.screen.root), self.fd)
    return self
end

function Server:add_window(win)    self.windows[tonumber(win.id)] = win end
function Server:remove_window(win) self.windows[tonumber(win.id)] = nil end

function Server:count()
    local n = 0
    for _ in pairs(self.windows) do n = n + 1 end
    return n
end

function Server:stop()  self.running = false end
function Server:flush() xcb.flush(self.conn) end

function Server:add_timer(interval_ms, callback)
    local now = timer.now_ms()
    local handle = {
        interval = interval_ms,
        next_at  = now + interval_ms,
        callback = callback,
        cancelled = false,
    }
    self.timers[handle] = true
    return {
        cancel = function()
            handle.cancelled = true
            self.timers[handle] = nil
        end
    }
end

function Server:_run_timers()
    if next(self.timers) == nil then return end
    local now = timer.now_ms()
    -- Recopilar primero, ejecutar despues: los callbacks pueden
    -- añadir o cancelar timers, y no queremos mutar durante el pairs.
    local due = {}
    for handle in pairs(self.timers) do
        if now >= handle.next_at then
            due[#due + 1] = handle
        end
    end
    for _, handle in ipairs(due) do
        if self.timers[handle] then
            handle.next_at = now + handle.interval
            local ok, err = pcall(handle.callback)
            if not ok then
                log.error("timer", "callback fallo: %s", tostring(err))
            end
        end
    end
end

-- Observa un archivo. Cuando aparece, lo lee, lo borra, y llama
-- al callback con su contenido (o "toggle" si esta vacio).
-- Cambios en tiempo real: cada 200ms.
function Server:watch_trigger(path, callback)
    self.trigger_path = path
    self.trigger_callback = callback
end

function Server:_check_trigger()
    if not self.trigger_path then return end
    local ffi = require("ffi")
    if ffi.C.access(self.trigger_path, 0) ~= 0 then return end
    local f = io.open(self.trigger_path, "r")
    local cmd = "toggle"
    if f then
        local line = f:read("*l")
        if line and line ~= "" then cmd = line end
        f:close()
    end
    os.remove(self.trigger_path)
    if self.trigger_callback then
        local ok, err = pcall(self.trigger_callback, cmd)
        if not ok then
            log.error("trigger", "callback fallo: %s", tostring(err))
        end
    end
end

function Server:cancel_all_timers()
    self.timers = {}
end

function Server:_next_timer_delay()
    local earliest = nil
    local now = timer.now_ms()
    for handle in pairs(self.timers) do
        if earliest == nil or handle.next_at < earliest then
            earliest = handle.next_at
        end
    end
    if earliest == nil then
        -- Sin timers: si hay trigger, despertar cada 200ms para
        -- comprobarlo. Si no, dormir indefinidamente.
        if self.trigger_path then return 200 end
        return -1
    end
    local delay = math.floor(earliest - now)
    if delay < 0 then delay = 0 end
    -- Si hay trigger, no dormir mas de 200ms seguidos.
    if self.trigger_path and delay > 200 then delay = 200 end
    return delay
end

-- Procesa todos los eventos pendientes en el buffer interno de
-- XCB. Devuelve true si proceso al menos uno.
--
-- Los eventos se enrutan:
--   - Si el window id corresponde a una ventana registrada, se
--     despacha a Window:_dispatch.
--   - Si es del root (self.screen.root), se pasa a self.on_root_event
--     (hook opcional que usa EWMH para PropertyNotify).
--   - Cualquier otro evento se descarta.
function Server:_process_events()
    local processed = false
    local root_id = tonumber(self.screen.root)
    while true do
        local ev = xcb.poll_event(self.conn)
        if ev == nil then break end
        processed = true
        local etype = bit.band(ev.response_type, 0x7f)
        local wid = extract_window_id(etype, ev)
        if wid then
            local win = self.windows[wid]
            if win then
                win:_dispatch(etype, ev)
            elseif wid == root_id and self.on_root_event then
                self.on_root_event(etype, ev)
            end
        end
        ffi.C.free(ev)
    end
    return processed
end

-- Registra un fd externo con su callback. El Server lo pollea
-- junto con el fd de XCB. Cuando el fd es legible, el callback se
-- llama una sola vez (hasta que el fd se vuelva a marcar).
function Server:add_fd(fd, cb)
    if not self.extra_fds then self.extra_fds = {} end
    self.extra_fds[#self.extra_fds + 1] = { fd = fd, cb = cb }
    log.info("server", "fd externo registrado (fd=%d)", fd)
    return fd
end

-- Llama a los callbacks de los fds externos que esten marcados
-- como listos por el ultimo poll.
function Server:_process_extra_fds()
    if not self.extra_fds then return end
    for _, e in ipairs(self.extra_fds) do
        if e.ready then
            e.ready = false
            local ok, err = pcall(e.cb)
            if not ok then
                log.warn("server", "fd callback fallo: %s", tostring(err))
            end
        end
    end
end

function Server:_loop()
    log.info("server", "entrando en loop")
    while self.running do
        local n = self:count()
        if self.exit_on_empty and n == 0 then
            -- Sin ventanas: cancelar timers pendientes y salir.
            -- Una app con UI no tiene sentido sin UI.
            if next(self.timers) ~= nil then
                log.info("server", "sin ventanas, cancelando %d timers",
                    (function() local c=0 for _ in pairs(self.timers) do c=c+1 end return c end)())
                self:cancel_all_timers()
            end
            break
        end

        -- Primero vaciar el buffer interno de XCB. Es CRITICO: el
        -- xcb.sync de map_window (y otras operaciones sincronas)
        -- puede haber leido eventos del socket y guardado en el
        -- buffer interno. Si solo consultamos poll(fd), esos
        -- eventos quedan invisibles hasta que llegue algo nuevo.
        local processed = self:_process_events()

        -- Si no habia nada pendiente, bloquearse hasta el proximo
        -- evento, timer, o fd externo legible.
        if not processed then
            local timeout = self:_next_timer_delay()
            local fd_list = { self.fd }
            for _, e in ipairs(self.extra_fds or {}) do
                fd_list[#fd_list + 1] = e.fd
            end
            local readable, broken, ready = poll.wait_multi(fd_list, timeout)
            -- Si el fd esta en POLLHUP/POLLERR/POLLNVAL, el otro
            -- extremo del socket ya no existe (alguien cerro la
            -- conexion X del cliente con XKillClient). Sin esto, poll
            -- devuelve inmediatamente en cada llamada y el loop gira a
            -- decenas de miles de iteraciones por segundo hasta que
            -- maten el proceso. Salimos limpio.
            if broken then
                log.error("server", "fd de XCB roto (POLLHUP/POLLERR), cerrando")
                self.running = false
                break
            end
            if readable then
                self:_process_events()
            end
            -- Marcar los fds externos que esten listos. El callback
            -- de cada uno los procesa.
            if ready then
                for i = 2, #fd_list do
                    if ready[i] then
                        self.extra_fds[i - 1].ready = true
                    end
                end
            end
        end

        self:_run_timers()
        self:_check_trigger()

        -- Procesar fds externos (signalfd, sockets, etc).
        self:_process_extra_fds()

        for _, win in pairs(self.windows) do
            win:draw()
        end
    end
end

function Server:run()
    -- pcall para capturar SIGINT (LuaJIT lanza "interrupted!").
    local ok, err = pcall(self._loop, self)
    if not ok then
        local msg = tostring(err):lower()
        if msg:match("interrupt") then
            log.info("server", "interrumpido por SIGINT, saliendo limpio")
        else
            -- Error real: limpiar y re-lanzar.
            for _, win in pairs(self.windows) do win:_shutdown() end
            xcb.disconnect(self.conn)
            error(err)
        end
    end

    for _, win in pairs(self.windows) do
        win:_shutdown()
    end
    xcb.disconnect(self.conn)
    log.info("server", "desconectado")
end

return Server
