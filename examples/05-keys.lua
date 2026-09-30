-- Prueba de teclado real con xkbcommon.
-- Muestra cada tecla pulsada y liberada con su nombre, texto y
-- modificadores.

local Window = require("lib.window")
local cairo  = require("lib.cairo")
local pango  = require("lib.pango")

local history = {}
local MAX_HISTORY = 12

local win = Window.new {
    title  = "xkbcommon",
    app_name  = "lanetk",
    class_name = "LtkKeys",
    width  = 640,
    height = 400,
    x = "center",
    y = "center",

    on_key = function(key)
        if not key.pressed then return end

        local mods = {}
        if key.mods.ctrl  then mods[#mods+1] = "Ctrl"  end
        if key.mods.alt   then mods[#mods+1] = "Alt"   end
        if key.mods.shift then mods[#mods+1] = "Shift" end
        if key.mods.super then mods[#mods+1] = "Super" end
        local modstr = #mods > 0 and (table.concat(mods, "+") .. "+") or ""

        local text_display = key.text ~= "" and ("'" .. key.text .. "'") or "(no text)"
        local line = string.format("%s%-10s  sym=0x%04x  %s",
            modstr, key.name, key.sym, text_display)

        print(line)
        table.insert(history, 1, line)
        while #history > MAX_HISTORY do
            table.remove(history)
        end
    end,

    on_draw = function(cr, w, h)
        cairo.set_rgb(cr, 0.10, 0.10, 0.13)
        cairo.paint(cr)

        pango.draw_text(cr, 30, 25, "Teclado (xkbcommon)",
            "DejaVu Sans Bold 20",
            { r = 0.95, g = 0.85, b = 0.30 })

        pango.draw_text(cr, 30, 55,
            "Pulsa teclas. Cada evento se muestra con su nombre y texto.",
            "DejaVu Sans 11",
            { r = 0.65, g = 0.65, b = 0.65 })

        pango.draw_text(cr, 30, 80,
            "'q' sin modificadores cierra la ventana.",
            "DejaVu Sans 11",
            { r = 0.55, g = 0.55, b = 0.55 })

        cairo.set_rgb(cr, 0.15, 0.15, 0.18)
        cairo.rectangle(cr, 20, 110, w - 40, h - 130)
        cairo.fill(cr)

        local y = 125
        for i = 1, #history do
            local alpha = 1.0 - (i - 1) * 0.06
            pango.draw_text(cr, 35, y, history[i],
                "DejaVu Sans Mono 11",
                { r = alpha, g = alpha, b = alpha })
            y = y + 18
        end

        if #history == 0 then
            pango.draw_text(cr, 35, y, "(esperando teclas...)",
                "DejaVu Sans Mono 11",
                { r = 0.5, g = 0.5, b = 0.5 })
        end
    end,
}

-- Redibujar cuando llega una tecla para actualizar el historial.
local original_on_key = win.opts.on_key
win.opts.on_key = function(key)
    original_on_key(key)
    win:draw()
end

print("Ventana lista. Pulsa teclas y observa el output.")
print("'q' sin modificadores cierra.")
win:run()
print("Adios.")
