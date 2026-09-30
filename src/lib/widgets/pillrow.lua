-- PillRow: fila horizontal de "pills" con formato [LABEL VALOR].
-- El label va en muted, el valor en el color que se especifique
-- (dinámico por pill).

local Area  = require("lib.area")
local cairo = require("lib.cairo")
local pango = require("lib.pango")
local G     = require("lib.helpers.graphics")

local PillRow = setmetatable({}, { __index = Area })
PillRow.__index = PillRow

-- opts:
--   theme    : tabla del theme (opcional)
--   items    : array de { id, label, value?, color? }
--   gap      : espacio entre pills (default 6)
--   pad_x    : padding horizontal interno (default 8)
--   pad_y    : padding vertical interno (default 3)
--   label_font : fuente del label
--   value_font : fuente del valor (default bold del mismo tamaño)
--   radius   : radio de las esquinas (default 3)
--   bg       : color de fondo de las pills (default theme.separator)
function PillRow.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), PillRow)
    local T = opts.theme or {}
    self.T = T

    self.gap    = opts.gap    or 6
    self.pad_x  = opts.pad_x  or 8
    self.pad_y  = opts.pad_y  or 3
    self.radius = opts.radius or 3

    self.label_font = opts.label_font or "DejaVu Sans 8"
    self.value_font = opts.value_font or "DejaVu Sans Bold 10"

    self.bg_color = opts.bg or T.separator or "#3c3836"
    self.label_color = opts.label_color or T.muted_rgb or { 0.55, 0.55, 0.60 }

    self.items = {}
    self.by_id = {}

    self.min_h = 0
    self.min_w = 0
    self.max_w = 10000
    self.max_h = 10000

    for _, it in ipairs(opts.items or {}) do
        self:add(it.id, it.label, it.value, it.color)
    end
    return self
end

function PillRow:add(id, label, value, color)
    local item = {
        id = id,
        label = label or id,
        value = value or "--",
        color = color or (self.T.fg_rgb or { 0.9, 0.9, 0.9 }),
        label_w = 0, value_w = 0,
        w = 0, h = 0,
        x0 = 0, y0 = 0, x1 = 0, y1 = 0,
    }
    item.label_w = pango.measure(item.label, self.label_font)
    item.value_w = pango.measure(item.value, self.value_font)
    -- Reserva el ancho para un valor tipico (mas largo que "--") asi
    -- el layout inicial no queda demasiado ajustado.
    local reserve_w = pango.measure("100%", self.value_font)
    if reserve_w > item.value_w then item.value_w_reserve = reserve_w end
    local _, lh = pango.measure(item.label, self.label_font)
    local _, vh = pango.measure(item.value, self.value_font)
    item.h = math.max(lh, vh) + self.pad_y * 2
    item.w = self.pad_x * 2 + item.label_w + 6 +
             math.max(item.value_w, item.value_w_reserve or 0)

    self.items[#self.items + 1] = item
    self.by_id[id] = item
    self:_recalc()
    return item
end

function PillRow:_recalc()
    local max_h = 0
    local total_w = 0
    for i, item in ipairs(self.items) do
        if item.h > max_h then max_h = item.h end
        total_w = total_w + item.w
        if i < #self.items then total_w = total_w + self.gap end
    end
    self.min_h = max_h
    self.min_w = total_w
end

-- Actualiza el valor y opcionalmente el color de una pill.
-- Si el ancho cambia mas de 4px, se invalida el layout del arbol
-- (el padre relayouta y las pills se reacomodan).
function PillRow:set(id, value, color)
    local item = self.by_id[id]
    if not item then return end
    local changed = false
    local old_w = item.w

    if value ~= nil and value ~= item.value then
        item.value = tostring(value)
        item.value_w = pango.measure(item.value, self.value_font)
        item.w = self.pad_x * 2 + item.label_w + 6 + item.value_w
        changed = true
    end
    if color ~= nil then
        item.color = color
        changed = true
    end
    if changed then
        self:_recalc()
        -- Si el ancho cambio, redistribuir las posiciones
        -- internas SIN invalidar el layout global. El relayout
        -- del arbol es caro y no hace falta: solo la fila de
        -- pills necesita recolocarse.
        if math.abs(item.w - old_w) > 4
           and self.x1 > self.x0 and self.y1 > self.y0 then
            self:layout(self.x0, self.y0, self.x1, self.y1)
        end
        self:damage()
    end
end

function PillRow:set_color(id, color)
    local item = self.by_id[id]
    if not item then return end
    item.color = color
    self:damage()
end

function PillRow:askMinMax(minw, minh, maxw, maxh)
    return minw + self.min_w, minh + self.min_h,
           maxw + 10000, maxh + self.min_h
end

function PillRow:layout(x0, y0, x1, y1)
    Area.layout(self, x0, y0, x1, y1)
    -- Centrar verticalmente la fila dentro del rect asignado.
    local h = self.min_h
    local cy = y0 + math.floor((y1 - y0 - h) / 2)
    local x = x0
    for i, item in ipairs(self.items) do
        item.x0 = x
        item.y0 = cy
        item.x1 = x + item.w
        item.y1 = cy + h
        x = x + item.w + self.gap
    end
end

function PillRow:draw(cr)
    for _, item in ipairs(self.items) do
        -- Fondo
        local br, bg_, bb = G.hex_to_rgba(
            type(self.bg_color) == "string" and self.bg_color or "#3c3836")
        cairo.set_rgb(cr, br, bg_, bb)
        cairo.rounded_rect(cr, item.x0, item.y0,
            item.w, item.h, self.radius)
        cairo.fill(cr)

        -- Label
        local lr, lg, lb
        if type(self.label_color) == "table" then
            lr, lg, lb = self.label_color[1], self.label_color[2], self.label_color[3]
        else
            lr, lg, lb = G.hex_to_rgba(self.label_color)
        end
        local _, lh = pango.measure(item.label, self.label_font)
        local ly = item.y0 + (item.h - lh) / 2
        pango.draw_text(cr, item.x0 + self.pad_x, ly,
            item.label, self.label_font,
            { r = lr, g = lg, b = lb })

        -- Valor (alineado a la derecha dentro de la pill)
        local vr, vg, vb
        if type(item.color) == "table" then
            vr, vg, vb = item.color[1], item.color[2], item.color[3]
        else
            vr, vg, vb = G.hex_to_rgba(item.color)
        end
        local _, vh = pango.measure(item.value, self.value_font)
        local vy = item.y0 + (item.h - vh) / 2
        pango.draw_text(cr,
            item.x1 - self.pad_x - item.value_w, vy,
            item.value, self.value_font,
            { r = vr, g = vg, b = vb })
    end
end

return PillRow
