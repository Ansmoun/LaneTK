local Server = require("lib.server")
local Window = require("lib.window")
local cairo  = require("lib.cairo")
local W      = require("lib.widgets")

local srv = Server.new()

local HOME = os.getenv("HOME")
local ICON_DIRS = {
    HOME .. "/.config/awesome/icons",
    HOME .. "/proyectos/lanetk/icons",
}

local function find_icon(name)
    for _, dir in ipairs(ICON_DIRS) do
        local p = dir .. "/" .. name
        local f = io.open(p, "rb")
        if f then f:close(); return p end
    end
    return nil
end

local icon_names = { "cpu.png", "ram.png", "temp.png", "net.png", "gpu.png" }

local rows = {}
local found = {}
for _, name in ipairs(icon_names) do
    local path = find_icon(name)
    if path then
        found[#found + 1] = name
        print("OK    " .. name .. "  ->  " .. path)
        local ico      = W.Icon.new { path = path, width = 24, height = 24,
                                      halign = "center", valign = "center" }
        local ico_tint = W.Icon.new { path = path, width = 24, height = 24,
                                      halign = "center", valign = "center",
                                      color_hex = "#f0a060" }
        local row = W.Group.new {
            orientation = "horizontal", spacing = 16,
            min_height = 28,
            children = {
                ico, ico_tint,
                W.Text.new { text = name, font = "DejaVu Sans 11",
                             valign = "center" },
            },
        }
        rows[#rows + 1] = row
    else
        print("FALTA " .. name)
        rows[#rows + 1] = W.Text.new {
            text = "No encontrado: " .. name,
            font = "DejaVu Sans 10",
            r = 0.65, g = 0.45, b = 0.45,
        }
    end
end

print(string.format("Encontrados: %d/%d", #found, #icon_names))

local header = W.Text.new {
    text = "PNG original  |  PNG tintado  |  nombre",
    font = "DejaVu Sans Bold 11",
    r = 0.85, g = 0.85, b = 0.85,
}

local list = W.Group.new {
    orientation = "vertical",
    spacing = 10,
    children = rows,
}

local root = W.Group.new {
    orientation = "vertical",
    spacing = 14,
    padding = 20,
    children = { header, list },
}

local win = Window.new(srv, {
    title = "Icon demo",
    app_name = "lanetk", class_name = "LtkIcon",
    width  = 360,
    height = 260,
    x = "center", y = "center",
    on_draw = function(cr, w, h)
        cairo.set_rgb(cr, 0.10, 0.10, 0.13)
        cairo.paint(cr)
    end,
})

win:set_root(root)
print("Ventana lista. 'q' para salir.")
srv:run()
print("Adios.")
