local Server = require("lib.server")
local Panel  = require("lib.panel")
local theme  = require("lib.theme")
local log    = require("lib.log")

local srv = Server.new()
local T = theme.load()
log.info("panel", "paleta: %s", T.path)

local notes_mod = require("lib.tabs.notes")

local panel
panel = Panel.new {
    server = srv,
    kind = "normal",
    title = "Notas",
    width = "70%", height = "75%",
    x = "center", y = "center",
    bg = T.bg_rgb,
    tabs = {
        { id = "notes", label = "Notas",
          factory = function()
              return notes_mod.new(srv, T, panel:get_window())
          end },
    },
}

print("Tab Notas. q/Esc cierra.")
srv:run()
