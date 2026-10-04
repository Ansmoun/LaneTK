local Area  = require("lib.area")
local cairo = require("lib.cairo")
local pango = require("lib.pango")

local Text = setmetatable({}, { __index = Area })
Text.__index = Text

-- opts:
--   text    : contenido plano
--   markup  : contenido con markup Pango (<b>, <i>, <span color=...>)
--             Si se pasa, tiene prioridad sobre text.
--   font    : "Familia Estilo Tamaño"
--   r,g,b   : color 0..1
--   align   : "left" | "center" | "right"
--   valign  : "top"  | "center" | "bottom"
function Text.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), Text)
    self.text   = opts.text  or ""
    self.markup = opts.markup
    self.font   = opts.font  or "DejaVu Sans 12"
    self.r      = opts.r or 1.0
    self.g      = opts.g or 1.0
    self.b      = opts.b or 1.0
    self.align  = opts.align  or "left"
    self.valign = opts.valign or "center"
    self.wrap   = opts.wrap or false

    self:_remeasure()
    return self
end

function Text:_remeasure()
    local plain = self.markup
        and self.markup:gsub("<[^>]+>", "")
        or  self.text
    local old_w, old_h = self.text_w, self.text_h
    self.text_w, self.text_h = pango.measure(plain, self.font)
    self.min_w, self.min_h = self.text_w, self.text_h
    self.max_w = 10000
    self.max_h = 10000
    -- Si el tamano del texto cambio, invalidar el layout del padre
    -- para que recalcule el minimo de este widget en el grupo.
    if old_w ~= self.text_w or old_h ~= self.text_h then
        local par = self.parent
        if par and par.invalidate_layout then
            par:invalidate_layout()
        elseif self.window and self.window.damage_all then
            self.window:damage_all()
        end
    end
end

function Text:set_text(text)
    self.text = text or ""
    self.markup = nil
    self:_remeasure()
    self:damage()
end

function Text:set_color(r, g, b)
    if self.r == r and self.g == g and self.b == b then return end
    self.r, self.g, self.b = r, g, b
    self:damage()
end

function Text:set_markup(markup)
    self.markup = markup
    self:_remeasure()
    self:damage()
end

function Text:askMinMax(minw, minh, maxw, maxh)
    return minw + self.min_w, minh + self.min_h,
           maxw + self.max_w, maxh + self.max_h
end

function Text:draw(cr)
    local x = self.x0
    if self.align == "center" then
        x = self.x0 + (self:getWidth() - self.text_w) / 2
    elseif self.align == "right" then
        x = self.x1 - self.text_w
    end

    local y = self.y0
    if self.valign == "center" then
        y = self.y0 + (self:getHeight() - self.text_h) / 2
    elseif self.valign == "bottom" then
        y = self.y1 - self.text_h
    end

    -- Si el texto desborda y no hay wrap, clip al rect del widget.
    if not (self.wrap and self:getWidth() < self.text_w) then
        if self.text_w > self:getWidth() or self.text_h > self:getHeight() then
            cairo.save(cr)
            cairo.rectangle(cr, self.x0, self.y0,
                self:getWidth(), self:getHeight())
            cairo.clip(cr)
            self:_draw_text(cr, x, y)
            cairo.restore(cr)
            return
        end
    end

    self:_draw_text(cr, x, y)
end

function Text:_draw_text(cr, x, y)
    local color = {
        r = self.r, g = self.g, b = self.b,
        align = pango.ALIGN.LEFT,
    }

    -- Si el texto es mas ancho que la celda y wrap esta activo,
    -- activar wrapping al ancho disponible. Empujamos el texto
    -- alineado a la izquierda cuando hacemos wrap (Pango alinea
    -- con respecto al ancho del layout, no al rect de dibujo).
    if self.wrap and self:getWidth() < self.text_w then
        color.wrap_width = self:getWidth()
    end

    if self.markup then
        pango.draw_markup(cr, x, y, self.markup, self.font, color)
    else
        pango.draw_text(cr, x, y, self.text, self.font, color)
    end
end

return Text
