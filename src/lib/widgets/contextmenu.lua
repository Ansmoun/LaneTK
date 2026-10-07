-- ContextMenu: menu contextual flotante, anclado a un punto de la
-- ventana padre. Soporta submenús jerárquicos al estilo Windows:
-- al posar el mouse sobre un ítem con submenu, se abre otro
-- ContextMenu a la derecha.
--
-- Se cierra por:
--   1. Click fuera del menú (en el release, ver _on_release).
--   2. El cursor sale del menú y no vuelve en 150ms (hover-out).
--   3. Escape.
--   4. Selección de una acción.
--
-- Uso:
--   local CM = require("lib.widgets.contextmenu")
--   local cm = CM.new(srv, parent_window, theme)
--   cm:show(x, y, {
--       { label = "Abrir", on_click = function() ... end },
--       { label = "Abrir con", submenu = {
--           { label = "Geany", on_click = function() ... end },
--       }},
--   })

local Window = require("lib.window")
local cairo  = require("lib.cairo")
local pango  = require("lib.pango")
local log    = require("lib.log")
local xcb    = require("lib.xcb")

local M = {}

local ContextMenu = {}
ContextMenu.__index = ContextMenu

local ITEM_H  = 26
local PAD_X   = 14
local PAD_Y   = 6
local MIN_W   = 180
local FONT    = "DejaVu Sans 10"
local CHEVRON = "\u{25B8}"     -- ▸
local HOVER_OUT_MS = 150

function M.new(srv, parent_win, theme)
    local self = setmetatable({}, ContextMenu)
    self.srv        = srv
    self.parent_win = parent_win
    self.theme      = theme
    self.win        = nil
    self.items      = {}
    self.hover_idx  = nil
    self.on_close_cb = nil
    self._submenu_cm  = nil
    self._submenu_idx = nil
    self._is_submenu  = false
    self._anchor_rect = nil
    self._pending_close  = false
    self._pending_action = nil
    self._hover_out_timer = nil
    self._saved_interceptor = nil
    return self
end

function M.is_available()
    return Window ~= nil
end

function ContextMenu:show(x, y, items, opts)
    opts = opts or {}
    if self.win and not self.win.destroyed then
        self:close()
    end

    self.items = items or {}
    self.hover_idx = nil
    self.on_close_cb = opts.on_close
    self._is_submenu = opts.no_grab and true or false
    self._anchor_rect = opts.anchor_rect
    self._pending_close  = false
    self._pending_action = nil

    local T = self.theme

    local max_w = 0
    for _, it in ipairs(self.items) do
        if it.label then
            local w = pango.measure(it.label, FONT)
            if w > max_w then max_w = w end
        end
    end
    local w = math.max(MIN_W, max_w + PAD_X * 2 + 20)

    local h = PAD_Y * 2
    for _, it in ipairs(self.items) do
        if it.sep then h = h + 1 else h = h + ITEM_H end
    end

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
            self:_on_press(mx, my, button)
        end,
        on_mouse_release = function(mx, my, button)
            self:_on_release(mx, my, button)
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

    if not opts.no_grab then
        xcb.grab_pointer(self.win.conn, self.win.id)
        self.win:set_input_focus()
        if self.srv then
            self.srv:block_input(100)
        end
        -- Interceptor en la ventana padre. Si un click llega a la
        -- ventana padre mientras el menú está abierto, significa
        -- que el grab_pointer no lo capturó (falla o timing). El
        -- interceptor cierra el menú y consume el click.
        if self.parent_win then
            self._saved_interceptor = self.parent_win._click_interceptor
            local my_self = self
            self.parent_win._click_interceptor =
                function(x, y, button, state)
                    if my_self.win then
                        my_self:close()
                    end
                    local saved = my_self._saved_interceptor
                    if saved then
                        return saved(x, y, button, state)
                    end
                    return true
                end
        end
    end
end

function ContextMenu:close()
    if not self.win then return end
    if self._hover_out_timer then
        self._hover_out_timer:cancel()
        self._hover_out_timer = nil
    end
    if self._submenu_cm then
        self._submenu_cm:close()
        self._submenu_cm = nil
        self._submenu_idx = nil
    end
    local w = self.win
    local conn = w.conn
    self.win = nil
    if not self._is_submenu then
        xcb.ungrab_pointer(conn)
        if self.srv then
            self.srv:block_input(150)
        end
        -- Restaurar el interceptor previo, si lo había.
        if self.parent_win then
            self.parent_win._click_interceptor = self._saved_interceptor
            self._saved_interceptor = nil
        end
    end
    if not w.destroyed then
        w:close("context menu cerrado")
    end
    if self.on_close_cb then self.on_close_cb() end
end

function ContextMenu:is_open()
    return self.win ~= nil and not self.win.destroyed
end

-- ============================================================
-- Submenús
-- ============================================================

function ContextMenu:_open_submenu_for(idx, item_global_y)
    if self._submenu_cm then
        self._submenu_cm:close()
        self._submenu_cm = nil
        self._submenu_idx = nil
    end
    local it = self.items[idx]
    if not it or not it.submenu then return end

    local gx = self.win.x + self.win.width - 2
    local gy = item_global_y - PAD_Y
    if gy < 4 then gy = 4 end

    local cm = M.new(self.srv, self.parent_win, self.theme)
    cm:show(gx, gy, it.submenu, { no_grab = true })
    self._submenu_cm = cm
    self._submenu_idx = idx
end

function ContextMenu:_close_submenu()
    if self._submenu_cm then
        self._submenu_cm:close()
        self._submenu_cm = nil
        self._submenu_idx = nil
    end
