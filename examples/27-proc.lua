local Server = require("lib.server")
local Panel  = require("lib.panel")
local theme  = require("lib.theme")
local log    = require("lib.log")

local srv = Server.new()
local T = theme.load()
log.info("panel", "paleta: %s", T.path)

local proc_mod = require("lib.tabs.proc")

local panel = Panel.new {
    server = srv,
    kind = "normal",
    title = "Procesos",
    width = "80%", height = "75%",
    x = "center", y = "center",
    bg = T.bg_rgb,
    tabs = {
        { id = "proc", label = "Procesos",
          factory = function() return proc_mod.new(srv, T) end },
    },
}

print("Tab Procesos. q/Esc cierra.")
srv:run()
