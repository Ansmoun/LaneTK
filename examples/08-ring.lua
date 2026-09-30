-- Prueba de Card + Ring + timers.
-- Un anillo que oscila simulando una metrica viva.

local Server = require("lib.server")
local Window = require("lib.window")
local cairo  = require("lib.cairo")
local W      = require("lib.widgets")

local srv = Server.new()

-- Ring de CPU
local cpu_ring = W.Ring.new {
    text = "0%",
    sub  = "0.0 GHz",
    color = { 0.40, 0.75, 0.55 },
    size = 160,
    thickness = 12,
}

-- Ring de RAM
local ram_ring = W.Ring.new {
    text = "0%",
    sub  = "0 MB",
    color = { 0.55, 0.55, 0.95 },
    size = 160,
    thickness = 12,
}

-- Card CPU
local cpu_card = W.Card.new {
    title   = "CPU",
    content = cpu_ring,
    padding = 12,
    bg      = { 0.14, 0.14, 0.18 },
    border  = { 0.28, 0.28, 0.34 },
}

-- Card RAM
local ram_card = W.Card.new {
    title   = "RAM",
    content = ram_ring,
    padding = 12,
    bg      = { 0.14, 0.14, 0.18 },
    border  = { 0.28, 0.28, 0.34 },
}

local row = W.Group.new {
    orientation = "horizontal",
    spacing = 16,
    children = { cpu_card, ram_card },
}

local footer = W.Text.new {
    text = "Datos simulados. Timer de 500ms. 'q' para salir.",
    font = "DejaVu Sans 11",
    r = 0.55, g = 0.55, b = 0.55,
    align = "center",
}

local root = W.Group.new {
    orientation = "vertical",
    spacing = 16,
    padding = 20,
    children = { row, footer },
}

local win = Window.new(srv, {
    title  = "Card + Ring + Timer",
    app_name  = "lanetk",
    class_name = "LtkRing",
    width  = 480,
    height = 300,
    x = "center",
    y = "center",

    on_draw = function(cr, w, h)
        cairo.set_rgb(cr, 0.10, 0.10, 0.13)
        cairo.paint(cr)
    end,
})

win:set_root(root)

-- Timer que actualiza los valores
local phase = 0
srv:add_timer(500, function()
    phase = phase + 0.15
    -- CPU oscila 15-85%
    local cpu = 0.5 + 0.35 * math.sin(phase)
    cpu_ring:set_value(cpu,
        string.format("%d%%", math.floor(cpu * 100)),
        string.format("%.1f GHz", 1.0 + cpu * 1.2))

    -- RAM oscila 30-70%
    local ram = 0.5 + 0.2 * math.cos(phase * 0.7)
    ram_ring:set_value(ram,
        string.format("%d%%", math.floor(ram * 100)),
        string.format("%d MB", math.floor(2000 + ram * 2000)))
    -- win:draw() ya no se llama: set_value marca damage y el server
    -- repinta solo esa region.
end)

print("Ventana con 2 rings animandose. 'q' para salir.")
srv:run()
print("Adios.")
