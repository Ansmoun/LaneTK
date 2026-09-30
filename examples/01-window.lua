local ffi = require("ffi")
local bit = require("bit")
local xcb   = require("lib.xcb")
local cairo = require("lib.cairo")

local W, H = 500, 300

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

-- Prepara el surface de Cairo sobre la ventana XCB
local visualtype = xcb.get_visualtype(conn, screen_num, screen.root_visual)
if visualtype == nil then
    error("no se encontro visualtype para el visual raiz")
end

local surface = cairo.surface_for_window(conn, wid, visualtype, W, H)
local cr = cairo.context(surface)
print("Surface y contexto Cairo listos.")

-- Funcion de dibujo
local function draw()
    -- Fondo oscuro
    cairo.set_rgb(cr, 0.10, 0.10, 0.13)
    cairo.paint(cr)

    -- Rectangulo rojo
    cairo.set_rgb(cr, 0.85, 0.20, 0.25)
    cairo.rectangle(cr, 40, 40, 180, 100)
    cairo.fill(cr)

    -- Circulo verde
    cairo.set_rgb(cr, 0.20, 0.75, 0.40)
    cairo.arc(cr, 350, 150, 80, 0, 2 * math.pi)
    cairo.fill(cr)

    -- Contorno blanco alrededor del circulo
    cairo.set_rgb(cr, 1.0, 1.0, 1.0)
    cairo.set_line_width(cr, 3)
    cairo.arc(cr, 350, 150, 80, 0, 2 * math.pi)
    cairo.stroke(cr)

    -- Linea diagonal
    cairo.set_rgb(cr, 0.95, 0.85, 0.30)
    cairo.set_line_width(cr, 2)
    cairo.move_to(cr, 40, 260)
    cairo.line_to(cr, 460, 260)
    cairo.stroke(cr)

    -- Asegura que Cairo empuje los pixeles a XCB
    cairo.flush_surface(surface)
    xcb.flush(conn)
end

draw()
print("Dibujo inicial hecho. Presiona 'q' en la ventana para salir.")

local running = true
while running do
    local ev = xcb.wait_event(conn)
    if ev == nil then
        print("wait_event devolvio nil")
        break
    end
    local etype = bit.band(ev.response_type, 0x7f)

    if etype == xcb.EVENT.Expose then
        local eev = ffi.cast("xcb_expose_event_t*", ev)
        print(string.format("Expose region %dx%d+%d+%d",
            eev.width, eev.height, eev.x, eev.y))
        draw()
    elseif etype == xcb.EVENT.KeyPress then
        local kev = ffi.cast("xcb_key_press_event_t*", ev)
        print(string.format("KeyPress keycode=%d", kev.detail))
        if kev.detail == 24 then
            running = false
        end
    elseif etype == xcb.EVENT.DestroyNotify then
        print("DestroyNotify")
        running = false
    end

    ffi.C.free(ev)
end

cairo.destroy_context(cr)
cairo.destroy_surface(surface)
xcb.destroy_window(conn, wid)
xcb.disconnect(conn)
print("Adios.")
