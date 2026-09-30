local Server = require("lib.server")
local Window = require("lib.window")
local cairo  = require("lib.cairo")
local log    = require("lib.log")

local srv = Server.new()

-- Padre VERDE
local main = Window.new(srv, {
    title = "test-main",
    width = 400, height = 300,
    x = "center", y = "center",
    on_draw = function(cr, w, h)
        cairo.set_rgb(cr, 0.2, 0.6, 0.2)
        cairo.paint(cr)
    end,
})
log.info("test", "main creado id=0x%x", tonumber(main.id))

-- Hijo ROJO con borde BLANCO
local popup = Window.new(srv, {
    parent_window = main,
    kind = "child",
    width = 150, height = 80,
    x = 100, y = 100,
    on_draw = function(cr, w, h)
        cairo.set_rgb(cr, 0.9, 0.1, 0.1)
        cairo.paint(cr)
        cairo.set_rgb(cr, 1, 1, 1)
        cairo.set_line_width(cr, 4)
        cairo.rectangle(cr, 2, 2, w - 4, h - 4)
        cairo.stroke(cr)
    end,
})
log.info("test", "popup creado id=0x%x", tonumber(popup.id))

-- Redibujar tras 1 segundo por si el primer draw falló
srv:add_timer(1000, function()
    log.info("test", "redibujando popup (t=1s)")
    popup:damage_all()
    popup:draw()
end)

print("VERDE = main.  Dentro, un cuadrado ROJO con borde BLANCO.")
print("Si tras 1 segundo no aparece el rojo, algo falla en el draw.")
srv:run()
