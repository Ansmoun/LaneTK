local Area  = require("lib.area")
local cairo = require("lib.cairo")
local pango = require("lib.pango")
local G     = require("lib.helpers.graphics")

local Pills = setmetatable({}, { __index = Area })
Pills.__index = Pills

-- opts:
--   items      : array de { id, text, color }
--   gap        : espacio horizontal entre pills (default 6)
--   pad_x      : padding horizontal interno      (default 8)
--   pad_y      : padding vertical interno        (default 3)
--   font
--   text_color : color del texto dentro del pill
--   radius     : radio de las esquinas (default = alto/2)
function Pills.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), Pills)

    self.gap        = opts.gap or 6
    self.pad_x      = opts.pad_x or 8
    self.pad_y      = opts.pad_y or 3
    self.font       = opts.font or "DejaVu Sans 10"
    self.text_color = opts.text_color or { 0.10, 0.10, 0.14 }
    self.radius     = opts.radius

    self.items = {}
    for _, item in ipairs(opts.items or {}) do
        self:add(item.id, item.text, item.color)
    end
    return self
end

function Pills:add(id, text, color)
    local pill = { id = id, text = text, color = color or "#8ec07c" }
    local tw, th = pango.measure(text, self.font)
    pill.text_w = tw
    pill.text_h = th
    pill.w = tw + self.pad_x * 2
    pill.h = th + self.pad_y * 2
    self.items[#self.items + 1] = pill
    return pill
end

function Pills:_total_height()
    local h = 0
    for _, p in ipairs(self.items) do
        if p.h > h then h = p.h end
    end
    return h
end

function Pills:_total_width()
    local w = 0
    for i, p in ipairs(self.items) do
        w = w + p.w
        if i < #self.items then w = w + self.gap end
    end
    return w
end

function Pills:askMinMax(minw, minh, maxw, maxh)
    return minw + self:_total_width(), minh + self:_total_height(),
           maxw + 10000, maxh + self:_total_height()
end

function Pills:layout(x0, y0, x1, y1)
    Area.layout(self, x0, y0, x1, y1)
    local x = x0
    local h = self:_total_height()
    for _, p in ipairs(self.items) do
        p.x0 = x
        p.y0 = y0 + (self:getHeight() - h) / 2
        p.x1 = x + p.w
        p.y1 = p.y0 + p.h
        x = x + p.w + self.gap
    end
end

function Pills:draw(cr)
    for _, p in ipairs(self.items) do
        local radius = self.radius or (p.h / 2)
        G.set_color(cr, p.color)
        cairo.rounded_rect(cr, p.x0, p.y0, p.w, p.h, radius)
        cairo.fill(cr)

        local tc = self.text_color
        pango.draw_text(cr, p.x0 + self.pad_x,
            p.y0 + (p.h - p.text_h) / 2,
            p.text, self.font,
            { r = tc[1], g = tc[2], b = tc[3] })
    end
end

function Pills:set(id, text)
    for _, p in ipairs(self.items) do
        if p.id == id then
            p.text = text
            local tw, th = pango.measure(text, self.font)
            p.text_w = tw
            p.text_h = th
            p.w = tw + self.pad_x * 2
            p.h = th + self.pad_y * 2
            self:damage()
            return
        end
    end
end

function Pills:set_color(id, color)
    for _, p in ipairs(self.items) do
        if p.id == id then
            p.color = color
            self:damage()
            return
        end
    end
end

return Pills
