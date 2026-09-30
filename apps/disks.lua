local App = require("lib.app")
App.new {
    name  = "disks",
    title = "LaneTK — Discos",
    width = 800, height = 500,
    build = function(srv, T)
        return require("lib.tabs.disks").new(srv, T)
    end,
}:run()
