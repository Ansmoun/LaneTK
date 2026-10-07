-- png_meta.lua: lee e inyecta chunks tEXt en archivos PNG.
--
-- El estandar freedesktop de thumbnails exige que cada thumbnail
-- PNG contenga los chunks:
--   tEXt  Thumb::URI       el file:// URI original
--   tEXt  Thumb::MTime     el mtime del original en epoch seconds
-- Otros thumbnailers (pcmanfm, tumbler, gnome) comprueban que
-- ambos coincidan antes de reutilizar la cache. Sin esta metadata,
-- nuestro PNG queda visible para el usuario pero invisible para
-- cualquier otro consumidor.
--
-- Implementacion: cairo ya escribe el PNG base (rapido, fiable),
-- y este modulo inserta los tEXt inmediatamente despues de IHDR.
-- Evita reimplementar el encoder y no obliga a pasar por
-- GdkPixbuf para guardar.
--
-- API publica:
--   M.read_text_chunks(path)              -> table { key = value } | nil, err
--   M.write_text_chunks(path, table)      -> true | false, err
--
-- write_text_chunks reescribe el archivo completo (los PNG de
-- thumbnails son <1 MB, no es un problema). Si un keyword ya
-- existe en el archivo, el chunk viejo se elimina y se reemplaza,
-- nunca se duplica.

local ffi  = require("ffi")
local zffi = require("bindings.cdef.zlib")
local zlib = zffi.load("libz.so.1")

local M = {}

local PNG_SIG = "\137PNG\r\n\26\n"

-- Escribe un entero unsigned 32-bit big-endian como 4 bytes.
local function be32(n)
    return string.char(
        bit.band(bit.rshift(n, 24), 0xFF),
        bit.band(bit.rshift(n, 16), 0xFF),
        bit.band(bit.rshift(n,  8), 0xFF),
        bit.band(n,                  0xFF))
end

-- Lee 4 bytes big-endian en posicion i.
local function rd32(s, i)
    local a, b, c, d = s:byte(i, i + 3)
    return a * 0x1000000 + b * 0x10000 + c * 0x100 + d
end

-- CRC32 segun el estandar PNG (mismo polinomio que zlib).
local function crc32(s)
    local buf = ffi.cast("const Bytef *", s)
    return tonumber(zlib.crc32(0, buf, #s))
end

-- Construye un chunk completo: length|type|data|crc.
local function make_chunk(typ, data)
    return be32(#data) .. typ .. data .. be32(crc32(typ .. data))
end

-- Devuelve tabla keyword->valor con todos los tEXt del PNG.
-- No decodifica zTXt ni iTXt (no los usamos, no los leemos).
function M.read_text_chunks(path)
    local f = io.open(path, "rb")
    if not f then return nil, "no se pudo abrir: " .. path end
    local data = f:read("*a")
    f:close()
    if data:sub(1, 8) ~= PNG_SIG then
        return nil, "no es PNG"
    end
    local out = {}
    local i = 9
    while i + 11 <= #data do
        local len = rd32(data, i)
        local typ = data:sub(i + 4, i + 7)
        local body = data:sub(i + 8, i + 8 + len - 1)
        if typ == "tEXt" then
            local sep = body:find("\0", 1, true)
            if sep then
                out[body:sub(1, sep - 1)] = body:sub(sep + 1)
            end
        end
        if typ == "IEND" then break end
        i = i + 12 + len
    end
    return out
end

-- Inserta (o reemplaza) chunks tEXt. Reescribe el archivo entero.
-- tbl = { ["Thumb::URI"] = "file://...", ["Thumb::MTime"] = "1700" }
function M.write_text_chunks(path, tbl)
    local f = io.open(path, "rb")
    if not f then return false, "no se pudo leer: " .. path end
    local data = f:read("*a")
    f:close()
    if data:sub(1, 8) ~= PNG_SIG then
        return false, "no es PNG"
    end

    -- Parsear el IHDR (obligatoriamente el primer chunk).
    local ihdr_len = rd32(data, 9)
    if data:sub(13, 16) ~= "IHDR" then
        return false, "PNG sin IHDR inicial"
    end
    local pre  = data:sub(1, 9 + 12 + ihdr_len - 1)
    local rest = data:sub(9 + 12 + ihdr_len)

    -- Recorrer el resto y descartar los tEXt que vamos a pisar.
    local kept = {}
    local j = 1
    while j + 11 <= #rest do
        local rlen = rd32(rest, j)
        local rtyp = rest:sub(j + 4, j + 7)
        local chunk_len = 12 + rlen
        local chunk = rest:sub(j, j + chunk_len - 1)
        local drop = false
        if rtyp == "tEXt" then
            local body = rest:sub(j + 8, j + 8 + rlen - 1)
            local sep = body:find("\0", 1, true)
            if sep and tbl[body:sub(1, sep - 1)] ~= nil then
                drop = true
            end
        end
        if not drop then kept[#kept + 1] = chunk end
        if rtyp == "IEND" then break end
        j = j + chunk_len
    end

    -- Chunks nuevos, en orden estable para que el archivo sea
    -- deterministico (facilita comparar dos generaciones).
    local keys = {}
    for k in pairs(tbl) do keys[#keys + 1] = k end
    table.sort(keys)
    local new_chunks = {}
    for _, k in ipairs(keys) do
        new_chunks[#new_chunks + 1] =
            make_chunk("tEXt", k .. "\0" .. tostring(tbl[k]))
    end

    local out = pre .. table.concat(new_chunks) .. table.concat(kept)
    local g = io.open(path, "wb")
    if not g then return false, "no se pudo escribir: " .. path end
    g:write(out)
    g:close()
    return true
end

return M
