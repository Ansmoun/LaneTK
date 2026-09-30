-- Configuracion de LaneTK: apariencia, entorno, atajos.
-- watch_theme = true para que reload_in_place local dispare el
-- rebuild del arbol (config aplica cambios de paleta en si mismo).

local App = require("lib.app")

App.new {
    name  = "config",
    title = "LaneTK — Configuracion",
    width = 700, height = 620,
    watch_theme = true,
    build = function(srv, T)
        return require("lib.tabs.config").new(srv, T)
    end,
}:run()
