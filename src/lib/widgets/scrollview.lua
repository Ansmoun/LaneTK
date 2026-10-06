-- ScrollView: lista con scroll pixel-perfect.
-- El contenido se dibuja via un callback draw_row(cr, item, idx,
-- y, row_h, width, hover, view). El ScrollView se encarga del
-- clip, el translate por el offset y el filtro de filas visibles.
--
-- Portado de widgets/cairo/scrollview.lua (Awesome). Cambios
-- respecto al original:
--   * Subclase de Area en vez de wibox.widget.
--   * on_mouse_move / on_wheel / on_mouse_press para hover y clicks.
--   * Sin cache de Pango layouts. Cada fila usa pango.draw_text
--     que crea su layout desde cero. Es mas lento pero elimina el
--     bug original de "solo dibuja la primera fila".
--   * Sin escritura a /tmp/sv-loop.log.

local Area  = require("lib.area")
local cairo = require("lib.cairo")
local G     = require("lib.helpers.graphics")

local ScrollView = setmetatable({}, { __index = Area })
ScrollView.__index = ScrollView

-- opts:
--   row_height      : alto de cada fila (default 18)
--   draw_row        : function(cr, item, idx, y, row_h, width, hover, self)
--                     Obligatorio. Debe dibujar el item en (0, y) y
--                     hasta (width, y + row_h).
--   on_click        : function(item, idx)
--   on_right_click  : function(item, idx)
--   bg_color        : "#hex" fondo (default transparente)
--   items           : lista inicial (opcional)
function ScrollView.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), ScrollView)

    self.row_height     = opts.row_height or 18
    self.draw_row       = opts.draw_row
    self.on_click       = opts.on_click
    self.on_right_click = opts.on_right_click
    self.bg_color       = opts.bg_color

    self.items      = {}
    self.offset     = 0
    self.offset_max = 0
    self.hover_idx  = -1
    self.change_cbs = {}

    if opts.items then self:set_items(opts.items) end

    self.min_w = opts.min_width  or 100
    self.min_h = opts.min_height or 100
    self.max_w = 10000
    self.max_h = 10000

    return self
end

