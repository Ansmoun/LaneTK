-- Primitivas de dibujo Cairo. Solo formas y colores.
-- El texto se maneja aparte con lib/pango.
--
-- Nota: las funciones que recibian un wibox.widget en el proyecto
-- original (G.widget, G.hrow, G.vcol, G.label, G.ring_text) NO
-- estan aqui. Se reemplazan por subclases de Area en lib/widgets/.

local cairo = require("lib.cairo")

local M = {}

-- "#RRGGBB" o "#RGB" -> r, g, b, a  (4 numeros sueltos, NO tabla).
-- Listos para cr:set_source_rgba(...). No envolver en tabla.
function M.hex_to_rgba(hex, alpha)
    alpha = alpha or 1.0
    if not hex or hex == "" then return 0, 0, 0, alpha end

    -- Permitir "#RRGGBB" y "RRGGBB"
    local s = hex:gsub("^#", "")

    local r, g, b
    if #s == 3 then
        r = tonumber(s:sub(1,1) .. s:sub(1,1), 16) / 255
        g = tonumber(s:sub(2,2) .. s:sub(2,2), 16) / 255
        b = tonumber(s:sub(3,3) .. s:sub(3,3), 16) / 255
    elseif #s == 6 then
        r = tonumber(s:sub(1,2), 16) / 255
        g = tonumber(s:sub(3,4), 16) / 255
        b = tonumber(s:sub(5,6), 16) / 255
    else
        r, g, b = 0, 0, 0
    end
    return r, g, b, alpha
end

-- Fila con un unico color.
function M.set_color(cr, hex, alpha)
    local r, g, b, a = M.hex_to_rgba(hex, alpha)
    cairo.set_rgba(cr, r, g, b, a)
end

-- Barra horizontal con relleno proporcional.
-- opts = { fg, bg, radius }
function M.bar(cr, x, y, w, h, pct, opts)
    opts = opts or {}
    pct = math.max(0, math.min(1, pct or 0))

    local radius = opts.radius or (h / 2)
    local bg = opts.bg or "#3c3836"
    local fg = opts.fg or "#8ec07c"

    -- Fondo
    M.set_color(cr, bg)
    cairo.rounded_rect(cr, x, y, w, h, radius)
    cairo.fill(cr)

    -- Relleno
    if pct > 0 then
        local fw = w * pct
        -- Clamp: si el fill es menor que el diametro, no redondear
        local r = math.min(radius, fw / 2)
        M.set_color(cr, fg)
        cairo.rounded_rect(cr, x, y, fw, h, r)
        cairo.fill(cr)
    end
end

-- Barra horizontal con segmentos apilados. La suma ideal de pct
-- es 1. Cada segmento lleva su color.
-- segments = { { pct = 0.3, color = "#hex" }, ... }
function M.stacked_bar(cr, x, y, w, h, segments, opts)
    opts = opts or {}
    local radius = opts.radius or (h / 2)
    local bg = opts.bg or "#3c3836"

    -- Fondo
    M.set_color(cr, bg)
    cairo.rounded_rect(cr, x, y, w, h, radius)
    cairo.fill(cr)

    -- Segmentos
    local cx = x
    for _, seg in ipairs(segments) do
        local pct = math.max(0, math.min(1, seg.pct or 0))
        local sw = w * pct
        if sw > 0 then
            M.set_color(cr, seg.color or "#8ec07c")
            cairo.rectangle(cr, cx, y, sw, h)
            cairo.fill(cr)
            cx = cx + sw
        end
    end

    -- Recorte redondeado final para que las esquinas queden limpias
    if radius > 0 then
        -- Redibujamos el contorno redondeado con clip
        cairo.save(cr)
        cairo.rounded_rect(cr, x, y, w, h, radius)
        cairo.clip(cr)
        -- Redibujar segmentos dentro del clip
        cx = x
        for _, seg in ipairs(segments) do
            local pct = math.max(0, math.min(1, seg.pct or 0))
            local sw = w * pct
            if sw > 0 then
                M.set_color(cr, seg.color or "#8ec07c")
                cairo.rectangle(cr, cx, y, sw, h)
                cairo.fill(cr)
                cx = cx + sw
            end
        end
        cairo.restore(cr)
    end
end

-- Anillo con progreso. Angulo 0 en las 3 en punto.
-- start_angle por defecto arriba (-pi/2).
function M.ring(cr, cx, cy, radius, pct, opts)
    opts = opts or {}
    pct = math.max(0, math.min(1, pct or 0))

    local thickness   = opts.thickness or 4
    local fg          = opts.fg or "#8ec07c"
    local bg          = opts.bg or "#3c3836"
    local start_angle = opts.start_angle or (-math.pi / 2)
    local end_angle   = opts.end_angle or (start_angle + 2 * math.pi)

    -- Anillo base
    M.set_color(cr, bg)
    cairo.set_line_width(cr, thickness)
    cairo.new_sub_path(cr)
    cairo.arc(cr, cx, cy, radius, start_angle, end_angle)
    cairo.stroke(cr)

    -- Arco del valor
    if pct > 0 then
        local a1 = start_angle + pct * (end_angle - start_angle)
        M.set_color(cr, fg)
        cairo.set_line_width(cr, thickness)
        cairo.new_sub_path(cr)
        cairo.arc(cr, cx, cy, radius, start_angle, a1)
        cairo.stroke(cr)
    end
