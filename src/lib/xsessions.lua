-- xsessions.lua: lee las sesiones graficas disponibles de
-- /usr/share/xsessions/*.desktop (y ~/.local/share/xsessions/ si
-- existe). Extrae Name, Exec, Comment. Filtra las que tienen
-- NoDisplay=true, Hidden=true, o sin Exec.
--
-- Uso:
--   local xs = require("lib.xsessions")
--   for _, s in ipairs(xs.list()) do
--       print(s.id, s.name, s.exec)
--   end
--   local cmd = xs.build_command("bspwm")  -- -> {"startx","/usr/bin/env","bspwm"}

local U = require("lib.helpers.util")

local M = {}

local SYSTEM_DIR = "/usr/share/xsessions"
local USER_DIR   = (os.getenv("HOME") or "") .. "/.local/share/xsessions"

-- Parsea un archivo .desktop y devuelve una tabla con los campos
-- que nos interesan, o nil si no es una sesion valida.
local function parse_desktop(path)
    local f = io.open(path, "r")
    if not f then return nil end

    local info = { path = path }
    local in_section = false
    local section = nil

    for line in f:lines() do
        line = line:gsub("\r$", "")  -- CRLF defensivo

        -- Cambio de seccion
        local sec = line:match("^%[([^%]]+)%]$")
        if sec then
            section = sec
            in_section = (sec == "Desktop Entry")
        elseif in_section then
            local k, v = line:match("^([%w%-]+)%s*=%s*(.-)%s*$")
            if k and v and v ~= "" then
                -- Deshacer los escapes de la spec
                v = v:gsub("\\n", "\n"):gsub("\\t", "\t")
                     :gsub("\\r", "\r"):gsub("\\\\", "\\")
                info[k] = v
            end
        end
    end
    f:close()

    -- Filtros
    if info.Type ~= "Application" then return nil end
    if info.NoDisplay == "true" then return nil end
    if info.Hidden == "true" then return nil end
    if not info.Exec or info.Exec == "" then return nil end
    if not info.Name or info.Name == "" then return nil end

    -- Nombre sin sufijos raros
    info.Name = info.Name:gsub("%s*%([^%)]+%)%s*$", "")

    -- ID = basename sin .desktop
    info.id = path:match("([^/]+)%.desktop$") or path

    return info
end

-- Devuelve la lista de sesiones disponibles. Ordenada por nombre.
function M.list()
    local out = {}
    local seen = {}

    local function add_dir(dir)
        local p = io.popen("ls -1 '" .. dir .. "'/*.desktop 2>/dev/null")
        if not p then return end
        for line in p:lines() do
            local info = parse_desktop(line)
            if info and not seen[info.id] then
                seen[info.id] = true
                out[#out + 1] = info
            end
        end
        p:close()
    end

    add_dir(USER_DIR)     -- user gana
    add_dir(SYSTEM_DIR)

    table.sort(out, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)
    return out
end

-- Devuelve el comando que hay que pasarle a greetd en start_session
-- para arrancar esa sesion. Por ahora asumimos que todas las
-- sesiones de /usr/share/xsessions son X11 y hay que envolverlas con
-- startx.
function M.build_command(id)
    -- Buscamos la sesion por id
    for _, s in ipairs(M.list()) do
        if s.id == id then
            -- Limpiar el Exec (sacar los % codes)
            local exec = s.Exec:gsub("%%[uUfFdDnNickvm]", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
            -- Armar el comando: startx /usr/bin/env <exec>
            -- startx se encarga de levantar X + correr el exec
            return { "startx", "/usr/bin/env", exec }
        end
    end
    return nil
end

return M
