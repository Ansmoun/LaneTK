local Server = require("lib.server")
local Window = require("lib.window")
local cairo  = require("lib.cairo")
local W      = require("lib.widgets")

local srv = Server.new()

-- BarRow con 4 metricas
local recursos = W.BarRow.new {
    left_width   = 60,
    pct_width    = 44,
    detail_width = 120,
    row_height   = 16,
    warn_at      = 0.60,
    crit_at      = 0.85,
    rows = {
        { id = "cpu",  label = "CPU" },
        { id = "ram",  label = "RAM" },
        { id = "disk", label = "Disco" },
        { id = "net",  label = "Red" },
    },
}

local recursos_card = W.Card.new {
    title = "Recursos",
    content = recursos,
    padding = 14,
    bg = { 0.14, 0.14, 0.18 },
    border = { 0.28, 0.28, 0.34 },
}

-- Motors: nucleos
local nucleos = W.Motors.new {
    left_width = 26,
    bar_height = 8,
    row_height = 12,
    rows = {
        { id = "c0", label = "C0" },
        { id = "c1", label = "C1" },
    },
}

local nucleos_card = W.Card.new {
    title = "Nucleos",
    content = nucleos,
    padding = 14,
    bg = { 0.14, 0.14, 0.18 },
    border = { 0.28, 0.28, 0.34 },
}

-- DualSpark
local historia = W.DualSpark.new {
    samples = 60,
    color_a = "#8ec07c",
    color_b = "#e06060",
    fill_a = true,
    fill_b = false,
    auto_max = true,
    floor_max = 10240,
    axis_width = 40,
    axis_format = "%dK",
    grid = true,
    min_width = 260,
    min_height = 100,
}

local historia_card = W.Card.new {
    title = "Historia (60s)",
    content = historia,
    padding = 14,
    bg = { 0.14, 0.14, 0.18 },
    border = { 0.28, 0.28, 0.34 },
}

local top_row = W.Group.new {
    orientation = "horizontal",
    spacing = 16,
    children = { recursos_card, nucleos_card },
}

local root = W.Group.new {
    orientation = "vertical",
    spacing = 16,
    padding = 20,
    children = { top_row, historia_card },
}

local win = Window.new(srv, {
    title = "BarRow + Motors + DualSpark",
    app_name = "lanetk",
    class_name = "LtkBarrow",
    width  = 640,
    height = 380,
    x = "center", y = "center",

    on_draw = function(cr, w, h)
        cairo.set_rgb(cr, 0.10, 0.10, 0.13)
        cairo.paint(cr)
    end,
})

win:set_root(root)

-- Timer de 300ms: mover todos los valores
local phase = 0
srv:add_timer(300, function()
    phase = phase + 0.12

    local cpu  = 0.5 + 0.4 * math.sin(phase)
    local ram  = 0.5 + 0.2 * math.cos(phase * 0.7)
    local disk = 0.3 + 0.5 * math.sin(phase * 0.4)
    local net  = 0.2 + 0.6 * math.abs(math.sin(phase * 1.5))

    recursos:set("cpu",  { pct = cpu,  detail = string.format("%d%%", math.floor(cpu*100)) })
    recursos:set("ram",  { pct = ram,  detail = string.format("%.1f GB", ram * 4) })
    recursos:set("disk", { pct = disk, detail = string.format("%d%% leido", math.floor(disk*100)) })
    recursos:set("net",  { pct = net,  detail = string.format("%.1f MB/s", net * 12) })

    nucleos:set("c0", 0.5 + 0.45 * math.sin(phase))
    nucleos:set("c1", 0.5 + 0.45 * math.cos(phase))

    historia:push_a(10240 + 8000 * math.sin(phase))
    historia:push_b(5120 + 4000 * math.cos(phase * 1.3))
end)

print("BarRow + Motors + DualSpark. 'q' para salir.")
srv:run()
print("Adios.")
