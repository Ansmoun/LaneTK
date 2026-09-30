local Server = require("lib.server")
local Window = require("lib.window")
local cairo  = require("lib.cairo")

local srv = Server.new()

local main = Window.new(srv, {
    title = "main",
    width = 500, height = 400,
    x = "center", y = "center",
    on_draw = function(cr, w, h)
        cairo.set_rgb(cr, 0.10, 0.10, 0.13)
        cairo.paint(cr)
        -- Marco gris: donde deberia estar el popup (50,50 a 250,150)
        cairo.set_rgb(cr, 0.30, 0.30, 0.30)
        cairo.set_line_width(cr, 1)
        cairo.rectangle(cr, 50, 50, 200, 100)
        cairo.stroke(cr)
    end,
})

local popup = Window.new(srv, {
    parent_window = main,
    kind = "child",
    width = 200, height = 100,
    x = 50, y = 50,
    on_draw = function(cr, w, h)
        cairo.set_rgb(cr, 0.9, 0.2, 0.2)
        cairo.paint(cr)
        cairo.set_rgb(cr, 1, 1, 1)
        cairo.set_line_width(cr, 3)
        cairo.rectangle(cr, 2, 2, w - 4, h - 4)
        cairo.stroke(cr)
    end,
})

print(string.format("main  id=0x%x", tonumber(main.id)))
print(string.format("popup id=0x%x", tonumber(popup.id)))
print("")
print("En otra terminal, mientras esto corre:")
print(string.format("  xwininfo -id 0x%x", tonumber(popup.id)))
print(string.format("  xwininfo -id 0x%x -tree", tonumber(main.id)))

srv:run()
