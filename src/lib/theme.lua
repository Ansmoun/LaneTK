-- theme.lua: carga una paleta y la expone como la tabla `theme`
-- que consumen los tabs.
--
-- Orden de busqueda de la paleta:
--   1. Env var LANETK_PALETTE
--        - si es ruta absoluta, se usa tal cual
--        - si es nombre (ej "nord"), busca en PALETTE_DIR/nord.lua
--   2. Archivo de config del usuario: ~/.config/lanetk/palette
--        Una sola linea con el nombre de la paleta.
--   3. Default: PALETTE_DIR/gruvbox-warm.lua
--
-- PALETTE_DIR se localiza subiendo directorios desde la ubicacion
-- de este archivo, buscando uno que contenga una carpeta `palettes/`.
-- Asi funciona tanto desde el repo fuente como instalado.

local G = require("lib.helpers.graphics")
local log = require("lib.log")

local function h2rgb(hex)
    if not hex then return { 0, 0, 0 } end
    local r, g, b = G.hex_to_rgba(hex)
    return { r, g, b }
end

local M = {}

-- Watchers del theme. Cada proceso tiene su propia lista. Las
-- apps registran una funcion que reconstruye su arbol; reload_in_place
-- las llama al terminar.
M._watchers = {}

local function dir_exists(path)
    local p = io.popen("test -d '" .. path .. "' && echo yes 2>/dev/null")
    if not p then return false end
    local ok = p:read("*l") == "yes"
    p:close()
    return ok
end

local function file_exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

-- Localiza la carpeta palettes/ subiendo desde el directorio de
-- este archivo.
local function find_palette_dir()
    -- 1. CWD: <cwd>/palettes/. Es lo que quiere un consumidor como LANE,
    --    que arranca con cd a su raiz. Desacopla el toolkit de donde
    --    viven las paletas del entorno.
    if dir_exists("palettes") then return "palettes" end

    -- 2. Env var generica, para consumidores que no controlan el CWD.
    local env = os.getenv("THEME_PALETTES_DIR")
    if env and dir_exists(env) then return env end

    -- 3. Fallback historico: subir desde el propio theme.lua.
    local src = debug.getinfo(1, "S").source or ""
    src = src:gsub("^@", "")
    local dir = src:match("^(.*)/[^/]+$") or "."
    local probe = dir
    for _ = 1, 6 do
        local cand = probe .. "/palettes"
        if dir_exists(cand) then return cand end
        probe = probe .. "/.."
    end
    return dir .. "/palettes"
end

M.PALETTE_DIR = find_palette_dir()
M.CONFIG_FILE = (os.getenv("HOME") or "") .. "/.config/lanetk/palette"

function M.find_palette_path()
    -- 1. Env var
    local env = os.getenv("LANETK_PALETTE")
    if env and env ~= "" then
        if env:sub(1, 1) == "/" then
            if file_exists(env) then return env end
        else
            local p = M.PALETTE_DIR .. "/" .. env .. ".lua"
            if file_exists(p) then return p end
        end
    end

    -- 2. Archivo de config
    if file_exists(M.CONFIG_FILE) then
        local f = io.open(M.CONFIG_FILE, "r")
        local name = f and f:read("*l") or nil
        if f then f:close() end
        if name and name ~= "" then
            name = name:gsub("%s+", "")
            local p = M.PALETTE_DIR .. "/" .. name .. ".lua"
            if file_exists(p) then return p end
        end
    end

    -- 3. Default
    local default = M.PALETTE_DIR .. "/gruvbox-warm.lua"
    if file_exists(default) then return default end

    error("theme: no se encontro ninguna paleta en " .. M.PALETTE_DIR)
end

