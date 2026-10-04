local ffi = require("bindings.cdef.cairo")

local cairo_lib = ffi.load("libcairo.so.2")

local M = {}

-- Valores de cairo_operator_t segun cairo.h:
M.OPERATOR = {
    CLEAR  = 0,
    SOURCE = 1,
    OVER   = 2,
    IN     = 3,
    OUT    = 4,
    ATOP   = 5,
    DEST   = 6,
    DEST_OVER = 7,
    DEST_IN   = 8,
    DEST_OUT  = 9,
    DEST_ATOP = 10,
    XOR    = 11,
    ADD    = 12,
    SATURATE = 13,
    MULTIPLY = 14,
}

M.FILTER = {
    FAST     = 0,
    GOOD     = 1,
    BEST     = 2,
    NEAREST  = 3,
    BILINEAR = 4,
}

M.FORMAT = {
    ARGB32 = 0,
    RGB24  = 1,
    A8     = 2,
    A1     = 3,
}

function M.surface_for_window(conn, drawable, visualtype, w, h)
    local surface = cairo_lib.cairo_xcb_surface_create(
        conn, drawable, visualtype, w, h
    )
    local st = cairo_lib.cairo_surface_status(surface)
    if st ~= 0 then
        error("cairo_xcb_surface_create fallo, status=" .. st)
    end
    return surface
end

function M.image_surface_create(w, h, format)
    format = format or M.FORMAT.ARGB32
    local surface = cairo_lib.cairo_image_surface_create(format, w, h)
    local st = cairo_lib.cairo_surface_status(surface)
    if st ~= 0 then
        error("cairo_image_surface_create fallo, status=" .. st)
    end
    return surface
end

function M.context(surface)
    local cr = cairo_lib.cairo_create(surface)
    local st = cairo_lib.cairo_status(cr)
    if st ~= 0 then
        error("cairo_create fallo, status=" .. st)
    end
    return cr
end

function M.set_rgb(cr, r, g, b) cairo_lib.cairo_set_source_rgb(cr, r, g, b) end
function M.set_rgba(cr, r, g, b, a) cairo_lib.cairo_set_source_rgba(cr, r, g, b, a) end
function M.set_line_width(cr, w) cairo_lib.cairo_set_line_width(cr, w) end
function M.paint(cr) cairo_lib.cairo_paint(cr) end
function M.paint_with_alpha(cr, a) cairo_lib.cairo_paint_with_alpha(cr, a) end
function M.rectangle(cr, x, y, w, h) cairo_lib.cairo_rectangle(cr, x, y, w, h) end
function M.arc(cr, xc, yc, r, a1, a2) cairo_lib.cairo_arc(cr, xc, yc, r, a1, a2) end
function M.move_to(cr, x, y) cairo_lib.cairo_move_to(cr, x, y) end
function M.line_to(cr, x, y) cairo_lib.cairo_line_to(cr, x, y) end
function M.close_path(cr) cairo_lib.cairo_close_path(cr) end
function M.fill(cr) cairo_lib.cairo_fill(cr) end
function M.stroke(cr) cairo_lib.cairo_stroke(cr) end
function M.destroy_context(cr) cairo_lib.cairo_destroy(cr) end
function M.destroy_surface(s) cairo_lib.cairo_surface_destroy(s) end
function M.flush_surface(s) cairo_lib.cairo_surface_flush(s) end

function M.new_sub_path(cr)
    cairo_lib.cairo_new_sub_path(cr)
end

-- Rectangulo redondeado. (x, y) es la esquina superior izquierda,
-- (w, h) son ancho/alto. r es el radio de las esquinas.
function M.rounded_rect(cr, x, y, w, h, r)
    local pi = math.pi
    local half_pi = pi / 2
    if r <= 0 then
        cairo_lib.cairo_rectangle(cr, x, y, w, h)
        return
    end
    -- Clamp del radio a la mitad del menor lado
    if r > w / 2 then r = w / 2 end
    if r > h / 2 then r = h / 2 end
    cairo_lib.cairo_new_sub_path(cr)
    cairo_lib.cairo_arc(cr, x + r,     y + r,     r, pi,           pi + half_pi)
    cairo_lib.cairo_arc(cr, x + w - r, y + r,     r, pi + half_pi, pi * 2)
    cairo_lib.cairo_arc(cr, x + w - r, y + h - r, r, 0,            half_pi)
    cairo_lib.cairo_arc(cr, x + r,     y + h - r, r, half_pi,      pi)
    cairo_lib.cairo_close_path(cr)
end

function M.save(cr)            cairo_lib.cairo_save(cr) end
function M.restore(cr)         cairo_lib.cairo_restore(cr) end
function M.clip(cr)            cairo_lib.cairo_clip(cr) end
function M.clip_preserve(cr)   cairo_lib.cairo_clip_preserve(cr) end
function M.new_path(cr)        cairo_lib.cairo_new_path(cr) end

