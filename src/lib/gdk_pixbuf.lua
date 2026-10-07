-- gdk_pixbuf.lua: decodifica imagenes (PNG, JPEG, GIF, WEBP, TIFF,
-- BMP, ...) via gdk-pixbuf y devuelve un cairo_image_surface ARGB32.
--
-- API publica:
--   M.load(path)             -> surface | nil, err
--   M.load_scaled(path, w, h)-> surface | nil, err
--
-- Sin cache en memoria. Para un file browser tocando cientos de
-- imagenes unicas, cachear surfaces ARGB32 en RAM revienta los 2 GB
-- de esta maquina. La cache es responsabilidad de lib.thumbs (Fase 2:
-- cache freedesktop en disco, hasheada por URI).
--
-- gdk-pixbuf entrega pixeles RGB o RGBA *no premultiplicados*.
-- cairo ARGB32 espera BGRA *premultiplicado* en little-endian.
-- Este modulo hace el swap R<->B y la premultiplicacion.

local ffi = require("bindings.cdef.gdk_pixbuf")
local lib = ffi.load("libgdk_pixbuf-2.0.so.0")

local cffi = require("bindings.cdef.cairo")
local clib = cffi.load("libcairo.so.2")

local log = require("lib.log")

local M = {}

local CAIRO_FORMAT_ARGB32 = 0

-- Extrae el mensaje de un GError y libera la estructura.
local function consume_error(errp)
    local err = errp[0]
    if err == nil then return nil end
    local msg = err.message and ffi.string(err.message) or nil
    lib.g_error_free(err)
    errp[0] = nil
    return msg
end

-- Copia pixeles de gdk-pixbuf a un cairo surface ARGB32 ya creado.
local function copy_pixels(pbuf, surf)
    local w        = lib.gdk_pixbuf_get_width(pbuf)
    local h        = lib.gdk_pixbuf_get_height(pbuf)
    local src      = lib.gdk_pixbuf_get_pixels(pbuf)
    local sstride  = lib.gdk_pixbuf_get_rowstride(pbuf)
    local nch      = lib.gdk_pixbuf_get_n_channels(pbuf)
    local has_alpha = lib.gdk_pixbuf_get_has_alpha(pbuf) ~= 0

    local dst      = clib.cairo_image_surface_get_data(surf)
    local dstride  = clib.cairo_image_surface_get_stride(surf)
    local U8       = ffi.typeof("uint8_t*")

    if not has_alpha then
        -- Camino rapido: RGB (o escala de grises expandido a 3 canales).
        -- dst = [B, G, R, 0xFF]
        for y = 0, h - 1 do
            local s = ffi.cast(U8, src + y * sstride)
            local d = ffi.cast(U8, dst + y * dstride)
            for x = 0, w - 1 do
                local i = x * nch
                local j = x * 4
                d[j + 0] = s[i + 2]   -- B
                d[j + 1] = s[i + 1]   -- G
                d[j + 2] = s[i + 0]   -- R
                d[j + 3] = 0xFF
            end
        end
    else
        -- RGBA: swap R<->B y premultiplicar. (c*a+127)/255 es la
        -- formula de redondeo que usa pixman; sin el +127 el
        -- resultado se ve mas oscuro en areas semitransparentes.
        for y = 0, h - 1 do
            local s = ffi.cast(U8, src + y * sstride)
            local d = ffi.cast(U8, dst + y * dstride)
            for x = 0, w - 1 do
                local i = x * nch
                local j = x * 4
                local a = s[i + 3]
                if a == 0 then
                    d[j + 0] = 0
                    d[j + 1] = 0
                    d[j + 2] = 0
                    d[j + 3] = 0
                elseif a == 255 then
                    d[j + 0] = s[i + 2]
                    d[j + 1] = s[i + 1]
                    d[j + 2] = s[i + 0]
                    d[j + 3] = 255
                else
                    d[j + 0] = math.floor((s[i + 2] * a + 127) / 255)
                    d[j + 1] = math.floor((s[i + 1] * a + 127) / 255)
                    d[j + 2] = math.floor((s[i + 0] * a + 127) / 255)
                    d[j + 3] = a
                end
            end
        end
    end

    clib.cairo_surface_mark_dirty(surf)
end

-- Envuelve un GdkPixbuf* en un cairo surface ARGB32.
local function to_cairo(pbuf)
    local w = lib.gdk_pixbuf_get_width(pbuf)
    local h = lib.gdk_pixbuf_get_height(pbuf)
    if w <= 0 or h <= 0 then
        return nil, "gdk-pixbuf: dimensiones invalidas"
    end
    local surf = clib.cairo_image_surface_create(CAIRO_FORMAT_ARGB32, w, h)
    local st = clib.cairo_surface_status(surf)
    if st ~= 0 then
        clib.cairo_surface_destroy(surf)
        return nil, "cairo_image_surface_create status=" .. st
    end
    copy_pixels(pbuf, surf)
    return surf
end

function M.load(path)
    local errp = ffi.new("GError*[1]")
    local pbuf = lib.gdk_pixbuf_new_from_file(path, errp)
    if pbuf == nil then
        return nil, consume_error(errp) or "gdk_pixbuf_new_from_file nil"
    end
    local surf, err = to_cairo(pbuf)
    lib.g_object_unref(pbuf)
    if not surf then
        return nil, err
    end
    return surf
end

function M.load_scaled(path, w, h)
    if not w or not h then
        return nil, "load_scaled: w y h son obligatorios"
    end
    w = math.floor(w)
    h = math.floor(h)
    if w < 1 then w = 1 end
    if h < 1 then h = 1 end

    local errp = ffi.new("GError*[1]")
    -- preserve_aspect_ratio = TRUE: encaja en w x h sin padding.
    local pbuf = lib.gdk_pixbuf_new_from_file_at_scale(
        path, w, h, 1, errp)
    if pbuf == nil then
        return nil, consume_error(errp)
            or "gdk_pixbuf_new_from_file_at_scale nil"
    end
    local surf, err = to_cairo(pbuf)
    lib.g_object_unref(pbuf)
    if not surf then
        return nil, err
    end
    return surf
end

-- Lee solo la cabecera del archivo: ancho y alto sin decodificar
-- ni un pixel. Util para decidir si vale la pena generar thumbnail
-- (por ejemplo, saltar imagenes menores al bucket pedido).
-- Devuelve w, h o nil, err.
function M.file_info(path)
    local wp = ffi.new("int[1]")
    local hp = ffi.new("int[1]")
    local fmt = lib.gdk_pixbuf_get_file_info(path, wp, hp)
    if fmt == nil then
        return nil, "gdk_pixbuf_get_file_info nil (formato no reconocido)"
    end
    return tonumber(wp[0]), tonumber(hp[0])
end

return M
