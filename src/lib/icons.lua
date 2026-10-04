-- icons.lua: resolución portable de iconos.
--
-- Busca iconos en <root>/icons-src/ (SVG) y <root>/icons-png/ (PNG).
-- Prefiere SVG. PNG es fallback mientras la migración está en curso.
--
-- El root es el CWD del proceso. lane-session y el run de Lefty hacen
-- cd a la raíz del proyecto antes de invocar nada, así que el CWD
-- apunta al lugar correcto sin configuración extra.
--
-- Los nombres se indexan por todos sus sufijos. Para el archivo
-- icons-src/awesome/tabs/home.svg son válidos:
--     home
--     tabs/home
--     awesome/tabs/home
-- y con extensión: home.svg, tabs/home.svg, awesome/tabs/home.svg.
--
-- Para icons-png/88/files/folder.png: folder, files/folder, y sus
-- variantes con .png. El directorio de tamaño se descarta.

local M = {}

local _root  = nil
local _index = nil
local _cache = {}       -- "name:size" -> surface | false

-- ── Índice ────────────────────────────────────────────────────────

-- Registra un archivo en el índice bajo todos sus sufijos, con y sin
-- extensión. Ej: rel="awesome/tabs/home.svg" produce las claves
-- awesome/tabs/home.svg, awesome/tabs/home, tabs/home.svg,
-- tabs/home, home.svg, home.
local function index_file(idx, full_path, rel_path)
    local ext = rel_path:match("%.([^.]+)$")
    if not ext then return end

    local parts = {}
    for p in rel_path:gmatch("[^/]+") do parts[#parts + 1] = p end
    parts[#parts] = parts[#parts]:gsub("%.[^.]+$", "")

    for i = 1, #parts do
        local key = table.concat(parts, "/", i)
        idx[key .. "." .. ext] = idx[key .. "." .. ext] or full_path
        idx[key]              = idx[key]              or full_path
    end
end

local function scan_tree(dir, ext, prefix_pattern)
    local idx = {}
    local h = io.popen(
        "find '" .. dir .. "' -type f -name '*." .. ext .. "' 2>/dev/null")
    if not h then return idx end
    for line in h:lines() do
        if line ~= "" then
            local rel = line:match(prefix_pattern)
            if rel then index_file(idx, line, rel) end
        end
    end
    h:close()
    return idx
end

local function build_index()
    local root = M.root()
    -- SVG primero: si un nombre existe en ambos formatos, gana el SVG.
    local idx = scan_tree(root .. "/icons-src", "svg", "icons%-src/(.+)$")
    local png = scan_tree(root .. "/icons-png", "png", "icons%-png/[^/]+/(.+)$")
    for k, v in pairs(png) do
        idx[k] = idx[k] or v
    end
    return idx
end

-- ── API ────────────────────────────────────────────────────────────

function M.root()
    if _root then return _root end
    return os.getenv("PWD") or "."
end

function M.set_root(path)
    _root  = path
    _index = nil
    _cache = {}
end

local function index()
    if not _index then _index = build_index() end
    return _index
end

-- Devuelve path del icono, o nil si no se encuentra.
function M.find(name)
    if not name or name == "" then return nil end
    return index()[name]
end

-- Devuelve una surface Cairo lista para dibujar.
-- SVG: renderizado a size x size. PNG: cargado a tamaño nativo.
function M.surface(name, size)
    if not name or name == "" then return nil end
    size = size or 24
    local key = name .. ":" .. size
    local cached = _cache[key]
    if cached ~= nil then return cached or nil end

    local path = M.find(name)
    if not path then
        _cache[key] = false
        return nil
    end

    local surf
    if path:match("%.svg$") then
        surf = require("lib.svg").load(path, size, size)
    else
        surf = require("lib.cairo").load_png_cached(path)
    end
    _cache[key] = surf or false
    return surf
end

function M.clear_cache()
    _cache = {}
end

return M