end

-- ============================================================
-- Draw
-- ============================================================

function ContextMenu:_draw(cr, w, h)
    local T = self.theme

    local br, bg, bb = T.bg_card_rgb[1], T.bg_card_rgb[2], T.bg_card_rgb[3]
    cairo.set_rgb(cr, br, bg, bb)
    cairo.paint(cr)

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
                local ar, ag, ab = T.accent_rgb[1],
                    T.accent_rgb[2], T.accent_rgb[3]
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

            if it.submenu then
                local chev_w = pango.measure(CHEVRON, FONT)
                local cx = w - PAD_X / 2 - chev_w
                local cc = is_hover and T.accent_rgb or T.muted_rgb
                pango.draw_text(cr, cx, ty, CHEVRON, FONT,
                    { r = cc[1], g = cc[2], b = cc[3] })
            end

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

function ContextMenu:_item_global_y(idx)
    if not self.win then return 0 end
    local y = PAD_Y
    for i, it in ipairs(self.items) do
        if i == idx then
            return self.win.y + y
        end
        if it.sep then y = y + 1 else y = y + ITEM_H end
    end
    return self.win.y + y
end

local function inside(x, y, w, h)
    return x >= 0 and x < w and y >= 0 and y < h
end

-- ============================================================
-- Press / Release
-- ============================================================

function ContextMenu:_on_press(mx, my, button)
    if not self.win then return end
    local w = self.win.width
    local h = self.win.height
    local gx = self.win.x + mx
    local gy = self.win.y + my

    if self._submenu_cm and self._submenu_cm.win then
        local sw = self._submenu_cm.win
        if gx >= sw.x and gx < sw.x + sw.width
           and gy >= sw.y and gy < sw.y + sw.height then
            return self._submenu_cm:_on_press(
                gx - sw.x, gy - sw.y, button)
        end
    end

    if not inside(mx, my, w, h) then
        self._pending_close = true
        return
    end

    if button ~= 1 then return end
    self._pending_action = self:_index_at(my)
end

function ContextMenu:_on_release(mx, my, button)
    if not self.win then return end
    local w = self.win.width
    local h = self.win.height
    local gx = self.win.x + mx
    local gy = self.win.y + my

    if self._submenu_cm and self._submenu_cm.win then
        local sw = self._submenu_cm.win
        if gx >= sw.x and gx < sw.x + sw.width
           and gy >= sw.y and gy < sw.y + sw.height then
            return self._submenu_cm:_on_release(
                gx - sw.x, gy - sw.y, button)
        end
    end

    if self._pending_close then
        self._pending_close = false
        self:close()
        return
    end

    if button ~= 1 then return end

    local pending = self._pending_action
    self._pending_action = nil
    if not pending then return end

    local idx = inside(mx, my, w, h) and self:_index_at(my) or nil
    if idx ~= pending then return end

    local it = self.items[idx]
    if not it or it.enabled == false then return end
    if it.submenu then return end

    if it.on_click then
        self:close()
        it.on_click()
    end
end

-- ============================================================
-- Hover-out
-- ============================================================

function ContextMenu:_cancel_hover_out()
    if self._hover_out_timer then
        self._hover_out_timer:cancel()
        self._hover_out_timer = nil
    end
end

function ContextMenu:_schedule_hover_out()
    if self._is_submenu then return end
    if self._hover_out_timer then return end
    if not self.srv then return end
    -- add_timeout: one-shot. Un solo disparo cierra el menu si el
    -- mouse no volvio a entrar. Con add_timer (periodico) el
    -- handle quedaba vivo tras el primer disparo.
    self._hover_out_timer = self.srv:add_timeout(HOVER_OUT_MS, function()
        self._hover_out_timer = nil
        if self.win then
            self:close()
        end
    end)
end

function ContextMenu:_on_mouse_move(mx, my)
    if not self.win then return end
    local w = self.win.width
    local h = self.win.height

    local gx = self.win.x + mx
    local gy = self.win.y + my

    local over_sub = false
    if self._submenu_cm and self._submenu_cm.win then
        local sw = self._submenu_cm.win
        if gx >= sw.x and gx < sw.x + sw.width
           and gy >= sw.y and gy < sw.y + sw.height then
            over_sub = true
        end
    end

    if over_sub then
        self:_cancel_hover_out()
        self._submenu_cm:_on_mouse_move(gx - self._submenu_cm.win.x,
            gy - self._submenu_cm.win.y)
        return
    end

    if inside(mx, my, w, h) then
        self:_cancel_hover_out()

        local new_hover = self:_index_at(my)
        local it = new_hover and self.items[new_hover]
        if it and it.sep then new_hover = nil; it = nil end
        if it and it.enabled == false then new_hover = nil; it = nil end

        if new_hover ~= self.hover_idx then
            self.hover_idx = new_hover
            if self.win then
                self.win:damage_all()
                self.win:draw()
            end
        end

        if new_hover ~= self._submenu_idx then
            if it and it.submenu then
                self:_open_submenu_for(
                    new_hover, self:_item_global_y(new_hover))
            else
                self:_close_submenu()
            end
        end
        return
    end

    if self.hover_idx ~= nil then
        self.hover_idx = nil
        if self.win then
            self.win:damage_all()
            self.win:draw()
        end
    end
    self:_schedule_hover_out()
end

function ContextMenu:_on_key(key)
    if not key.pressed then return end
    if key.name == "Escape" then
        self:close()
    end
end

return M