function M.set_filter(cr, filter)
    cairo_lib.cairo_pattern_set_filter(
        cairo_lib.cairo_get_source(cr), filter)
end

function M.set_source_surface(cr, surface, x, y)
    cairo_lib.cairo_set_source_surface(cr, surface, x, y)
end

function M.set_operator(cr, op)
    cairo_lib.cairo_set_operator(cr, op)
end

function M.translate(cr, tx, ty) cairo_lib.cairo_translate(cr, tx, ty) end
-- Carga una imagen PNG en un surface de Cairo. Devuelve el surface
-- o nil + mensaje si falla.
function M.load_png(path)
    local surface = cairo_lib.cairo_image_surface_create_from_png(path)
    local st = cairo_lib.cairo_surface_status(surface)
    if st ~= 0 then
        cairo_lib.cairo_surface_destroy(surface)
        return nil, "png load failed (status=" .. st .. "): " .. tostring(path)
    end
    return surface
end

function M.surface_width(surface)
    return cairo_lib.cairo_image_surface_get_width(surface)
end

function M.surface_height(surface)
    return cairo_lib.cairo_image_surface_get_height(surface)
end

-- Dibuja un surface en (x, y) con un tamano destino (w, h).
-- Si w/h son nil, usa el tamano nativo de la imagen.
function M.draw_surface(cr, surface, x, y, w, h, filter)
    if w == nil then w = M.surface_width(surface) end
    if h == nil then h = M.surface_height(surface) end
    local nw = M.surface_width(surface)
    local nh = M.surface_height(surface)
    if nw == 0 or nh == 0 then return end

    cairo_lib.cairo_save(cr)
    cairo_lib.cairo_translate(cr, x, y)
    cairo_lib.cairo_scale(cr, w / nw, h / nh)
    cairo_lib.cairo_set_source_surface(cr, surface, 0, 0)
    if filter then
        cairo_lib.cairo_pattern_set_filter(
            cairo_lib.cairo_get_source(cr), filter)
    end
    cairo_lib.cairo_paint(cr)
    cairo_lib.cairo_restore(cr)
end

-- Dibuja un surface tintado con un color solido. Util para iconos
-- monocromo. Preserva el canal alpha del source (formula SOURCE_IN
-- de Porter-Duff: destino = fuente ORIGINAL * alpha_del_mask).
function M.draw_surface_tinted(cr, surface, x, y, w, h, r, g, b)
    local nw = M.surface_width(surface)
    local nh = M.surface_height(surface)
    if nw == 0 or nh == 0 then return end
    if w == nil then w = nw end
    if h == nil then h = nh end

    -- Construir el icono tintado en una surface temporal ARGB32
    -- transparente. Sin esto, el "IN" se aplica sobre el fondo
    -- opaco del destino y pinta el area entera, no solo la silueta.
    local tmp = cairo_lib.cairo_image_surface_create(0, nw, nh)
    local tmp_cr = cairo_lib.cairo_create(tmp)

    -- Paso 1: pintar el icono (queda con su alpha original sobre
    -- un fondo transparente).
    cairo_lib.cairo_set_operator(tmp_cr, 2)   -- OVER
    cairo_lib.cairo_set_source_surface(tmp_cr, surface, 0, 0)
    cairo_lib.cairo_paint(tmp_cr)

    -- Paso 2: aplicar el color con IN (source * dest_alpha).
    -- Ahora dest_alpha=0 fuera de la silueta, asi que el color solo
    -- aparece donde el icono tiene pixeles.
    cairo_lib.cairo_set_operator(tmp_cr, 3)   -- IN
    cairo_lib.cairo_set_source_rgb(tmp_cr, r, g, b)
    cairo_lib.cairo_paint(tmp_cr)
    cairo_lib.cairo_destroy(tmp_cr)

    -- Paso 3: blitear al destino con escalado.
    cairo_lib.cairo_save(cr)
    cairo_lib.cairo_translate(cr, x, y)
    cairo_lib.cairo_scale(cr, w / nw, h / nh)
    cairo_lib.cairo_set_operator(cr, 2)   -- OVER
    cairo_lib.cairo_set_source_surface(cr, tmp, 0, 0)
    cairo_lib.cairo_paint(cr)
    cairo_lib.cairo_restore(cr)

    cairo_lib.cairo_surface_destroy(tmp)
end

-- Cache de surfaces cargadas por ruta. Evita releer del disco.
local _surface_cache = {}

function M.load_png_cached(path)
    local s = _surface_cache[path]
    if s then return s end
    local surface, err = M.load_png(path)
    if not surface then return nil, err end
    _surface_cache[path] = surface
    return surface
end

function M.clear_surface_cache()
    for _, s in pairs(_surface_cache) do
        cairo_lib.cairo_surface_destroy(s)
    end
    _surface_cache = {}
end

function M.write_png(surface, path)
    local st = cairo_lib.cairo_surface_write_to_png(surface, path)
    return st == 0
end

return M
