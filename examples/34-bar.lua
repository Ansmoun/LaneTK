-- Barra data-driven con cambio de layout en caliente.
-- El botón "⇄" rota entre 3 presets: top, bottom, free-centrado.
-- Geometría, colores y widgets vienen de layout.lua y de la paleta.

local Server   = require("lib.server")
local Window   = require("lib.window")
local theme    = require("lib.theme")
local W        = require("lib.widgets")
local cairo    = require("lib.cairo")
local screens  = require("lib.screens")
local geometry = require("lib.bar.geometry")
local bar_eng  = require("lib.bar.engine")
local bar_ctor = require("lib.bar.constructors")
local log      = require("lib.log")

local srv = Server.new()
local T = theme.load()
log.info("bar", "paleta: %s", T.path)

-- Spec base (layout.lua del usuario)
local base_spec = dofile((os.getenv("HOME") or "") ..
    "/proyectos/lanetk/layout.lua")

-- Presets de geometría. Solo cambian estos campos; el resto del
-- spec (separator, gap, left, center, right, etc.) se mantiene.
local presets = {
    { position = "top",    width = "screen", height = 24 },
    { position = "bottom", width = "screen", height = 24 },
    { position = "free",   width = 640, height = 24,
      x = "center", y = 0 },
}
local current_idx = 1

-- Monitor principal
local function pick_primary_screen()
    local list = screens.list()
    for _, s in ipairs(list) do
        if s.name == "VGA-1" then return s end
    end
    return list[1]
end
local mon = pick_primary_screen()

-- Estado mutable
local bar_win = nil
local bar_data = nil

-- Forward declaration
local rebuild_bar

-- ─── Botón de cambio de layout ───
-- Registrado como constructor antes de construir la barra. La
-- closure captura srv y current_idx, y llama a rebuild_bar cuando
-- el usuario pulsa.
bar_ctor.register("layout_switch", function(theme)
    local b = W.Button.new {
        text = "⇄",
        flat = true,
        font = "DejaVu Sans Bold 11",
        padding_x = 10, padding_y = 3,
    }
    b.opts.on_click = function()
        current_idx = (current_idx % #presets) + 1
        log.info("bar", "cambiando a preset %d", current_idx)
        -- Diferido: el botón vive en la ventana que vamos a
        -- destruir. Si llamamos a rebuild_bar directamente, la
        -- ventana se destruiría a mitad del callback.
        local h
        h = srv:add_timer(50, function()
            h:cancel()
            rebuild_bar()
        end)
    end
    return { widget = b }
end)

-- Añadir el botón al spec si no está (al final del right, junto al reloj).
local function ensure_switch_in_spec(spec)
    local function contains(list, name)
        for _, v in ipairs(list or {}) do
            if v == name then return true end
        end
        return false
    end
    spec.right = spec.right or {}
    if not contains(spec.right, "layout_switch") then
        table.insert(spec.right, 1, "layout_switch")
    end
end
ensure_switch_in_spec(base_spec)

-- ─── Rebuild ───
rebuild_bar = function()
    -- Cerrar la ventana anterior si existe.
    if bar_win and not bar_win.destroyed then
        bar_win:close("rebuild")
        bar_win = nil
    end

    -- Copia superficial del spec base y aplicación del preset.
    local spec = {}
    for k, v in pairs(base_spec) do spec[k] = v end
    for k, v in pairs(presets[current_idx]) do spec[k] = v end

    -- Geometría traducida a coordenadas absolutas.
    local geo = geometry.compute(spec, mon)

    -- Montar el árbol de la barra.
    local bar = bar_eng.build(T, spec, bar_ctor)

    -- Padding interno opcional.
    local root = bar.widget
    if (spec.padding or 0) > 0 then
        root = W.Group.new {
            orientation = "horizontal",
            padding = spec.padding,
            children = { { widget = bar.widget, weight = 1 } },
        }
    end

    -- Ventana nueva.
    bar_win = Window.new(srv, {
        kind = "menu",           -- override_redirect
        title = "lanetk-bar",
        width  = geo.w,
        height = geo.h,
        x = geo.x,
        y = geo.y,
        disable_q_close = true,
        on_draw = function(cr, w, h)
            cairo.set_rgb(cr, T.bg_rgb[1], T.bg_rgb[2], T.bg_rgb[3])
            cairo.paint(cr)
            cairo.set_rgb(cr, T.separator_rgb[1], T.separator_rgb[2],
                T.separator_rgb[3])
            cairo.rectangle(cr, 0, h - 1, w, 1)
            cairo.fill(cr)
        end,
    })
    bar_win:set_root(root)
    bar_data = bar

    log.info("bar", "preset %d (%s): %dx%d+%d+%d sep=%s",
        current_idx, geo.position, geo.w, geo.h, geo.x, geo.y,
        bar.sep_style)
end

rebuild_bar()

print(string.format("Barra en %s. Pulsa ⇄ para rotar entre los 3 layouts.",
    mon.name))
print("Ctrl+C para terminar.")

srv:run()
