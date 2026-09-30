local ffi = require("ffi")
local bit = require("bit")
local xcb   = require("lib.xcb")
local cairo = require("lib.cairo")
local pango = require("lib.pango")

local W, H = 600, 400

local conn, screen_num = xcb.connect()
print("Conectado. Screen:", screen_num)

local EVENT_MASK = bit.bor(
    xcb.EVENT_MASK.Exposure,
    xcb.EVENT_MASK.KeyPress,
    xcb.EVENT_MASK.StructureNotify
)

local wid, screen = xcb.create_window(conn, {
    width = W,
    height = H,
    event_mask = EVENT_MASK,
})

xcb.map_window(conn, wid)
print("Ventana mapeada. ID:", wid)

local visualtype = xcb.get_visualtype(conn, screen_num, screen.root_visual)
local surface = cairo.surface_for_window(conn, wid, visualtype, W, H)
local cr = cairo.context(surface)
print("Surface y contexto listos.")

local function draw()
    cairo.set_rgb(cr, 0.10, 0.10, 0.13)
    cairo.paint(cr)

    -- Titulo grande
    pango.draw_text(cr, 30, 30, "Hola, tekUI",
        "DejaVu Sans Bold 28",
        { r = 0.95, g = 0.85, b = 0.30 })

    -- Texto normal
    pango.draw_text(cr, 30, 90, "Esto es texto plano dibujado con Pango.",
        "DejaVu Sans 14",
        { r = 0.85, g = 0.85, b = 0.85 })

    -- Markup: negrita, italica, color
    pango.draw_markup(cr, 30, 130,
        "Mezcla: <b>negrita</b>, <i>italica</i>, " ..
        "<span foreground='#e06060'>rojo</span>, " ..
        "<span foreground='#60c060'>verde</span>.",
        "DejaVu Sans 14",
        { r = 1, g = 1, b = 1 })

    -- Texto con wrapping
    pango.draw_text(cr, 30, 180,
        "Este parrafo se ajusta automaticamente al ancho que le demos. " ..
        "Pango rompe las lineas por palabras y respeta el espaciado.",
        "DejaVu Sans 12",
        {
            r = 0.75, g = 0.75, b = 0.75,
            wrap_width = 540,
            align = pango.ALIGN.LEFT,
        })

    -- Mide texto y dibuja un rectangulo detras
    local mw, mh = pango.measure("texto medido", "DejaVu Sans 16")
    cairo.set_rgb(cr, 0.20, 0.30, 0.50)
    cairo.rectangle(cr, 30, 290, mw + 12, mh + 8)
    cairo.fill(cr)

    pango.draw_text(cr, 36, 294, "texto medido",
        "DejaVu Sans 16",
        { r = 1, g = 1, b = 1 })

    -- Info de tamaño
    pango.draw_text(cr, 30, 350,
        string.format("El texto medido ocupa %dx%d px", mw, mh),
        "DejaVu Sans Mono 10",
        { r = 0.55, g = 0.55, b = 0.55 })

    cairo.flush_surface(surface)
    xcb.flush(conn)
end

draw()
print("Dibujo inicial hecho. Presiona 'q' para salir.")

local running = true
while running do
    local ev = xcb.wait_event(conn)
    if ev == nil then break end
    local etype = bit.band(ev.response_type, 0x7f)

    if etype == xcb.EVENT.Expose then
        draw()
    elseif etype == xcb.EVENT.KeyPress then
        local kev = ffi.cast("xcb_key_press_event_t*", ev)
        if kev.detail == 24 then running = false end
    elseif etype == xcb.EVENT.DestroyNotify then
        running = false
    end

    ffi.C.free(ev)
end

cairo.destroy_context(cr)
cairo.destroy_surface(surface)
xcb.destroy_window(conn, wid)
xcb.disconnect(conn)
print("Adios.")
