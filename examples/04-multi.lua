-- Prueba multi-ventana con logs.
-- Uso:
--   LANETK_LOG=debug ~/proyectos/lanetk/run examples/04-multi.lua
--   LANETK_LOG=trace ~/proyectos/lanetk/run examples/04-multi.lua   (verboso)
--
-- Cada ventana imprime su id. Para monitorear con xev desde otra terminal:
--   xev -id 0x<id>

local Server = require("lib.server")
local Window = require("lib.window")
local cairo  = require("lib.cairo")
local pango  = require("lib.pango")

local srv = Server.new()

local function make_win(title, x, y, w, h, color)
    return Window.new(srv, {
        title  = title,
        app_name = "lanetk",
        class_name = "LtkDemo",
        width  = w, height = h,
        x = x, y = y,

        on_draw = function(cr, cw, ch)
            cairo.set_rgb(cr, color[1], color[2], color[3])
            cairo.paint(cr)

            pango.draw_text(cr, 20, 20, title,
                "DejaVu Sans Bold 18",
                { r = 1, g = 1, b = 1 })

            pango.draw_text(cr, 20, 60,
                string.format("Tamano: %d x %d", cw, ch),
                "DejaVu Sans 12",
                { r = 0.85, g = 0.85, b = 0.85 })

            pango.draw_text(cr, 20, 85,
                "Pulsa 'q' aqui o Mod4+Shift+Q desde el WM.",
                "DejaVu Sans 10",
                { r = 0.65, g = 0.65, b = 0.65 })
        end,

        on_key = function(keycode, state)
            print(string.format("[%s] on_key keycode=%d state=0x%x",
                title, keycode, state))
        end,

        on_close = function()
            print("Cerrando: " .. title)
        end,
    })
end

local wa = make_win("Ventana A", 50,  50,  400, 250, {0.15, 0.20, 0.35})
local wb = make_win("Ventana B", 500, 150, 450, 300, {0.30, 0.15, 0.20})
local wc = make_win("Ventana C", 250, 400, 350, 200, {0.15, 0.30, 0.20})

print(string.format("3 ventanas creadas: A=0x%x B=0x%x C=0x%x",
    tonumber(wa.id), tonumber(wb.id), tonumber(wc.id)))
print("")
print("Para monitorear eventos reales desde otra terminal:")
print(string.format("  xev -id 0x%x", tonumber(wa.id)))
print("")
print("Cierra todas con 'q' o Mod4+Shift+Q. El server termina al vaciarse.")
print("----------------------------------------")

srv:run()
print("----------------------------------------")
print("Server terminado.")
