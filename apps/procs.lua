local App = require("lib.app")
App.new {
    name  = "procs",
    title = "LaneTK — Procesos",
    width = 900, height = 600,
    build = function(srv, T)
        return require("lib.tabs.proc").new(srv, T)
    end,
}:run()
