-- CloseButton: boton pequeno con una X. Uso tipico: cerrar panel,
-- cerrar popup, cerrar tab.

local Area  = require("lib.area")
local cairo = require("lib.cairo")
local G     = require("lib.helpers.graphics")

local CloseButton = setmetatable({}, { __index = Area })
CloseButton.__index = CloseButton

function CloseButton.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), CloseButton)
    self._hover_visual  = true
    self._pressed_visual = true

    self.size             = opts.size or 24
    self.color            = opts.color or { 0.65, 0.65, 0.70 }
    self.color_hover      = opts.color_hover      or { 0.95, 0.95, 0.95 }
    self.color_pressed    = opts.color_pressed    or { 1.0, 1.0, 1.0 }
    self.color_hover_bg   = opts.color_hover_bg   or "#7a3030"
    self.color_pressed_bg = opts.color_pressed_bg or "#a04040"
    self.corner_radius    = opts.corner_radius or 4

    self.min_w = self.size
    self.min_h = self.size
    self.max_w = self.size
    self.max_h = self.size

    return self
end

function CloseButton:draw(cr)
    local x, y = self.x0, self.y0
    local s = self.size

    local bg
    if self.pressed then
        bg = self.color_pressed_bg
    elseif self.hover then
        bg = self.color_hover_bg
    end
    if bg then
        local r, g, b = G.hex_to_rgba(bg)
        cairo.set_rgb(cr, r, g, b)
        cairo.rounded_rect(cr, x, y, s, s, self.corner_radius)
        cairo.fill(cr)
    end

    local c = self.color
    if self.pressed then
        c = self.color_pressed
    elseif self.hover then
        c = self.color_hover
    end

    local pad = s * 0.30
    cairo.set_rgb(cr, c[1], c[2], c[3])
    cairo.set_line_width(cr, 1.6)
    cairo.new_sub_path(cr)
    cairo.move_to(cr, x + pad, y + pad)
    cairo.line_to(cr, x + s - pad, y + s - pad)
    cairo.stroke(cr)
    cairo.new_sub_path(cr)
    cairo.move_to(cr, x + s - pad, y + pad)
    cairo.line_to(cr, x + pad, y + s - pad)
    cairo.stroke(cr)
    cairo.new_path(cr)
end

function CloseButton:on_mouse_press(mx, my, button)
    if button == 1 and self.opts.on_click then
        self.opts.on_click(self)
    end
end

return CloseButton
