-- Prueba de Header, Bignum y KV.

local Server = require("lib.server")
local Window = require("lib.window")
local cairo  = require("lib.cairo")
local W      = require("lib.widgets")

local srv = Server.new()

-- Fila superior: 3 bignums
local bignum_cpu = W.Bignum.new {
    value = "45",
    unit = "%",
    caption = "CPU",
    size = 32,
    color = { 0.55, 0.85, 0.60 },
}

local bignum_ram = W.Bignum.new {
    value = "1.2",
    unit = "GB",
    caption = "RAM usada",
    size = 32,
    color = { 0.65, 0.65, 0.95 },
}

local bignum_temp = W.Bignum.new {
    value = "62",
    unit = "C",
    caption = "Temperatura",
    size = 32,
    color = { 0.95, 0.65, 0.45 },
}

local bignums_row = W.Group.new {
    orientation = "horizontal",
    spacing = 32,
    children = { bignum_cpu, bignum_ram, bignum_temp },
}

local bignums_card = W.Card.new {
    title = "Metricas",
    content = bignums_row,
    padding = 16,
    bg = { 0.14, 0.14, 0.18 },
    border = { 0.28, 0.28, 0.34 },
}

-- KV a la izquierda
local info_kv = W.KV.new {
    key_width = 100,
    row_height = 18,
    row_spacing = 6,
    rows = {
        { id = "kernel",  label = "Kernel" },
        { id = "uptime",  label = "Encendido" },
        { id = "distro",  label = "Distro" },
        { id = "shell",   label = "Shell" },
        { id = "loadavg", label = "Load avg" },
    },
}

local info_card = W.Card.new {
    title = "Sistema",
    content = info_kv,
    padding = 16,
    bg = { 0.14, 0.14, 0.18 },
    border = { 0.28, 0.28, 0.34 },
}

-- Header para specs
local hw_header = W.Header.new {
    text = "<b>Intel HD Graphics</b> (Sandy Bridge GT1) &middot; 32 nm &middot; 6 EU",
    markup = true,
    font = "DejaVu Sans 10",
    color = { 0.75, 0.75, 0.80 },
    valign = "top",
    wrap = true,
}

local hw_card = W.Card.new {
    title = "Hardware",
    content = hw_header,
    padding = 14,
    bg = { 0.14, 0.14, 0.18 },
    border = { 0.28, 0.28, 0.34 },
}

local two_cols = W.Group.new {
    orientation = "horizontal",
    spacing = 16,
    children = { info_card, hw_card },
}

local root = W.Group.new {
    orientation = "vertical",
    spacing = 16,
    padding = 20,
    children = { bignums_card, two_cols },
}

local win = Window.new(srv, {
    title = "KV + Bignum + Header",
    app_name = "lanetk",
    class_name = "LtkKVBignum",
    width = 640,
    height = 320,
    x = "center",
    y = "center",

    on_draw = function(cr, w, h)
        cairo.set_rgb(cr, 0.10, 0.10, 0.13)
        cairo.paint(cr)
    end,
})

win:set_root(root)

-- Valores iniciales
info_kv:set("kernel", "6.6.52_1")
info_kv:set("uptime", "3d 11h 20m")
info_kv:set("distro", "Void Linux")
info_kv:set("shell", "/bin/bash")
info_kv:set("loadavg", "0.42 0.31 0.28")

-- Actualizar CPU cada 500ms para ver el Bignum cambiar
local phase = 0
srv:add_timer(500, function()
    phase = phase + 0.2
    local v = math.floor(50 + 30 * math.sin(phase))
    bignum_cpu:set(tostring(v))
end)

print("KV + Bignum + Header. 'q' para salir.")
srv:run()
print("Adios.")
