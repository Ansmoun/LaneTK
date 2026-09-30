local Area  = require("lib.area")
local cairo = require("lib.cairo")
local pango = require("lib.pango")
local G     = require("lib.helpers.graphics")

local Spark = setmetatable({}, { __index = Area })
Spark.__index = Spark

-- opts:
--   samples     : numero de muestras (default 60)
--   min, max    : rango del eje Y (opcional; autoscale si no)
--   color       : "#RRGGBB"
--   fill        : bool (default true)
--   axis_format : formato para etiquetas del eje (ej "%d%%" o "%d")
--   axis_width  : ancho reservado al eje Y (default 0)
--   grid        : bool (default false)
--   width, height : tamano minimo preferido
function Spark.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), Spark)

    self.samples     = opts.samples or 60
    self.min_v       = opts.min
    self.max_v       = opts.max
    self.color       = opts.color or "#8ec07c"
    self.fill        = opts.fill
    if self.fill == nil then self.fill = true end
    self.axis_format = opts.axis_format
    self.axis_width  = opts.axis_width or 0
    self.grid        = opts.grid or false

    -- Alpha global (0..1) aplicado a la sparkline. Default 1.0.
    self.alpha       = 1.0
    -- Reveal horizontal (0..1). Recorta el ancho visible de la
    -- sparkline desde la izquierda. Default 1.0 = sin clip.
    self.reveal      = 1.0
    -- Handle de la animacion del ultimo punto (push_animated).
    -- Se cancela si llega un push nuevo antes de terminar.
    self._push_handle = nil
    -- Tipo de animacion para intro.lua.
    self._anim_kind = "spark"
    -- Flag: el intro setea esto a true, y el primer push que
    -- llegue dispara el tween de alpha/reveal. Permite animar
    -- el spark recien cuando tiene datos reales (>= 2 puntos).
    self._anim_pending = false
    -- Trazo progresivo del ultimo segmento (0..1). Default 1.0.
    self.tail = 1.0
    -- Scroll global (0..1). Default 0. Ver push_animated.
    self.scroll = 0.0
    self.history = G.history(self.samples)

    self.min_w = opts.min_width  or 100
    self.min_h = opts.min_height or 80
    self.max_w = opts.max_width  or 10000
    self.max_h = opts.max_height or 10000

    return self
end

function Spark:push(v)
    self.history:push(v)
    -- Resetear a estado final por si veniamos de un push_animated
    -- cancelado a mitad.
    self.tail = 1
    self.scroll = 0
    -- Si el intro dejo el spark pendiente, disparar el fade
    -- ahora que ya hay datos.
    if self._anim_pending and #self.history:get() >= 2 then
        self._anim_pending = false
        local anim = require("lib.anim")
        if anim.is_ready() then
            anim.tween(self, "alpha", 0, 1, 600, anim.EASE.out_quad)
            anim.tween(self, "reveal", 0, 1, 900, anim.EASE.out_cubic)
        else
            self.alpha = 1
            self.reveal = 1
        end
    end
    self:damage()
end

