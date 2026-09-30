-- Prueba de Button con hover y click.
-- Un contador que se incrementa al pulsar.

local Window = require("lib.window")
local cairo  = require("lib.cairo")
local pango  = require("lib.pango")
local W      = require("lib.widgets")

local count = 0

local title = W.Text.new {
    text  = "Button",
    font  = "DejaVu Sans Bold 22",
    r = 0.95, g = 0.85, b = 0.30,
    align = "center",
}

local counter_label = W.Text.new {
    text  = "0 clicks",
    font  = "DejaVu Sans 14",
    r = 0.85, g = 0.85, b = 0.85,
    align = "center",
}

local click_btn = W.Button.new {
    text = "Click me",
    on_click = function(self, button)
        count = count + 1
        counter_label:set_text(string.format("%d clicks", count))
        print(string.format("click #%d (boton %d)", count, button))
    end,
}

local reset_btn = W.Button.new {
    text = "Reset",
    color_normal  = { 0.30, 0.15, 0.15 },
    color_hover   = { 0.40, 0.20, 0.20 },
    color_pressed = { 0.20, 0.10, 0.10 },
    color_border  = { 0.60, 0.35, 0.35 },
    on_click = function()
        count = 0
        counter_label:set_text("0 clicks")
        print("reset")
    end,
}

local buttons_row = W.Group.new {
    orientation = "horizontal",
    spacing = 16,
    children = { click_btn, reset_btn },
}

local footer = W.Text.new {
    text = "Pasa el raton sobre los botones. Click para actuar. 'q' sale.",
    font = "DejaVu Sans 11",
    r = 0.55, g = 0.55, b = 0.55,
    align = "center",
}

local root = W.Group.new {
    orientation = "vertical",
    spacing = 20,
    padding = 30,
    children = { title, counter_label, buttons_row, footer },
}

local win = Window.new {
    title  = "Button demo",
    app_name  = "lanetk",
    class_name = "LtkButton",
    width  = 500,
    height = 320,
    x = "center",
    y = "center",

    on_draw = function(cr, w, h)
        cairo.set_rgb(cr, 0.10, 0.10, 0.13)
        cairo.paint(cr)
    end,
}

win:set_root(root)
print("Ventana lista. Prueba hover, click, reset. 'q' para salir.")
win:run()
print("Adios.")
