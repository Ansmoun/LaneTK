local Area  = require("lib.area")
local cairo = require("lib.cairo")
local pango = require("lib.pango")
local Text  = require("lib.widgets.text")
local G     = require("lib.helpers.graphics")
local RowParse = require("lib.widgets.rowparse")

local BarRow = setmetatable({}, { __index = Area })
BarRow.__index = BarRow

-- opts:
--   rows         : array de { id, label, color? }
--   left_width   : ancho reservado a la etiqueta      (default 60)
--   pct_width    : ancho reservado al porcentaje      (default 0=oculto)
--   detail_width : ancho reservado al detalle         (default 0=oculto)
--   row_height   : alto de cada fila                  (default 14)
--   row_spacing  : espacio vertical entre filas       (default 4)
--   bar_color    : "#hex" color por defecto de la barra
--   bar_bg       : "#hex" color del fondo de la barra
--   warn_at      : 0..1 (opcional) si pct >= warn_at, usar warn_color
--   crit_at      : 0..1 (opcional) si pct >= crit_at, usar crit_color
--   warn_color, crit_color : "#hex"
--   text_warn    : bool. Si true, el texto del pct tambien cambia
--                  de color segun umbrales. Default false.
--   bar_height   : alto de la barra dentro de la fila (default 6)
--   label_font, label_color
--   pct_font, pct_color
--   detail_font, detail_color
function BarRow.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), BarRow)

    self.left_width   = opts.left_width   or 60
    self.pct_width    = opts.pct_width    or 0
    self.detail_width = opts.detail_width or 0
    self.row_height   = opts.row_height   or 14
    self.row_spacing  = opts.row_spacing  or 4
    self.bar_height   = opts.bar_height   or 6
    self.bar_color    = opts.bar_color    or "#8ec07c"
    self.bar_bg       = opts.bar_bg       or "#3c3836"
    self.warn_at      = opts.warn_at
    self.crit_at      = opts.crit_at
    self.warn_color   = opts.warn_color   or "#e5b567"
    self.crit_color   = opts.crit_color   or "#e06060"
    self.text_warn    = opts.text_warn or true

    -- Pre-calcular warn/crit como {r,g,b} para reusar.
    local function hex_to_tab(h)
        local r, g, b = G.hex_to_rgba(h)
        return { r, g, b }
    end
    self.warn_tab = hex_to_tab(self.warn_color)
    self.crit_tab = hex_to_tab(self.crit_color)

    self.label_font   = opts.label_font   or "DejaVu Sans 10"
    self.label_color  = opts.label_color  or { 0.75, 0.75, 0.80 }
    self.pct_font     = opts.pct_font     or "DejaVu Sans Mono 10"
    self.pct_color    = opts.pct_color    or { 0.90, 0.90, 0.90 }
    self.detail_font  = opts.detail_font  or "DejaVu Sans 10"
    self.detail_color = opts.detail_color or { 0.60, 0.60, 0.65 }

    -- Tipo de animacion para intro.lua. Motors hereda de BarRow
    -- y usa el mismo tipo ("barrow").
    self._anim_kind = "barrow"
    self.rows = {}     -- array en orden
    self.by_id = {}    -- id -> row

    for _, row in ipairs(opts.rows or {}) do
        local id, label = RowParse.parse(row, { "id", "label" })
        self:add_row(id, label, row.color)
    end
    return self
end

