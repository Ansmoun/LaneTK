-- Icon: dibuja una imagen PNG en un Area.
-- Soporta tintado (color solido) preservando el alpha del original.

local Area  = require("lib.area")
local cairo = require("lib.cairo")

local Icon = setmetatable({}, { __index = Area })
Icon.__index = Icon

-- opts:
--   path      : ruta al PNG
--   width     : ancho en pixeles (default: nativo)
--   height    : alto en pixeles  (default: nativo)
--   color     : {r,g,b} opcional. Si se pasa, tinta el icono.
--   color_hex : "#RRGGBB" alternativa a color.
--   valign    : "top" | "center" | "bottom"  (default "center")
--   halign    : "left" | "center" | "right"  (default "left")
--   on_click  : function(self) opcional
function Icon.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), Icon)
    self._hover_visual  = true
    self._pressed_visual = true

    self.path     = opts.path
    self.color    = opts.color
    self.valign   = opts.valign or "center"
    self.halign   = opts.halign or "left"

    if opts.color_hex and not self.color then
        local G = require("lib.helpers.graphics")
        local r, g, b = G.hex_to_rgba(opts.color_hex)
        self.color = { r, g, b }
    end

    self.surface, self.err = nil, nil
    if opts.surface then
        self.surface = opts.surface
    elseif self.path then
        if self.path:sub(-4):lower() == ".svg" then
            self.surface, self.err = require("lib.svg").load(
                self.path, opts.width, opts.height)
        else
            self.surface, self.err = cairo.load_png_cached(self.path)
        end
    end

    if self.surface then
        self.native_w = cairo.surface_width(self.surface)
        self.native_h = cairo.surface_height(self.surface)
    else
        self.native_w, self.native_h = 16, 16
    end

    self.width  = opts.width  or self.native_w
    self.height = opts.height or self.native_h

    self.min_w = self.width
    self.min_h = self.height
    self.max_w = self.width
    self.max_h = self.height

    return self
end

function Icon:set_path(path)
    self.path = path
    if path then
        if path:sub(-4):lower() == ".svg" then
            self.surface, self.err = require("lib.svg").load(
                path, self.width, self.height)
        else
            self.surface, self.err = cairo.load_png_cached(path)
        end
        if self.surface then
            self.native_w = cairo.surface_width(self.surface)
            self.native_h = cairo.surface_height(self.surface)
        end
    else
        self.surface = nil
    end
    self:damage()
end

function Icon:set_color(r, g, b)
    if r == nil then
        self.color = nil
    else
        self.color = { r, g, b }
    end
    self:damage()
end

function Icon:set_color_hex(hex)
    if not hex then
        self.color = nil
    else
        local G = require("lib.helpers.graphics")
        local r, g, b = G.hex_to_rgba(hex)
        self.color = { r, g, b }
    end
    self:damage()
end

function Icon:draw(cr)
    if not self.surface then return end

    local x = self.x0
    local y = self.y0
    if self.halign == "center" then
        x = self.x0 + (self:getWidth() - self.width) / 2
    elseif self.halign == "right" then
        x = self.x1 - self.width
    end
    if self.valign == "center" then
        y = self.y0 + (self:getHeight() - self.height) / 2
    elseif self.valign == "bottom" then
        y = self.y1 - self.height
    end

    if self.color then
        cairo.draw_surface_tinted(cr, self.surface, x, y,
            self.width, self.height,
            self.color[1], self.color[2], self.color[3])
    else
        cairo.draw_surface(cr, self.surface, x, y,
            self.width, self.height)
    end
end

function Icon:on_mouse_press(mx, my, button)
    if button == 1 and self.opts.on_click then
        self.opts.on_click(self)
    end
end

return Icon