function M.list_palettes()
    local p = io.popen("ls -1 '" .. M.PALETTE_DIR .. "'/*.lua 2>/dev/null")
    if not p then return {} end
    local out = {}
    for line in p:lines() do
        local name = line:match("([^/]+)%.lua$")
        if name then out[#out + 1] = name end
    end
    p:close()
    table.sort(out)
    return out
end

function M.load(palette_path)
    palette_path = palette_path or M.find_palette_path()

    local chunk, err = loadfile(palette_path)
    if not chunk then
        error("theme: no se pudo cargar " .. palette_path .. ": " .. tostring(err))
    end
    local p = chunk()
    if not p or not p.colors or not p.semantic then
        error("theme: " .. palette_path ..
              " no tiene la estructura esperada (colors/semantic)")
    end

    local t = { path = palette_path }

    t.bg          = p.colors.bg
    t.bg_card     = p.colors.bg_card or p.colors.bg_focus or p.colors.bg
    t.bg_focus    = p.colors.bg_focus
    t.fg_normal   = p.colors.fg
    t.fg_on_color = p.colors.text_on_color
    t.accent      = p.colors.accent
    t.urgent      = p.colors.urgent

    t.muted       = p.semantic.muted
    t.ghost       = p.semantic.ghost
    t.separator   = p.semantic.separator
    t.usage_warn  = p.semantic.usage_warn
    t.usage_crit  = p.semantic.usage_crit

    t.telemetry   = p.telemetry or {}

    t.bg_rgb        = h2rgb(t.bg)
    t.bg_card_rgb   = h2rgb(t.bg_card)
    t.bg_focus_rgb  = h2rgb(t.bg_focus)
    t.separator_rgb = h2rgb(t.separator)
    t.accent_rgb    = h2rgb(t.accent)
    t.urgent_rgb    = h2rgb(t.urgent)
    t.fg_rgb        = h2rgb(t.fg_normal)
    t.muted_rgb     = h2rgb(t.muted)

    return t
end

-- Devuelve la ruta completa de una paleta por nombre.
function M.palette_path(name)
    return M.PALETTE_DIR .. "/" .. name .. ".lua"
end

-- Registra una funcion que se llamara cada vez que reload_in_place
-- termine. Devuelve la misma funcion para poder hacer unwatch.
function M.watch(fn)
    M._watchers[#M._watchers + 1] = fn
    return fn
end

function M.unwatch(fn)
    for i, w in ipairs(M._watchers) do
        if w == fn then
            table.remove(M._watchers, i)
            return true
        end
    end
    return false
end

local function notify_watchers()
    for _, w in ipairs(M._watchers) do
        local ok, err = pcall(w)
        if not ok then
            log.warn("theme", "watcher fallo: %s", tostring(err))
        end
    end
end

-- Recarga una paleta en una tabla theme existente, mutando en su
-- lugar. Todos los que tengan referencia a la tabla ven los cambios.
-- No afecta a widgets que ya capturaron colores en construccion:
-- para eso hay que reconstruir el arbol (ver PanelApp:rebuild).
function M.reload_in_place(T, palette_path)
    palette_path = palette_path or M.find_palette_path()
    local chunk, err = loadfile(palette_path)
    if not chunk then
        return false, "load fallo: " .. tostring(err)
    end
    local p = chunk()
    if not p or not p.colors or not p.semantic then
        return false, "paleta sin estructura esperada"
    end

    T.path = palette_path
    T.bg          = p.colors.bg
    T.bg_card     = p.colors.bg_card or p.colors.bg_focus or p.colors.bg
    T.bg_focus    = p.colors.bg_focus
    T.fg_normal   = p.colors.fg
    T.fg_on_color = p.colors.text_on_color
    T.accent      = p.colors.accent
    T.urgent      = p.colors.urgent

    T.muted       = p.semantic.muted
    T.ghost       = p.semantic.ghost
    T.separator   = p.semantic.separator
    T.usage_warn  = p.semantic.usage_warn
    T.usage_crit  = p.semantic.usage_crit

    T.telemetry   = p.telemetry or {}

    T.bg_rgb        = h2rgb(T.bg)
    T.bg_card_rgb   = h2rgb(T.bg_card)
    T.bg_focus_rgb  = h2rgb(T.bg_focus)
    T.separator_rgb = h2rgb(T.separator)
    T.accent_rgb    = h2rgb(T.accent)
    T.urgent_rgb    = h2rgb(T.urgent)
    T.fg_rgb        = h2rgb(T.fg_normal)
    T.muted_rgb     = h2rgb(T.muted)

    notify_watchers()
    return true
end

return M
