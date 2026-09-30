-- greetd.lua: cliente del protocolo greetd.
--
-- Protocolo: JSON line-delimited sobre Unix socket. Cada mensaje
-- termina en \n. Los campos son los que espera greetd 0.10.x.
--
-- Uso tipico (flujo de autenticacion):
--   local cli = require("lib.greetd").connect()
--   cli:create_session("ansmoun", function(kind, data)
--       if kind == "auth_message" then
--           if data.auth_message_type == "secret" then
--               cli:post_auth_response(get_password(), on_msg)
--           else
--               cli:post_auth_response(nil, on_msg)
--           end
--       elseif kind == "success" then
--           cli:start_session({ "bspwm" }, function(k2, d2)
--               -- k2 = "success" | "error"
--           end)
--       elseif kind == "error" then
--           -- data.error_type, data.description
--       end
--   end)
--
-- El socket es bloqueante. Cada call hace un round-trip sincronico
-- con greetd. Es correcto para el flujo de login: son pocos mensajes,
-- espaciados por input del usuario.
--
-- Si GREETD_SOCK no esta seteado, connect() falla. greetd lo exporta
-- antes de lanzar el greeter.

local ffi = require("bindings.cdef.net")
local json = require("lib.helpers.json")
local log = require("lib.log")

local M = {}

-- Constantes de socket. AF_UNIX = 1, SOCK_STREAM = 1.
local AF_UNIX     = 1
local SOCK_STREAM = 1

local Client = {}
Client.__index = Client

-- ══════════════════════════════════════════════════════════════════
-- I/O
-- ══════════════════════════════════════════════════════════════════

-- Lee una linea completa del socket (hasta \n inclusive).
-- Devuelve (linea_sin_\n) o (nil, err).
function Client:_read_line()
    local buf = {}
    local byte = ffi.new("char[1]")
    while true do
        local n = ffi.C.recv(self.fd, byte, 1, 0)
        if n == 0 then
            return nil, "EOF del socket"
        elseif n < 0 then
            return nil, "recv fallo"
        end
        local b = byte[0]
        if b == 10 then  -- '\n'
            return table.concat(buf)
        end
        buf[#buf + 1] = ffi.string(byte, 1)
    end
end

function Client:_send(tbl)
    local s, err = json.encode(tbl)
    if not s then
        log.error("greetd", "encode fallo: %s", tostring(err))
        return false, err
    end
    -- greetd espera el mensaje con \n de terminador.
    s = s .. "\n"
    local n = ffi.C.send(self.fd, s, #s, 0)
    if n < 0 then
        return false, "send fallo"
    end
    return true
end

-- Lee una respuesta y la despacha al callback con (kind, data).
--   kind = "auth_message" | "success" | "error" | "io_error" | "parse_error"
--   data = la tabla decodificada del JSON, o el mensaje de error
function Client:_recv_dispatch(cb)
    local line, err = self:_read_line()
    if not line then
        if cb then cb("io_error", err) end
        return
    end
    local msg, jerr = json.decode(line)
    if not msg then
        if cb then cb("parse_error", jerr) end
        return
    end
    local kind = msg.type or "unknown"
    if cb then cb(kind, msg) end
end

-- ══════════════════════════════════════════════════════════════════
-- API publica
-- ══════════════════════════════════════════════════════════════════

-- Conecta al socket de greetd. Sin argumento, usa $GREETD_SOCK.
-- Devuelve (client) o (nil, err).
function M.connect(sock_path)
    sock_path = sock_path or os.getenv("GREETD_SOCK")
    if not sock_path or sock_path == "" then
        return nil, "GREETD_SOCK no seteado"
    end

    local fd = ffi.C.socket(AF_UNIX, SOCK_STREAM, 0)
    if fd < 0 then
        return nil, "socket() fallo"
    end

    -- struct sockaddr_un: la familia en el primer campo, despues
    -- el path (con \0 final). sockaddr_un.sun_path tiene 108 bytes.
    local addr = ffi.new("struct sockaddr_un")
    addr.sun_family = AF_UNIX
    if #sock_path > 107 then
        ffi.C.close(fd)
        return nil, "path del socket demasiado largo"
    end
    ffi.copy(addr.sun_path, sock_path, #sock_path)
    -- El byte 0 ya esta por el ffi.new (memset a 0).

    local ret = ffi.C.connect(fd,
        ffi.cast("struct sockaddr*", addr),
        ffi.sizeof("struct sockaddr_un"))
    if ret < 0 then
        ffi.C.close(fd)
        return nil, "connect() fallo a " .. sock_path
    end

    local self = setmetatable({}, Client)
    self.fd = fd
    self.sock_path = sock_path
    log.info("greetd", "conectado a %s (fd=%d)", sock_path, fd)
    return self
end

-- Inicia el flujo de autenticacion. greetd responde con una serie
-- de auth_message hasta success o error.
function Client:create_session(username, cb)
    self:_send({ type = "create_session", username = username })
    self:_recv_dispatch(cb)
end

-- Responde al ultimo auth_message. `response` puede ser string o
-- nil (para mensajes de tipo info/error, donde no hay input).
function Client:post_auth_response(response, cb)
    self:_send({
        type = "post_auth_message_response",
        response = response,
    })
    self:_recv_dispatch(cb)
end

-- Arranca la sesion autenticada. `cmd` es un array de strings.
-- greetd lo ejecuta via /bin/sh -c.
--
-- IMPORTANTE: greetd NO responde a start_session. Solo procesa el
-- mensaje, mata al proceso del greeter, y lanza la sesion del
-- usuario. Esperar una respuesta aca es deadlock: el cliente queda
-- bloqueado en recv, el wrapper espera a lefty, greetd espera al
-- wrapper, nadie avanza.
--
-- Despues de llamar a este metodo, el consumidor debe cerrar el
-- socket y terminar (por ejemplo cerrando la ventana principal).
function Client:start_session(cmd)
    self:_send({ type = "start_session", cmd = cmd })
    -- No leer respuesta. Cerrar la conexion explicitamente para
    -- que greetd sepa que ya no estamos esperando nada.
    if self.fd and self.fd >= 0 then
        ffi.C.close(self.fd)
        self.fd = -1
    end
end

-- Cancela el flujo de autenticacion actual. No espera respuesta.
function Client:cancel_session()
    self:_send({ type = "cancel_session" })
end

function Client:close()
    if self.fd and self.fd >= 0 then
        ffi.C.close(self.fd)
        log.info("greetd", "socket cerrado (fd=%d)", self.fd)
        self.fd = -1
    end
end

return M
