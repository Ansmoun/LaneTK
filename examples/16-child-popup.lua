-- Prueba de ventana hija X11.
-- Ventana principal con un boton "Abrir popup".
-- El popup es una X11 child window: se posiciona dentro de la
-- principal, se recorta a sus limites, y se mueve con ella.

local Server = require("lib.server")
local Window = require("lib.window")
local cairo  = require("lib.cairo")
local W      = require("lib.widgets")

local srv = Server.new()

-- ---- Ventana principal --------------------------------------
local main_win = Window.new(srv, {
    title = "Child popup demo",
    app_name = "lanetk", class_name = "LtkChild",
    width  = 500, height = 360,
    x = "center", y = "center",
    on_draw = function(cr, w, h)
        cairo.set_rgb(cr, 0.10, 0.10, 0.13)
        cairo.paint(cr)
    end,
    on_key = function(key)
        if key.text == "Escape" and main_win.popup and not main_win.popup.destroyed then
            main_win.popup:close("escape")
        end
    end,
})

-- ---- Popup (child) ------------------------------------------
local popup = nil

local function open_popup()
    if popup and not popup.destroyed then
        popup:close("reabrir")
        popup = nil
        return
    end

    -- Layout del popup
    local title = W.Text.new {
        text = "Soy un popup",
        font = "DejaVu Sans Bold 14",
        r = 0.95, g = 0.85, b = 0.30,
        align = "center",
    }

    local info = W.Text.new {
        text = "Ventana hija X11. Se recorta al padre.",
        font = "DejaVu Sans 10",
        r = 0.75, g = 0.75, b = 0.80,
        align = "center",
    }

    local close_btn = W.Button.new {
        text = "Cerrar",
        on_click = function()
            popup:close("boton cerrar")
            popup = nil
        end,
    }

    local inner = W.Group.new {
        orientation = "vertical",
        spacing = 12,
        padding = 16,
        children = { title, info, close_btn },
    }

    -- Crear el child con parent = main_win
    popup = Window.new(srv, {
        parent_window = main_win,
        kind = "child",
        width = 280,
        height = 140,
        x = 110, y = 110,   -- relativo al interior del padre
        on_draw = function(cr, w, h)
            -- Fondo del popup
            cairo.set_rgb(cr, 0.16, 0.16, 0.22)
            cairo.paint(cr)
            -- Borde
            cairo.set_rgb(cr, 0.40, 0.40, 0.55)
            cairo.set_line_width(cr, 2)
            cairo.rectangle(cr, 1, 1, w - 2, h - 2)
            cairo.stroke(cr)
        end,
        on_close = function()
            print("popup cerrado")
        end,
    })
    popup:set_root(inner)

    -- Pedir el foco de teclado al popup. Sin esto, KeyPress
    -- llega al padre (la ventana con foco X11).
    popup:set_input_focus()

    main_win.popup = popup
    print("popup abierto")
end

local open_btn = W.Button.new {
    text = "Abrir popup",
    on_click = open_popup,
}

local hint = W.Text.new {
    text = "Esc cierra el popup. Mueve la ventana principal y veras\n" ..
           "que el popup se mueve con ella (child de X11).",
    font = "DejaVu Sans 10",
    r = 0.60, g = 0.60, b = 0.65,
    align = "center",
}

local root = W.Group.new {
    orientation = "vertical",
    spacing = 20,
    padding = 30,
    children = { open_btn, hint },
}

main_win:set_root(root)

print("Ventana principal. Pulsa 'q' (sobre la principal) para salir.")
srv:run()
print("Adios.")
