-- svg.lua: render de SVG en runtime via resvg (libresvg.so.0).
--
-- Reemplaza la version anterior que usaba librsvg. resvg aporta
-- ~3 MB de RSS en lugar de ~20 MB, y renderiza a cualquier tamano
-- sin cachear a disco.
--
-- API publica:
--   M.load(path, w?, h?)  -> cairo_image_surface ARGB32, o nil, err
--   M.clear_cache()       -- destruye todos los surfaces cacheados
--
-- Si se pasan w y h, se renderiza a ese tamano exacto. Si solo uno,
-- se calcula el otro respetando el aspect ratio del SVG. Si ninguno,
-- se usa el tamano intrinseco del SVG.

local ffi = require("bindings.cdef.svg")
local lib = ffi.load("/usr/lib/libresvg.so.0.48")

-- cairo: para crear el surface y copiar los pixeles
local cffi = require("bindings.cdef.cairo")
local clib = cffi.load("libcairo.so.2")

local log = require("lib.log")

local M = {}

local RESVG_OK = 0

-- Cache en memoria: "path:WxH" -> surface | false
local _cache = {}

local function render(path, w, h)
    -- options
    local opt = lib.resvg_options_create()
    if opt == nil then return nil, "resvg_options_create fallo" end

    -- parse
    local tree_p = ffi.new("resvg_render_tree*[1]")
    local err = lib.resvg_parse_tree_from_file(path, opt, tree_p)
    lib.resvg_options_destroy(opt)
    if err ~= RESVG_OK then
        return nil, "resvg_parse_tree_from_file error=" .. tostring(err)
    end
    local tree = tree_p[0]
    if tree == nil then
        return nil, "tree nil"
    end

    -- tamano intrinseco
    local size = lib.resvg_get_image_size(tree)
    local iw, ih = size.width, size.height
    if iw <= 0 or ih <= 0 then
        lib.resvg_tree_destroy(tree)
        return nil, string.format("tamano intrinseco invalido: %.1fx%.1f",
            iw, ih)
    end

    -- resolver tamano de render
    local rw, rh
    if w and h then
        rw, rh = math.floor(w), math.floor(h)
    elseif w then
        rw = math.floor(w)
        rh = math.floor(ih * rw / iw + 0.5)
    elseif h then
        rh = math.floor(h)
        rw = math.floor(iw * rh / ih + 0.5)
    else
        rw, rh = math.floor(iw + 0.5), math.floor(ih + 0.5)
    end
    if rw < 1 then rw = 1 end
    if rh < 1 then rh = 1 end

    -- Construir transformacion de escala. resvg_render con
    -- transform identidad dibuja al tamano intrinseco del SVG
    -- (ej. 22x22) en la esquina superior izquierda del pixmap,
    -- dejando el resto vacio. Hay que escalar al tamano destino.
    local sx = rw / iw
    local sy = rh / ih
    local ts = ffi.new("resvg_transform")
    ts.a = sx; ts.b = 0
    ts.c = 0;  ts.d = sy
    ts.e = 0;  ts.f = 0

    -- render a buffer RGBA premultiplicado
    local buf = ffi.new("char[?]", rw * rh * 4)
    lib.resvg_render(tree, ts, rw, rh, buf)
    lib.resvg_tree_destroy(tree)

    -- cairo surface ARGB32
    local surf = clib.cairo_image_surface_create(0, rw, rh)  -- ARGB32 = 0
    local data = clib.cairo_image_surface_get_data(surf)
    local stride = clib.cairo_image_surface_get_stride(surf)
    if data == nil then
        clib.cairo_surface_destroy(surf)
        return nil, "cairo_image_surface_get_data nil"
    end

    -- swap R<->B: resvg devuelve RGBA, cairo ARGB32 quiere BGRA
    -- en little-endian.
    local U8 = ffi.typeof("uint8_t*")
    for y = 0, rh - 1 do
        local src = ffi.cast(U8, buf + y * rw * 4)
        local dst = ffi.cast(U8, data + y * stride)
        for x = 0, rw - 1 do
            local i = x * 4
            dst[i + 0] = src[i + 2]  -- B
            dst[i + 1] = src[i + 1]  -- G
            dst[i + 2] = src[i + 0]  -- R
            dst[i + 3] = src[i + 3]  -- A
        end
    end
    clib.cairo_surface_mark_dirty(surf)
    return surf
end

function M.load(path, w, h)
    local key = path .. ":" .. tostring(w) .. "x" .. tostring(h)
    local cached = _cache[key]
    if cached ~= nil then
        return cached or nil
    end
    local surf, err = render(path, w, h)
    if not surf then
        log.warn("svg", "load fallo: %s (%s)", path, err or "?")
        _cache[key] = false
        return nil
    end
    _cache[key] = surf
    return surf
end

function M.invalidate(path)
    -- Destruye todos los tamanos cacheados para el path dado.
    for key, s in pairs(_cache) do
        if key:sub(1, #path + 1) == path .. ":" then
            if s then clib.cairo_surface_destroy(s) end
            _cache[key] = nil
        end
    end
end

function M.clear_cache()
    for _, s in pairs(_cache) do
        if s then clib.cairo_surface_destroy(s) end
    end
    _cache = {}
end

return M
