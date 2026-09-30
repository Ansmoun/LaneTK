local Server   = require("lib.server")
local PanelApp = require("lib.panelapp")
local theme    = require("lib.theme")
local log      = require("lib.log")

local srv = Server.new()
local T = theme.load()
log.info("panel", "paleta: %s", T.path)

local inicio_mod = require("lib.tabs.inicio")

local app = PanelApp.new {
    server = srv,
    theme  = T,
    panel_opts = {
        title = "Inicio",
        width = "70%", height = "75%",
        x = "center", y = "center",
        tabs = {
            { id = "inicio", label = "Inicio",
              factory = function() return inicio_mod.new(srv, T) end },
        },
    },
}

app:show()
print("Tab Inicio. q/Esc cierra.")
srv:run()
