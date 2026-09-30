-- Prueba de Stack + TabsBar.
-- Tres paginas con contenido distinto, navegacion con tabs.

local Server = require("lib.server")
local Window = require("lib.window")
local cairo  = require("lib.cairo")
local W      = require("lib.widgets")

local srv = Server.new()

-- Pagina 1: un anillo
local page1_ring = W.Ring.new {
    text = "45%", sub = "CPU",
    color = { 0.55, 0.85, 0.60 },
    size = 160, thickness = 12,
}
local page1 = W.Card.new {
    title = "Anillo",
    content = page1_ring,
    padding = 14,
    bg = { 0.14, 0.14, 0.18 },
    border = { 0.28, 0.28, 0.34 },
}

-- Pagina 2: bignums
local page2_row = W.Group.new {
    orientation = "horizontal", spacing = 24,
    children = {
        W.Bignum.new { value = "1.2", unit = "GB", caption = "RAM", size = 32 },
        W.Bignum.new { value = "62",  unit = "C",  caption = "Temp", size = 32,
                       color = { 0.95, 0.65, 0.45 } },
    },
}
local page2 = W.Card.new {
    title = "Numeros",
    content = page2_row,
    padding = 14,
    bg = { 0.14, 0.14, 0.18 },
    border = { 0.28, 0.28, 0.34 },
}

-- Pagina 3: kv
local page3_kv = W.KV.new {
    key_width = 100, row_height = 18, row_spacing = 6,
    rows = {
        { id = "kernel", label = "Kernel" },
        { id = "uptime", label = "Uptime" },
        { id = "distro", label = "Distro" },
    },
}
local page3 = W.Card.new {
    title = "Sistema",
    content = page3_kv,
    padding = 14,
    bg = { 0.14, 0.14, 0.18 },
    border = { 0.28, 0.28, 0.34 },
}

-- Stack con las 3 paginas
local stack = W.Stack.new {}
stack:add("ring", page1)
stack:add("nums", page2)
stack:add("sys",  page3)

-- TabsBar
local tabs = W.TabsBar.new {
    items = {
        { id = "ring", label = "Anillo" },
        { id = "nums", label = "Numeros" },
        { id = "sys",  label = "Sistema" },
    },
    active = "ring",
    on_select = function(id)
        stack:set_active(id)
    end,
}

local root = W.Group.new {
    orientation = "vertical",
    spacing = 12,
    padding = 16,
    children = { tabs, stack },
}

local win = Window.new(srv, {
    title = "Stack + TabsBar",
    app_name = "lanetk", class_name = "LtkTabs",
    width = 480, height = 340,
    x = "center", y = "center",
    on_draw = function(cr, w, h)
        cairo.set_rgb(cr, 0.10, 0.10, 0.13)
        cairo.paint(cr)
    end,
})

win:set_root(root)

-- Poblar valores
page3_kv:set("kernel", "6.6.52_1")
page3_kv:set("uptime", "3d 11h 20m")
page3_kv:set("distro", "Void Linux")

-- Animar el ring
local phase = 0
srv:add_timer(500, function()
    phase = phase + 0.15
    local v = 0.5 + 0.3 * math.sin(phase)
    page1_ring:set_value(v,
        string.format("%d%%", math.floor(v * 100)),
        "CPU")
end)

print("Click en los tabs para cambiar de pagina. 'q' para salir.")
srv:run()
print("Adios.")
