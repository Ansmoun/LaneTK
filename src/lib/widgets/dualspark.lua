local Area  = require("lib.area")
local cairo = require("lib.cairo")
local pango = require("lib.pango")
local G     = require("lib.helpers.graphics")

local DualSpark = setmetatable({}, { __index = Area })
DualSpark.__index = DualSpark

-- opts:
--   samples     : numero de muestras (default 60)
--   color_a     : "#hex" color serie A (rellena por defecto)
--   color_b     : "#hex" color serie B (linea por defecto)
--   fill_a      : bool (default true)
--   fill_b      : bool (default false)
--   auto_max    : bool, escala al maximo entre ambas (default true)
--   min         : minimo del eje Y
--   max         : maximo del eje Y (ignorado si auto_max)
--   floor_max   : minimo del maximo calculado (evita picos planos)
--   axis_width, axis_format, grid
function DualSpark.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), DualSpark)

    self.samples   = opts.samples or 60
    self.color_a   = opts.color_a or "#8ec07c"
    self.color_b   = opts.color_b or "#e06060"
    self.fill_a    = opts.fill_a
    if self.fill_a == nil then self.fill_a = true end
    self.fill_b    = opts.fill_b or false
    self.auto_max  = opts.auto_max
    if self.auto_max == nil then self.auto_max = true end
    self.min_v     = opts.min
    self.max_v     = opts.max
    self.floor_max = opts.floor_max or 0
    self.axis_width  = opts.axis_width or 0
    self.axis_format = opts.axis_format
    self.grid        = opts.grid or false

    -- Animaciones: mismo esquema que Spark. alpha/reveal para el
    -- fade-in de entrada; tail/scroll para el trazo progresivo del
    -- ultimo segmento cuando llega un punto nuevo. Los dos canales
    -- (A y B) comparten estos valores; no animan por separado.
    self.alpha  = 1.0
    self.reveal = 1.0
    self.tail   = 1.0
    self.scroll = 0.0
    self._anim_kind = "dualspark"
    self._anim_pending = false
    self._push_handle  = nil

    self.history_a = G.history(self.samples)
    self.history_b = G.history(self.samples)

    self.min_w = opts.min_width  or 100
    self.min_h = opts.min_height or 80
    self.max_w = opts.max_width  or 10000
    self.max_h = opts.max_height or 10000

    return self
end

function DualSpark:push_a(v)
    self.history_a:push(v)
    self.tail = 1
    self.scroll = 0
    self:_maybe_anim_start()
    self:damage()
end
function DualSpark:push_b(v)
    self.history_b:push(v)
    -- NO tocar tail/scroll aqui. tail/scroll son de la serie A
    -- (la que se anima con push_a_animated). Si los reseteamos,
    -- pisamos el tween en curso cuando conexion.lua llama
    -- push_a_animated y push_b en el mismo tick, y el trazo no
    -- se ve. Bug reportado y confirmado.
    self:_maybe_anim_start()
    self:damage()
end

-- Si el intro dejo el duallspark pendiente (alpha=0, reveal=0),
-- dispara el fade-in en cuanto haya datos suficientes en alguna
-- de las dos series.
function DualSpark:_maybe_anim_start()
    if not self._anim_pending then return end
    local na = #self.history_a:get()
    local nb = #self.history_b:get()
    if na < 2 and nb < 2 then return end
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

