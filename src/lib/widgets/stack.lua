-- Stack: contenedor con varios hijos, uno visible a la vez.
-- Se usa para paginas: cada hijo es una "pagina", se activa por
-- nombre. Base de tabs, wizards, sub-paneles.

local Area = require("lib.area")

local Stack = setmetatable({}, { __index = Area })
Stack.__index = Stack

function Stack.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), Stack)

    self.pages = {}      -- name -> Area
    self.order = {}      -- array de nombres en orden de insercion
    self.active = nil

    self.min_w = opts.min_width or 0
    self.min_h = opts.min_height or 0
    self.max_w = 10000
    self.max_h = 10000

    return self
end

-- add(name, widget)
function Stack:add(name, widget)
    widget.parent = self
    if self.window then
        if widget.set_window then
            widget:set_window(self.window)
        else
            widget.window = self.window
        end
    end
    self.pages[name] = widget
    self.order[#self.order + 1] = name

    -- Si este es el primer widget, activarlo e invalidar layout
    -- EXPLICITAMENTE. Sin esto, el primer set_active(name) que
    -- haga el consumidor encuentra self.active == name y hace
    -- early return, dejando al widget sin layout (x0=x1=0).
    -- No activar aqui. Si activamos, el set_active(name) posterior
    -- encuentra self.active == name y hace early return sin llamar
    -- invalidate_layout, dejando el arbol a medio layoutear (rects
    -- en 0, KV sin expandir, etc). El consumidor siempre llama
    -- set_active despues del add, y ahi se hace el relayout con el
    -- arbol completo.
    return widget
end

function Stack:remove(name)
    local w = self.pages[name]
    if not w then return false end
    self.pages[name] = nil
    for i, n in ipairs(self.order) do
        if n == name then
            table.remove(self.order, i)
            break
        end
    end
    if self.active == name then
        self.active = self.order[1]
        self:invalidate_layout()
    end
    return true
end

function Stack:set_active(name)
    if not self.pages[name] then return false end
    if self.active == name then return true end
    self.active = name
    self:invalidate_layout()
    return true
end

function Stack:get_active()
    return self.active
end

function Stack:get(name)
    return self.pages[name]
end

function Stack:set_window(win)
    self.window = win
    for _, w in pairs(self.pages) do
        if w.set_window then
            w:set_window(win)
        else
            w.window = win
        end
    end
end

function Stack:askMinMax(minw, minh, maxw, maxh)
    -- Medir TODAS las paginas, no solo la activa. Si solo mide la
    -- activa, al cambiar de tab los minimos cambian, el Group padre
    -- redistribuye y el Stack se desplaza verticalmente unos px.
    -- Eso rompe la alineacion del overlay del crossfade: el rect del
    -- Stack cambia tras el swap_fn y anim.crossfade cancelaba el fade
    -- o lo dejaba desalineado. Con todas las paginas medidas, el rect
    -- del Stack es estable y el crossfade ve el mismo rect antes y
    -- despues del swap. El coste de medir N paginas (N tipicamente
    -- 2-5) es despreciable frente al relayout completo.
    local cw, ch, mw, mh = 0, 0, 0, 0
    for _, w in pairs(self.pages) do
        local pw, ph, pmw, pmh = w:askMinMax(0, 0, 0, 0)
        if pw > cw then cw = pw end
        if ph > ch then ch = ph end
        if pmw > mw then mw = pmw end
        if pmh > mh then mh = pmh end
    end
    return minw + cw, minh + ch, maxw + mw, maxh + mh
end

function Stack:layout(x0, y0, x1, y1)
    Area.layout(self, x0, y0, x1, y1)
    local w = self.pages[self.active]
    if w then w:layout(x0, y0, x1, y1) end
end

function Stack:draw(cr)
    local w = self.pages[self.active]
    if w and w:should_draw() then w:draw(cr) end
end

function Stack:getByXY(x, y)
    if x < self.x0 or x >= self.x1 or y < self.y0 or y >= self.y1 then
        return nil
    end
    local w = self.pages[self.active]
    if w then
        local hit = w:getByXY(x, y)
        if hit then return hit end
    end
    return self
end

return Stack
