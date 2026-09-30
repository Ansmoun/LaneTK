local Server   = require("lib.server")
local PanelApp = require("lib.panelapp")
local theme    = require("lib.theme")
local log      = require("lib.log")

local srv = Server.new()
local T = theme.load()
log.info("panel", "paleta: %s", T.path)

local search_mod = require("lib.tabs.search")

local app = PanelApp.new {
    server = srv,
    theme  = T,
    panel_opts = {
        title = "Buscar",
        width = "80%", height = "80%",
        x = "center", y = "center",
        tabs = {
            { id = "search", label = "Buscar",
              factory = function() return search_mod.new(srv, T) end },
        },
    },
}

app:show()
print("Tab Buscar. Click en input, escribe, Enter o boton Buscar.")
print("Click en resultado abre con xdg-open. Click derecho copia ruta.")
srv:run()
