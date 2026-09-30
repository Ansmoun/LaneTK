local Area  = require("lib.area")
local cairo = require("lib.cairo")
local pango = require("lib.pango")
local Group = require("lib.widgets.group")

local Card = setmetatable({}, { __index = Area })
Card.__index = Card

function Card.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), Card)

    self.title         = opts.title
    self.content       = opts.content
    self.padding       = opts.padding or 10
    self.spacing       = opts.spacing or 8
    self.corner_radius = opts.corner_radius or 8
    self.bg            = opts.bg or { 0.14, 0.14, 0.18 }
    self.border        = opts.border
    self.title_font    = opts.title_font or "DejaVu Sans Bold 10"
    self.title_color   = opts.title_color or { 0.65, 0.65, 0.65 }

    if self.title then
        self.title_w, self.title_h = pango.measure(self.title, self.title_font)
    else
        self.title_w, self.title_h = 0, 0
    end

    -- Altura reservada para el titulo + separacion con el contenido.
    -- Si no hay titulo, es 0.
    self.title_block_h = self.title and (self.title_h + self.spacing) or 0

    return self
end

function Card:set_title(text)
    self.title = text
    if text then
        local plain = text:gsub("<[^>]+>", "")
        self.title_w, self.title_h = pango.measure(plain, self.title_font)
        self.title_block_h = self.title_h + self.spacing
        self.title_is_markup = text:find("<") ~= nil
    else
        self.title_w, self.title_h = 0, 0
        self.title_block_h = 0
        self.title_is_markup = false
    end
    self:damage()
end

function Card:askMinMax(minw, minh, maxw, maxh)
    local pad2 = self.padding * 2
    local w = self.title_w
    local h = self.title_block_h
    if self.content then
        local cminw, cminh, cmaxw, cmaxh = self.content:askMinMax(0, 0, 0, 0)
        w = math.max(w, cminw)
        h = h + cminh
    end
    if self.opts.min_height and h + pad2 < self.opts.min_height then
        h = self.opts.min_height - pad2
    end
    if self.opts.min_width and w + pad2 < self.opts.min_width then
        w = self.opts.min_width - pad2
    end
    return minw + w + pad2, minh + h + pad2,
           maxw + w + pad2, maxh + h + pad2
end

function Card:layout(x0, y0, x1, y1)
    Area.layout(self, x0, y0, x1, y1)
    if not self.content then return end
    local px0 = x0 + self.padding
    local py0 = y0 + self.padding + self.title_block_h
    local px1 = x1 - self.padding
    local py1 = y1 - self.padding
    self.content:layout(px0, py0, px1, py1)
end

function Card:set_window(win)
    self.window = win
    if self.content and self.content.set_window then
        self.content:set_window(win)
    elseif self.content then
        self.content.window = win
    end
end

function Card:getByXY(x, y)
    if self.content then
        local hit = self.content:getByXY(x, y)
        if hit then return hit end
    end
    return Area.getByXY(self, x, y)
end

function Card:draw(cr)
    local x, y = self.x0, self.y0
    local w, h = self:getWidth(), self:getHeight()

    cairo.set_rgb(cr, self.bg[1], self.bg[2], self.bg[3])
    cairo.rounded_rect(cr, x, y, w, h, self.corner_radius)
    cairo.fill(cr)

    if self.border then
        local b = self.border
        cairo.set_rgb(cr, b[1], b[2], b[3])
        cairo.set_line_width(cr, 1)
        cairo.rounded_rect(cr, x + 0.5, y + 0.5,
                           w - 1, h - 1, self.corner_radius)
        cairo.stroke(cr)
    end

    -- Titulo, con clip a su ancho disponible
    if self.title then
        local avail = w - self.padding * 2
        local tx = x + (w - self.title_w) / 2
        local ty = y + self.padding
        local c = self.title_color

        cairo.save(cr)
        cairo.rectangle(cr, x + self.padding, y,
            avail, self.padding + self.title_h + 2)
        cairo.clip(cr)
        if self.title_is_markup then
            pango.draw_markup(cr, tx, ty, self.title, self.title_font,
                { r = c[1], g = c[2], b = c[3] })
        else
            pango.draw_text(cr, tx, ty, self.title, self.title_font,
                { r = c[1], g = c[2], b = c[3] })
        end
        cairo.restore(cr)
    end

    -- Contenido, con clip al area interior
    if self.content then
        local px0 = x + self.padding
        local py0 = y + self.padding + self.title_block_h
        local px1 = x + w - self.padding
        local py1 = y + h - self.padding
        if px1 > px0 and py1 > py0 then
            cairo.save(cr)
            cairo.rectangle(cr, px0, py0, px1 - px0, py1 - py0)
            cairo.clip(cr)
            if self.content:should_draw() then
                self.content:draw(cr)
            end
            cairo.restore(cr)
        end
    end
end

return Card
