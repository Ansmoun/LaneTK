local ffi = require("bindings.cdef.pango")

local pango_core  = ffi.load("libpango-1.0.so.0")
local pangocairo  = ffi.load("libpangocairo-1.0.so.0")
local gobject     = ffi.load("libgobject-2.0.so.0")
local cairo_lib   = ffi.load("libcairo.so.2")
local fontconfig  = ffi.load("libfontconfig.so.1")

fontconfig.FcInit()

local M = {}

M.ALIGN = { LEFT = 0, CENTER = 1, RIGHT = 2 }
M.WRAP  = { WORD = 0, CHAR = 1, WORD_CHAR = 2 }

-- Cache de PangoLayouts por (texto, fuente, ancho_wrap, align,
-- spacing). Crear un PangoLayout es caro: cada llamada hace
-- fontconfig lookup, shaping del texto, layout de lineas. En
-- widgets con texto estático (listas, labels) reusar el mismo
-- layout reduce el coste del draw casi a cero.
--
-- El cache crece indefinidamente. Está pensado para widgets con
-- texto acotado (nombres de archivo, labels de formulario). Para
-- textos muy variables, llamar M.clear_layout_cache
-- periódicamente.
local _layout_cache = {}
local _layout_count = 0
local LAYOUT_CACHE_LIMIT = 5000

function M.clear_layout_cache()
    for _, layout in pairs(_layout_cache) do
        gobject.g_object_unref(layout)
    end
    _layout_cache = {}
    _layout_count = 0
end

local function layout_cache_key(text, font, opts)
    opts = opts or {}
    return table.concat({
        font or "",
        tostring(opts.wrap_width or 0),
        tostring(opts.align or 0),
        text,
    }, "\0")
end

-- Devuelve un layout cacheado para (texto, fuente, opts). El
-- llamador NO debe liberarlo: es propiedad del cache.
local function get_cached_layout(cr, text, font, opts)
    local key = layout_cache_key(text, font, opts)
    local cached = _layout_cache[key]
    if cached then
        return cached
    end

    -- Crear uno nuevo.
    local layout = pangocairo.pango_cairo_create_layout(cr)
    pango_core.pango_layout_set_text(layout, text, -1)

    local desc
    if font then
        desc = pango_core.pango_font_description_from_string(font)
        pango_core.pango_layout_set_font_description(layout, desc)
        pango_core.pango_font_description_free(desc)
    end

    if opts and opts.wrap_width then
        pango_core.pango_layout_set_width(layout, opts.wrap_width * 1024)
        pango_core.pango_layout_set_wrap(layout, opts.wrap or M.WRAP.WORD)
    end
    if opts and opts.align then
        pango_core.pango_layout_set_alignment(layout, opts.align)
    end

    -- Evitar que el cache crezca sin límite.
    if _layout_count >= LAYOUT_CACHE_LIMIT then
        M.clear_layout_cache()
    end

    _layout_cache[key] = layout
    _layout_count = _layout_count + 1
    return layout
end

function M.measure(text, font)
    local dummy = cairo_lib.cairo_image_surface_create(0, 1, 1)
    local cr = cairo_lib.cairo_create(dummy)

    local layout = pangocairo.pango_cairo_create_layout(cr)
    pango_core.pango_layout_set_text(layout, text, -1)

    local desc
    if font then
        desc = pango_core.pango_font_description_from_string(font)
        pango_core.pango_layout_set_font_description(layout, desc)
    end

    local w = ffi.new("int[1]")
    local h = ffi.new("int[1]")
    pango_core.pango_layout_get_pixel_size(layout, w, h)

    if desc then pango_core.pango_font_description_free(desc) end
    gobject.g_object_unref(layout)
    cairo_lib.cairo_destroy(cr)
    cairo_lib.cairo_surface_destroy(dummy)

    return w[0], h[0]
end

local function draw_layout(cr, x, y, layout, font, opts)
    opts = opts or {}

    local desc
    if font then
        desc = pango_core.pango_font_description_from_string(font)
        pango_core.pango_layout_set_font_description(layout, desc)
    end

    if opts.wrap_width then
        pango_core.pango_layout_set_width(layout, opts.wrap_width * 1024)
        pango_core.pango_layout_set_wrap(layout, opts.wrap or M.WRAP.WORD)
    end
    if opts.align then
        pango_core.pango_layout_set_alignment(layout, opts.align)
    end

    cairo_lib.cairo_set_source_rgb(cr, opts.r or 1.0, opts.g or 1.0, opts.b or 1.0)
    cairo_lib.cairo_move_to(cr, x, y)
    pangocairo.pango_cairo_show_layout(cr, layout)

    if desc then pango_core.pango_font_description_free(desc) end