function ScrollView:on_change(fn)
    self.change_cbs[#self.change_cbs + 1] = fn
end

function ScrollView:_notify(silent)
    if silent then return end
    for _, fn in ipairs(self.change_cbs) do
        fn(self.offset, self.offset_max)
    end
end

function ScrollView:_recalc_max()
    local view_h = self:getHeight()
    self.offset_max = math.max(0, #self.items * self.row_height - view_h)
    if self.offset > self.offset_max then self.offset = self.offset_max end
end

-- Compara dos items para decidir si una fila necesita repintado.
-- Sin opts.compare, cualquier cambio en la lista fuerza redraw
-- completo del scrollview.
function ScrollView:_items_equal(a, b)
    if a == b then return true end
    if not a or not b then return false end
    if not self.opts.compare then return false end
    return self.opts.compare(a, b)
end

function ScrollView:set_items(items)
    items = items or {}
    local old = self.items
    self.items = items
    self:_recalc_max()

    -- Sin comparador: redraw completo (comportamiento previo).
    if not self.opts.compare then
        self.hover_idx = -1
        self:damage()
        self:_notify(false)
        return
    end

    -- Sin rect valido (widget aun no layouted) o lista cambio de
    -- tamaño: dañar todo. El diff granular solo tiene sentido
    -- cuando el widget ya tiene posicion en pantalla.
    if self.x1 <= self.x0 or self.y1 <= self.y0 or #items ~= #old then
        self.hover_idx = -1
        self:damage()
        self:_notify(false)
        return
    end

    local row_h = self.row_height
    local view_h = self:getHeight()
    local first = math.floor(self.offset / row_h)
    local last_visible = first + math.ceil(view_h / row_h)

    local any = false
    for i = 1, #items do
        if not self:_items_equal(old[i], items[i]) then
            -- Solo dañar si la fila esta visible.
            if i - 1 >= first and i - 1 <= last_visible then
                local rel = (i - 1) - first
                local y0 = self.y0 + rel * row_h
                local y1 = y0 + row_h
                if y1 > self.y1 then y1 = self.y1 end
                if y0 < self.y1 and self.window then
                    self.window:add_damage(self.x0, y0, self.x1, y1)
                    any = true
                end
            end
        end
    end

    if any then
        -- Nada mas: el damage_list ya tiene los rects
    else
        -- No hay filas distintas: no hay que repintar.
    end
    -- No notificar cambio de offset (no cambió).
end

function ScrollView:set_offset(px, silent)
    if px < 0 then px = 0 end
    if px > self.offset_max then px = self.offset_max end
    if math.abs(px - self.offset) < 0.01 then return end
    self.offset = px
    self:damage()
    self:_notify(silent)
end

function ScrollView:get_offset()     return self.offset end
function ScrollView:get_offset_max() return self.offset_max end
function ScrollView:get_row_height() return self.row_height end
function ScrollView:get_count()      return #self.items end

function ScrollView:layout(x0, y0, x1, y1)
    Area.layout(self, x0, y0, x1, y1)
    self:_recalc_max()
end

function ScrollView:set_window(win)
    self.window = win
end

function ScrollView:draw(cr)
    local x, y = self.x0, self.y0
    local w, h = self:getWidth(), self:getHeight()

    cairo.save(cr)
    cairo.rectangle(cr, x, y, w, h)
    cairo.clip(cr)
    cairo.new_path(cr)

    if self.bg_color then
        G.set_color(cr, self.bg_color)
        cairo.rectangle(cr, x, y, w, h)
        cairo.fill(cr)
        cairo.new_path(cr)
    end

    local row_h = self.row_height
    if #self.items > 0 and self.draw_row then
        local first = math.floor(self.offset / row_h)
        local last  = math.min(first + math.ceil(h / row_h),
                               #self.items - 1)
        local y0 = y - (self.offset - first * row_h)

        for i = first, last do
            local idx = i + 1
            local ry = y0 + (i - first) * row_h

            cairo.save(cr)
            cairo.new_path(cr)
            cairo.translate(cr, x, 0)
            self.draw_row(cr, self.items[idx], idx, ry, row_h, w,
                          self.hover_idx == idx, self)
            cairo.new_path(cr)
            cairo.restore(cr)
        end
    end

    cairo.restore(cr)
    cairo.new_path(cr)
end

-- Hover de fila segun la posicion local del cursor.
-- Daña solo la fila indicada (o nada si no esta visible).
function ScrollView:_damage_row(idx)
    if idx < 1 or not self.window then return end
    local row_h = self.row_height
    local view_h = self:getHeight()
    local first = math.floor(self.offset / row_h)
    local rel = idx - first - 1
    if rel < 0 then return end
    -- Restar la fraccion del offset para alinear el damage con la
    -- posicion real de la fila. Sin esto, con offsets que no son
    -- multiplos exactos de row_height (por ejemplo el tick de la
    -- rueda cuando vale media fila), el rectangulo queda desplazado
    -- por esa fraccion y el hover deja una banda sin repintar.
    local frac = self.offset - first * row_h
    local y0 = self.y0 + rel * row_h - frac
    local y1 = y0 + row_h
    if y0 >= self.y1 then return end
    if y1 > self.y1 then y1 = self.y1 end
    if y0 < self.y0 then y0 = self.y0 end
    self.window:add_damage(self.x0, y0, self.x1, y1)
end

function ScrollView:on_mouse_move(mx, my)
    if my < 0 or my >= self:getHeight() then
        if self.hover_idx ~= -1 then
            local old = self.hover_idx
            self.hover_idx = -1
            self:_damage_row(old)
        end
        return
    end
    local idx = math.floor((my + self.offset) / self.row_height) + 1
    if idx ~= self.hover_idx then
        local old = self.hover_idx
        self.hover_idx = idx
        self:_damage_row(old)
        self:_damage_row(idx)
    end
end

-- Mouse fuera del scrollview
function ScrollView:set_hover(v)
    Area.set_hover(self, v)
    if not v and self.hover_idx ~= -1 then
        self.hover_idx = -1
        self:damage()
    end
end

function ScrollView:on_wheel(direction)
    if direction == 4 then
        self:set_offset(self.offset - self.row_height * 3)
    elseif direction == 5 then
        self:set_offset(self.offset + self.row_height * 3)
    end
end

function ScrollView:on_mouse_press(mx, my, button)
    local idx = math.floor((my + self.offset) / self.row_height) + 1
    local item = self.items[idx]
    if not item then return end
    if button == 1 and self.on_click then
        self.on_click(item, idx)
    elseif button == 3 and self.on_right_click then
        -- Pasar también las coordenadas locales al widget. El
        -- consumidor las necesita para anclar menús contextuales.
        -- Retrocompatible: los handlers que solo esperan
        -- (item, idx) ignoran los argumentos extra.
        self.on_right_click(item, idx, mx, my)
    end
end

return ScrollView
