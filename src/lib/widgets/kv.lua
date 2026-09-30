local Area  = require("lib.area")
local pango = require("lib.pango")
local Group = require("lib.widgets.group")
local Text  = require("lib.widgets.text")
local RowParse = require("lib.widgets.rowparse")

local KV = setmetatable({}, { __index = Area })
KV.__index = KV

function KV.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), KV)

    self.key_width   = opts.key_width or 90
    self.row_height  = opts.row_height or 16
    self.key_color   = opts.key_color or { 0.55, 0.55, 0.60 }
    self.value_color = opts.value_color or { 0.90, 0.90, 0.90 }
    self.value_align = opts.value_align or "right"
    self.row_spacing = opts.row_spacing or 4
    self.key_font    = opts.key_font or "DejaVu Sans 10"
    self.value_font  = opts.value_font or "DejaVu Sans Mono 11"
    self.col_gap     = opts.col_gap or 8

    -- Alpha global (0..1) aplicado a los colores del texto.
    -- Default 1.0 = sin animacion.
    self.alpha = 1.0
    -- Tipo de animacion para intro.lua.
    self._anim_kind = "kv"
    self.rows_by_id = {}
    self.order = {}
    self.children = {}

    for _, row in ipairs(opts.rows or {}) do
        local id, label = RowParse.parse(row, { "id", "label" })
        self:add_row(id, label, row.format)
    end

    self:_rebuild()
    return self
end

function KV:add_row(id, label, format)
    local key_text = Text.new {
        text = label,
        font = self.key_font,
        r = self.key_color[1],
        g = self.key_color[2],
        b = self.key_color[3],
        align = "left",
        valign = "center",
    }
    local val_text = Text.new {
        text = "--",
        font = self.value_font,
        r = self.value_color[1],
        g = self.value_color[2],
        b = self.value_color[3],
        align = self.value_align,
        valign = "center",
    }

    local entry = {
        id = id,
        label = label,
        format = format,
        key_text = key_text,
        val_text = val_text,
        row_group = nil,
    }
    self.rows_by_id[id] = entry
    self.order[#self.order + 1] = entry
    self:_rebuild()
    return entry
end

function KV:_rebuild()
    self.children = {}
    for _, entry in ipairs(self.order) do
        local row_group = Group.new {
            orientation = "horizontal",
            spacing = self.col_gap,
            children = { entry.key_text, entry.val_text },
        }
        entry.row_group = row_group
        self.children[#self.children + 1] = row_group
    end
    self:_remeasure()
end

function KV:_remeasure()
    local h = 0
    local n = #self.children
    if n > 0 then
        h = n * self.row_height + (n - 1) * self.row_spacing
    end
    self.min_h = h
    self.max_h = 10000

    -- Ancho natural: max del ancho natural de cada key + max del
    -- valor + gap.
    local max_key_w = 0
    for _, entry in ipairs(self.order) do
        local kw = entry.key_text.text_w or 0
        if kw > max_key_w then max_key_w = kw end
    end
    self.min_w = max_key_w + self.col_gap + 60
    self.max_w = 10000
end

-- Aplica un multiplicador de alpha a los colores base del texto.
function KV:set_alpha(a)
    if a < 0 then a = 0 end
    if a > 1 then a = 1 end
    self.alpha = a
    local kc, vc = self.key_color, self.value_color
    for _, entry in ipairs(self.order) do
        entry.key_text:set_color(kc[1] * a, kc[2] * a, kc[3] * a)
        entry.val_text:set_color(vc[1] * a, vc[2] * a, vc[3] * a)
    end
end

function KV:set_window(win)
    self.window = win
    for _, entry in ipairs(self.order) do
        entry.key_text.window = win
        entry.val_text.window = win
        entry.row_group.window = win
    end
end

function KV:set(id, value)
    local entry = self.rows_by_id[id]
    if not entry then return end
    local text
    if entry.format and type(value) == "number" then
        text = string.format(entry.format, value)
    else
        text = tostring(value)
    end
    entry.val_text:set_text(text)
end

function KV:set_markup(id, markup)
    local entry = self.rows_by_id[id]
    if not entry then return end
    entry.val_text:set_markup(markup)
end

function KV:set_title(markup) end

function KV:askMinMax(minw, minh, maxw, maxh)
    return minw + self.min_w, minh + self.min_h,
           maxw + self.max_w, maxh + self.max_h
end

function KV:layout(x0, y0, x1, y1)
    Area.layout(self, x0, y0, x1, y1)
    local n = #self.children
    if n == 0 then return end

    local avail_w = x1 - x0
    local avail_h = y1 - y0

    -- Reparto vertical: comprimir o repartir
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

    -- Reparto horizontal: key_width se adapta al contenido natural
    local max_key_w = 0
    for _, entry in ipairs(self.order) do
        local kw = entry.key_text.text_w or 0
        if kw > max_key_w then max_key_w = kw end
    end
    -- La key toma su ancho natural (o el minimo configurado), el
    -- resto va al valor.
    local key_w = math.max(self.key_width, max_key_w)
    if key_w + self.col_gap + 40 > avail_w then
        key_w = math.max(40, avail_w - self.col_gap - 40)
    end

    local y = y0
    for _, row in ipairs(self.children) do
        row:layout(x0, y, x1, y + row_h)
        -- El row_group es horizontal: key y value
        -- Group:layout reparte con weights. Forzamos reparto:
        local key_text = row.children[1]
        local val_text = row.children[2]
        key_text:layout(x0, y, x0 + key_w, y + row_h)
        val_text:layout(x0 + key_w + self.col_gap, y, x1, y + row_h)
        y = y + row_h + row_gap
    end
end

function KV:draw(cr)
    for _, row in ipairs(self.children) do
        row:draw(cr)
    end
end

return KV
