-- SidebarItem: item clickeable para barra lateral.
-- Soporta modo "header" (no clickeable, indent 0) e "indent" (para
-- hijos dentro de un grupo).

local Area  = require("lib.area")
local cairo = require("lib.cairo")
local pango = require("lib.pango")

local SidebarItem = setmetatable({}, { __index = Area })
SidebarItem.__index = SidebarItem

function SidebarItem.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), SidebarItem)
    self._hover_visual  = not opts.header
    self._pressed_visual = not opts.header
    self.id = opts.id
    self.label = opts.label or ""
    self.theme = opts.theme or {}
    self.selected = false
    self.header = opts.header and true or false
    self.indent = opts.indent or 0
    self.min_w, self.max_w = opts.min_w or 140, 10000
    self.min_h, self.max_h = opts.height or 30, opts.height or 30
    return self
end

function SidebarItem:set_selected(v)
    if self.header then return end
    v = v and true or false
    if self.selected == v then return end
    self.selected = v
    self:damage()
end

function SidebarItem:draw(cr)
    local T = self.theme
    local w, h = self:getWidth(), self:getHeight()
    local base_x = self.x0 + 14 + self.indent

    if self.header then
        local mu = T.muted_rgb
        pango.draw_text(cr, self.x0 + 14, self.y0 + (h - 14) / 2,
            self.label, "DejaVu Sans Bold 10",
            { r = mu[1], g = mu[2], b = mu[3] })
        return
    end

    local bg, fg
    if self.selected then
        bg = T.accent_rgb; fg = T.bg_rgb
    elseif self.pressed or self.hover then
        bg = T.bg_focus_rgb; fg = T.fg_rgb
    else
        fg = T.fg_rgb
    end

    if bg then
        cairo.set_rgb(cr, bg[1], bg[2], bg[3])
        cairo.rounded_rect(cr, self.x0 + 6, self.y0, w - 12, h, 6)
        cairo.fill(cr)
    end

    pango.draw_text(cr, base_x, self.y0 + (h - 15) / 2,
        self.label, "DejaVu Sans 11",
        { r = fg[1], g = fg[2], b = fg[3] })
end

function SidebarItem:on_mouse_press(mx, my, button)
    if self.header then return end
    if button == 1 and self.opts.on_click then
        self.opts.on_click(self.id)
    end
end

return SidebarItem