function BarRow:add_row(id, label, color)
    local row = {
        id = id,
        label = label,
        color = color,
        pct_value = nil,
        empty_text = "--",

        label_w = Text.new {
            text = label, font = self.label_font,
            r = self.label_color[1], g = self.label_color[2], b = self.label_color[3],
            align = "left", valign = "center",
        },
        pct_w = Text.new {
            text = "", font = self.pct_font,
            r = self.pct_color[1], g = self.pct_color[2], b = self.pct_color[3],
            align = "right", valign = "center",
        },
        detail_w = Text.new {
            text = "", font = self.detail_font,
            r = self.detail_color[1], g = self.detail_color[2], b = self.detail_color[3],
            align = "left", valign = "center",
        },
        bar_x0 = 0, bar_y0 = 0, bar_x1 = 0, bar_y1 = 0,
        -- Reveal individual por fila (0..1). Multiplica el pct
        -- efectivo de la barra. Default 1.0 = sin animacion.
        reveal = 1.0,
        -- Handle del tween de pct_value (set_animated).
        _anim_handle = nil,
    }
    self.rows[#self.rows + 1] = row
    self.by_id[id] = row
    return row
end

function BarRow:set_window(win)
    self.window = win
    for _, row in ipairs(self.rows) do
        row.label_w.window = win
        row.pct_w.window = win
        row.detail_w.window = win
    end
end

function BarRow:remove_all_rows()
    self.rows = {}
    self.by_id = {}
    self:damage()
end

function BarRow:_total_height()
    local n = #self.rows
    if n == 0 then return 0 end
    return n * self.row_height + (n - 1) * self.row_spacing
end

function BarRow:askMinMax(minw, minh, maxw, maxh)
    local w = self.left_width + self.pct_width + self.detail_width + 12
    local h = self:_total_height()
    return minw + w, minh + h, maxw + 10000, maxh + h
end

-- Color de la barra para un pct dado. Nunca nil: siempre devuelve
-- al menos self.bar_color.
function BarRow:_bar_color_for(row)
    if row.pct_value == nil then return self.bar_color end
    if self.crit_at and row.pct_value >= self.crit_at then
        return self.crit_color
    end
    if self.warn_at and row.pct_value >= self.warn_at then
        return self.warn_color
    end
    return row.color or self.bar_color
end

-- Color del texto del pct segun umbrales. Devuelve nil si no hay
-- umbral superado (el text conserva su color por defecto).
function BarRow:_text_color_for(row)
    if row.pct_value == nil then return nil end
    if self.crit_at and row.pct_value >= self.crit_at then
        return self.crit_tab
    end
    if self.warn_at and row.pct_value >= self.warn_at then
        return self.warn_tab
    end
    return nil
end

function BarRow:layout(x0, y0, x1, y1)
    Area.layout(self, x0, y0, x1, y1)
    if #self.rows == 0 then return end

    local y = y0
    for _, row in ipairs(self.rows) do
        local ry0 = y
        local ry1 = y + self.row_height

        row.label_w:layout(x0, ry0, x0 + self.left_width, ry1)

        local bar_x0 = x0 + self.left_width + 4
        local bar_x1 = x1 - self.pct_width - self.detail_width - 8
        if bar_x1 < bar_x0 then bar_x1 = bar_x0 end
        local bar_cy = (ry0 + ry1) / 2
        local bar_cy0 = bar_cy - self.bar_height / 2
        local bar_cy1 = bar_cy + self.bar_height / 2
        row.bar_x0, row.bar_y0 = bar_x0, bar_cy0
        row.bar_x1, row.bar_y1 = bar_x1, bar_cy1

        if self.pct_width > 0 then
            row.pct_w:layout(
                x1 - self.pct_width - self.detail_width - 4, ry0,
                x1 - self.detail_width - 4, ry1)
        end

        if self.detail_width > 0 then
            row.detail_w:layout(
                x1 - self.detail_width, ry0,
                x1, ry1)
        end

        y = ry1 + self.row_spacing
    end
end

function BarRow:draw(cr)
    for _, row in ipairs(self.rows) do
        local w = row.bar_x1 - row.bar_x0
        if w > 0 then
            local pct = (row.pct_value or 0) * (row.reveal or 1.0)
            if pct < 0 then pct = 0 end
            if pct > 1 then pct = 1 end
            G.bar(cr, row.bar_x0, row.bar_y0,
                  w, row.bar_y1 - row.bar_y0,
                  pct, {
                      fg = self:_bar_color_for(row),
                      bg = self.bar_bg,
                      radius = (row.bar_y1 - row.bar_y0) / 2,
                  })
        end

        row.label_w:draw(cr)
        if self.pct_width > 0 then row.pct_w:draw(cr) end
        if self.detail_width > 0 then row.detail_w:draw(cr) end
    end
end

function BarRow:set(id, data)
    local row = self.by_id[id]
    if not row then return end
    local pct = data.pct
    local detail = data.detail

    local changed = false
    if pct ~= row.pct_value then
        row.pct_value = pct
        changed = true
        if pct ~= nil and self.pct_width > 0 then
            row.pct_w:set_text(string.format("%d%%", math.floor(pct * 100)))
        elseif pct == nil then
            row.pct_w:set_text(row.empty_text)
        end

        -- Color dinamico del texto del porcentaje (si text_warn)
        if self.text_warn then
            local c = self:_text_color_for(row)
            if c then
                row.pct_w:set_color(c[1], c[2], c[3])
            else
                -- Restaurar color por defecto
                row.pct_w:set_color(self.pct_color[1],
                                    self.pct_color[2],
                                    self.pct_color[3])
            end
        end
    end
    if detail ~= nil and detail ~= row.detail_w.text then
        row.detail_w:set_text(detail)
        changed = true
    end
    if changed then self:damage() end
end

-- Variante animada de set: hace el update normal (texto, color,
-- detail) y anima row.pct_value desde el valor actual al nuevo
-- en duration ms. Si el motor no esta listo, cae a set normal.
-- Usar cuando el tab tenga animate_values = true.
function BarRow:set_animated(id, data, duration)
    local row = self.by_id[id]
    if not row then return end
    local from = row.pct_value
    local target = data.pct
    -- Update normal (texto, color, detail). Deja row.pct_value
    -- en el valor final; lo restauramos al from para animar.
    BarRow.set(self, id, data)
    if target == nil or from == nil or from == target then return end
    local anim = require("lib.anim")
    if not anim.is_ready() then return end
    if row._anim_handle then
        row._anim_handle:cancel()
        row._anim_handle = nil
    end
    row.pct_value = from
    row._anim_handle = anim.tween_custom(self, function(e)
        row.pct_value = from + (target - from) * e
        self:damage()
    end, duration or 500, anim.EASE.out_quad, function()
        row.pct_value = target
        row._anim_handle = nil
    end)
end

function BarRow:set_empty(id, text)
    local row = self.by_id[id]
    if not row then return end
    row.pct_value = nil
    row.empty_text = text or "--"
    row.pct_w:set_text(row.empty_text)
    row.detail_w:set_text("")
    self:damage()
end

return BarRow
