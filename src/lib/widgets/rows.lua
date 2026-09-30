local Area  = require("lib.area")
local Text  = require("lib.widgets.text")
local RowParse = require("lib.widgets.rowparse")

local Rows = setmetatable({}, { __index = Area })
Rows.__index = Rows

function Rows.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), Rows)

    self.group_width = opts.group_width or 48
    self.name_width  = opts.name_width  or 110
    self.value_width = opts.value_width or 60
    self.row_height  = opts.row_height  or 16
    self.row_spacing = opts.row_spacing or 4
    self.col_gap     = opts.col_gap or 6

    self.group_font  = opts.group_font  or "DejaVu Sans 10"
    self.group_color = opts.group_color or { 0.55, 0.55, 0.60 }
    self.name_font   = opts.name_font   or "DejaVu Sans 10"
    self.name_color  = opts.name_color  or { 0.85, 0.85, 0.90 }
    self.value_font  = opts.value_font  or "DejaVu Sans Mono 10"
    self.value_color = opts.value_color or { 0.90, 0.90, 0.90 }
    self.value_align = opts.value_align or "right"

    self.rows = {}
    self.by_id = {}

    for _, r in ipairs(opts.rows or {}) do
        local id, group, name = RowParse.parse(r, { "id", "group", "name" })
        self:add_row(id, group, name)
    end
    return self
end

function Rows:add_row(id, group, name)
    local row = {
        id = id,
        group = group,
        name = name,
        group_w = Text.new {
            text = group, font = self.group_font,
            r = self.group_color[1], g = self.group_color[2], b = self.group_color[3],
            align = "left", valign = "center",
        },
        name_w = Text.new {
            text = name, font = self.name_font,
            r = self.name_color[1], g = self.name_color[2], b = self.name_color[3],
            align = "left", valign = "center",
        },
        value_w = Text.new {
            text = "--", font = self.value_font,
            r = self.value_color[1], g = self.value_color[2], b = self.value_color[3],
            align = self.value_align, valign = "center",
        },
    }
    self.rows[#self.rows + 1] = row
    self.by_id[id] = row
    return row
end

function Rows:set_window(win)
    self.window = win
    for _, r in ipairs(self.rows) do
        r.group_w.window = win
        r.name_w.window = win
        r.value_w.window = win
    end
end

function Rows:_total_height()
    local n = #self.rows
    if n == 0 then return 0 end
    return n * self.row_height + (n - 1) * self.row_spacing
end

function Rows:askMinMax(minw, minh, maxw, maxh)
    local w = self.group_width + self.name_width + self.value_width + 16
    local h = self:_total_height()
    return minw + w, minh + h, maxw + 10000, maxh + 10000
end

function Rows:layout(x0, y0, x1, y1)
    Area.layout(self, x0, y0, x1, y1)
    local n = #self.rows
    if n == 0 then return end

    local avail_w = x1 - x0
    local avail_h = y1 - y0

    -- Reparto vertical
    local total = n * self.row_height + (n - 1) * self.row_spacing
    local row_h = self.row_height
    local row_gap = self.row_spacing
    if total > 0 and avail_h > total then
        row_h = row_h + math.floor((avail_h - total) / n)
    elseif total > 0 and avail_h < total then
        local scale = avail_h / total
        row_h = math.max(12, math.floor(row_h * scale))
        row_gap = math.max(1, math.floor(row_gap * scale))
    end

    -- Anchos de columna: naturales segun contenido, con minimos.
    local max_group_w = 0
    local max_name_w = 0
    local max_value_w = 0
    for _, r in ipairs(self.rows) do
        local gw = r.group_w.text_w or 0
        local nw = r.name_w.text_w or 0
        local vw = r.value_w.text_w or 0
        if gw > max_group_w then max_group_w = gw end
        if nw > max_name_w then max_name_w = nw end
        if vw > max_value_w then max_value_w = vw end
    end
    max_group_w = math.max(max_group_w, self.group_width)
    max_name_w  = math.max(max_name_w,  self.name_width)
    max_value_w = math.max(max_value_w, self.value_width)

    local needed = max_group_w + max_name_w + max_value_w
                 + self.col_gap * 2
    local group_w, name_w, value_w
    if needed <= avail_w then
        -- Hay hueco: repartir proporcionalmente entre name y value
        -- (group queda a su natural, el resto se reparte).
        group_w = max_group_w
        local extra = avail_w - needed
        name_w  = max_name_w  + math.floor(extra / 2)
        value_w = max_value_w + (extra - math.floor(extra / 2))
    else
        -- Comprimir proporcionalmente al natural.
        local scale = avail_w / needed
        group_w = math.floor(max_group_w * scale)
        name_w  = math.floor(max_name_w  * scale)
        value_w = math.floor(max_value_w * scale)
    end

    local y = y0
    for _, row in ipairs(self.rows) do
        local ry0 = y
        local ry1 = y + row_h

        local gx0 = x0
        local gx1 = x0 + group_w
        local nx0 = gx1 + self.col_gap
        local nx1 = nx0 + name_w
        local vx0 = x1 - value_w
        if vx0 < nx1 + self.col_gap then vx0 = nx1 + self.col_gap end

        row.group_w:layout(gx0, ry0, gx1, ry1)
        row.name_w:layout(nx0, ry0, nx1, ry1)
        row.value_w:layout(vx0, ry0, x1, ry1)

        y = ry1 + row_gap
    end
end

function Rows:draw(cr)
    for _, row in ipairs(self.rows) do
        row.group_w:draw(cr)
        row.name_w:draw(cr)
        row.value_w:draw(cr)
    end
end

function Rows:set(id, value, format)
    local row = self.by_id[id]
    if not row then return end
    local text
    if format and type(value) == "number" then
        text = string.format(format, value)
    else
        text = tostring(value)
    end
    row.value_w:set_text(text)
end

function Rows:set_markup(id, markup)
    local row = self.by_id[id]
    if not row then return end
    row.value_w:set_markup(markup)
end

return Rows
