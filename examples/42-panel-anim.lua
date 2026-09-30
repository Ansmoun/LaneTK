-- examples/42-panel-anim.lua
-- Prueba del panel con crossfade de tabs. Lee las preferencias de
-- conf.lua. Antes de correr, asegurarse de tener en
-- ~/.config/awesome/conf.lua:
--   animate_panel = "true"
--   anim_hz       = "30"
--
-- Si esas claves no existen, el panel arranca sin animación (default).
--
-- Correr:
--   LANETK_LOG=info ./run examples/42-panel-anim.lua
--
-- Medir consumo con la animación activa:
--   top -p $(pgrep -f 42-panel-anim.lua) -b -n 3 | tail -10

local Server = require("lib.server")
local W      = require("lib.widgets")
local Panel  = require("lib.panel")
local log    = require("lib.log")

local srv = Server.new { exit_on_empty = true }

-- Tabs de prueba: dos páginas simples con colores distintos.
local function make_page(title, color_bg, color_accent)
    local header = W.Text.new {
        text = title,
        font = "DejaVu Sans Bold 22",
        align = "center", valign = "center",
        r = color_accent[1], g = color_accent[2], b = color_accent[3],
    }
    local body = W.Text.new {
        text = "Contenido de la página " .. title ..
               "\n\nCambiá de tab con los botones de arriba.\n" ..
               "La transición es crossfade si animate_panel = true.",
        font = "DejaVu Sans 11",
        align = "center", valign = "center",
        wrap = true,
    }
    local inner = W.Group.new {
        orientation = "vertical", spacing = 20, padding = 40,
        children = {
            { widget = W.Text.new { text = "" }, weight = 1 },
            { widget = header, weight = 0 },
            { widget = body,   weight = 0 },
            { widget = W.Text.new { text = "" }, weight = 1 },
        },
    }
    return W.Card.new {
        title = nil,
        content = inner,
        padding = 20,
        bg = color_bg,
        border = color_accent,
        min_width = 400, min_height = 400,
    }
end

local tabs = {
    {
        id = "page1", label = "Página 1", icon = "home",
        factory = function()
            return {
                widget = make_page("Página 1",
                    { 0.16, 0.20, 0.16 }, { 0.55, 0.85, 0.60 }),
            }
        end,
    },
    {
        id = "page2", label = "Página 2", icon = "chip",
        factory = function()
            return {
                widget = make_page("Página 2",
                    { 0.22, 0.16, 0.16 }, { 0.95, 0.55, 0.35 }),
            }
        end,
    },
    {
        id = "page3", label = "Página 3", icon = "list",
        factory = function()
            return {
                widget = make_page("Página 3",
                    { 0.16, 0.18, 0.24 }, { 0.55, 0.75, 0.95 }),
            }
        end,
    },
}

local panel = Panel.new {
    server = srv,
    title  = "Panel animado",
    width  = 700, height = 500,
    tabs   = tabs,
    -- Forzar animación para el test, sin depender de conf.lua.
    animate_panel = true,
    anim_hz       = 30,
    anim_duration = 400,
}

log.info("42", "panel creado, corriendo")
srv:run()
