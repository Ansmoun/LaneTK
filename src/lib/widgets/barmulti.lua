local Area  = require("lib.area")
local cairo = require("lib.cairo")
local pango = require("lib.pango")
local G     = require("lib.helpers.graphics")

local BarMulti = setmetatable({}, { __index = Area })
BarMulti.__index = BarMulti

-- opts:
--   segments        : array de { id, color, label }
--   bar_height      : alto de la barra
--   legend_cols     : MAXIMO de columnas (se reduce si no caben)
--   legend_cols_min : minimo de columnas (default 1)
--   legend_gap_y    : separacion vertical entre filas (minimo)
--   legend_gap_x    : separacion horizontal entre columnas (minimo)
--   legend_dot      : tamaño del cuadro de color
--   legend_font
--   legend_color
--   value_format    : string.format para el valor
--   bar_bg
--   bar_radius
function BarMulti.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), BarMulti)

    self.bar_height     = opts.bar_height     or 18
    self.bar_bg         = opts.bar_bg         or "#3c3836"
    self.bar_radius     = opts.bar_radius     or (self.bar_height / 2)
    self.legend_cols    = opts.legend_cols    or 2
    self.legend_cols_min= opts.legend_cols_min or 1
    self.legend_gap_y   = opts.legend_gap_y   or 4
    self.legend_gap_x   = opts.legend_gap_x   or 12
    self.legend_dot     = opts.legend_dot     or 10
    self.legend_font    = opts.legend_font    or "DejaVu Sans 10"
    self.legend_color   = opts.legend_color   or { 0.75, 0.75, 0.80 }
    self.value_format   = opts.value_format   or "%.1f"

    self.segments = {}
    self.by_id = {}
    for _, s in ipairs(opts.segments or {}) do
        self:add_segment(s.id, s.color, s.label)
    end
    return self
end

function BarMulti:add_segment(id, color, label)
    local seg = {
        id = id, color = color, label = label,
        pct = 0, value_str = nil,
    }
    self.segments[#self.segments + 1] = seg
    self.by_id[id] = seg
    return seg
end

function BarMulti:_text_for(seg)
    if seg.value_str then
        return string.format("%s  %s", seg.label, seg.value_str)
    elseif self.value_format then
        return string.format("%s  " .. self.value_format,
            seg.label, seg.pct * 100)
    end
    return seg.label
end

function BarMulti:askMinMax(minw, minh, maxw, maxh)
    -- Minimo: barra + una fila de leyenda.
    local _, line_h = pango.measure("X", self.legend_font)
    local h = self.bar_height + 8 + line_h
    local w = 120
    return minw + w, minh + h, maxw + 10000, maxh + 10000
end

function BarMulti:set(values)
    local changed = false
    for _, v in ipairs(values) do
        local seg = self.by_id[v.id]
        if seg then
            if v.pct ~= seg.pct then seg.pct = v.pct; changed = true end
            if v.color then seg.color = v.color end
            if v.value_str ~= nil and v.value_str ~= seg.value_str then
                seg.value_str = v.value_str
                changed = true
            end
        end
    end
    if changed then self:damage() end
end

-- Calcula el layout de la leyenda para el rect dado.
-- Devuelve: cols, rows, col_widths[], col_x[], row_h, gap_y, gap_x
function BarMulti:_compute_legend(w, avail_h)
    local n = #self.segments
    if n == 0 then return nil end

    local _, line_h = pango.measure("X", self.legend_font)

    -- Anchos naturales de cada segmento
    local natural = {}
    for i, seg in ipairs(self.segments) do
        local tw = pango.measure(self:_text_for(seg), self.legend_font)
        natural[i] = tw + self.legend_dot + 6 + 4  -- dot + gap + margen
    end

    -- Probar de max_cols hacia abajo hasta cols_min, buscando la
    -- primera configuracion que quepa en el ancho Y en el alto.
    for cols = self.legend_cols, self.legend_cols_min, -1 do
        local rows = math.ceil(n / cols)

        -- Ancho de cada columna = max de los anchos de sus segmentos
        local col_w = {}
        for c = 1, cols do col_w[c] = 0 end
        for i = 1, n do
            local col = (i - 1) % cols + 1
            if natural[i] > col_w[col] then col_w[col] = natural[i] end
        end

        local total_w = 0
        for c = 1, cols do total_w = total_w + col_w[c] end
        total_w = total_w + (cols - 1) * self.legend_gap_x

        -- Alto que ocuparia
        local needed_h = rows * line_h + (rows - 1) * self.legend_gap_y

        if total_w <= w and needed_h <= avail_h then
            -- Encaja. Repartir el sobrante de ancho en partes iguales.
            local extra_x = 0
            if cols > 1 and total_w < w then
                extra_x = (w - total_w) / (cols - 1)
            end

            local col_x = {}
            local cx = 0
            for c = 1, cols do
                col_x[c] = cx
                cx = cx + col_w[c] + self.legend_gap_x + extra_x
            end

            -- Repartir tambien el sobrante de alto en gaps.
            local gap_y = self.legend_gap_y
            if rows > 1 and needed_h < avail_h then
                gap_y = (avail_h - rows * line_h) / (rows - 1)
            end

            return {
                cols = cols, rows = rows,
                col_w = col_w, col_x = col_x,
                line_h = line_h,
                gap_y = gap_y,
            }
        end
    end

    -- Ni con cols_min cabe. Usar cols_min y clip.
    local cols = self.legend_cols_min
    local rows = math.ceil(n / cols)
    local col_w = {}
    for c = 1, cols do col_w[c] = w / cols end
    local col_x = {}
    for c = 1, cols do col_x[c] = (c - 1) * (w / cols) end
    return {
        cols = cols, rows = rows,
        col_w = col_w, col_x = col_x,
        line_h = line_h,
        gap_y = self.legend_gap_y,
    }
end

function BarMulti:draw(cr)
    local x, y = self.x0, self.y0
    local w = self:getWidth()
    local h = self:getHeight()

    -- Barra apilada
    local bar_parts = {}
    for _, seg in ipairs(self.segments) do
        bar_parts[#bar_parts + 1] = { pct = seg.pct, color = seg.color }
    end
    G.stacked_bar(cr, x, y, w, self.bar_height, bar_parts, {
        bg = self.bar_bg,
        radius = self.bar_radius,
    })

    -- Leyenda
    local legend_y = y + self.bar_height + 8
    local avail_h = h - self.bar_height - 8
    if avail_h <= 0 then return end

    local L = self:_compute_legend(w, avail_h)
    if not L then return end

    for i, seg in ipairs(self.segments) do
        local col = (i - 1) % L.cols + 1
        local row = math.floor((i - 1) / L.cols)
        local lx = x + L.col_x[col]
        local cw = L.col_w[col]
        local ly = legend_y + row * (L.line_h + L.gap_y)

        -- Clip por celda
        cairo.save(cr)
        cairo.rectangle(cr, lx, ly, cw, L.line_h + 2)
        cairo.clip(cr)

        G.set_color(cr, seg.color)
        cairo.rounded_rect(cr, lx, ly + (L.line_h - self.legend_dot) / 2,
            self.legend_dot, self.legend_dot, 2)
        cairo.fill(cr)

        local c = self.legend_color
        pango.draw_text(cr, lx + self.legend_dot + 6, ly,
            self:_text_for(seg), self.legend_font,
            { r = c[1], g = c[2], b = c[3] })

        cairo.restore(cr)
    end
end

return BarMulti
