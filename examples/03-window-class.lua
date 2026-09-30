local Window = require("lib.window")
local cairo  = require("lib.cairo")
local pango  = require("lib.pango")

local win = Window.new {
    title  = "Clase Window",
    width  = "60%",
    height = "60%",
    aspect = 16/9,
    min_width  = 400,
    min_height = 300,
    x = "center",
    y = "center",

    on_draw = function(cr, w, h)
        cairo.set_rgb(cr, 0.10, 0.10, 0.13)
        cairo.paint(cr)

        pango.draw_text(cr, 30, 30, "Clase Window",
            "DejaVu Sans Bold 22",
            { r = 0.95, g = 0.85, b = 0.30 })

        pango.draw_text(cr, 30, 80,
            string.format("Tamano actual: %d x %d px", w, h),
            "DejaVu Sans 14",
            { r = 0.85, g = 0.85, b = 0.85 })

        pango.draw_text(cr, 30, 110,
            "Aspect declarado: 16:9. El WM lo respeta al redimensionar.",
            "DejaVu Sans 12",
            { r = 0.65, g = 0.65, b = 0.65 })

        pango.draw_text(cr, 30, 140,
            "Pulsa 'q' para salir.",
            "DejaVu Sans 12",
            { r = 0.55, g = 0.55, b = 0.55 })
    end,

    on_resize = function(w, h)
        print(string.format("Resize: %dx%d (aspect = %.3f)", w, h, w / h))
    end,

    on_close = function()
        print("Cerrando...")
    end,
}

print("Ventana creada. Redimensionala con el WM o pulsa 'q'.")
win:run()
print("Adios.")
