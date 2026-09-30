-- data/session: preferencias de sesion del entorno LaneTK.
-- Archivo: ~/.config/lanetk/session.conf
--
-- A diferencia de lib/data/config.lua (que lee/escribe el conf.lua
-- del proyecto Awesome original), este modulo es del entorno modular
-- de LaneTK. Las claves son de sesion (WM, etc.), no de apariencia.

local U = require("lib.helpers.util")

local M = {}

local HOME = os.getenv("HOME")
M.FILE = HOME .. "/.config/lanetk/session.conf"

-- Lista de WMs conocidos. Cada entrada tiene id (nombre del binario)
-- y descripcion. Se filtran los que esten en $PATH.
M.WM_CANDIDATES = {
    { id = "bspwm",       name = "bspwm",       desc = "Tiling binario" },
    { id = "openbox",     name = "Openbox",     desc = "Stacking ligero" },
    { id = "fluxbox",     name = "Fluxbox",     desc = "Stacking clasico" },
    { id = "i3",          name = "i3",          desc = "Tiling con arbol" },
    { id = "dwm",         name = "dwm",         desc = "Tiling minimalista" },
    { id = "awesome",     name = "AwesomeWM",   desc = "Tiling en Lua" },
    { id = "xmonad",      name = "XMonad",      desc = "Tiling en Haskell" },
    { id = "qtile",       name = "qtile",       desc = "Tiling en Python" },
    { id = "herbstluftwm", name = "herbstluftwm", desc = "Tiling manual" },
    { id = "icewm",       name = "IceWM",       desc = "Stacking tradicional" },
}

-- ── Helpers internos ──────────────────────────────────────────────

local function read_all()
    local content = U.read_file(M.FILE)
    if not content then return {} end
    local conf = {}
    for line in content:gmatch("[^\n]+") do
        local k, v = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
        if k and v and v ~= "" then
            conf[k] = v
        end
    end
    return conf
end

local function write_all(conf)
    os.execute("mkdir -p '" .. HOME .. "/.config/lanetk'")
    local lines = {}
    for k, v in pairs(conf) do
        lines[#lines + 1] = k .. " = " .. v
    end
    table.sort(lines)
    U.write_file(M.FILE, table.concat(lines, "\n") .. "\n")
end

-- ── API publica ───────────────────────────────────────────────────

function M.get(key)
    return read_all()[key]
end

function M.set(key, value)
    local conf = read_all()
    conf[key] = tostring(value)
    write_all(conf)
    return true
end

function M.get_wm()
    return M.get("wm")
end

function M.set_wm(name)
    return M.set("wm", name)
end

-- Devuelve la lista de WMs conocidos instalados en $PATH.
-- Cada entrada tiene { id, name, desc, path }.
function M.list_installed()
    local out = {}
    for _, c in ipairs(M.WM_CANDIDATES) do
        local p = io.popen("command -v " .. c.id .. " 2>/dev/null")
        local path = p and p:read("*l") or nil
        if p then p:close() end
        if path and path ~= "" then
            out[#out + 1] = {
                id   = c.id,
                name = c.name,
                desc = c.desc,
                path = path,
            }
        end
    end
    return out
end

return M
