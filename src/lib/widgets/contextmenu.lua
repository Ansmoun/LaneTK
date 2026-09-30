-- ContextMenu: menu contextual flotante, anclado a un punto de la
-- ventana padre. Uso tipico: click derecho sobre un item.
--
-- Usa una ventana child del padre + xcb_grab_pointer para detectar
-- clicks fuera de su rect. Mientras esta abierto, TODOS los clicks
-- van al menu (por el grab). El primer click fuera de su rect lo
-- cierra y se consume.
--
-- Uso:
--   local CM = require("lib.widgets.contextmenu")
--   local cm = CM.new(srv, parent_window, theme)
--   cm:show(x, y, {
--       { label = "Terminar", on_click = function() ... end },
--       { label = "Forzar", color = {0.9,0.4,0.4}, on_click = ... },
--       { sep = true },
--       { label = "Propiedades", on_click = ... },
--   })
--
--   cm:is_open()   -- consultar si esta abierto
--   cm:close()     -- cerrar sin ejecutar

local Window = require("lib.window")
local cairo  = require("lib.cairo")
local pango  = require("lib.pango")
local log    = require("lib.log")
local xcb    = require("lib.xcb")

local M = {}

local ContextMenu = {}
ContextMenu.__index = ContextMenu

local ITEM_H = 26
local PAD_X  = 14
local PAD_Y  = 6
local MIN_W  = 180
local FONT   = "DejaVu Sans 10"

function M.new(srv, parent_win, theme)
    local self = setmetatable({}, ContextMenu)
    self.srv        = srv
    self.parent_win = parent_win
    self.theme      = theme
    self.win        = nil
    self.items      = {}
    self.hover_idx  = nil
    self.on_close_cb = nil
    return self
end

function M.is_available()
    return Window ~= nil
end

-- items: array de { label, on_click, color?, enabled? } o { sep = true }
-- opts: { on_close = function }
function ContextMenu:show(x, y, items, opts)
    opts = opts or {}
    if self.win and not self.win.destroyed then
        self:close()
    end

    self.items = items or {}
    self.hover_idx = nil
    self.on_close_cb = opts.on_close

    local T = self.theme

    -- Ancho: max del texto + espacio para un chevron a la derecha.
    local max_w = 0
    for _, it in ipairs(self.items) do
        if it.label then
            local w = pango.measure(it.label, FONT)
            if w > max_w then max_w = w end
        end
    end
    local w = math.max(MIN_W, max_w + PAD_X * 2 + 16)

    -- Alto total
    local h = PAD_Y * 2
    for _, it in ipairs(self.items) do
        if it.sep then h = h + 1 else h = h + ITEM_H end
    end

    -- Reposicionar si se sale del parent
    local px, py = math.floor(x), math.floor(y)
    local parent_w = self.parent_win.width
    local parent_h = self.parent_win.height
    if px + w > parent_w - 4 then px = parent_w - w - 4 end
    if py + h > parent_h - 4 then py = parent_h - h - 4 end
    if px < 4 then px = 4 end
    if py < 4 then py = 4 end

    local win
    win = Window.new(self.srv, {
        parent_window = self.parent_win,
        kind          = "child",
        width         = w,
        height        = h,
        x             = px,
        y             = py,
        disable_q_close = true,
        on_draw = function(cr, cw, ch)
            self:_draw(cr, cw, ch)
        end,
        on_mouse = function(mx, my, button)
            self:_on_mouse(mx, my, button)
        end,
        on_mouse_move = function(mx, my)
            self:_on_mouse_move(mx, my)
        end,
        on_key = function(key)
            self:_on_key(key)
        end,
    })
    self.win = win
    self.win_w = w
    self.win_h = h

    -- Grab de pointer: todos los clicks van al child.
    xcb.grab_pointer(self.win.conn, self.win.id)
    -- Foco para teclado (Esc).
    self.win:set_input_focus()
end

function ContextMenu:close()
    if not self.win then return end
    local w = self.win
    local conn = w.conn
    self.win = nil
    xcb.ungrab_pointer(conn)
    if not w.destroyed then
        w:close("context menu cerrado")
    end
    if self.on_close_cb then self.on_close_cb() end
