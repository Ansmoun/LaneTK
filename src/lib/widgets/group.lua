local Area = require("lib.area")

local Group = setmetatable({}, { __index = Area })
Group.__index = Group

function Group.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), Group)
    self.orientation = opts.orientation or "horizontal"
    self.spacing     = opts.spacing or 0
    self.padding     = opts.padding or 0
    self.children    = {}
    self.weights     = {}
    for _, c in ipairs(opts.children or {}) do
        self:add(c)
    end
    return self
end

-- add(child, weight)
--   child puede ser:
--     - un Area directamente
--     - una tabla { widget = <Area>, weight = <number> }
--   En el segundo caso, el weight se toma de la tabla.
function Group:add(child, weight)
    if type(child) == "table" and child.widget and child.widget.askMinMax then
        weight = weight or child.weight
        child = child.widget
    end
    if weight == nil and child.opts then
        weight = child.opts.weight
    end
    weight = weight or 1

    child.parent = self
    if self.window then
        if child.set_window then child:set_window(self.window)
        else child.window = self.window end
    end
    self.children[#self.children + 1] = child
    self.weights[#self.children] = weight
    self:damage()
    return child
end

function Group:remove(child)
    for i, c in ipairs(self.children) do
        if c == child then
            table.remove(self.children, i)
            table.remove(self.weights, i)
            child.parent = nil
            self:damage()
            return true
        end
    end
    return false
end

function Group:clear()
    for _, c in ipairs(self.children) do
        c.parent = nil
    end
    self.children = {}
    self.weights = {}
    self:damage()
end

function Group:set_window(win)
    self.window = win
    for _, c in ipairs(self.children) do
        if c.set_window then c:set_window(win)
        else c.window = win end
    end
end

function Group:askMinMax(minw, minh, maxw, maxh)
    -- Eje principal: suma de los hijos. Eje transversal: maximo.
    --
    -- Antes se acumulaba la suma en AMBOS ejes via la convencion
    -- de Area:askMinMax (cada hijo devuelve sus valores sumados a
    -- los que recibio), y despues se usaba math.max(minh, ch).
    -- Como ch ya era la suma, el "maximo" tomaba la suma. Eso
    -- inflaba el min_h de cualquier Group horizontal con hijos de
    -- distinto alto (por ejemplo un centered(widget) con spacers
    -- de 19 px y un avatar de 140). El minimo inflado hacia que
    -- el padre le diera un rect mas grande que el real, y todo se
    -- superponia.
    --
    -- Ahora se acumulan por separado:
    --   suma_min_<eje>  -- suma de los minimos de los hijos
    --   suma_max_<eje>  -- suma de los maximos de los hijos
    --   pico_min_<eje>  -- maximo de los minimos
    --   pico_max_<eje>  -- maximo de los maximos
    -- Cada eje usa suma o pico segun su orientacion.
    local suma_min_w, suma_min_h = 0, 0
    local suma_max_w, suma_max_h = 0, 0
    local pico_min_w, pico_min_h = 0, 0
    local pico_max_w, pico_max_h = 0, 0

    for _, c in ipairs(self.children) do
        local nw, nh, xw, xh = c:askMinMax(0, 0, 0, 0)
        suma_min_w = suma_min_w + nw
        suma_min_h = suma_min_h + nh
        suma_max_w = suma_max_w + xw
        suma_max_h = suma_max_h + xh
        if nw > pico_min_w then pico_min_w = nw end
        if nh > pico_min_h then pico_min_h = nh end
        if xw > pico_max_w then pico_max_w = xw end
        if xh > pico_max_h then pico_max_h = xh end
    end

    local n = #self.children
    local gaps = math.max(0, n - 1) * self.spacing
    local pad2 = self.padding * 2

    if self.orientation == "horizontal" then
        minw = minw + suma_min_w + gaps + pad2
        minh = math.max(minh, pico_min_h + pad2)
        maxw = maxw + suma_max_w + gaps + pad2
        maxh = math.max(maxh, pico_max_h + pad2)
    else
        minw = math.max(minw, pico_min_w + pad2)
        minh = minh + suma_min_h + gaps + pad2
        maxw = math.max(maxw, pico_max_w + pad2)
        maxh = maxh + suma_max_h + gaps + pad2
    end
    return minw, minh, maxw, maxh
end

function Group:layout(x0, y0, x1, y1)
    Area.layout(self, x0, y0, x1, y1)

    local n = #self.children
    if n == 0 then return end

    local horizontal = (self.orientation == "horizontal")

    local px0 = x0 + self.padding
    local py0 = y0 + self.padding
    local px1 = x1 - self.padding
    local py1 = y1 - self.padding

    local gaps = math.max(0, n - 1) * self.spacing

    -- Recolectar minimos y pesos.
    -- Recolectar minimos, maximos y pesos. Ademas, clasificar cada
    -- hijo en rigido (min == max en el eje principal) o flexible
    -- (min < max). Los rigidos (por ejemplo un TabsBar, que declara
    -- min_h = max_h) NUNCA se achican mientras haya espacio para
    -- ellos. Los flexibles absorben el sobrante o se recortan si no
    -- alcanza.
    local mins = {}
    local maxs = {}
    local rigid = {}
    local total_min = 0
    local total_min_rigid = 0
    local total_min_flex = 0
    local total_weight = 0
    for i, c in ipairs(self.children) do
        local cminw, cminh, cmaxw, cmaxh = c:askMinMax(0, 0, 0, 0)
        local cmin = horizontal and cminw or cminh
        local cmax = horizontal and cmaxw or cmaxh
        mins[i] = cmin
        maxs[i] = cmax
        rigid[i] = (cmax <= cmin)
        total_min = total_min + cmin
        if rigid[i] then
            total_min_rigid = total_min_rigid + cmin
        else
            total_min_flex = total_min_flex + cmin
        end
        local w = self.weights[i] or 1
        if w > 0 then total_weight = total_weight + w end
    end

    local available = (horizontal and (px1 - px0) or (py1 - py0)) - gaps
    local sizes = {}
    local any_weight = total_weight > 0

    if available >= total_min then
        -- Cabe todo. Reparto normal: minimos a todos, sobrante
        -- repartido por peso entre los que tienen weight > 0.
        local extra = available - total_min
        if any_weight and extra > 0 then
            for i = 1, n do
                local w = self.weights[i] or 1
                if w > 0 then
                    sizes[i] = mins[i] + math.floor(extra * w / total_weight)
                else
                    sizes[i] = mins[i]
                end
            end
        else
            for i = 1, n do sizes[i] = mins[i] end
        end
    elseif available >= total_min_rigid then
        -- No cabe todo, pero alcanza para los rigidos. Los rigidos
        -- reciben su minimo completo. Los flexibles se escalan
        -- proporcionalmente a lo que sobra.
        local flex_avail = available - total_min_rigid
        local scale = total_min_flex > 0 and (flex_avail / total_min_flex) or 0
        for i = 1, n do
            if rigid[i] then
                sizes[i] = mins[i]
            else
                sizes[i] = math.max(0, math.floor(mins[i] * scale))
            end
        end
    else
        -- Ni para los rigidos alcanza. Fallback: escalar TODOS
        -- proporcionalmente al minimo. Es el ultimo recurso; no
        -- deberia pasar con layouts razonables.
        local scale = total_min > 0 and (available / total_min) or 0
        for i = 1, n do
            sizes[i] = math.max(0, math.floor(mins[i] * scale))
        end
    end

    if horizontal then
        local cx = px0
        for i, c in ipairs(self.children) do
            local right = cx + sizes[i]
            c:layout(cx, py0, right, py1)
            cx = right + self.spacing
        end
    else
        local cy = py0
        for i, c in ipairs(self.children) do
            local bottom = cy + sizes[i]
            c:layout(px0, cy, px1, bottom)
            cy = bottom + self.spacing
        end
    end
end

function Group:draw(cr)
    for _, c in ipairs(self.children) do
        if c:should_draw() then
            c:draw(cr)
        end
    end
end

function Group:getByXY(x, y)
    if x < self.x0 or x >= self.x1 or y < self.y0 or y >= self.y1 then
        return nil
    end
    for i = #self.children, 1, -1 do
        local hit = self.children[i]:getByXY(x, y)
        if hit then return hit end
    end
    return self
end

return Group
