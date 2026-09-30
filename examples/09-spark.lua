-- Prueba de Spark: sparkline animada que simula CPU con historial.

local Server = require("lib.server")
local Window = require("lib.window")
local cairo  = require("lib.cairo")
local W      = require("lib.widgets")

local srv = Server.new()

local cpu_spark = W.Spark.new {
    samples = 60,
    min = 0, max = 100,
    color = "#8ec07c",
    fill = true,
    axis_width = 30,
    axis_format = "%d%%",
    grid = true,
    min_width  = 300,
    min_height = 120,
}

local cpu_card = W.Card.new {
    title   = "CPU (historial)",
    content = cpu_spark,
    padding = 12,
    bg      = { 0.14, 0.14, 0.18 },
    border  = { 0.28, 0.28, 0.34 },
}

local footer = W.Text.new {
    text = "Historial circular de 60 muestras. Timer de 200ms.",
    font = "DejaVu Sans 11",
    r = 0.55, g = 0.55, b = 0.55,
    align = "center",
}

local root = W.Group.new {
    orientation = "vertical",
    spacing = 16,
    padding = 20,
    children = { cpu_card, footer },
}

local win = Window.new(srv, {
    title  = "Spark demo",
    app_name  = "lanetk",
    class_name = "LtkSpark",
    width  = 480,
    height = 260,
    x = "center",
    y = "center",

    on_draw = function(cr, w, h)
        cairo.set_rgb(cr, 0.10, 0.10, 0.13)
        cairo.paint(cr)
    end,
})

win:set_root(root)

local phase = 0
srv:add_timer(200, function()
    phase = phase + 0.15
    -- Media 50%, oscila +-35%, con un poco de ruido
    local v = 50 + 35 * math.sin(phase) + (math.random() - 0.5) * 8
    if v < 0 then v = 0 end
    if v > 100 then v = 100 end
    cpu_spark:push(v)
end)

print("Ventana con sparkline animada. 'q' para salir.")
srv:run()
print("Adios.")