end

function M.draw_text(cr, x, y, text, font, opts)
    local layout = get_cached_layout(cr, text, font, opts)
    -- pango_cairo_update_layout es necesario cuando cambia el
    -- contexto Cairo (por ejemplo al cambiar de superficie). En
    -- nuestro caso el contexto es el mismo durante toda la vida
    -- del layout cacheado, así que no lo llamamos.
    --
    -- El color y la posición NO son parte del layout: son del
    -- contexto Cairo y se aplican aquí.
    opts = opts or {}
    cairo_lib.cairo_set_source_rgb(cr,
        opts.r or 1.0, opts.g or 1.0, opts.b or 1.0)
    cairo_lib.cairo_move_to(cr, x, y)
    pangocairo.pango_cairo_show_layout(cr, layout)
end


-- Entidades HTML comunes. Pango solo conoce las 5 basicas de XML
-- (&amp; &lt; &gt; &quot; &apos;), asi que traducimos el resto a
-- caracteres Unicode literales antes de pasarselo.
local HTML_ENTITIES = {
    middot   = "·",   -- ·
    times    = "×",   -- ×
    divide   = "÷",   -- ÷
    nbsp     = " ",   -- espacio duro
    deg      = "°",   -- °
    plusmn   = "±",   -- ±
    micro    = "µ",   -- µ
    para     = "¶",   -- ¶
    sect     = "§",   -- §
    copy     = "©",   -- ©
    reg      = "®",   -- ®
    trade    = "™",   -- ™
    euro     = "€",   -- €
    pound    = "£",   -- £
    yen      = "¥",   -- ¥
    cent     = "¢",   -- ¢
    larr     = "←",   -- ←
    rarr     = "→",   -- →
    uarr     = "↑",   -- ↑
    darr     = "↓",   -- ↓
    harr     = "↔",   -- ↔
    mdash    = "—",   -- —
    ndash    = "–",   -- –
    hellip   = "…",   -- …
    lsquo    = "‘",   -- '
    rsquo    = "’",   -- '
    ldquo    = "“",   -- "
    rdquo    = "”",   -- "
    laquo    = "«",   -- «
    raquo    = "»",   -- »
    bullet   = "•",   -- •
    prime    = "′",   -- ′
    Prime    = "″",   -- ″
    infin    = "∞",   -- ∞
    ne       = "≠",   -- ≠
    le       = "≤",   -- ≤
    ge       = "≥",   -- ≥
    check    = "✓",   -- ✓
    cross    = "✗",   -- ✗
    star     = "★",   -- ★
    heart    = "♥",   -- ♥
    alpha    = "α",   -- α
    beta     = "β",   -- β
    gamma    = "γ",   -- γ
    delta    = "δ",   -- δ
    pi       = "π",   -- π
    mu       = "μ",   -- μ
    omega    = "ω",   -- ω
    Omega    = "Ω",   -- Ω
}

-- Traduce entidades HTML con nombre a su caracter Unicode.
-- Respeta las 5 basicas de XML (amp, lt, gt, quot, apos), que Pango
-- ya conoce y no deben tocarse aqui.
function M.html_entities(s)
    if not s then return s end
    return (s:gsub("&(%a+);", function(name)
        if name == "amp" or name == "lt" or name == "gt"
           or name == "quot" or name == "apos" then
            return "&" .. name .. ";"  -- dejar a Pango
        end
        local c = HTML_ENTITIES[name]
        if c then return c end
        return "&" .. name .. ";"  -- desconocida: dejar tal cual (Pango avisara)
    end))
end

function M.draw_markup(cr, x, y, markup, font, opts)
    local layout = pangocairo.pango_cairo_create_layout(cr)
    pango_core.pango_layout_set_markup(layout, M.html_entities(markup), -1)
    draw_layout(cr, x, y, layout, font, opts)
    gobject.g_object_unref(layout)
end

-- Escapa los caracteres especiales de Pango markup.
function M.escape(s)
    if not s then return "" end
    return (tostring(s)
        :gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;"))
end

return M
