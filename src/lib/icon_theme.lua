-- icon_theme.lua: resuelve nombres de iconos del tema activo de GTK.
--
-- API:
--   M.theme()                -- nombre del tema activo
--   M.find_path(name, size)  -- ruta al SVG/PNG, o nil
--   M.resolve(name, size)    -- surface cairo listo para dibujar
--   M.clear_cache()

local U      = require("lib.helpers.util")
local svg    = require("lib.svg")
local cairo  = require("lib.cairo")

local M = {}

local _surface_cache = {}
local _path_cache    = {}
local _theme         = nil
local _parents       = nil

local COMMON_CATS = {
    "mimetypes", "places", "actions", "categories",
    "devices", "apps", "applications", "emblems",
    "panel", "status", "stock", "filetypes",
    "filesystems", "symbolic",
}

local function read_gtk_icon_theme(path)
    local f = io.open(path, "r")
    if not f then return nil end
    for line in f:lines() do
        local v = line:match("^gtk%-icon%-theme%-name%s*=%s*(.+)$")
        if v then
            v = v:gsub('^"', ""):gsub('"$', "")
            f:close()
            return U.trim(v)
        end
    end
    f:close()
    return nil
end

local function detect_theme()
    local home = os.getenv("HOME") or ""
    local candidates = {
        home .. "/.config/gtk-3.0/settings.ini",
        home .. "/.config/gtk-4.0/settings.ini",
        home .. "/.gtkrc-2.0",
    }
    for _, p in ipairs(candidates) do
        local t = read_gtk_icon_theme(p)
        if t and t ~= "" then return t end
    end
    return "hicolor"
end

local function collect_parents(theme)
    local result = { theme }
    local seen = { [theme] = true }

    local function add(name)
        if seen[name] then return end
        seen[name] = true
        result[#result + 1] = name

        local home = os.getenv("HOME") or ""
        local bases = {
            home .. "/.local/share/icons/" .. name,
            "/usr/share/icons/" .. name,
        }
        for _, base in ipairs(bases) do
            local f = io.open(base .. "/index.theme", "r")
            if f then
                for line in f:lines() do
                    local inh = line:match("^Inherits%s*=%s*(.+)$")
                    if inh then
                        for parent in inh:gmatch("[^,]+") do
                            parent = U.trim(parent)
                            if parent ~= "" then add(parent) end
                        end
                    end
                end
                f:close()
                break
            end
        end
    end

    add(theme)
    return result
end

local function try_file(base_dir, name)
    for _, ext in ipairs({ "svg", "png" }) do
        local p = base_dir .. "/" .. name .. "." .. ext
        local f = io.open(p, "rb")
        if f then f:close(); return p end
    end
    return nil
end

local function find_in_theme(theme, name, size)
    local size_dirs = {}
    if type(size) == "number" then
        size_dirs[#size_dirs + 1] = tostring(size)
    end
    size_dirs[#size_dirs + 1] = "scalable"
    for _, s in ipairs({16, 22, 24, 32, 48, 64, 96, 128, 256}) do
        size_dirs[#size_dirs + 1] = tostring(s)
    end

    local home = os.getenv("HOME") or ""
    local bases = {
        home .. "/.local/share/icons/" .. theme,
        "/usr/share/icons/" .. theme,
    }

    for _, base in ipairs(bases) do
        for _, sd in ipairs(size_dirs) do
            local sd_path = base .. "/" .. sd
            local exists = os.execute("test -d '" .. sd_path .. "'")
            if exists == true then
                for _, cat in ipairs(COMMON_CATS) do
                    local p = try_file(sd_path .. "/" .. cat, name)
                    if p then return p end
                end
                local p = try_file(sd_path, name)
                if p then return p end
            end
        end
    end
    return nil
end

function M.theme()
    if _theme == nil then _theme = detect_theme() end
    return _theme
end

function M.parents()
    if _parents == nil then
        _parents = collect_parents(M.theme())
    end
    return _parents
end

function M.find_path(name, size)
    size = size or 22
    local key = name .. ":" .. tostring(size)
    local cached = _path_cache[key]
    if cached ~= nil then return cached or nil end
    for _, theme in ipairs(M.parents()) do
        local p = find_in_theme(theme, name, size)
        if p then
            _path_cache[key] = p
            return p
        end
    end
    _path_cache[key] = false
    return nil
end

function M.resolve(name, size)
    size = size or 22
    local key = name .. ":" .. tostring(size)
    local cached = _surface_cache[key]
    if cached ~= nil then return cached or nil end
    local path = M.find_path(name, size)
    if not path then
        _surface_cache[key] = false
        return nil
    end
    local surface
    if path:sub(-4) == ".svg" then
        surface = svg.load(path, size, size)
    else
        surface = cairo.load_png_cached(path)
    end
    _surface_cache[key] = surface or false
    return surface
end

-- Destruye los surfaces de Cairo y vacia los caches.
--
-- IMPORTANTE: solo llamar cuando ningun widget tenga referencias
-- a los surfaces ya devueltos por resolve(). Si un widget guardo
-- el surface en un campo propio y despues se llama clear_cache,
-- el widget dibujara con un surface destruido. La convencion del
-- toolkit es que cada consumidor llama clear_cache al desmontar
-- su arbol, no a mitad de vida.
function M.clear_cache()
    for _, s in pairs(_surface_cache) do
        if s then cairo.destroy_surface(s) end
    end
    _surface_cache = {}
    _path_cache = {}
    _theme = nil
    _parents = nil
end

return M
