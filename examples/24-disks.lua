local Server = require("lib.server")
local Panel  = require("lib.panel")
local theme  = require("lib.theme")
local log    = require("lib.log")

local srv = Server.new()
local T = theme.load()
log.info("panel", "paleta: %s", T.path)

local disk_mod = require("lib.tabs.disks")

local panel = Panel.new {
    server = srv,
    kind = "normal",
    title = "Discos",
    width = "80%", height = "70%",
    x = "center", y = "center",
    bg = T.bg_rgb,
    tabs = {
        { id = "disks", label = "Discos",
          factory = function() return disk_mod.new(srv, T) end },
    },
}

print("Tab Discos. q/Esc cierra.")
print("SMART se actualiza en background cada 60s a /tmp/lanetk-smart.tsv")
srv:run()
