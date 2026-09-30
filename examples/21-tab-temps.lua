-- Primer tab real portado del panel de Awesome: "Temperaturas".

local Server = require("lib.server")
local Panel  = require("lib.panel")
local W      = require("lib.widgets")
local log    = require("lib.log")

local srv = Server.new()

local theme = {
    fg_normal   = "#ebdbb2",
    muted       = "#928374",
    accent      = "#8ec07c",
    separator   = "#504945",
    bg_focus    = "#3c3836",
    usage_warn  = "#d79921",
    usage_crit  = "#cc241d",
    telemetry   = {
        cpu     = "#8ec07c",
        ram     = "#83a598",
        gpu     = "#d3869b",
        temp    = "#d65d0e",
        battery = "#b8bb26",
        disk    = "#fabd2f",
    },
}

local temps_mod = require("lib.tabs.temps")

local function make_temps_tab()
    log.info("tab", "construyendo temps")
    return temps_mod.new(srv, theme)
end

local function make_hello_tab()
    log.info("tab", "construyendo hello")
    local text = W.Text.new {
        text = "Hello tab",
        font = "DejaVu Sans 20",
        r = 0.95, g = 0.85, b = 0.30,
        align = "center",
    }
    return { widget = text }
end

local panel = Panel.new {
    server = srv,
    kind = "normal",
    title = "Tab Temps (portado)",
    width = "70%", height = "75%",
    x = "center", y = "center",
    bg = { 0.10, 0.10, 0.13 },
    tabs = {
        { id = "temps", label = "Temperaturas", factory = make_temps_tab },
        { id = "hello", label = "Hello",        factory = make_hello_tab },
    },
}

print("Panel con el tab 'Temperaturas' portado.")
print("'q' o Esc para cerrar. Proceso sigue vivo.")
print("Trigger: echo toggle > /tmp/lanetk-panel.cmd")
srv:run()
