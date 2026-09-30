local Area  = require("lib.area")
local cairo = require("lib.cairo")
local pango = require("lib.pango")

local Button = setmetatable({}, { __index = Area })
Button.__index = Button

-- opts:
--   text            : etiqueta
--   font            : fuente Pango
--   padding_x       : espacio horizontal interno (default 16)
--   padding_y       : espacio vertical interno   (default 8)
--   corner_radius   : radio de las esquinas      (default 6)
--   color_normal    : {r,g,b} fondo normal       (default gris oscuro)
--   color_hover     : {r,g,b} fondo con hover
--   color_pressed   : {r,g,b} fondo pulsado
--   color_border    : {r,g,b} color del borde
--   color_text      : {r,g,b} color del texto
--   on_click        : function(self, button)
--   on_hover        : function(self, hover_bool)
--   on_press        : function(self, pressed_bool)
function Button.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), Button)
    self._hover_visual  = true
    self._pressed_visual = true

    self.text          = opts.text or "Button"
    self.font          = opts.font or "DejaVu Sans Bold 12"
    self.padding_x     = opts.padding_x or 16
    self.padding_y     = opts.padding_y or 8
    self.corner_radius = opts.corner_radius or 6
    self.flat          = opts.flat or false

    if self.flat then
        self.color_normal  = opts.color_normal  or { 0, 0, 0 }
        self.color_hover   = opts.color_hover   or { 0.28, 0.28, 0.36 }
        self.color_pressed = opts.color_pressed or { 0.14, 0.14, 0.20 }
        self.color_border  = nil
        self.color_text    = opts.color_text    or { 0.95, 0.95, 0.95 }
    else
        self.color_normal  = opts.color_normal  or { 0.20, 0.20, 0.26 }
        self.color_hover   = opts.color_hover   or { 0.28, 0.28, 0.36 }
        self.color_pressed = opts.color_pressed or { 0.14, 0.14, 0.20 }
        self.color_border  = opts.color_border  or { 0.45, 0.45, 0.55 }
        self.color_text    = opts.color_text    or { 0.95, 0.95, 0.95 }
    end

    self.text_w, self.text_h = pango.measure(self.text, self.font)
    self.min_w = self.text_w + self.padding_x * 2
    self.min_h = self.text_h + self.padding_y * 2
    self.max_w = self.min_w
    self.max_h = self.min_h

    return self
end

function Button:set_text(text)
    self.text = text
    self.text_w, self.text_h = pango.measure(self.text, self.font)
    self.min_w = self.text_w + self.padding_x * 2
    self.min_h = self.text_h + self.padding_y * 2
    self.max_w = self.min_w
    self.max_h = self.min_h
    self:damage()
end

function Button:draw(cr)
    local x, y = self.x0, self.y0
    local w, h = self:getWidth(), self:getHeight()

    local bg = nil
    if self.pressed then
        bg = self.color_pressed
    elseif self.hover then
        bg = self.color_hover
    elseif not self.flat then
        bg = self.color_normal
    end

    if bg then
        cairo.set_rgb(cr, bg[1], bg[2], bg[3])
        cairo.rounded_rect(cr, x, y, w, h, self.corner_radius)
        cairo.fill(cr)
    end

    if self.color_border then
        local b = self.color_border
        cairo.set_rgb(cr, b[1], b[2], b[3])
        cairo.set_line_width(cr, 1)
        cairo.rounded_rect(cr, x + 0.5, y + 0.5, w - 1, h - 1, self.corner_radius)
        cairo.stroke(cr)
    end

    -- Texto centrado
    local tx = x + (w - self.text_w) / 2
    local ty = y + (h - self.text_h) / 2
    local c = self.color_text
    pango.draw_text(cr, tx, ty, self.text, self.font,
        { r = c[1], g = c[2], b = c[3] })
end

return Button
