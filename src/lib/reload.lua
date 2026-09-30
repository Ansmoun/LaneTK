-- reload.lua: hot reload entre procesos via signalfd.
--
-- Uso:
--   local reload = require("lib.reload")
--   reload.install(srv, function()
--       -- se llama cuando llega SIGUSR1, en contexto normal
--   end)
--   ...
--   -- en otro proceso:
--   reload.broadcast()  -- envia SIGUSR1 a todos los apps/*.lua
--
-- Implementacion:
--   1. install() bloquea SIGUSR1 con sigprocmask y crea un signalfd.
--      Al bloquearla, la señal NO interrumpe el proceso: queda
--      pendiente en el kernel hasta que el signalfd la consuma.
--   2. El signalfd se registra en el Server con add_fd(fd, cb).
--   3. Cuando llega una señal, poll la marca legible, el Server
--      llama al callback (en contexto normal, no de señal), y el
--      callback hace el read() para drenar el signalfd.
--
-- Esta es la razon por la que NO usamos signal() con un handler Lua:
-- LuaJIT no permite reentrar su runtime desde un signal handler.
-- El sintoma es "PANIC: unprotected error in call to Lua API
-- (bad callback)".

local ffi = require("ffi")
local log = require("lib.log")

local M = {}

M.SIGUSR1  = 10
M.SIG_BLOCK = 0   -- sigprocmask: bloquear las señales del set

-- Estado del modulo (singleton por proceso).
local _fd = nil
local _cbs = {}

function M.install(srv, cb)
    _cbs[#_cbs + 1] = cb

    if _fd then return _fd end

    -- Armar el sigset con solo SIGUSR1
    local set = ffi.new("sigset_t")
    ffi.C.sigemptyset(set)
    ffi.C.sigaddset(set, M.SIGUSR1)

    -- Bloquear SIGUSR1 en este proceso (y todos sus hijos).
    -- SIG_BLOCK = 0
    if ffi.C.sigprocmask(M.SIG_BLOCK, set, nil) ~= 0 then
        log.error("reload", "sigprocmask fallo")
        return nil
    end

    -- Crear el signalfd. -1 = crear uno nuevo.
    -- SFD_NONBLOCK = 0x800, SFD_CLOEXEC = 0x80000
    _fd = ffi.C.signalfd(-1, set, 0x800 + 0x80000)
    if _fd < 0 then
        log.error("reload", "signalfd fallo")
        _fd = nil
        return nil
    end

    log.info("reload", "signalfd creado (fd=%d)", _fd)

    -- Registrar el fd en el Server. El callback hace el read() y
    -- luego llama a los watchers.
    srv:add_fd(_fd, function()
        -- Drenar el signalfd (puede haber mas de una señal pendiente).
        local buf = ffi.new("signalfd_siginfo[1]")
        while ffi.C.read(_fd, buf, ffi.sizeof("signalfd_siginfo")) > 0 do
            -- nada mas que drenar
        end
        -- Ahora llamar a los watchers en contexto normal.
        for _, cb2 in ipairs(_cbs) do
            local ok, err = pcall(cb2)
            if not ok then
                log.warn("reload", "callback fallo: %s", tostring(err))
            end
        end
    end)

    return _fd
end

-- Envia SIGUSR1 a todos los procesos apps/*.lua vivos excepto este.
function M.broadcast()
    local self_pid = tonumber(ffi.C.getpid())
    local p = io.popen("pgrep -f 'apps/.*\\.lua' 2>/dev/null")
    if not p then return 0 end
    local n = 0
    for line in p:lines() do
        local pid = tonumber(line)
        if pid and pid ~= self_pid then
            ffi.C.kill(pid, M.SIGUSR1)
            n = n + 1
        end
    end
    p:close()
    log.info("reload", "broadcast SIGUSR1 a %d procesos", n)
    return n
end

return M
