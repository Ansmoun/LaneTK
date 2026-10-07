local ffi = require("bindings.cdef.poll")
local bit = require("bit")

local M = {}

M.POLLIN   = 0x0001
M.POLLOUT  = 0x0004
M.POLLERR  = 0x0008
M.POLLHUP  = 0x0010
M.POLLNVAL = 0x0020

-- Espera a que el fd sea legible, o al timeout (en ms).
-- Devuelve dos valores:
--   readable (bool): hay datos para leer
--   broken   (bool): el fd esta en error o hung-up. El consumidor debe
--                    dejar de usar el fd. Caso tipico: alguien cierra
--                    la conexion X del cliente con XKillClient (por
--                    ejemplo `bspc node -k` o `xdotool windowkill`),
--                    poll devuelve POLLIN|POLLHUP en cada llamada y el
--                    socket nunca se drena. Sin el flag broken, el
--                    loop del server gira a decenas de miles de
--                    iteraciones por segundo.
function M.wait_readable(fd, timeout_ms)
    local pfd = ffi.new("struct pollfd[1]")
    pfd[0].fd = fd
    pfd[0].events = M.POLLIN
    pfd[0].revents = 0
    local n = ffi.C.poll(pfd, 1, timeout_ms)
    if n < 0 then
        return false, false
    end
    local revents = pfd[0].revents
    local broken = bit.band(revents, M.POLLHUP)  ~= 0
                or bit.band(revents, M.POLLERR)  ~= 0
                or bit.band(revents, M.POLLNVAL) ~= 0
    return n > 0, broken
end

-- Version multi-fd. Recibe una lista de fds (enteros) y un timeout.
-- Devuelve tres valores:
--   any_readable (bool)  -- algun fd tiene datos o error
--   xcb_broken   (bool)  -- SOLO si fd_list[1] (XCB) esta en error
--   ready        (tabla) -- ready[i] = true si fd_list[i] esta listo
--
-- 'xcb_broken' es verdadero unicamente cuando el PRIMER fd de la
-- lista (por convencion, la conexion X) esta en POLLHUP/POLLERR/
-- POLLNVAL. Un fd externo (PTY, signalfd) que se cierre NO debe
-- tumbar todo el server; su callback se encarga.
--
-- Bug previo: cualquier fd roto devolvia any_broken = true, y el
-- server lo interpretaba como "XCB roto" -> cerraba la app entera.
-- Con un PTY en la lista, cuando el shell moria, el server mataba
-- la ventana aunque el XCB estuviera perfectamente vivo.
function M.wait_multi(fd_list, timeout_ms)
    local n = #fd_list
    if n == 0 then return false, false, {} end

    local pfds = ffi.new("struct pollfd[?]", n)
    for i = 1, n do
        pfds[i - 1].fd      = fd_list[i]
        pfds[i - 1].events  = M.POLLIN
        pfds[i - 1].revents = 0
    end

    local ret = ffi.C.poll(pfds, n, timeout_ms)
    if ret < 0 then return false, false, {} end

    local any_readable = false
    local xcb_broken   = false
    local ready = {}

    for i = 1, n do
        local rev = pfds[i - 1].revents
        if rev ~= 0 then
            ready[i] = true
            any_readable = true
            if bit.band(rev, M.POLLHUP)  ~= 0 or
               bit.band(rev, M.POLLERR)  ~= 0 or
               bit.band(rev, M.POLLNVAL) ~= 0 then
                if i == 1 then
                    xcb_broken = true
                end
            end
        end
    end

    return any_readable, xcb_broken, ready
end

return M
