-- Prueba del ContextMenu: click derecho sobre cualquier punto de
-- la ventana abre el menu.

local Server = require("lib.server")
local Window = require("lib.window")
local theme  = require("lib.theme")
local W      = require("lib.widgets")
local cairo  = require("lib.cairo")
local xcb    = require("lib.xcb")
local log    = require("lib.log")

local srv = Server.new()
local T = theme.load()
log.info("cm", "paleta: %s", T.path)

local cm = W.ContextMenu.new(srv, nil, T)

local txt = W.Text.new {
    text = "Click derecho en cualquier parte",
    font = "DejaVu Sans 14",
    align = "center",
    r = 0.9, g = 0.9, b = 0.95,
}

local root = W.Group.new {
    orientation = "vertical",
    padding = 30,
    children = { { widget = txt, weight = 1 } },
}

local win
win = Window.new(srv, {
    kind = "normal",
    width = 500, height = 300,
    x = "center", y = "center",
    disable_q_close = true,
    on_draw = function(cr, w, h)
        cairo.set_rgb(cr, 0.10, 0.10, 0.13)
        cairo.paint(cr)
    end,
    on_mouse = function(mx, my, button)
        if button == 3 then
            if not cm.parent_win then
                cm = W.ContextMenu.new(srv, win, T)
            end
            cm:show(mx, my, {
                { label = "Item 1",  on_click = function() print("item 1") end },
                { label = "Item 2",  on_click = function() print("item 2") end },
                { sep = true },
                { label = "Peligroso",
                  color = { 0.9, 0.4, 0.4 },
                  on_click = function() print("peligroso") end },
                { label = "Deshabilitado", enabled = false },
            })
        end
    end,
})

win:set_root(root)

print("Click derecho en cualquier parte para abrir el menu.")
print("Esc o click fuera cierra. Enter sobre un item lo ejecuta.")
srv:run()
