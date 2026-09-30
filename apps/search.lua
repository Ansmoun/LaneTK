local App = require("lib.app")
App.new {
    name  = "search",
    title = "LaneTK — Buscar archivos",
    width = 900, height = 600,
    build = function(srv, T)
        return require("lib.tabs.search").new(srv, T)
    end,
}:run()
