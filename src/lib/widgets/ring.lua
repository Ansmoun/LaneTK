local Area  = require("lib.area")
local cairo = require("lib.cairo")
local pango = require("lib.pango")

local Ring = setmetatable({}, { __index = Area })
Ring.__index = Ring

-- opts:
--   value       : 0..1 (inicial)
--   text        : texto principal (ej "45%")
--   sub         : texto secundario (ej "1.2 GHz")
--   thickness   : grosor del anillo (default 10)
--   color       : {r,g,b} color del arco
--   color_bg    : {r,g,b} color del anillo base
--   value_font  : fuente del valor
--   sub_font    : fuente del sub
--   value_color : {r,g,b}
--   sub_color   : {r,g,b}
--   size        : diametro minimo en pixeles
function Ring.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), Ring)

    self.value       = opts.value or 0
    self.raw_range   = opts.raw_range   -- {min, max} opcional
    self.raw_value   = nil               -- ultimo valor en rango crudo
    self.text        = opts.text or "0"
    self.sub         = opts.sub or ""
    self.thickness   = opts.thickness or 10
    self.color       = opts.color or { 0.40, 0.75, 0.55 }
    self.color_bg    = opts.color_bg or { 0.22, 0.22, 0.28 }
    self.value_font  = opts.value_font or "DejaVu Sans Bold 22"
    self.sub_font    = opts.sub_font or "DejaVu Sans 10"
    self.value_color = opts.value_color or { 0.95, 0.95, 0.95 }
    self.sub_color   = opts.sub_color or { 0.65, 0.65, 0.65 }
    -- Factor de reveal (0..1). Multiplica el angulo del arco del
    -- valor sin tocar el texto ni el anillo base. Default 1.0.
    self.reveal      = 1.0
    -- Handle de la animacion de valor en curso. Se cancela si
    -- llega un animate_to nuevo antes de terminar el anterior.
    self._anim_handle = nil

    local size = opts.size or 140
    self.min_w = size
    self.min_h = size
    -- Puede crecer hasta el rect que le asigne el padre.
    self.max_w = 10000
    self.max_h = 10000

    return self
end

function Ring:set_value(v, text, sub)
    local changed = false
    if v ~= nil then
        local norm = v
        if self.raw_range then
            local mn, mx = self.raw_range[1], self.raw_range[2]
            if mx and mn and mx > mn then
                norm = (v - mn) / (mx - mn)
            else
                norm = 0
            end
        end
        norm = math.max(0, math.min(1, norm))
        self.raw_value = v
        if norm ~= self.value then self.value = norm; changed = true end
    end
    if text ~= nil and text ~= self.text then self.text = text; changed = true end
    if sub ~= nil and sub ~= self.sub then self.sub = sub; changed = true end
    if changed then self:damage() end
end

-- Anima self.value (0..1) del valor actual al nuevo, actualizando
-- text y sub inmediatamente. Si el motor de animacion no esta
-- listo, hace un set_value normal (instantaneo). Cancela una
-- animacion previa si la hay, para evitar acumulacion de tweens
-- cuando el timer de refresco dispara antes de que la animacion
-- anterior haya terminado.
function Ring:animate_to(v, text, sub, duration)
    if text ~= nil then self.text = text end
    if sub  ~= nil then self.sub  = sub  end

    local target = v
    if self.raw_range then
        local mn, mx = self.raw_range[1], self.raw_range[2]
        if mx and mn and mx > mn then
            target = (v - mn) / (mx - mn)
        else
            target = 0
        end
    end
    target = math.max(0, math.min(1, target))
    self.raw_value = v

    local anim = require("lib.anim")
    if not anim.is_ready() then
        self.value = target
        self:damage()
        return
    end

    if self._anim_handle then
        self._anim_handle:cancel()
        self._anim_handle = nil
    end

    self._anim_handle = anim.tween(self, "value",
        self.value, target, duration or 700, anim.EASE.out_quad,
        function() self._anim_handle = nil end)
end

function Ring:draw(cr)
    local cx = (self.x0 + self.x1) / 2
    local cy = (self.y0 + self.y1) / 2
    local r  = math.min(self:getWidth(), self:getHeight()) / 2
              - self.thickness / 2 - 2
    if r < 5 then return end
    if r < 5 then return end

    -- Anillo base (fondo).
    -- new_sub_path antes y despues para que el stroke no conecte
    -- con el siguiente arco.
    cairo.set_rgb(cr, self.color_bg[1], self.color_bg[2], self.color_bg[3])
    cairo.set_line_width(cr, self.thickness)
    cairo.new_sub_path(cr)
    cairo.arc(cr, cx, cy, r, 0, 2 * math.pi)
    cairo.stroke(cr)

    -- Arco del valor: empieza arriba (-pi/2) y recorre
    -- value * 2pi en sentido horario.
    if self.value > 0 then
        local a0 = -math.pi / 2
        local rv = self.reveal or 1.0
        if rv < 0 then rv = 0 end
        if rv > 1 then rv = 1 end
        local a1 = a0 + math.min(1, self.value) * 2 * math.pi * rv
        cairo.set_rgb(cr, self.color[1], self.color[2], self.color[3])
        cairo.set_line_width(cr, self.thickness)
        cairo.new_sub_path(cr)
        cairo.arc(cr, cx, cy, r, a0, a1)
        cairo.stroke(cr)
    end

    -- Texto centrado
    local vw, vh = pango.measure(self.text, self.value_font)
    local sw, sh = 0, 0
    if self.sub ~= "" then
        sw, sh = pango.measure(self.sub, self.sub_font)
    end

    local total_h = vh + (self.sub ~= "" and (sh + 2) or 0)
    local ty = cy - total_h / 2

    local vc = self.value_color
    pango.draw_text(cr, cx - vw / 2, ty, self.text, self.value_font,
        { r = vc[1], g = vc[2], b = vc[3] })

    if self.sub ~= "" then
        local sc = self.sub_color
        pango.draw_text(cr, cx - sw / 2, ty + vh + 2,
            self.sub, self.sub_font,
            { r = sc[1], g = sc[2], b = sc[3] })
    end
end

return Ring
