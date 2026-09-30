-- json.lua: parser y encoder JSON minimos, sin dependencias.
--
-- Uso:
--   local json = require("lib.helpers.json")
--   local v, err = json.decode('{"a": 1, "b": [true, null]}')
--   local s, err = json.encode({ a = 1, b = { true, json.NULL } })
--
-- Reglas del encoder:
--   - Tabla vacia -> {} (objeto vacio). Los arrays vacios son raros
--     en JSON; si se necesitan, usar json.EMPTY_ARRAY.
--   - Tabla con claves 1..n consecutivas -> array.
--   - Tabla con claves string -> objeto.
--   - Tabla mixta -> error.
--   - nil se serializa como null. Dentro de un array, nil corta la
--     secuencia (comportamiento de # en Lua). Usar json.NULL donde
--     haga falta un null explicito dentro de un array.
--
-- Errores: decode y encode devuelven (valor) o (nil, mensaje_de_error).

local M = {}

-- Marcadores publicos
M.NULL        = setmetatable({}, { __tostring = function() return "null" end })
M.EMPTY_ARRAY = setmetatable({}, { __tostring = function() return "[]" end })

-- ══════════════════════════════════════════════════════════════════
-- Parser
-- ══════════════════════════════════════════════════════════════════
-- Convencion: cada funcion devuelve (valor, nueva_pos) o
-- (nil, nil, err). El consumidor distingue por el tercer valor.

local function skip_ws(s, i)
    local n = #s
    while i <= n do
        local c = s:byte(i)
        if c == 0x20 or c == 0x09 or c == 0x0A or c == 0x0D then
            i = i + 1
        else
            break
        end
    end
    return i
end

local SIMPLE_ESCAPES = {
    ['"'] = '"', ['\\'] = '\\', ['/'] = '/',
    b = '\b', f = '\f', n = '\n', r = '\r', t = '\t',
}

local function utf8_from_cp(cp)
    if cp < 0x80 then
        return string.char(cp)
    elseif cp < 0x800 then
        return string.char(
            0xC0 + math.floor(cp / 0x40),
            0x80 + (cp % 0x40))
    elseif cp < 0x10000 then
        return string.char(
            0xE0 + math.floor(cp / 0x1000),
            0x80 + (math.floor(cp / 0x40) % 0x40),
            0x80 + (cp % 0x40))
    else
        return string.char(
            0xF0 + math.floor(cp / 0x40000),
            0x80 + (math.floor(cp / 0x1000) % 0x40),
            0x80 + (math.floor(cp / 0x40) % 0x40),
            0x80 + (cp % 0x40))
    end
end

local function parse_hex4(s, i)
    if i + 3 > #s then return nil, nil, "hex: fin de string" end
    local h = s:sub(i, i + 3)
    if not h:match("^%x%x%x%x$") then
        return nil, nil, "hex invalido: " .. h
    end
    return tonumber(h, 16), i + 4
end

local parse_value

local function parse_string(s, i)
    -- i apunta al " de apertura
    local out = {}
    i = i + 1
    local n = #s
    while i <= n do
        local b = s:byte(i)
        if b == 0x22 then
            return table.concat(out), i + 1
        elseif b == 0x5C then
            local e = s:sub(i + 1, i + 1)
            local simple = SIMPLE_ESCAPES[e]
            if simple then
                out[#out + 1] = simple
                i = i + 2
            elseif e == 'u' then
                local cp, ni, err = parse_hex4(s, i + 2)
                if not cp then return nil, nil, err end
                i = ni
                if cp >= 0xD800 and cp <= 0xDBFF then
                    if s:sub(i, i + 1) ~= "\\u" then
                        return nil, nil, "surrogate alto sin bajo"
                    end
                    local lo
                    lo, i = parse_hex4(s, i + 2)
                    if not lo then return nil, nil, "surrogate bajo invalido" end
                    if lo < 0xDC00 or lo > 0xDFFF then
                        return nil, nil, "surrogate bajo fuera de rango"
                    end
                    cp = 0x10000 + (cp - 0xD800) * 0x400 + (lo - 0xDC00)
                elseif cp >= 0xDC00 and cp <= 0xDFFF then
                    return nil, nil, "surrogate bajo solo"
                end
                out[#out + 1] = utf8_from_cp(cp)
            else
                return nil, nil, "escape invalido: \\" .. e
            end
        elseif b < 0x20 then
            return nil, nil, "caracter de control en string"
        else
            -- Copiar bytes UTF-8 hasta el proximo caracter especial.
            local j = i
            while j <= n do
                local bj = s:byte(j)
                if bj == 0x22 or bj == 0x5C or bj < 0x20 then
                    break
                end
                j = j + 1
            end
            out[#out + 1] = s:sub(i, j - 1)
            i = j
        end
    end
    return nil, nil, "string sin cerrar"
end

local function parse_number(s, i)
    local j = i
    local n = #s
    if s:byte(j) == 0x2D then j = j + 1 end
    while j <= n do
        local b = s:byte(j)
        if (b >= 0x30 and b <= 0x39) or b == 0x2E or b == 0x65
           or b == 0x45 or b == 0x2B or b == 0x2D then
            j = j + 1
        else
            break
        end
    end
    local num = tonumber(s:sub(i, j - 1))
    if not num then return nil, nil, "numero invalido" end
    return num, j
end

local function parse_array(s, i)
    local arr = {}
    local n = #s
    i = skip_ws(s, i + 1)
    if i <= n and s:byte(i) == 0x5D then
        return arr, i + 1
    end
    while i <= n do
        local v, ni, err = parse_value(s, i)
        if v == nil and ni == nil then return nil, nil, err end
        arr[#arr + 1] = v
        i = skip_ws(s, ni)
        if i > n then return nil, nil, "array sin cerrar" end
        local b = s:byte(i)
        if b == 0x5D then
            return arr, i + 1
        elseif b == 0x2C then
            i = skip_ws(s, i + 1)
        else
            return nil, nil, "array: se esperaba , o ] en pos " .. i
        end
    end
    return nil, nil, "array sin cerrar"
end

local function parse_object(s, i)
    local obj = {}
    local n = #s
    i = skip_ws(s, i + 1)
    if i <= n and s:byte(i) == 0x7D then
        return obj, i + 1
    end
    while i <= n do
        if s:byte(i) ~= 0x22 then
            return nil, nil, "objeto: se esperaba \" en pos " .. i
        end
        local k
        k, i = parse_string(s, i)
        if not k then return nil, nil, "objeto: clave malformada" end
        i = skip_ws(s, i)
        if s:byte(i) ~= 0x3A then
            return nil, nil, "objeto: se esperaba : en pos " .. i
        end
        i = skip_ws(s, i + 1)
        local v, ni, err = parse_value(s, i)
        if v == nil and ni == nil then return nil, nil, err end
        obj[k] = v
        i = skip_ws(s, ni)
        if i > n then return nil, nil, "objeto sin cerrar" end
        local b = s:byte(i)
        if b == 0x7D then
            return obj, i + 1
        elseif b == 0x2C then
            i = skip_ws(s, i + 1)
        else
            return nil, nil, "objeto: se esperaba , o } en pos " .. i
        end
    end
    return nil, nil, "objeto sin cerrar"
end

parse_value = function(s, i)
    i = skip_ws(s, i)
    if i > #s then return nil, nil, "fin inesperado" end
    local b = s:byte(i)
    if b == 0x7B then
        return parse_object(s, i)
    elseif b == 0x5B then
        return parse_array(s, i)
    elseif b == 0x22 then
        return parse_string(s, i)
    elseif b == 0x74 then
        if s:sub(i, i + 3) == "true" then return true, i + 4 end
        return nil, nil, "esperaba true"
    elseif b == 0x66 then
        if s:sub(i, i + 4) == "false" then return false, i + 5 end
        return nil, nil, "esperaba false"
    elseif b == 0x6E then
        if s:sub(i, i + 3) == "null" then return M.NULL, i + 4 end
        return nil, nil, "esperaba null"
    elseif b == 0x2D or (b >= 0x30 and b <= 0x39) then
        return parse_number(s, i)
    else
        return nil, nil, "caracter inesperado: " .. string.char(b)
    end
end

function M.decode(s)
    if type(s) ~= "string" then return nil, "no es string" end
    local v, _, err = parse_value(s, 1)
    if v == nil then return nil, err or "parse error" end
    return v
end

-- ══════════════════════════════════════════════════════════════════
-- Encoder
-- ══════════════════════════════════════════════════════════════════

local ESCAPE_MAP = {
    [0x22] = '\\"',
    [0x5C] = '\\\\',
    [0x08] = '\\b',
    [0x0C] = '\\f',
    [0x0A] = '\\n',
    [0x0D] = '\\r',
    [0x09] = '\\t',
}

local function escape_string(s)
    local out = { '"' }
    for i = 1, #s do
        local b = s:byte(i)
        local e = ESCAPE_MAP[b]
        if e then
            out[#out + 1] = e
        elseif b < 0x20 then
            out[#out + 1] = string.format("\\u%04x", b)
        else
            out[#out + 1] = string.char(b)
        end
    end
    out[#out + 1] = '"'
    return table.concat(out)
end

-- Verifica si t es un array (claves 1..n consecutivas). Devuelve
-- true, n en caso afirmativo. Asume que t no esta vacia.
local function is_array(t)
    local n = 0
    for k in pairs(t) do
        if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then
            return false
        end
        if k > n then n = k end
    end
    for i = 1, n do
        if t[i] == nil then return false end
    end
    return true, n
end

local encode_value

local function encode_table(t, depth)
    if t == M.EMPTY_ARRAY then return "[]" end
    if t == M.NULL then return "null" end

    local n = 0
    for _ in pairs(t) do n = n + 1 end
    if n == 0 then return "{}" end

    local arr, arr_n = is_array(t)
    if arr then
        local out = { "[" }
        for i = 1, arr_n do
            if i > 1 then out[#out + 1] = "," end
            out[#out + 1] = encode_value(t[i], depth + 1)
        end
        out[#out + 1] = "]"
        return table.concat(out)
    end

    local out = { "{" }
    local first = true
    for k, v in pairs(t) do
        if type(k) ~= "string" then
            error("clave no-string en objeto: " .. type(k))
        end
        if not first then out[#out + 1] = "," end
        first = false
        out[#out + 1] = escape_string(k)
        out[#out + 1] = ":"
        out[#out + 1] = encode_value(v, depth + 1)
    end
    out[#out + 1] = "}"
    return table.concat(out)
end

encode_value = function(v, depth)
    if v == nil then return "null" end
    if v == M.NULL then return "null" end
    if v == M.EMPTY_ARRAY then return "[]" end
    local tv = type(v)
    if tv == "boolean" then
        return v and "true" or "false"
    elseif tv == "number" then
        if v ~= v then error("nan no serializable") end
        if v == math.huge or v == -math.huge then
            error("inf no serializable")
        end
        return tostring(v)
    elseif tv == "string" then
        return escape_string(v)
    elseif tv == "table" then
        return encode_table(v, depth)
    else
        error("tipo no serializable: " .. tv)
    end
end

function M.encode(v)
    local ok, s = pcall(encode_value, v, 0)
    if not ok then return nil, s end
    return s
end

return M
