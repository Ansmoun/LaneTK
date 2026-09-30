-- Panel con sub-tabs.
-- Replica la estructura del panel original:
--   Recursos  -> General / CPU / RAM / GPU
--   Sistema   -> Kernel / Hardware

local Server = require("lib.server")
local Panel  = require("lib.panel")
local W      = require("lib.widgets")
local cairo  = require("lib.cairo")

local srv = Server.new()

-- ============================================================
-- Sub-tabs de "Recursos"
-- ============================================================

local function sub_general()
    print("[recursos/general] construyendo")
    local bars = W.BarRow.new {
        left_width = 60, pct_width = 44, detail_width = 100,
        row_height = 18, warn_at = 0.7, crit_at = 0.9,
        rows = {
            { id = "cpu",  label = "CPU" },
            { id = "ram",  label = "RAM" },
            { id = "gpu",  label = "GPU" },
            { id = "swap", label = "SWAP" },
        },
    }
    local card = W.Card.new {
        title = "Uso general", content = bars, padding = 14,
        bg = {0.14,0.14,0.18}, border = {0.28,0.28,0.34},
    }
    local timer, phase = nil, 0
    return {
        widget = card,
        start = function()
            timer = srv:add_timer(500, function()
                phase = phase + 0.12
                bars:set("cpu",  { pct = 0.5 + 0.3*math.sin(phase),  detail = "1.8 GHz" })
                bars:set("ram",  { pct = 0.4 + 0.2*math.cos(phase),  detail = "1.6 GB" })
                bars:set("gpu",  { pct = 0.3 + 0.3*math.abs(math.sin(phase*1.5)), detail = "45 C" })
                bars:set("swap", { pct = 0.10, detail = "0.2 GB" })
            end)
        end,
        stop = function() if timer then timer:cancel() end end,
    }
end

local function sub_cpu()
    print("[recursos/cpu] construyendo")
    local ring = W.Ring.new {
        text = "0%", sub = "CPU",
        color = { 0.55, 0.85, 0.60 }, size = 160, thickness = 12,
    }
    local motors = W.Motors.new {
        left_width = 30, bar_height = 8, row_height = 14,
        rows = {
            { id = "c0", label = "C0" },
            { id = "c1", label = "C1" },
        },
    }
    local row = W.Group.new {
        orientation = "horizontal", spacing = 16,
        children = {
            W.Card.new { title="Uso", content=ring, padding=14,
                         bg={0.14,0.14,0.18}, border={0.28,0.28,0.34} },
            W.Card.new { title="Nucleos", content=motors, padding=14,
                         bg={0.14,0.14,0.18}, border={0.28,0.28,0.34} },
        },
    }
    local timer, phase = nil, 0
    return {
        widget = row,
        start = function()
            timer = srv:add_timer(400, function()
                phase = phase + 0.15
                local v = 0.5 + 0.4*math.sin(phase)
                ring:set_value(v, string.format("%d%%", math.floor(v*100)),
                    "CPU")
                motors:set("c0", 0.5 + 0.45*math.sin(phase))
                motors:set("c1", 0.5 + 0.45*math.cos(phase))
            end)
        end,
        stop = function() if timer then timer:cancel() end end,
    }
end

local function sub_ram()
    print("[recursos/ram] construyendo")
    local rows = W.Rows.new {
        group_width = 60, name_width = 100, value_width = 80,
        rows = {
            { id="total", group="Total", name="Fisica" },
            { id="used",  group="Usado", name="Real" },
            { id="cache", group="Cache", name="Buffers" },
            { id="swap",  group="Swap",  name="Total" },
        }
    }
    local card = W.Card.new {
        title="Memoria", content=rows, padding=14,
        bg={0.14,0.14,0.18}, border={0.28,0.28,0.34},
    }
    local timer, phase = nil, 0
    return {
        widget = card,
        start = function()
            timer = srv:add_timer(1000, function()
                phase = phase + 0.1
                rows:set("total", "3.8 GB")
                rows:set("used",  string.format("%.1f GB", 1.4 + 0.3*math.sin(phase)))
                rows:set("cache", string.format("%.1f GB", 0.6 + 0.1*math.cos(phase)))
                rows:set("swap",  "2.0 GB")
            end)
        end,
        stop = function() if timer then timer:cancel() end end,
    }
end

local function sub_gpu()
    print("[recursos/gpu] construyendo")
    local hist = W.Spark.new {
        samples = 60, min = 0, max = 100,
        color = "#a070e0", fill = true,
        axis_width = 30, axis_format = "%d%%", grid = true,
        min_width = 300, min_height = 140,
    }
    local card = W.Card.new {
        title="GPU (historia)", content=hist, padding=14,
        bg={0.14,0.14,0.18}, border={0.28,0.28,0.34},
    }
    local timer, phase = nil, 0
    return {
        widget = card,
        start = function()
            timer = srv:add_timer(300, function()
                phase = phase + 0.1
                hist:push(40 + 35*math.sin(phase) + (math.random()-0.5)*8)
            end)
        end,
        stop = function() if timer then timer:cancel() end end,
    }
end

-- ============================================================
-- Tab padre "Recursos" con sub-tabs
-- ============================================================

local function make_recursos_tab()
    print("[recursos] construyendo TabbedPanel")
    local inner = W.TabbedPanel.new {
        tabs = {
            { id = "general", label = "General", factory = sub_general },
            { id = "cpu",     label = "CPU",     factory = sub_cpu },
            { id = "ram",     label = "RAM",     factory = sub_ram },
            { id = "gpu",     label = "GPU",     factory = sub_gpu },
        },
    }
    -- El padre no necesita start/stop; el TabbedPanel interno
    -- los maneja por su cuenta al cambiar sub-tab.
    return { widget = inner }
end

-- ============================================================
-- Tab padre "Sistema"
-- ============================================================

local function make_sistema_tab()
    print("[sistema] construyendo")
    local kv = W.KV.new {
        key_width = 120, row_height = 20, row_spacing = 8,
        rows = {
            { id = "kernel", label = "Kernel" },
            { id = "distro", label = "Distro" },
            { id = "uptime", label = "Encendido" },
        }
    }
    local card = W.Card.new {
        title="Sistema", content=kv, padding=16,
        bg={0.14,0.14,0.18}, border={0.28,0.28,0.34},
    }
    return {
        widget = card,
        start = function()
            kv:set("kernel", "6.6.52_1")
            kv:set("distro", "Void Linux")
            kv:set("uptime", "3d 11h 20m")
        end,
    }
end

-- ============================================================
-- Panel principal
-- ============================================================
local panel = Panel.new {
    server = srv,
    kind = "normal",
    title = "Panel con sub-tabs",
    width = "75%", height = "75%",
    x = "center", y = "center",
    tabs = {
        { id = "recursos", label = "Recursos", factory = make_recursos_tab },
        { id = "sistema",  label = "Sistema",  factory = make_sistema_tab },
    },
}

print("Panel con 2 tabs, uno tiene 4 sub-tabs.")
print("Observa el log: la primera vez que abres cada sub-tab,")
print("se construye. Al volver, solo se hace start/stop.")
srv:run()
