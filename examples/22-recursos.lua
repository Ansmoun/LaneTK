-- Panel "Recursos": 4 sub-tabs (General, CPU, RAM, GPU).
-- Usa la paleta activa (config, env var, o default).

local Server = require("lib.server")
local Panel  = require("lib.panel")
local W      = require("lib.widgets")
local theme  = require("lib.theme")
local log    = require("lib.log")

local srv = Server.new()

local T = theme.load()
log.info("panel", "paleta: %s", T.path)

local tab_general = require("lib.tabs.general")
local tab_cpu     = require("lib.tabs.cpu")
local tab_ram     = require("lib.tabs.ram")
local tab_gpu     = require("lib.tabs.gpu")

local function make_general() return tab_general.new(srv, T) end
local function make_cpu()     return tab_cpu.new(srv, T) end
local function make_ram()     return tab_ram.new(srv, T) end
local function make_gpu()     return tab_gpu.new(srv, T) end

local panel = Panel.new {
    server = srv,
    kind = "normal",
    title = "Recursos",
    width = "75%", height = "80%",
    x = "center", y = "center",
    bg = T.bg_rgb,
    tabs = {
        { id = "general", label = "General", factory = make_general },
        { id = "cpu",     label = "CPU",     factory = make_cpu },
        { id = "ram",     label = "RAM",     factory = make_ram },
        { id = "gpu",     label = "GPU",     factory = make_gpu },
    },
}

print("Panel Recursos: General / CPU / RAM / GPU.")
print("Paleta: " .. T.path)
print("Paletas disponibles: " .. table.concat(theme.list_palettes(), ", "))
print("Cambiar: LANETK_PALETTE=nord ~/proyectos/lanetk/run examples/22-recursos.lua")
print("q/Esc cierra.")
srv:run()
