local Area  = require("lib.area")
local pango = require("lib.pango")

local Header = setmetatable({}, { __index = Area })
Header.__index = Header

-- opts:
--   text   : texto (plano o con markup segun `markup`)
--   markup : bool, si true trata text como markup Pango
--   font   : default "DejaVu Sans 11"
--   color  : {r,g,b} default muted
--   align  : "left" | "center" | "right" (default left)
--   valign : "top" | "center" | "bottom" (default center)
--   wrap   : bool. Si true, hace wrapping al ancho disponible
--            cuando el texto excede la celda.
function Header.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), Header)
    self.text      = opts.text or ""
    self.is_markup = opts.markup or false
    self.font      = opts.font or "DejaVu Sans 11"
    self.color     = opts.color or { 0.65, 0.65, 0.70 }
    self.align     = opts.align or "left"
    self.valign    = opts.valign or "center"
    self.wrap      = opts.wrap or false

    self:_remeasure()
    return self
end

function Header:_plain()
    if self.is_markup then
        return (self.text:gsub("<[^>]+>", ""))
    end
    return self.text
end

function Header:_remeasure()
    local plain = self:_plain()
    self.text_w, self.text_h = pango.measure(plain, self.font)
    self.min_w = self.text_w
    self.min_h = self.text_h
    self.max_w = self.text_w
    self.max_h = self.text_h
end

function Header:set(text)
    self.text = text
    self:_remeasure()
    self:damage()
end

function Header:set_markup(markup)
    self.text = markup
    self.is_markup = true
    self:_remeasure()
    self:damage()
end

function Header:askMinMax(minw, minh, maxw, maxh)
    return minw + self.min_w, minh + self.min_h,
           maxw + self.max_w, maxh + self.max_h
end

function Header:draw(cr)
    local avail = self:getWidth()
    local x = self.x0
    if self.align == "center" and not (self.wrap and avail < self.text_w) then
        x = self.x0 + (avail - self.text_w) / 2
    elseif self.align == "right" and not (self.wrap and avail < self.text_w) then
        x = self.x1 - self.text_w
    end

    local y = self.y0
    if self.valign == "center" then
        -- Cuando hay wrap, el alto real puede ser mayor que text_h.
        -- Dejamos que Pango lo maneje desde el tope de la celda.
        if not (self.wrap and avail < self.text_w) then
            y = self.y0 + (self:getHeight() - self.text_h) / 2
        end
    elseif self.valign == "bottom" then
        y = self.y1 - self.text_h
    end

    local c = self.color
    local opts = { r = c[1], g = c[2], b = c[3] }

    if self.wrap and avail < self.text_w then
        opts.wrap_width = avail
    end

    if self.is_markup then
        pango.draw_markup(cr, x, y, self.text, self.font, opts)
    else
        pango.draw_text(cr, x, y, self.text, self.font, opts)
    end
end

return Header
