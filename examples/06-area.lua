-- Prueba de Area + Group + Text.
-- Jerarquia:
--   Group vertical
--     Text titulo (center)
--     Group horizontal (con spacing)
--       Text "A"
--       Text "B"
--       Text "C"
--     Text pie

local Window = require("lib.window")
local cairo  = require("lib.cairo")
local pango  = require("lib.pango")
local W      = require("lib.widgets")

local title = W.Text.new {
    text  = "Area + Group + Text",
    font  = "DejaVu Sans Bold 22",
    r = 0.95, g = 0.85, b = 0.30,
    align = "center",
}

local a = W.Text.new {
    text = "A",
    font = "DejaVu Sans Bold 40",
    r = 0.90, g = 0.35, b = 0.40,
    align = "center",
}
local b = W.Text.new {
    text = "B",
    font = "DejaVu Sans Bold 40",
    r = 0.35, g = 0.75, b = 0.45,
    align = "center",
}
local c = W.Text.new {
    text = "C",
    font = "DejaVu Sans Bold 40",
    r = 0.40, g = 0.55, b = 0.95,
    align = "center",
}

local row = W.Group.new {
    orientation = "horizontal",
    spacing = 20,
    children = { a, b, c },
}

local footer = W.Text.new {
    text = "Pulsa 'q' para salir.",
    font = "DejaVu Sans 11",
    r = 0.55, g = 0.55, b = 0.55,
    align = "center",
}

local root = W.Group.new {
    orientation = "vertical",
    spacing = 16,
    padding = 24,
    children = { title, row, footer },
}

local win = Window.new {
    title  = "Area demo",
    app_name  = "lanetk",
    class_name = "LtkArea",
    width  = "50%",
    height = "50%",
    x = "center",
    y = "center",

    on_draw = function(cr, w, h)
        cairo.set_rgb(cr, 0.10, 0.10, 0.13)
        cairo.paint(cr)
    end,
}

win:set_root(root)
print("Ventana creada. Redimensionala para ver el layout adaptarse.")
win:run()
print("Adios.")
