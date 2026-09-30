local App = require("lib.app")
App.new {
    name  = "battery",
    title = "LaneTK — Bateria",
    width = 500, height = 560,
    build = function(srv, T)
        return require("lib.tabs.bat").new(srv, T)
    end,
}:run()
