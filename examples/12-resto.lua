local Server = require("lib.server")
local Window = require("lib.window")
local cairo  = require("lib.cairo")
local W      = require("lib.widgets")

local srv = Server.new()

-- Pills arriba
local pills = W.Pills.new {
    items = {
        { id = "up",   text = "OK",     color = "#8ec07c" },
        { id = "warn", text = "WARN",   color = "#e5b567" },
        { id = "err",  text = "ERROR",  color = "#e06060" },
        { id = "info", text = "INFO",   color = "#83a598" },
    },
}

local pills_card = W.Card.new {
    title = "Estado",
    content = pills,
    padding = 12,
    bg = { 0.14, 0.14, 0.18 },
    border = { 0.28, 0.28, 0.34 },
}

-- Rows de sensores
local sensores = W.Rows.new {
    group_width = 40,
    name_width  = 110,
    value_width = 70,
    rows = {
        { id = "t1", group = "CPU", name = "Package" },
        { id = "t2", group = "CPU", name = "Core 0" },
        { id = "t3", group = "SSD", name = "Temp" },
        { id = "t4", group = "Fan", name = "RPM" },
    },
}

local sensores_card = W.Card.new {
    title = "Sensores",
    content = sensores,
    padding = 12,
    bg = { 0.14, 0.14, 0.18 },
    border = { 0.28, 0.28, 0.34 },
}

-- BarMulti: uso de CPU por nucleo
local breakdown = W.BarMulti.new {
    legend_cols = 2,
    bar_height = 16,
    segments = {
        { id = "usr", color = "#8ec07c", label = "Usuario" },
        { id = "sys", color = "#83a598", label = "Sistema" },
        { id = "iow", color = "#e5b567", label = "I/O Wait" },
        { id = "idle", color = "#3c3836", label = "Idle" },
    },
}

local breakdown_card = W.Card.new {
    title = "Breakdown",
    content = breakdown,
    padding = 12,
    bg = { 0.14, 0.14, 0.18 },
    border = { 0.28, 0.28, 0.34 },
}

-- Actions
local acciones = W.Actions.new {
    button_width = 160,
    actions = {
        { label = "Limpiar cache", cmd = "true",        ok_msg = "Cache limpiada" },
        { label = "Sync discos",   cmd = "sync",        ok_msg = "Discos sincronizados" },
        { label = "Probar fallo",  cmd = "false",       ok_msg = "No deberia verse" },
    },
}

local acciones_card = W.Card.new {
    title = "Acciones",
    content = acciones,
    padding = 12,
    bg = { 0.14, 0.14, 0.18 },
    border = { 0.28, 0.28, 0.34 },
}

-- Layout: 2x2
local top_row = W.Group.new {
    orientation = "horizontal", spacing = 12,
    children = { pills_card, sensores_card },
}
local bot_row = W.Group.new {
    orientation = "horizontal", spacing = 12,
    children = { breakdown_card, acciones_card },
}

local root = W.Group.new {
    orientation = "vertical", spacing = 12, padding = 16,
    children = { top_row, bot_row },
}

local win = Window.new(srv, {
    title = "Resto de vistas",
    app_name = "lanetk", class_name = "LtkResto",
    width = 720, height = 380,
    x = "center", y = "center",
    on_draw = function(cr, w, h)
        cairo.set_rgb(cr, 0.10, 0.10, 0.13); cairo.paint(cr)
    end,
})

win:set_root(root)

-- Valores dinamicos
local phase = 0
srv:add_timer(500, function()
    phase = phase + 0.15
    sensores:set("t1", string.format("%d C", math.floor(60 + 10*math.sin(phase))))
    sensores:set("t2", string.format("%d C", math.floor(55 + 8*math.cos(phase))))
    sensores:set("t3", string.format("%d C", math.floor(35 + 5*math.sin(phase*1.3))))
    sensores:set("t4", string.format("%d", math.floor(1200 + 300*math.sin(phase*2))))

    local usr = 0.3 + 0.2 * math.sin(phase)
    local sys = 0.15 + 0.1 * math.cos(phase)
    local iow = 0.05 + 0.05 * math.abs(math.sin(phase*1.5))
    local idle = 1 - usr - sys - iow
    breakdown:set({
        { id = "usr",  pct = usr,  value_str = string.format("%.0f%%", usr*100) },
        { id = "sys",  pct = sys,  value_str = string.format("%.0f%%", sys*100) },
        { id = "iow",  pct = iow,  value_str = string.format("%.0f%%", iow*100) },
        { id = "idle", pct = idle, value_str = string.format("%.0f%%", idle*100) },
    })

    -- Cambiar pills cada cierto tiempo
    if math.floor(phase * 10) % 5 == 0 then
        pills:set_color("up", "#8ec07c")
    else
        pills:set_color("up", "#5a8a4c")
    end
end)

print("Rows + BarMulti + Actions + Pills. 'q' para salir.")
print("Prueba los botones: Limpiar cache, Sync discos (OK) / Probar fallo (error).")
srv:run()
print("Adios.")
