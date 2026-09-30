-- Popup arrastrable.
-- El popup tiene una barra de titulo (primeros 26px). Al pulsar
-- en ella y arrastrar, el popup se mueve con el cursor.

local Server = require("lib.server")
local Window = require("lib.window")
local cairo  = require("lib.cairo")
local pango  = require("lib.pango")
local W      = require("lib.widgets")

local srv = Server.new()

-- ---- Padre --------------------------------------------------
local main = Window.new(srv, {
    title = "main",
    width  = 500, height = 400,
    x = "center", y = "center",
    on_draw = function(cr, w, h)
        cairo.set_rgb(cr, 0.10, 0.10, 0.13)
        cairo.paint(cr)
    end,
})

-- ---- Popup arrastrable --------------------------------------
local DRAG_BAR_H = 26

local popup = Window.new(srv, {
    parent_window = main,
    kind = "child",
    width  = 280, height = 180,
    x = 120, y = 100,
    on_draw = function(cr, w, h)
        -- Fondo
        cairo.set_rgb(cr, 0.16, 0.16, 0.22)
        cairo.paint(cr)

        -- Barra de titulo
        cairo.set_rgb(cr, 0.25, 0.25, 0.34)
        cairo.rectangle(cr, 0, 0, w, DRAG_BAR_H)
        cairo.fill(cr)

        -- Texto de la barra
        pango.draw_text(cr, 10, 6, "Popup arrastrable",
            "DejaVu Sans Bold 11",
            { r = 0.95, g = 0.90, b = 0.70 })

        -- Borde
        cairo.set_rgb(cr, 0.40, 0.40, 0.55)
        cairo.set_line_width(cr, 1)
        cairo.rectangle(cr, 0.5, 0.5, w - 1, h - 1)
        cairo.stroke(cr)

        -- Texto de ayuda
        pango.draw_text(cr, 10, DRAG_BAR_H + 10,
            "Arrastra desde la barra de arriba.",
            "DejaVu Sans 10",
            { r = 0.75, g = 0.75, b = 0.80 })
    end,
})

-- Estado del drag
local dragging = false
local drag_start_x, drag_start_y = 0, 0
local drag_origin_x, drag_origin_y = 0, 0

-- Interceptar el press: si esta en la barra, empezar drag.
local original_dispatch = popup._dispatch
function popup:_dispatch(etype, ev)
    if etype == require("lib.xcb").EVENT.ButtonPress then
        local ffi = require("ffi")
        local bev = ffi.cast("xcb_button_press_event_t*", ev)
        if bev.event_y < DRAG_BAR_H then
            dragging = true
            drag_start_x, drag_start_y = bev.root_x, bev.root_y
            drag_origin_x, drag_origin_y = popup.x, popup.y
            return
        end
    elseif etype == require("lib.xcb").EVENT.MotionNotify then
        if dragging then
            local ffi = require("ffi")
            local mev = ffi.cast("xcb_motion_notify_event_t*", ev)
            local dx = mev.root_x - drag_start_x
            local dy = mev.root_y - drag_start_y
            popup:move(drag_origin_x + dx, drag_origin_y + dy)
            return
        end
    elseif etype == require("lib.xcb").EVENT.ButtonRelease then
        if dragging then
            dragging = false
            return
        end
    end
    return original_dispatch(popup, etype, ev)
end

popup:set_input_focus()

-- ---- Contenido del padre ------------------------------------
local hint = W.Text.new {
    text = "El popup es una ventana hija X11.\n" ..
           "Arrastralo con el raton desde su barra de titulo.\n" ..
           "Esto no lo hace X11 solo: es el programa quien lo mueve.",
    font = "DejaVu Sans 10",
    r = 0.70, g = 0.70, b = 0.75,
    align = "center",
}

local root = W.Group.new {
    orientation = "vertical",
    spacing = 20, padding = 30,
    children = { hint },
}

main:set_root(root)

print("Ventana principal con un popup arrastrable.")
print("Arrastra el popup desde su barra de titulo.")
srv:run()