-- Empuja un valor animando el punto nuevo y, si corresponde, el
-- desplazamiento del sparkline.
-- Dos casos:
--   (1) Buffer aun no lleno (count < samples): la linea crece
--       hacia la derecha. Los puntos previos NO se mueven. Solo
--       se anima el tail (nuevo segmento se dibuja de izquierda
--       a derecha). scroll queda en 0.
--   (2) Buffer lleno (count == samples): al entrar un punto, el
--       array desplaza todo 1 posicion a la izquierda. Se anima
--       tail y scroll juntos: el nuevo segmento se dibuja y todo
--       el contenido se desliza dx a la izquierda en el mismo
--       tween, sin saltos.
function Spark:push_animated(v, duration)
    local n_antes = self.history.count
    local was_full = (n_antes >= self.samples)

    if self._push_handle then
        self._push_handle:cancel()
        self._push_handle = nil
    end

    self.history:push(v)
    self:damage()

    -- Si el intro dejo el spark pendiente, disparar el fade
    -- ahora que ya hay datos suficientes.
    if self._anim_pending and self.history.count >= 2 then
        self._anim_pending = false
        local anim0 = require("lib.anim")
        if anim0.is_ready() then
            anim0.tween(self, "alpha", 0, 1, 600, anim0.EASE.out_quad)
            anim0.tween(self, "reveal", 0, 1, 900, anim0.EASE.out_cubic)
        else
            self.alpha = 1
            self.reveal = 1
        end
    end

    -- Animar el segmento ya desde el 2do punto. n_antes=0 significa
    -- que tras el push solo hay 1 punto (nada que dibujar). n_antes=1
    -- significa que tras el push hay 2 puntos: hay segmento real y
    -- hay que animarlo. Antes estaba < 2, lo que saltaba la animacion
    -- en el 2do push y solo animaba a partir del 3ro.
    if n_antes < 1 then
        self.tail = 1
        self.scroll = 0
        return
    end
    local anim = require("lib.anim")
    if not anim.is_ready() then
        self.tail = 1
        self.scroll = 0
        return
    end

    if was_full then
        self.tail = 0
        self.scroll = 1
        self._push_handle = anim.tween_custom(self, function(e)
            self.tail = e
            self.scroll = 1 - e
            self:damage()
        end, duration or 350, anim.EASE.out_quad, function()
            self.tail = 1
            self.scroll = 0
            self._push_handle = nil
        end)
    else
        self.tail = 0
        self.scroll = 0
        self._push_handle = anim.tween(self, "tail", 0, 1,
            duration or 350, anim.EASE.out_quad, function()
                self.tail = 1
                self._push_handle = nil
            end)
    end
end

function Spark:set_range(vmin, vmax)
    self.min_v = vmin
    self.max_v = vmax
    self:damage()
end

function Spark:clear()
    self.history:clear()
    self:damage()
end

function Spark:draw(cr)
    local w, h = self:getWidth(), self:getHeight()
    if w < 4 or h < 4 then return end

    local ax = self.axis_width
    local sx = self.x0 + ax
    local sy = self.y0
    local sw = w - ax
    local sh = h

    -- Grid horizontal
    if self.grid then
        G.set_color(cr, "#3c3836", 0.5)
        cairo.set_line_width(cr, 1)
        for i = 1, 3 do
            local y = sy + (sh / 4) * i
            cairo.move_to(cr, sx, y)
            cairo.line_to(cr, sx + sw, y)
        end
        cairo.stroke(cr)
    end

    -- Etiquetas del eje
    if self.axis_format and self.min_v and self.max_v then
        local top = string.format(self.axis_format, self.max_v)
        local bot = string.format(self.axis_format, self.min_v)
        G.set_color(cr, "#888888")
        -- medir y dibujar
        local _, th = pango.measure(top, "DejaVu Sans 8")
        pango.draw_text(cr, self.x0, sy, top, "DejaVu Sans 8",
            { r = 0.55, g = 0.55, b = 0.55 })
        pango.draw_text(cr, self.x0, sy + sh - th, bot, "DejaVu Sans 8",
            { r = 0.55, g = 0.55, b = 0.55 })
    end

    -- Sparkline
    local data = self.history:get()
    if #data >= 2 then
        G.sparkline(cr, sx, sy, sw, sh, data, {
            fg = self.color,
            fill = self.fill,
            min = self.min_v,
            max = self.max_v,
            width = 1.5,
            alpha = self.alpha,
            reveal = self.reveal,
            tail = self.tail,
            scroll = self.scroll,
            size = self.samples,
        })
    else
        -- Sin datos suficientes: mensaje
        pango.draw_text(cr, sx + 8, sy + sh/2 - 6,
            "Recolectando...", "DejaVu Sans 9",
            { r = 0.45, g = 0.45, b = 0.45 })
    end
end

return Spark
