-- Dropdown: selecciona un item de una lista.
--
-- IMPORTANTE: la altura del widget es la lista completa expandida.
-- Abrir/cerrar NO cambia el tamaño; solo decide si las filas fuera
-- del header se dibujan. Así los hermanos del widget nunca se
-- reacomodan. Cuando la lista es larga conviene envolver el Dropdown
-- en un ScrollView o usar max_visible.

local Area  = require("lib.area")
local cairo = require("lib.cairo")
local pango = require("lib.pango")

local Dropdown = setmetatable({}, { __index = Area })
Dropdown.__index = Dropdown

function Dropdown.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), Dropdown)
    self._hover_visual  = true
    self._pressed_visual = true
    self.items = opts.items or {}
    self.selected = opts.selected
    self.placeholder = opts.placeholder or "(seleccionar)"
    self.theme = opts.theme or {}
    self.row_h = opts.row_h or 34
    self.pad = opts.pad or 4
    self.draw_preview = opts.draw_preview
    -- visible_rows = cuantos items de la lista se ven al abrir,
    -- SIN contar el header. La altura reservada total es
    -- (visible_rows + 1) * row_h + pad * 2.
    local visible = opts.visible_rows or #self.items
    if visible < 1 then visible = 1 end
    if visible > #self.items and #self.items > 0 then
        visible = #self.items
    end
    self.visible_rows = visible
    self.open = false
    self.hover_idx = -1
    self:_recalc()
    return self
end

function Dropdown:_recalc()
    -- Total: header + N items visibles.
    local rows = self.visible_rows + 1
    local h = rows * self.row_h + self.pad * 2
    self.min_h, self.max_h = h, h
    self.min_w, self.max_w = 100, 10000
end

function Dropdown:_current_label()
    for _, it in ipairs(self.items) do
        if it.id == self.selected then return it.label or tostring(it.id) end
    end
    return self.placeholder
end

function Dropdown:set_items(items)
    self.items = items or {}
    if not self.visible_rows or self.visible_rows > #self.items then
        self.visible_rows = math.max(1, #self.items)
    end
    self:_recalc()
    self:invalidate_layout()
end

function Dropdown:set_selected(id)
    if self.selected == id then return end
    self.selected = id
    self:damage()
end

function Dropdown:set_open(v)
    v = v and true or false
    if self.open == v then return end
    self.open = v
    self.hover_idx = -1
    self:damage()
end

function Dropdown:draw(cr)
    local T = self.theme
    local x, y = self.x0, self.y0
    local w, h = self:getWidth(), self:getHeight()
    local rows = self.visible_rows
    local header_h = self.row_h + self.pad * 2

    -- Header (siempre visible)
    cairo.set_rgb(cr, T.bg_card_rgb[1], T.bg_card_rgb[2], T.bg_card_rgb[3])
    cairo.rounded_rect(cr, x, y, w, header_h, 5)
    cairo.fill(cr)
    cairo.set_rgb(cr, T.separator_rgb[1], T.separator_rgb[2], T.separator_rgb[3])
    cairo.set_line_width(cr, 1)
    cairo.rounded_rect(cr, x + 0.5, y + 0.5, w - 1, header_h - 1, 5)
    cairo.stroke(cr)

    local fg = T.fg_rgb
    pango.draw_text(cr, x + 12, y + self.pad + (self.row_h - 15) / 2,
        self:_current_label(), "DejaVu Sans 11",
        { r = fg[1], g = fg[2], b = fg[3] })
    local mu = T.muted_rgb
    pango.draw_text(cr, x + w - 22, y + self.pad + (self.row_h - 15) / 2,
        self.open and "\u{25B4}" or "\u{25BE}", "DejaVu Sans 12",
        { r = mu[1], g = mu[2], b = mu[3] })

    if not self.open then return end

    -- Lista expandida debajo del header
    for i, it in ipairs(self.items) do
        if i > self.visible_rows then break end
        local ry = y + header_h + (i - 1) * self.row_h
        local sel = (it.id == self.selected)
        local hov = (self.hover_idx == i)

        -- Fondo de la fila
        if sel then
            cairo.set_rgb(cr, T.accent_rgb[1], T.accent_rgb[2], T.accent_rgb[3])
        elseif hov then
            cairo.set_rgb(cr, T.bg_focus_rgb[1], T.bg_focus_rgb[2], T.bg_focus_rgb[3])
        else
            cairo.set_rgb(cr, T.bg_card_rgb[1], T.bg_card_rgb[2], T.bg_card_rgb[3])
        end
        cairo.rectangle(cr, x, ry, w, self.row_h)
        cairo.fill(cr)

        local rfg = sel and T.bg_rgb or T.fg_rgb
        local px = x + 12
        if self.draw_preview then
            local pw = math.min(w - 180, 160)
            if pw >= 50 then
                self.draw_preview(cr, it, px, ry + 6, pw, self.row_h - 12)
                px = px + pw + 10
            end
        end
        pango.draw_text(cr, px, ry + (self.row_h - 15) / 2,
            it.label or tostring(it.id), "DejaVu Sans 11",
            { r = rfg[1], g = rfg[2], b = rfg[3] })
    end

    -- Borde exterior de la lista
    cairo.set_rgb(cr, T.separator_rgb[1], T.separator_rgb[2], T.separator_rgb[3])
    cairo.set_line_width(cr, 1)
    local list_h = rows * self.row_h
    cairo.rectangle(cr, x + 0.5, y + header_h + 0.5, w - 1, list_h - 1)
    cairo.stroke(cr)
end

function Dropdown:_row_at(my)
    local header_h = self.row_h + self.pad * 2
    if my < header_h then return -2 end  -- click en el header
    local i = math.floor((my - header_h) / self.row_h) + 1
    if i < 1 or i > self.visible_rows or i > #self.items then return -1 end
    return i
end

function Dropdown:on_mouse_move(mx, my)
    if not self.open then return end
    local idx = self:_row_at(my)
    if idx ~= self.hover_idx then
        self.hover_idx = idx
        self:damage()
    end
end

function Dropdown:on_mouse_press(mx, my, button)
    if button ~= 1 then return end
    if not self.open then
        self:set_open(true)
        return
    end
    local idx = self:_row_at(my)
    if idx == -2 then
        -- Click en el header: cierra
        self:set_open(false)
    elseif idx > 0 then
        local it = self.items[idx]
        if it then
            self.selected = it.id
            self:set_open(false)
            if self.opts.on_select then self.opts.on_select(it.id) end
        end
    else
        -- Click fuera de la lista: cierra
        self:set_open(false)
    end
end

return Dropdown
