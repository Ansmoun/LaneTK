-- Panel con tabs y carga bajo demanda.
-- Cada tab es un modulo que expone { widget, start, stop }.
-- El widget solo se construye la primera vez que se abre.

local Server = require("lib.server")
local Panel  = require("lib.panel")
local W      = require("lib.widgets")
local cairo  = require("lib.cairo")

local srv = Server.new()

-- ============================================================
-- Tab 1: CPU (Ring + KV)
-- ============================================================
local function make_cpu_tab()
    print("[cpu] construyendo widget")
    local ring = W.Ring.new {
        text = "0%", sub = "CPU",
        color = { 0.55, 0.85, 0.60 },
        size = 160, thickness = 12,
    }
    local kv = W.KV.new {
        key_width = 100, row_height = 18, row_spacing = 6,
        rows = {
            { id = "model", label = "Modelo" },
            { id = "cores", label = "Nucleos" },
            { id = "freq",  label = "Frecuencia" },
        }
    }
    local row = W.Group.new {
        orientation = "horizontal", spacing = 16,
        children = {
            W.Card.new { title = "Uso", content = ring, padding = 14,
                         bg = {0.14, 0.14, 0.18}, border = {0.28, 0.28, 0.34} },
            W.Card.new { title = "Info", content = kv, padding = 14,
                         bg = {0.14, 0.14, 0.18}, border = {0.28, 0.28, 0.34} },
        },
    }

    local timer, phase = nil, 0
    return {
        widget = row,
        start = function()
            print("[cpu] start")
            kv:set("model", "Intel Celeron 847")
            kv:set("cores", "2")
            timer = srv:add_timer(500, function()
                phase = phase + 0.12
                local v = 0.5 + 0.35 * math.sin(phase)
                ring:set_value(v,
                    string.format("%d%%", math.floor(v * 100)),
                    string.format("%.1f GHz", 1.0 + v * 1.2))
                kv:set("freq", string.format("%.1f GHz", 1.0 + v * 1.2))
            end)
        end,
        stop = function()
            print("[cpu] stop")
            if timer then timer:cancel() end
        end,
    }
end

-- ============================================================
-- Tab 2: RAM (BarRow)
-- ============================================================
local function make_ram_tab()
    print("[ram] construyendo widget")
    local bar = W.BarRow.new {
        left_width = 70, pct_width = 44, detail_width = 120,
        row_height = 18, warn_at = 0.7, crit_at = 0.9,
        rows = {
            { id = "used", label = "Usado" },
            { id = "cache", label = "Cache" },
            { id = "free", label = "Libre" },
            { id = "swap", label = "Swap" },
        },
    }
    local card = W.Card.new {
        title = "Memoria", content = bar, padding = 14,
        bg = {0.14, 0.14, 0.18}, border = {0.28, 0.28, 0.34},
    }

    local timer, phase = nil, 0
    return {
        widget = card,
        start = function()
            print("[ram] start")
            timer = srv:add_timer(500, function()
                phase = phase + 0.1
                local used  = 0.45 + 0.15 * math.sin(phase)
                local cache = 0.20 + 0.10 * math.cos(phase * 0.7)
                local free  = 1 - used - cache
                if free < 0 then free = 0 end
                bar:set("used",  { pct = used,  detail = string.format("%.1f GB", used * 4) })
                bar:set("cache", { pct = cache, detail = string.format("%.1f GB", cache * 4) })
                bar:set("free",  { pct = free,  detail = string.format("%.1f GB", free * 4) })
                bar:set("swap",  { pct = 0.10,  detail = "0.2 GB" })
            end)
        end,
        stop = function()
            print("[ram] stop")
            if timer then timer:cancel() end
        end,
    }
end

-- ============================================================
-- Tab 3: Historia (DualSpark)
-- ============================================================
local function make_hist_tab()
    print("[hist] construyendo widget")
    local dsp = W.DualSpark.new {
        samples = 60,
        color_a = "#8ec07c",
        color_b = "#e06060",
        fill_a = true,
        auto_max = true,
        floor_max = 100,
        axis_width = 40,
        axis_format = "%d%%",
        grid = true,
        min_width = 300, min_height = 140,
    }
    local card = W.Card.new {
        title = "Historia (CPU / RAM)",
        content = dsp, padding = 14,
        bg = {0.14, 0.14, 0.18}, border = {0.28, 0.28, 0.34},
    }

    local timer, phase = nil, 0
    return {
        widget = card,
        start = function()
            print("[hist] start")
            timer = srv:add_timer(300, function()
                phase = phase + 0.15
                dsp:push_a(50 + 30 * math.sin(phase))
                dsp:push_b(45 + 25 * math.cos(phase * 1.3))
            end)
        end,
        stop = function()
            print("[hist] stop")
            if timer then timer:cancel() end
        end,
    }
end

-- ============================================================
-- Tab 4: Sistema (KV estatico)
-- ============================================================
local function make_sys_tab()
    print("[sys] construyendo widget")
    local kv = W.KV.new {
        key_width = 120, row_height = 20, row_spacing = 8,
        rows = {
            { id = "kernel", label = "Kernel" },
            { id = "distro", label = "Distro" },
            { id = "uptime", label = "Encendido" },
            { id = "shell",  label = "Shell" },
            { id = "user",   label = "Usuario" },
        }
    }
    local card = W.Card.new {
        title = "Sistema", content = kv, padding = 16,
        bg = {0.14, 0.14, 0.18}, border = {0.28, 0.28, 0.34},
    }
    return {
        widget = card,
        start = function()
            print("[sys] start")
            kv:set("kernel", "6.6.52_1")
            kv:set("distro", "Void Linux")
            kv:set("uptime", "3d 11h 20m")
            kv:set("shell",  "/bin/bash")
            kv:set("user",   "ansmoun")
        end,
        -- sin stop: no hay timer
    }
end

-- ============================================================
-- Panel
-- ============================================================
local panel = Panel.new {
    server = srv,
    kind = "normal",
    title = "Panel de sistema",
    width = "70%", height = "70%",
    x = "center", y = "center",
    tabs = {
        { id = "cpu",  label = "CPU",      factory = make_cpu_tab },
        { id = "ram",  label = "RAM",      factory = make_ram_tab },
        { id = "hist", label = "Historia", factory = make_hist_tab },
        { id = "sys",  label = "Sistema",  factory = make_sys_tab },
    },
}

print("Panel abierto. Cambia de tab para forzar la carga bajo demanda.")
print("Observa el log: solo se construye cada tab la primera vez.")
print("'q' para salir.")
srv:run()
print("Adios.")
