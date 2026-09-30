-- Igual que 06-area.lua pero con rectangulos de fondo para visualizar
-- las celdas que asigna el layout a cada widget.

local Window = require("lib.window")
local cairo  = require("lib.cairo")
local pango  = require("lib.pango")
local Area   = require("lib.area")
local W      = require("lib.widgets")

-- Widget "Debug": Text con un rectangulo de fondo para ver su celda.
local DebugText = setmetatable({}, { __index = W.Text })
DebugText.__index = DebugText

function DebugText.new(opts)
    local self = setmetatable(W.Text.new(opts), DebugText)
    self.bg_r = opts.bg_r or 0.20
    self.bg_g = opts.bg_g or 0.20
    self.bg_b = opts.bg_b or 0.25
    self.border_r = opts.border_r or 0.5
    self.border_g = opts.border_g or 0.5
    self.border_b = opts.border_b or 0.6
    return self
end

function DebugText:draw(cr)
    -- Rectangulo de fondo
    cairo.set_rgb(cr, self.bg_r, self.bg_g, self.bg_b)
    cairo.rectangle(cr, self.x0, self.y0,
                    self:getWidth(), self:getHeight())
    cairo.fill(cr)
    -- Borde
    cairo.set_rgb(cr, self.border_r, self.border_g, self.border_b)
    cairo.set_line_width(cr, 1)
    cairo.rectangle(cr, self.x0 + 0.5, self.y0 + 0.5,
                    self:getWidth() - 1, self:getHeight() - 1)
    cairo.stroke(cr)
    -- Texto
    W.Text.draw(self, cr)
end

local title = DebugText.new {
    text  = "Area + Group + Text",
    font  = "DejaVu Sans Bold 22",
    r = 0.95, g = 0.85, b = 0.30,
    align = "center",
    bg_r = 0.15, bg_g = 0.15, bg_b = 0.20,
}

local a = DebugText.new {
    text = "A",
    font = "DejaVu Sans Bold 40",
    r = 0.90, g = 0.35, b = 0.40,
    align = "center",
    bg_r = 0.20, bg_g = 0.10, bg_b = 0.12,
}
local b = DebugText.new {
    text = "B",
    font = "DejaVu Sans Bold 40",
    r = 0.35, g = 0.75, b = 0.45,
    align = "center",
    bg_r = 0.10, bg_g = 0.20, bg_b = 0.12,
}
local c = DebugText.new {
    text = "C",
    font = "DejaVu Sans Bold 40",
    r = 0.40, g = 0.55, b = 0.95,
    align = "center",
    bg_r = 0.10, bg_g = 0.12, bg_b = 0.22,
}

local row = W.Group.new {
    orientation = "horizontal",
    spacing = 20,
    children = { a, b, c },
}

local footer = DebugText.new {
    text = "Pulsa 'q' para salir.",
    font = "DejaVu Sans 11",
    r = 0.55, g = 0.55, b = 0.55,
    align = "center",
    bg_r = 0.15, bg_g = 0.15, bg_b = 0.18,
}

local root = W.Group.new {
    orientation = "vertical",
    spacing = 16,
    padding = 24,
    children = { title, row, footer },
}

local win = Window.new {
    title  = "Area debug",
    app_name  = "lanetk",
    class_name = "LtkAreaDebug",
    width  = "50%",
    height = "50%",
    x = "center",
    y = "center",

    on_draw = function(cr, w, h)
        cairo.set_rgb(cr, 0.05, 0.05, 0.08)
        cairo.paint(cr)
    end,
}

win:set_root(root)
print("Si ves 3 celdas verticales (titulo / fila / footer)")
print("y dentro de la fila 3 celdas horizontales (A / B / C),")
print("el layout funciona correctamente.")
print("Pulsa 'q' para salir.")
win:run()