-- Empuja un valor y traza el ultimo segmento. Solo anima el
-- canal A (el visible); B se puede empujar con push_b normal.
function DualSpark:push_a_animated(v, duration)
    local n_antes = self.history_a.count
    local was_full = (n_antes >= self.samples)
    if self._push_handle then
        self._push_handle:cancel()
        self._push_handle = nil
    end
    self.history_a:push(v)
    self:_maybe_anim_start()
    self:damage()
    -- Ver comentario en Spark:push_animated. n_antes=0 -> 1 punto
    -- tras el push (nada). n_antes=1 -> 2 puntos (hay segmento).
    if n_antes < 1 then
        self.tail = 1; self.scroll = 0; return
    end
    local anim = require("lib.anim")
    if not anim.is_ready() then
        self.tail = 1; self.scroll = 0; return
    end
    if was_full then
        self.tail = 0; self.scroll = 1
        self._push_handle = anim.tween_custom(self, function(e)
            self.tail = e
            self.scroll = 1 - e
            self:damage()
        end, duration or 350, anim.EASE.out_quad, function()
            self.tail = 1; self.scroll = 0; self._push_handle = nil
        end)
    else
        self.tail = 0; self.scroll = 0
        self._push_handle = anim.tween(self, "tail", 0, 1,
            duration or 350, anim.EASE.out_quad, function()
                self.tail = 1; self._push_handle = nil
            end)
    end
end

function DualSpark:set_range(vmin, vmax)
    self.min_v = vmin
    self.max_v = vmax
    self:damage()
end

function DualSpark:clear()
    self.history_a:clear()
    self.history_b:clear()
    self:damage()
end

function DualSpark:_effective_range()
    local vmin = self.min_v or 0
    local vmax = self.max_v

    if self.auto_max then
        vmax = nil
        for _, v in ipairs(self.history_a:get()) do
            if vmax == nil or v > vmax then vmax = v end
        end
        for _, v in ipairs(self.history_b:get()) do
            if vmax == nil or v > vmax then vmax = v end
        end
        if vmax == nil then vmax = self.floor_max end
        if vmax < self.floor_max then vmax = self.floor_max end
        -- Margen del 10% arriba para no pegar la linea al borde
        vmax = vmax * 1.10
    end

    if vmax == nil then vmax = 1 end
    if vmax <= vmin then vmax = vmin + 1 end
    return vmin, vmax
end

function DualSpark:draw(cr)
    local w, h = self:getWidth(), self:getHeight()
    if w < 4 or h < 4 then return end

    local ax = self.axis_width
    local sx = self.x0 + ax
    local sy = self.y0
    local sw = w - ax
    local sh = h

    local vmin, vmax = self:_effective_range()

    -- Grid
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
    if self.axis_format then
        local top = string.format(self.axis_format, math.floor(vmax))
        local bot = string.format(self.axis_format, math.floor(vmin))
        local _, th = pango.measure(top, "DejaVu Sans 8")
        pango.draw_text(cr, self.x0, sy, top, "DejaVu Sans 8",
            { r = 0.55, g = 0.55, b = 0.55 })
        pango.draw_text(cr, self.x0, sy + sh - th, bot, "DejaVu Sans 8",
            { r = 0.55, g = 0.55, b = 0.55 })
    end

    local da = self.history_a:get()
    local db = self.history_b:get()

    -- Serie A primero (debajo). Con animaciones activas, usar
    -- alpha/reveal/tail/scroll como Spark.
    if #da >= 2 then
        G.sparkline(cr, sx, sy, sw, sh, da, {
            fg = self.color_a, fill = self.fill_a,
            min = vmin, max = vmax, width = 1.5,
            alpha = self.alpha, reveal = self.reveal,
            tail = self.tail, scroll = self.scroll,
            size = self.samples,
        })
    end

    -- Serie B encima. Comparte alpha y reveal con A pero no
    -- tail/scroll, porque cada serie tiene su propio largo.
    if #db >= 2 then
        G.sparkline(cr, sx, sy, sw, sh, db, {
            fg = self.color_b, fill = self.fill_b,
            min = vmin, max = vmax, width = 1.5,
            alpha = self.alpha, reveal = self.reveal,
            size = self.samples,
        })
    end

    if #da < 2 and #db < 2 then
        pango.draw_text(cr, sx + 8, sy + sh / 2 - 6,
            "Recolectando...", "DejaVu Sans 9",
            { r = 0.45, g = 0.45, b = 0.45 })
    end
end

return DualSpark
