-- uri.lua: conversion entre paths de archivo y URIs file://
-- normalizadas, segun lo que espera el estandar freedesktop de
-- thumbnails (https://specifications.freedesktop.org/thumbnail-spec).
--
-- El estandar dice que el hash del nombre del archivo cacheado es
-- MD5 del URI canonico, no del path. Por eso la normalizacion
-- importa: si dos apps generan "file:///home/u/foto.png" y
-- "file:///home/u/Foto.PNG" tienen que producir el mismo hash.
--
-- Reglas de encoding que aplicamos:
--   * El path debe ser absoluto. Relativos son error.
--   * Percent-encode de TODO byte fuera de [A-Za-z0-9-._~/].
--   * Se encodea byte a byte (no char a char) para no romper UTF-8.
--   * No se decodifica doble: si el path ya tiene "%20" literal, se
--     convierte en "%2520". Es correcto: en disco "%20" es 3 bytes.
--
-- API publica:
--   M.file_uri(path)  -> "file:///..." | nil, err
--   M.to_path(uri)    -> "/..." | nil, err
--   M.md5(s)          -> hex 32 chars

local ffi  = require("bindings.cdef.glib")
local glib = ffi.load("libglib-2.0.so.0")

local M = {}

local G_CHECKSUM_MD5 = 0

-- Byte permitido literal en un file URI. "/" se permite porque es
-- separador de path. Todo lo demas va percent-encoded.
local function is_unreserved(b)
    return (b >= 0x41 and b <= 0x5A)      -- A-Z
        or (b >= 0x61 and b <= 0x7A)      -- a-z
        or (b >= 0x30 and b <= 0x39)      -- 0-9
        or b == 0x2D or b == 0x2E         -- - .
        or b == 0x5F or b == 0x7E         -- _ ~
        or b == 0x2F                      -- /
end

local function percent_encode(path)
    local out = {}
    for i = 1, #path do
        local b = path:byte(i)
        if is_unreserved(b) then
            out[#out + 1] = string.char(b)
        else
            out[#out + 1] = string.format("%%%02X", b)
        end
    end
    return table.concat(out)
end

-- Convierte un path absoluto a un file URI canonico.
function M.file_uri(path)
    if type(path) ~= "string" or path == "" then
        return nil, "path vacio"
    end
    if path:sub(1, 1) ~= "/" then
        return nil, "path no absoluto: " .. path
    end
    return "file://" .. percent_encode(path)
end

-- Inverso. Acepta "file:///..." y "file://localhost/...". Rechaza
-- hosts no vacios (no soportamos NFS en esta fase).
function M.to_path(uri)
    if type(uri) ~= "string" then return nil, "uri invalida" end
    local rest = uri:match("^file://(.*)$")
    if not rest then return nil, "no es file://" end
    if rest:sub(1, 10) == "localhost/" then
        rest = rest:sub(10)
    elseif rest:sub(1, 1) ~= "/" then
        return nil, "host remoto no soportado"
    end
    local decoded = rest:gsub("%%(%x%x)", function(h)
        return string.char(tonumber(h, 16))
    end)
    return decoded
end

-- MD5 hexadecimal en minusculas via GLib. Devuelve 32 chars.
function M.md5(s)
    local out = glib.g_compute_checksum_for_string(
        G_CHECKSUM_MD5, s, #s)
    if out == nil then return nil, "g_compute_checksum_for_string nil" end
    local hex = ffi.string(out)
    glib.g_free(out)
    return hex
end

return M