end

-- Sparkline con opcion de relleno bajo la linea.
-- data: array de numeros. Requiere #data >= 2.
function M.sparkline(cr, x, y, w, h, data, opts)
    opts = opts or {}
    if #data < 2 then return end

    local fg    = opts.fg or "#8ec07c"
    local fill  = opts.fill
    if fill == nil then fill = true end
    local width = opts.width or 1.5
    -- Multiplicador de alpha para animaciones (fade in del spark).
    -- Se aplica al fill (0.18 base) y a la linea (1.0 base).
    -- Default 1.0 = comportamiento sin animacion.
    local alpha = opts.alpha or 1.0
    if alpha < 0 then alpha = 0 end
    if alpha > 1 then alpha = 1 end
    local vmin  = opts.min
    local vmax  = opts.max

    -- Calcular min/max si no se especifican
    if vmin == nil or vmax == nil then
        local mn, mx = data[1], data[1]
        for i = 2, #data do
            local v = data[i]
            if v < mn then mn = v end
            if v > mx then mx = v end
        end
        if vmin == nil then vmin = mn end
        if vmax == nil then vmax = mx end
    end
    -- Si todos los valores son iguales, evitar division por cero
    if vmax == vmin then vmax = vmin + 1 end

    local n = #data
    -- dx fijo basado en size (no en n). Si dx dependiera de n,
    -- durante el llenado inicial del buffer todo el dibujo se
    -- reescalaria con cada push (el ancho por muestra encoge
    -- a medida que llegan puntos) y la parte izquierda se
    -- moveria visiblemente. Con dx fijo, los puntos previos
    -- mantienen su posicion mientras el buffer se llena.
    local size = opts.size or n
    if size < 2 then size = 2 end
    local dx = w / (size - 1)

    -- Scroll (0..1). Cuando el buffer ya esta lleno y llega un
    -- punto nuevo, todo el contenido se desplaza dx a la
    -- izquierda. scroll=1 dibuja el estado pre-shift (todo dx
    -- a la derecha); scroll=0 el estado final. Se anima de 1 a
    -- 0 para que el desplazamiento sea fluido.
    local scroll = opts.scroll or 0
    if scroll < 0 then scroll = 0 end
    if scroll > 1 then scroll = 1 end
    local dxs = dx * scroll

    -- Normalizar
    local function px(i)
        return x + (i - 1) * dx + dxs
    end
    local function py(v)
        local t = (v - vmin) / (vmax - vmin)
        t = math.max(0, math.min(1, t))
        return y + h - t * h
    end
    -- Trazo progresivo del ultimo segmento. tail=1 dibuja la
    -- linea completa. tail<1 trunca el ultimo segmento a
    -- px(n-1) + dx*tail, con la y interpolada. Permite que el
    -- punto nuevo se 'dibuje' de izquierda a derecha.
    local tail = opts.tail or 1.0
    if tail < 0 then tail = 0 end
    if tail > 1 then tail = 1 end
    local last_x, last_y
    if tail < 1 and n >= 2 then
        local x1, y1 = px(n - 1), py(data[n - 1])
        local x2, y2 = px(n),     py(data[n])
        last_x = x1 + (x2 - x1) * tail
        last_y = y1 + (y2 - y1) * tail
    else
        last_x, last_y = px(n), py(data[n])
    end

    -- Reveal horizontal (0..1). Recorta el area visible a
    -- w * reveal desde la izquierda. Permite que la linea se
    -- 'dibuje' progresivamente al entrar. Default 1.0 = sin clip.
    local reveal = opts.reveal or 1.0
    if reveal <= 0 then return end
    cairo.save(cr)
    if reveal < 1 then
        cairo.rectangle(cr, x, y, w * reveal, h)
        cairo.clip(cr)
    end

    -- Relleno bajo la linea
    if fill then
        M.set_color(cr, fg, 0.18 * alpha)
        cairo.new_path(cr)
        cairo.move_to(cr, px(1), y + h)
        cairo.line_to(cr, px(1), py(data[1]))
        for i = 2, n - 1 do
            cairo.line_to(cr, px(i), py(data[i]))
        end
        cairo.line_to(cr, last_x, last_y)
        cairo.line_to(cr, last_x, y + h)
        cairo.close_path(cr)
        cairo.fill(cr)
    end

    -- Linea
    M.set_color(cr, fg, alpha)
    cairo.set_line_width(cr, width)
    cairo.move_to(cr, px(1), py(data[1]))
    for i = 2, n - 1 do
        cairo.line_to(cr, px(i), py(data[i]))
    end
    cairo.line_to(cr, last_x, last_y)
    cairo.stroke(cr)

    cairo.restore(cr)
end

-- Buffer circular. push añade al final descartando el mas viejo.
function M.history(size)
    local h = {
        size = size,
        data = {},
        count = 0,
    }

    function h:push(v)
        if self.count < self.size then
            self.count = self.count + 1
            self.data[self.count] = v
        else
            -- Desplazar: el mas viejo cae, el nuevo entra al final.
            for i = 1, self.size - 1 do
                self.data[i] = self.data[i + 1]
            end
            self.data[self.size] = v
        end
    end

    function h:get()
        return self.data
    end

    function h:clear()
        self.data = {}
        self.count = 0
    end

    return h
end

return M
