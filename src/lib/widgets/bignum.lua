local Area  = require("lib.area")
local pango = require("lib.pango")

local Bignum = setmetatable({}, { __index = Area })
Bignum.__index = Bignum

-- opts:
--   value       : string del numero (ej "45")
--   unit        : string debajo del numero pero mas pequeño (ej "%")
--                 Opcional; si nil, no se muestra.
--   caption     : string de caption (ej "Uso de CPU")
--   size        : tamaño de la fuente del numero (default 28)
--   caption_size: tamaño de la fuente del caption (default 10)
--   color       : {r,g,b} del numero
--   caption_color
--   unit_color  : color de la unidad (default caption_color)
function Bignum.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), Bignum)
    self.value        = opts.value or "0"
    self.unit         = opts.unit
    self.caption      = opts.caption or ""
    self.size         = opts.size or 28
    self.caption_size = opts.caption_size or 10
    self.color        = opts.color or { 0.95, 0.95, 0.95 }
    self.unit_color   = opts.unit_color or { 0.65, 0.65, 0.70 }
    self.caption_color = opts.caption_color or { 0.55, 0.55, 0.60 }

    self.num_font = string.format("DejaVu Sans Bold %d", self.size)
    self.unit_font = string.format("DejaVu Sans %d", self.caption_size)
    self.cap_font  = string.format("DejaVu Sans %d", self.caption_size)
    self:_remeasure()
    return self
end

function Bignum:_remeasure()
    local num_w, num_h = pango.measure(self.value, self.num_font)
    local unit_w, unit_h = 0, 0
    if self.unit then
        unit_w, unit_h = pango.measure(self.unit, self.unit_font)
    end
    local cap_w, cap_h = 0, 0
    if self.caption ~= "" then
        cap_w, cap_h = pango.measure(self.caption, self.cap_font)
    end

    self.w_min = math.max(num_w, unit_w, cap_w)
    self.h_min = num_h + (self.unit and (unit_h + 1) or 0)
               + (self.caption ~= "" and (cap_h + 2) or 0)

    self.min_w, self.min_h = self.w_min, self.h_min
    self.max_w, self.max_h = self.w_min, self.h_min
end

function Bignum:set(value, caption, unit)
    if value ~= nil then self.value = tostring(value) end
    if caption ~= nil then self.caption = caption end
    if unit ~= nil then self.unit = unit end
    self:_remeasure()
    self:damage()
end

function Bignum:draw(cr)
    local total_w = self:getWidth()
    local cx = self.x0 + total_w / 2
    local y = self.y0

    local num_w, num_h = pango.measure(self.value, self.num_font)
    local c = self.color
    pango.draw_text(cr, cx - num_w / 2, y, self.value, self.num_font,
        { r = c[1], g = c[2], b = c[3] })
    y = y + num_h

    if self.unit then
        local uw, uh = pango.measure(self.unit, self.unit_font)
        local uc = self.unit_color
        pango.draw_text(cr, cx - uw / 2, y + 1, self.unit, self.unit_font,
            { r = uc[1], g = uc[2], b = uc[3] })
        y = y + uh + 1
    end

    if self.caption ~= "" then
        local cw, ch = pango.measure(self.caption, self.cap_font)
        local cc = self.caption_color
        pango.draw_text(cr, cx - cw / 2, y + 2, self.caption, self.cap_font,
            { r = cc[1], g = cc[2], b = cc[3] })
    end
end

return Bignum
