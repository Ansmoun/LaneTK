-- Area: clase base de todos los widgets.
-- Un Area ocupa un rectangulo (x0, y0, x1, y1) que le asigna su
-- padre o la Window. Sabe medirse (askMinMax) y dibujarse (draw).
--
-- Estado de interaccion:
--   hover:   true si el cursor esta sobre el widget
--   pressed: true si el boton del raton fue presionado sobre el widget
--            y aun no se ha soltado

local Area = {}
Area.__index = Area

function Area.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Area)
    self.opts = opts
    self.x0, self.y0, self.x1, self.y1 = 0, 0, 0, 0
    self.min_w, self.min_h = opts.min_width  or 0, opts.min_height or 0
    self.max_w, self.max_h = opts.max_width  or 0, opts.max_height or 0
    self.parent = nil
    self.window = nil
    self.hover = false
    self.pressed = false
    return self
end

function Area:askMinMax(minw, minh, maxw, maxh)
    return minw + self.min_w,
           minh + self.min_h,
           maxw + self.max_w,
           maxh + self.max_h
end

function Area:layout(x0, y0, x1, y1)
    self.x0, self.y0, self.x1, self.y1 = x0, y0, x1, y1
end

-- Devuelve true si este widget interseca el damage actual del
-- window. Los contenedores lo usan para saltar hijos que no
-- necesitan repintarse.
function Area:should_draw()
    local w = self.window
    if not w then return true end
    if w.force_redraw then return true end
    -- Si hay overlay (crossfade u otra composicion), redibujar
    -- TODO. El overlay se compone sobre el arbol completo en
    -- Window:draw, y los widgets que estan fuera del rect del
    -- overlay (por ejemplo el TabsBar encima del Stack) necesitan
    -- reescribirse al image_surface en cada frame para que la
    -- composicion final sea coherente. Sin esta rama, should_draw
    -- filtra esos widgets contra un damage_list que solo contiene
    -- el rect del overlay y el del extra_damage_area; si el extra
    -- no llega (o llega mal), los widgets quedan con los pixeles
    -- del frame anterior y se ven "vacios" durante el fade.
    if w.overlay then return true end
    local list = w.damage_list
    if not list or #list == 0 then return false end
    -- Si el widget no tiene rect valido, hay que dibujarlo (puede
    -- ser la primera vez).
    if self.x0 == self.x1 or self.y0 == self.y1 then return true end
    for _, r in ipairs(list) do
        -- r = { x0, y0, x1, y1 } del damage
        if not (self.x1 <= r[1] or self.x0 >= r[3] or
                self.y1 <= r[2] or self.y0 >= r[4]) then
            return true
        end
    end
    return false
end

function Area:draw(cr)
    -- Base no dibuja nada.
end

-- Devuelve self si el punto (x, y) cae dentro del rect, nil si no.
-- Subclases con hijos deben sobreescribir y delegar en los hijos.
function Area:getByXY(x, y)
    if x >= self.x0 and x < self.x1 and y >= self.y0 and y < self.y1 then
        return self
    end
    return nil
end

-- Handlers genericos de raton. Las subclases que los necesiten
-- los sobreescriben. Reciben coordenadas LOCALES al widget.
--   x, y    : posicion relativa a (self.x0, self.y0)
--   button  : 1=izq, 3=der, 4=wheel-up, 5=wheel-down
function Area:on_mouse_move(x, y) end
function Area:on_mouse_press(x, y, button) end
function Area:on_mouse_release(x, y, button) end
function Area:on_wheel(direction) end

-- Marca el area como dañada y pide a la ventana que rehaga el
-- layout. Usar cuando el tamaño minimo cambia (por ejemplo, al
-- cambiar de pagina en un Stack).
function Area:invalidate_layout()
    if self.window then
        self.window:damage_all()
        self.window:_relayout()
        self.window:draw()
    end
end

function Area:getRect()
    return self.x0, self.y0, self.x1, self.y1
end

function Area:getWidth()  return self.x1 - self.x0 end
function Area:getHeight() return self.y1 - self.y0 end

-- Marca este widget como dañado. La window acumula el rect y
-- repinta solo esa region en el proximo ciclo.
function Area:damage()
    if self.window and self.window.add_damage then
        self.window:add_damage(self.x0, self.y0, self.x1, self.y1)
    end
end

-- Cambios de estado con callbacks opcionales.
-- Por defecto NO dañan: la mayoria de widgets contenedores no
-- pintan nada distinto al cambiar hover/pressed. Los widgets que
-- SI tienen visual (Button, TabsBar, etc.) declaran
-- self._hover_visual = true / self._pressed_visual = true en su
-- constructor. Sin esa marca, hover y pressed no generan
-- repintado.
function Area:set_hover(v)
    v = v and true or false
    if self.hover == v then return end
    self.hover = v
    if self.opts.on_hover then self.opts.on_hover(self, v) end
    if self._hover_visual then self:damage() end
end

function Area:set_pressed(v)
    v = v and true or false
    if self.pressed == v then return end
    self.pressed = v
    if self.opts.on_press then self.opts.on_press(self, v) end
    if self._pressed_visual then self:damage() end
end

function Area:newClass()
    local cls = {}
    cls.__index = cls
    cls.__parent = self
    setmetatable(cls, { __index = self })
    return cls
end

return Area
