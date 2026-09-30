-- data/config: lee/escribe conf.lua del proyecto Awesome y lista
-- los recursos disponibles (temas, paletas). Sin dependencias.

local U = require("lib.helpers.util")

local M = {}

local HOME = os.getenv("HOME")
M.CONF   = HOME .. "/.config/awesome/conf.lua"
M.THEMES = HOME .. "/.config/awesome/ui/themes"
M.PALETTES = HOME .. "/.config/lanetk/palettes"

-- Paletas del proyecto lanetk. Si no existe esa carpeta, cae al
-- directorio de awesome.
local function palettes_dir()
    local f = io.open(M.PALETTES .. "/ayu.lua", "r")
    if f then f:close(); return M.PALETTES end
    return HOME .. "/.config/awesome/ui/palettes"
end

-- Lee una clave string de conf.lua
function M.get(key)
    return U.read_conf_key(M.CONF, key)
end

-- Escribe una clave string en conf.lua. Si la clave existe, la
-- sobrescribe. Si no existe, la añade antes del `return` final
-- del archivo (o al final si no hay return). U.write_conf_key
-- solo sobrescribe claves existentes; las claves nuevas
-- (animate_tabs, animate_widgets, animate_values) se añaden
-- la primera vez que el usuario interactua con sus toggles.
function M.set(key, value)
    local content = U.read_file(M.CONF)
    if not content then return false end

    local str_val = tostring(value)
    local pattern = "(" .. key .. "%s*=%s*\")([^\"]*)(\")"

    if content:find(pattern) then
        local new_content = content:gsub(pattern, "%1" .. str_val .. "%3", 1)
        return U.write_file(M.CONF, new_content)
    end

    local line = key .. " = \"" .. str_val .. "\"\n"
    local ret_pos = content:find("\nreturn")
    if ret_pos then
        local before = content:sub(1, ret_pos - 1)
        local after  = content:sub(ret_pos + 1)
        return U.write_file(M.CONF, before .. "\n" .. line .. after)
    end
    local suffix = content:sub(-1) == "\n" and "" or "\n"
    return U.write_file(M.CONF, content .. suffix .. line)
end

-- Lista temas (directorios con theme.lua dentro)
function M.list_themes()
    local out = {}
    local p = io.popen("ls -1d " .. M.THEMES .. "/*/ 2>/dev/null")
    if p then
        for line in p:lines() do
            local name = line:match("([^/]+)/$")
            if name and name ~= "" then out[#out + 1] = name end
        end
        p:close()
    end
    table.sort(out)
    return out
end

-- Lista paletas (.lua sin extension)
function M.list_palettes()
    local dir = palettes_dir()
    local out = {}
    local p = io.popen("ls -1 " .. dir .. "/*.lua 2>/dev/null")
    if p then
        for line in p:lines() do
            local name = line:match("([^/]+)%.lua$")
            if name and name ~= "" then out[#out + 1] = name end
        end
        p:close()
    end
    table.sort(out)
    return out
end

-- Wallpapers: comprueba que existan los scripts destino.
function M.has_locker()
    local f = io.open(HOME .. "/.config/locker/locker.sh", "r")
    if f then f:close(); return true end
    return false
end

function M.has_greeter()
    local f = io.open(HOME .. "/sh/greeter-wallpaper.sh", "r")
    if f then f:close(); return true end
    return false
end

function M.has_wallpaper_conf()
    local f = io.open(HOME .. "/.config/awesome/wallpaper.conf", "r")
    if f then f:close(); return true end
    return false
end

-- ── Helpers tipados sobre read_conf_key / write_conf_key ────
-- conf.lua solo guarda strings entre comillas dobles. Estos
-- helpers convierten entre el string y el tipo real.

-- Lee un booleano: "true" o "false" como string, o el default.
function M.get_bool(key, default)
    local v = M.get(key)
    if v == "true"  then return true  end
    if v == "false" then return false end
    return default
end

-- Escribe un booleano como "true" o "false".
function M.set_bool(key, value)
    return M.set(key, value and "true" or "false")
end

-- Lee un entero. Devuelve el default si no se puede parsear.
function M.get_int(key, default)
    local v = M.get(key)
    if not v then return default end
    local n = tonumber(v)
    if not n then return default end
    return math.floor(n)
end

-- Escribe un entero como string.
function M.set_int(key, value)
    return M.set(key, tostring(math.floor(value)))
end

-- Devuelve las opciones de animación del panel en el formato que
-- espera TabbedPanel y los tabs. Lee las claves de conf.lua:
--   animate_panel    master ("true"/"false", default false)
--   animate_tabs     crossfade entre tabs (default true si master)
--   animate_widgets  animaciones de entrada de widgets (default true)
--   animate_values   animaciones de cambios de datos (default true)
--   anim_hz          entero, default 30
--   anim_duration    entero ms, default 300
--
-- Si animate_panel es false, los tres sub-toggles quedan en false
-- sin importar lo que digan sus claves. Es el "apagador general".
-- Si animate_panel es true y las claves nuevas no existen, default
-- true para preservar el comportamiento historico.
function M.get_anim_opts()
    local master = M.get_bool("animate_panel", false)
    return {
        animate  = master,
        tabs     = master and M.get_bool("animate_tabs",    true) or false,
        widgets  = master and M.get_bool("animate_widgets", true) or false,
        values   = master and M.get_bool("animate_values",  true) or false,
        hz       = M.get_int("anim_hz", 30),
        duration = M.get_int("anim_duration", 300),
    }
end

return M
