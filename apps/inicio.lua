local App = require("lib.app")
App.new {
    name  = "inicio",
    title = "LaneTK — Inicio",
    width = 700, height = 560,
    build = function(srv, T)
        return require("lib.tabs.inicio").new(srv, T)
    end,
}:run()
