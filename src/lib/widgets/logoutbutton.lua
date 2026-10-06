-- LogoutButton: boton cuadrado (o ancho) con icono PNG, label, y
-- animacion de hover por interpolacion de color.
--
-- Modos:
--   - Cuadrado (default): icono arriba, label abajo.
--   - Wide: icono a la izquierda, label a la derecha.
--
-- Hover: al entrar el cursor, anima hover_t de 0 a 1 en 200 ms.
-- El draw interpola color de fondo, color de texto, y elige entre
-- el icono light y el dark (swap en hover_t >= 0.5, como el
-- original de Awesome).

local Area  = require("lib.area")
local cairo = require("lib.cairo")
local pango = require("lib.pango")
local anim  = require("lib.anim")
local G     = require("lib.helpers.graphics")

local LogoutButton = setmetatable({}, { __index = Area })
LogoutButton.__index = LogoutButton

local function hex_to_rgb(hex)
    local r, g, b = G.hex_to_rgba(hex)
    return { r, g, b }
end

function LogoutButton.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), LogoutButton)

    self._hover_visual = true
    self.icon        = opts.icon
    self.label       = opts.label or ""
    self.icon_dir    = opts.icon_dir or ""
    self.hover_color = opts.hover_color or "#888888"
    self.bg_color    = opts.bg_color    or "#111111"
    self.fg_color    = opts.fg_color    or "#ebdbb2"
    self.fg_dark     = opts.fg_dark     or "#000000"
    self.border_color = opts.border_color
    self.font        = opts.font or "DejaVu Sans 10"
    self.icon_size   = opts.icon_size or 44
    self.corner_radius = opts.corner_radius or 6
    self.wide        = opts.wide or false

    self.width  = opts.width  or 120
    self.height = opts.height or 120
    self.min_w, self.min_h = self.width, self.height
    self.max_w, self.max_h = self.width, self.height

    if self.icon then
        -- Resolver via lib.icons primero, que prefiere SVG y cae
        -- a PNG. El widget antes solo cargaba PNG directo, y tras
        -- la migracion a SVG los iconos quedaban invisibles.
        local ok_icons, icons = pcall(require, "lib.icons")
        if ok_icons and icons then
            self.icon_light = icons.surface(self.icon, self.icon_size)
            self.icon_dark  = icons.surface(self.icon .. "-dark",
                                            self.icon_size)
        end
        -- Fallback a PNG directo desde icon_dir.
        if not self.icon_light then
            self.icon_light = cairo.load_png_cached(
                self.icon_dir .. self.icon .. ".png")
        end
        if not self.icon_dark then
            self.icon_dark = cairo.load_png_cached(
                self.icon_dir .. self.icon .. "-dark.png")
        end
    end

    self.hover_t = 0
    self._hover_handle = nil

    self._bg_rgb      = hex_to_rgb(self.bg_color)
    self._hover_rgb   = hex_to_rgb(self.hover_color)
    self._fg_rgb      = hex_to_rgb(self.fg_color)
    self._fg_dark_rgb = hex_to_rgb(self.fg_dark)
    self._border_rgb  = self.border_color and hex_to_rgb(self.border_color) or nil

    return self
end

function LogoutButton:set_hover(v)
    v = v and true or false
    if self.hover == v then return end
    Area.set_hover(self, v)
    self:_animate_hover(v and 1 or 0)
end

function LogoutButton:_animate_hover(target)
    if self._hover_handle then
        self._hover_handle:cancel()
        self._hover_handle = nil
    end
    local from = self.hover_t
    if math.abs(target - from) < 0.001 then
        self.hover_t = target
        self:damage()
        return
    end
    if anim.is_ready() then
        local dur = math.max(20, 200 * math.abs(target - from))
        self._hover_handle = anim.tween_custom(self,
            function(eased)
                self.hover_t = from + (target - from) * eased
                self:damage()
            end,
            dur, anim.EASE.out_cubic,
            function()
                self.hover_t = target
                self._hover_handle = nil
                self:damage()
            end)
    else
        self.hover_t = target
        self:damage()
    end
end

function LogoutButton:draw(cr)
    local w = self:getWidth()
    local h = self:getHeight()
    local t = self.hover_t
    local r = self.corner_radius

    local bg_r = self._bg_rgb[1] + (self._hover_rgb[1] - self._bg_rgb[1]) * t
    local bg_g = self._bg_rgb[2] + (self._hover_rgb[2] - self._bg_rgb[2]) * t
    local bg_b = self._bg_rgb[3] + (self._hover_rgb[3] - self._bg_rgb[3]) * t

    cairo.set_rgb(cr, bg_r, bg_g, bg_b)
    cairo.rounded_rect(cr, self.x0, self.y0, w, h, r)
    cairo.fill(cr)

    if self._border_rgb then
        cairo.set_rgb(cr, self._border_rgb[1], self._border_rgb[2], self._border_rgb[3])
        cairo.set_line_width(cr, 1)
        cairo.rounded_rect(cr, self.x0 + 0.5, self.y0 + 0.5, w - 1, h - 1, r)
        cairo.stroke(cr)
    end

    local fg_r = self._fg_rgb[1] + (self._fg_dark_rgb[1] - self._fg_rgb[1]) * t
    local fg_g = self._fg_rgb[2] + (self._fg_dark_rgb[2] - self._fg_rgb[2]) * t
    local fg_b = self._fg_rgb[3] + (self._fg_dark_rgb[3] - self._fg_rgb[3]) * t

    local surface = (t >= 0.5) and self.icon_dark or self.icon_light
    local lw, lh = pango.measure(self.label, self.font)
    local iw, ih = self.icon_size, self.icon_size

    if self.wide then
        local gap = 14
        local total = iw + gap + lw
        local sx = self.x0 + (w - total) / 2
        local ix = sx
        local iy = self.y0 + (h - ih) / 2
        if surface then
            cairo.draw_surface(cr, surface, ix, iy, iw, ih)
        end
        local lx = sx + iw + gap
        local ly = self.y0 + (h - lh) / 2
        pango.draw_text(cr, lx, ly, self.label, self.font,
            { r = fg_r, g = fg_g, b = fg_b })
    else
        local gap = 8
        local block_h = ih + gap + lh
        local by = self.y0 + (h - block_h) / 2
        local ix = self.x0 + (w - iw) / 2
        if surface then
            cairo.draw_surface(cr, surface, ix, by, iw, ih)
        end
        local lx = self.x0 + (w - lw) / 2
        local ly = by + ih + gap
        pango.draw_text(cr, lx, ly, self.label, self.font,
            { r = fg_r, g = fg_g, b = fg_b })
    end
end

return LogoutButton