end

function ContextMenu:is_open()
    return self.win ~= nil and not self.win.destroyed
end

-- ============================================================
-- Internals
-- ============================================================

function ContextMenu:_draw(cr, w, h)
    local T = self.theme

    -- Fondo
    local br, bg, bb = T.bg_card_rgb[1], T.bg_card_rgb[2], T.bg_card_rgb[3]
    cairo.set_rgb(cr, br, bg, bb)
    cairo.paint(cr)

    -- Borde
    local sr, sg, sb = T.separator_rgb[1], T.separator_rgb[2], T.separator_rgb[3]
    cairo.set_rgb(cr, sr, sg, sb)
    cairo.set_line_width(cr, 1)
    cairo.rectangle(cr, 0.5, 0.5, w - 1, h - 1)
    cairo.stroke(cr)

    local y = PAD_Y
    for i, it in ipairs(self.items) do
        if it.sep then
            cairo.set_rgb(cr, sr, sg, sb)
            cairo.rectangle(cr, PAD_X, y, w - PAD_X * 2, 1)
            cairo.fill(cr)
            y = y + 1
        else
            local is_hover = (self.hover_idx == i)
            local is_enabled = it.enabled ~= false

            if is_hover and is_enabled then
                local ar, ag, ab = T.accent_rgb[1], T.accent_rgb[2], T.accent_rgb[3]
                cairo.set_rgba(cr, ar, ag, ab, 0.25)
                cairo.rectangle(cr, 4, y, w - 8, ITEM_H)
                cairo.fill(cr)
            end

            local color
            if not is_enabled then
                color = T.muted_rgb
            elseif it.color then
                color = it.color
            else
                color = T.fg_rgb
            end
            local tr, tg, tb = color[1], color[2], color[3]
            local _, th = pango.measure(it.label, FONT)
            local ty = y + (ITEM_H - th) / 2
            pango.draw_text(cr, PAD_X, ty, it.label, FONT,
                { r = tr, g = tg, b = tb })
            y = y + ITEM_H
        end
    end
end

function ContextMenu:_index_at(my)
    local y = PAD_Y
    for i, it in ipairs(self.items) do
        if it.sep then
            y = y + 1
        else
            if my >= y and my < y + ITEM_H then
                return i
            end
            y = y + ITEM_H
        end
    end
    return nil
end

-- Devuelve true si el click esta dentro del menu.
local function inside(x, y, w, h)
    return x >= 0 and x < w and y >= 0 and y < h
end

function ContextMenu:_on_mouse(mx, my, button)
    -- El grab redirige clicks de cualquier lugar al child, pero
    -- event_x/event_y pueden ser negativos o mayores que w/h si el
    -- click fue fuera.
    local w = self.win and self.win.width  or self.win_w
    local h = self.win and self.win.height or self.win_h

    if not inside(mx, my, w, h) then
        -- Click fuera: cerrar y consumir. El primer click fuera
        -- cierra el menu, no ejecuta nada del padre.
        self:close()
        return
    end

    if button ~= 1 then return end
    local idx = self:_index_at(my)
    if idx then
        local it = self.items[idx]
        if it and it.enabled ~= false and it.on_click then
            self:close()
            -- Ejecutar despues de cerrar para que el menu
            -- desaparezca antes que la accion.
            it.on_click()
            return
        end
    end
end

function ContextMenu:_on_mouse_move(mx, my)
    local w = self.win and self.win.width  or self.win_w
    local h = self.win and self.win.height or self.win_h
    local new_hover = nil
    if inside(mx, my, w, h) then
        new_hover = self:_index_at(my)
        local it = new_hover and self.items[new_hover]
        if it and it.sep then new_hover = nil end
        if it and it.enabled == false then new_hover = nil end
    end
    if new_hover ~= self.hover_idx then
        self.hover_idx = new_hover
        if self.win then
            self.win:damage_all()
            self.win:draw()
        end
    end
end

function ContextMenu:_on_key(key)
    if not key.pressed then return end
    if key.name == "Escape" then
        self:close()
    end
end

return M
