local Server   = require("lib.server")
local PanelApp = require("lib.panelapp")
local theme    = require("lib.theme")
local log      = require("lib.log")

local srv = Server.new()
local T = theme.load()
log.info("panel", "paleta inicial: %s", T.path)

local config_mod = require("lib.tabs.config")

local app = PanelApp.new {
    server = srv,
    theme  = T,
    panel_opts = {
        title = "Configuración",
        width = "70%", height = "75%",
        x = "center", y = "center",
        tabs = {
            { id = "config", label = "Configuración",
              factory = function() return config_mod.new(srv, T) end },
        },
    },
}

app:show()
print("Tab Configuración. Cicla y pulsa Aplicar. q/Esc cierra.")
srv:run()
