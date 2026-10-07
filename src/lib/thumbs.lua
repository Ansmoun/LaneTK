-- thumbs.lua: cache de thumbnails siguiendo el estandar freedesktop.
-- https://specifications.freedesktop.org/thumbnail-spec
--
-- Sustituye la version anterior basada en ffmpeg sincrono. Ahora:
--   * decodifica con gdk-pixbuf (PNG, JPEG, GIF, WEBP, BMP, TIFF...)
--   * SVG via libresvg (como antes)
--   * guarda en ~/.cache/thumbnails/<bucket>/<md5(uri)>.png
--   * inyecta metadata Thumb::URI y Thumb::MTime en cada PNG
--   * respeta el fail-marker del spec (<hash>.png.fail)
--
-- API publica:
--   M.ensure(src, bucket)   -> cache_path | nil, err
--   M.surface(src, bucket)  -> cairo_surface | nil, err
--   M.clear()               -- borra TODA la cache de thumbnails
--                              (comportamiento estandar de los
--                              limpiadores del escritorio)
--   M.BUCKETS               -- tabla bucket -> lado mayor en px
--
-- Buckets: normal=128, large=256, x-large=512, xx-large=1024.
-- El lado mayor de la imagen resultante es el del bucket; el otro
-- se calcula respetando el aspect ratio (sin padding).

local fs  = require("lib.fs")
local uri = require("lib.uri")
local gp  = require("lib.gdk_pixbuf")
local svg = require("lib.svg")
local png_meta = require("lib.png_meta")
local log = require("lib.log")

local M = {}

-- Buckets segun el spec. El valor es el lado mayor en pixeles.
M.BUCKETS = {
    normal     = 128,
    large      = 256,
    ["x-large"]  = 512,
    ["xx-large"] = 1024,
}

local HOME = os.getenv("HOME") or "/tmp"
local XDG_CACHE = os.getenv("XDG_CACHE_HOME") or (HOME .. "/.cache")
local THUMBS_ROOT = XDG_CACHE .. "/thumbnails"

local SOFTWARE_TAG = "lanetk-thumbs"

local function bucket_dir(bucket)
    return THUMBS_ROOT .. "/" .. bucket
end

-- Devuelve cache_path y uri canonico, o nil si el src no es
-- hasheable (path relativo, vacio, etc).
local function cache_path_for(src, bucket)
    local file_uri, uerr = uri.file_uri(src)
    if not file_uri then return nil, nil, uerr end
    local hash, herr = uri.md5(file_uri)
    if not hash then return nil, nil, herr end
    return bucket_dir(bucket) .. "/" .. hash .. ".png", file_uri
end

-- Decodifica el origen al tamano pedido. Devuelve cairo_surface.
-- Rutas .svg/.svgz van por resvg; el resto por gdk-pixbuf.
local function decode_scaled(src, side)
    local lower = src:lower()
    if lower:match("%.svg$") or lower:match("%.svgz$") then
        return svg.load(src, side, side)
    end
    return gp.load_scaled(src, side, side)
end

-- Genera el thumbnail y lo escribe con metadata. Devuelve true
-- si el PNG quedo en disco, false + err si fallo.
local function generate(src, bucket, cache_path, file_uri, src_mtime)
    local side = M.BUCKETS[bucket]
    local dir = bucket_dir(bucket)
    os.execute("mkdir -p '" .. dir:gsub("'", "'\\''") .. "'")

    local surf, derr = decode_scaled(src, side)
    if not surf then
        -- Fail marker del spec: <hash>.png.fail vacio.
        local marker = io.open(cache_path .. ".fail", "w")
        if marker then marker:close() end
        return false, derr or "decode fallo"
    end

    local cairo = require("lib.cairo")
    if not cairo.write_png(surf, cache_path) then
        cairo.destroy_surface(surf)
        return false, "cairo_surface_write_to_png fallo"
    end
    cairo.destroy_surface(surf)

    local ok, werr = png_meta.write_text_chunks(cache_path, {
        ["Thumb::URI"]   = file_uri,
        ["Thumb::MTime"] = tostring(src_mtime),
        ["Software"]     = SOFTWARE_TAG,
    })
    if not ok then
        -- El PNG esta escrito pero sin metadata: borralo, no
        -- sirve para nadie. Mejor regenerar la proxima vez.
        os.remove(cache_path)
        return false, werr or "no se pudo escribir metadata"
    end
    return true
end

-- Comprueba que un PNG cacheado corresponde exactamente al src
-- actual: mismo URI y mismo mtime. Si la metadata falta o no
-- coincide, el archivo esta stale.
local function cache_is_valid(cache_path, file_uri, src_mtime)
    if not fs.is_file(cache_path) then return false end
    local meta, err = png_meta.read_text_chunks(cache_path)
    if not meta then
        log.warn("thumbs", "cache ilegible: %s (%s)",
            cache_path, err or "?")
        return false
    end
    if meta["Thumb::URI"] ~= file_uri then return false end
    local cached_mtime = tonumber(meta["Thumb::MTime"])
    if cached_mtime ~= src_mtime then return false end
    return true
end

-- Devuelve la ruta al PNG cacheado. Genera si hace falta.
function M.ensure(src, bucket)
    bucket = bucket or "normal"
    if not M.BUCKETS[bucket] then
        return nil, "bucket desconocido: " .. tostring(bucket)
    end

    local cache_path, file_uri, cerr = cache_path_for(src, bucket)
    if not cache_path then
        return nil, cerr or "no se pudo hashear el URI"
    end

    -- El spec dice: si existe <hash>.png.fail, no reintentar.
    if fs.exists(cache_path .. ".fail") then
        return nil, "marcado como fallo previo"
    end

    local src_mtime = fs.mtime(src)
    if not src_mtime then
        return nil, "origen no existe o sin mtime: " .. src
    end

    if cache_is_valid(cache_path, file_uri, src_mtime) then
        return cache_path
    end

    -- Stale o inexistente: borrar y regenerar.
    if fs.exists(cache_path) then
        os.remove(cache_path)
    end

    local ok, gerr = generate(src, bucket, cache_path, file_uri, src_mtime)
    if not ok then
        return nil, gerr
    end
    return cache_path
end

-- Devuelve un cairo_surface listo para dibujar. Es ensure() +
-- load() del PNG cacheado. El caller es responsable de destruirlo.
function M.surface(src, bucket)
    local cache_path, err = M.ensure(src, bucket)
    if not cache_path then return nil, err end
    local surf, lerr = gp.load(cache_path)
    if not surf then
        -- El PNG cacheado se corrompio; borralo para que la
        -- proxima llamada lo regenere.
        os.remove(cache_path)
        return nil, lerr or "no se pudo cargar el cache"
    end
    return surf
end

-- Solo devuelve el path canonico del cache para un src+bucket,
-- SIN comprobar existencia ni generar. Util para consumidores que
-- quieren hacer "carga si existe, sino ignora" (evita bloquear el
-- event loop generando de golpe).
function M.cache_path(src, bucket)
    bucket = bucket or "normal"
    if not M.BUCKETS[bucket] then return nil end
    local p = cache_path_for(src, bucket)
    return p
end

-- Borra la cache completa de thumbnails. Afecta a TODOS los
-- thumbnailers del sistema (es el directorio estandar). Es lo
-- que hacen gnome-thumbnail-cleaner y equivalentes.
function M.clear()
    os.execute("rm -rf '" .. THUMBS_ROOT:gsub("'", "'\\''") .. "'")
end

return M
