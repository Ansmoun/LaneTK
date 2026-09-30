-- CardButton: boton con icono PNG grande arriba, titulo y subtitulo
-- debajo. Hover animado por interpolacion de color de fondo.
-- Pensado para grillas de modos/opciones.
--
-- A diferencia de LogoutButton, no intercambia icono light/dark en
-- hover: el color de fondo cambia sutilmente pero el icono se queda
-- igual. Apropiado para botones de "modo" que no tienen semantica
-- de color por accion.

local Area  = require("lib.area")
local cairo = require("lib.cairo")
local pango = require("lib.pango")
local anim  = require("lib.anim")
local G     = require("lib.helpers.graphics")

local CardButton = setmetatable({}, { __index = Area })
CardButton.__index = CardButton

local function hex_to_rgb(hex)
    local r, g, b = G.hex_to_rgba(hex)
    return { r, g, b }
end

function CardButton.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), CardButton)
    self._hover_visual = true

    self.icon          = opts.icon
    self.icon_dir      = opts.icon_dir or ""
    self.icon_size     = opts.icon_size or 48
    self.title         = opts.title or ""
    self.subtitle      = opts.subtitle or ""
    self.bg_color      = opts.bg_color      or "#13171f"
    self.hover_color   = opts.hover_color   or "#1a1f28"
    self.fg_color      = opts.fg_color      or "#bfbdb6"
    self.fg_dark_color = opts.fg_dark_color or "#000000"
    self.fg_sub_color  = opts.fg_sub_color  or "#565b66"
    self.border_color  = opts.border_color  or "#242a35"
    self.corner_radius = opts.corner_radius or 8
    self.font_title    = opts.font_title    or "DejaVu Sans Bold 11"
    self.font_sub      = opts.font_sub      or "DejaVu Sans 9"

    self.width  = opts.width  or 200
    self.height = opts.height or 110
    self.min_w, self.max_w = self.width, self.width
    self.min_h, self.max_h = self.height, self.height

    if self.icon then
        self.icon_surface = cairo.load_png_cached(
            self.icon_dir .. self.icon .. ".png")
    end

    self.selected = false
    self.accent_color = opts.accent_color or "#e6b450"
    self.hover_t = 0
    self._hover_handle = nil

    self._bg_rgb     = hex_to_rgb(self.bg_color)
    self._hover_rgb  = hex_to_rgb(self.hover_color)
    self._fg_rgb      = hex_to_rgb(self.fg_color)
    self._fg_dark_rgb = hex_to_rgb(self.fg_dark_color)
    self._fg_sub_rgb  = hex_to_rgb(self.fg_sub_color)
    self._border_rgb  = hex_to_rgb(self.border_color)
    self._accent_rgb  = hex_to_rgb(self.accent_color)

    return self
end

function CardButton:set_hover(v)
    v = v and true or false
    if self.hover == v then return end
    Area.set_hover(self, v)
    self:_animate_hover(v and 1 or 0)
end

function CardButton:_animate_hover(target)
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
        local dur = math.max(20, 180 * math.abs(target - from))
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

function CardButton:draw(cr)
    local w = self:getWidth()
    local h = self:getHeight()
    local t = self.hover_t
    local r = self.corner_radius

    -- Fondo interpolado
    local br = self._bg_rgb[1] + (self._hover_rgb[1] - self._bg_rgb[1]) * t
    local bg = self._bg_rgb[2] + (self._hover_rgb[2] - self._bg_rgb[2]) * t
    local bb = self._bg_rgb[3] + (self._hover_rgb[3] - self._bg_rgb[3]) * t
    cairo.set_rgb(cr, br, bg, bb)
    cairo.rounded_rect(cr, self.x0, self.y0, w, h, r)
    cairo.fill(cr)

    -- Borde: accent de 2px si selected, sino 1px del theme.
    if self.selected and self._accent_rgb then
        cairo.set_rgb(cr, self._accent_rgb[1],
            self._accent_rgb[2], self._accent_rgb[3])
        cairo.set_line_width(cr, 2)
        cairo.rounded_rect(cr, self.x0 + 1, self.y0 + 1,
            w - 2, h - 2, r)
        cairo.stroke(cr)
    elseif self._border_rgb then
        cairo.set_rgb(cr, self._border_rgb[1],
            self._border_rgb[2], self._border_rgb[3])
        cairo.set_line_width(cr, 1)
        cairo.rounded_rect(cr, self.x0 + 0.5, self.y0 + 0.5,
            w - 1, h - 1, r)
        cairo.stroke(cr)
    end

    -- Interpolar fg y subtitle hacia negro segun hover_t
    local fg_r = self._fg_rgb[1] +
        (self._fg_dark_rgb[1] - self._fg_rgb[1]) * t
    local fg_g = self._fg_rgb[2] +
        (self._fg_dark_rgb[2] - self._fg_rgb[2]) * t
    local fg_b = self._fg_rgb[3] +
        (self._fg_dark_rgb[3] - self._fg_rgb[3]) * t

    -- El subtitle tambien va hacia negro (mas tenue el contraste)
    local sub_r = self._fg_sub_rgb[1] +
        (self._fg_dark_rgb[1] - self._fg_sub_rgb[1]) * t
    local sub_g = self._fg_sub_rgb[2] +
        (self._fg_dark_rgb[2] - self._fg_sub_rgb[2]) * t
    local sub_b = self._fg_sub_rgb[3] +
        (self._fg_dark_rgb[3] - self._fg_sub_rgb[3]) * t

    -- Layout interno: icono arriba, titulo en medio, subtitle abajo
    local tw, th = pango.measure(self.title, self.font_title)
    local sw, sh = 0, 0
    if self.subtitle ~= "" then
        sw, sh = pango.measure(self.subtitle, self.font_sub)
    end

    local icon_sz = self.icon_size
    local gap1 = 6
    local gap2 = 3
    local block_h = icon_sz + gap1 + th
    if self.subtitle ~= "" then block_h = block_h + gap2 + sh end
    local start_y = self.y0 + (h - block_h) / 2

    if self.icon_surface then
        local ix = self.x0 + (w - icon_sz) / 2
        -- Tintar el icono con el color fg interpolado. Preserva el
        -- alpha del PNG (los SVG tienen trazo blanco solido sobre
        -- fondo transparente, asi que el tintado da el color exacto
        -- donde hay tinta).
        cairo.draw_surface_tinted(cr, self.icon_surface, ix, start_y,
            icon_sz, icon_sz, fg_r, fg_g, fg_b)
    end

    local ty = start_y + icon_sz + gap1
    local tx = self.x0 + (w - tw) / 2
    pango.draw_text(cr, tx, ty, self.title, self.font_title,
        { r = fg_r, g = fg_g, b = fg_b })

    if self.subtitle ~= "" then
        local sy = ty + th + gap2
        local sx = self.x0 + (w - sw) / 2
        pango.draw_text(cr, sx, sy, self.subtitle, self.font_sub,
            { r = sub_r, g = sub_g, b = sub_b })
    end
end

return CardButton
