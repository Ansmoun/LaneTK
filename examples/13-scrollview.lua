-- Prueba de ScrollView + ScrollBar.
-- Lista de 200 items con hover, click, rueda y drag del scrollbar.

local Server = require("lib.server")
local Window = require("lib.window")
local cairo  = require("lib.cairo")
local pango  = require("lib.pango")
local G      = require("lib.helpers.graphics")
local W      = require("lib.widgets")
local Area   = require("lib.area")

local srv = Server.new()

-- Generar items de prueba
local items = {}
for i = 1, 200 do
    items[i] = {
        idx = i,
        label = string.format("Item %03d", i),
        value = math.random(100, 999),
    }
end

-- Callback de dibujo de cada fila
local function draw_row(cr, item, idx, y, row_h, width, hover)
    -- Fondo de hover
    if hover then
        G.set_color(cr, "#3c3836")
        cairo.rectangle(cr, 0, y, width, row_h)
        cairo.fill(cr)
    end

    -- Linea divisoria
    G.set_color(cr, "#2a2a2a")
    cairo.set_line_width(cr, 1)
    cairo.move_to(cr, 0, y + row_h - 0.5)
    cairo.line_to(cr, width, y + row_h - 0.5)
    cairo.stroke(cr)

    -- Texto izquierda
    pango.draw_text(cr, 12, y + (row_h - 12) / 2,
        item.label, "DejaVu Sans 11",
        { r = 0.90, g = 0.90, b = 0.90 })

    -- Texto derecha
    local val_str = tostring(item.value)
    local vw = pango.measure(val_str, "DejaVu Sans Mono 11")
    pango.draw_text(cr, width - vw - 12, y + (row_h - 12) / 2,
        val_str, "DejaVu Sans Mono 11",
        { r = 0.55, g = 0.75, b = 0.60 })
end

-- ScrollView
local list = W.ScrollView.new {
    row_height = 22,
    draw_row = draw_row,
    bg_color = "#1a1a1a",
    items = items,
    min_width = 300,
    min_height = 200,
    on_click = function(item, idx)
        print(string.format("click en item %d (%s)", idx, item.label))
    end,
    on_right_click = function(item, idx)
        print(string.format("click derecho en %d", idx))
    end,
}

-- ScrollBar
local sb = W.ScrollBar.new {
    orientation = "vertical",
    width = 16,
    thickness = 4,
    handle_r = 5,
    step = 60,
    color_track = "#3a3a3a",
    color_handle = "#8ec07c",
    auto_hide = true,
}

-- Coordinar
W.ScrollLink.link(list, sb)

-- Contenedor: scrollview + scrollbar lado a lado
-- El consumidor decide el ancho del scrollbar.
local container = setmetatable({}, { __index = W.Group })
container.__index = container

local function new_container(list, sb)
    local self = setmetatable({}, container)
    self.list = list
    self.sb = sb
    self.x0, self.y0, self.x1, self.y1 = 0, 0, 0, 0
    self.min_w, self.min_h = 300, 200
    self.max_w, self.max_h = 10000, 10000
    self.window = nil
    return self
end

function container:set_window(win)
    self.window = win
    self.list.window = win
    self.sb.window = win
end

function container:askMinMax(minw, minh, maxw, maxh)
    return minw + self.min_w, minh + self.min_h,
           maxw + self.max_w, maxh + self.max_h
end

function container:layout(x0, y0, x1, y1)
    Area.layout(self, x0, y0, x1, y1)
    local sb_w = self.sb:is_visible() and self.sb.width or 0
    self.list:layout(x0, y0, x1 - sb_w, y1)
    self.sb:layout(x1 - sb_w, y0, x1, y1)
    -- Despues de fijar el rect de la lista, recalcular offset_max
    self.list:_recalc_max()
end

function container:draw(cr)
    self.list:draw(cr)
    self.sb:draw(cr)
end

function container:getByXY(x, y)
    local hit = self.list:getByXY(x, y)
    if hit then return hit end
    hit = self.sb:getByXY(x, y)
    if hit then return hit end
    if x >= self.x0 and x < self.x1 and y >= self.y0 and y < self.y1 then
        return self
    end
    return nil
end

local root = new_container(list, sb)

local footer = W.Text.new {
    text = "Rueda: scroll 3 filas. Click: selecciona. Drag en el handle.",
    font = "DejaVu Sans 10",
    r = 0.55, g = 0.55, b = 0.55,
    align = "center",
}

local layout_root = W.Group.new {
    orientation = "vertical",
    spacing = 8,
    padding = 12,
    children = { root, footer },
}

local win = Window.new(srv, {
    title = "ScrollView demo",
    app_name = "lanetk", class_name = "LtkScroll",
    width  = 420,
    height = 360,
    x = "center", y = "center",
    on_draw = function(cr, w, h)
        cairo.set_rgb(cr, 0.10, 0.10, 0.13)
        cairo.paint(cr)
    end,
})

win:set_root(layout_root)

print("ScrollView con 200 items.")
print("Prueba: rueda, click, drag del handle, resize la ventana.")
print("'q' para salir.")
srv:run()
print("Adios.")
