local Server = require("lib.server")
local Panel  = require("lib.panel")
local theme  = require("lib.theme")
local log    = require("lib.log")

local srv = Server.new()
local T = theme.load()
log.info("panel", "paleta: %s", T.path)

local net_mod = require("lib.tabs.net")

local panel = Panel.new {
    server = srv,
    kind = "normal",
    title = "Red",
    width = "75%", height = "75%",
    x = "center", y = "center",
    bg = T.bg_rgb,
    tabs = {
        { id = "net", label = "Red",
          factory = function() return net_mod.new(srv, T) end },
    },
}

print("Tab Red con 3 sub-tabs. q/Esc cierra.")
srv:run()
