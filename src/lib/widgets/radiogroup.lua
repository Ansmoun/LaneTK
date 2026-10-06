-- RadioGroup: lista vertical de opciones, una seleccionada.
local Area  = require("lib.area")
local cairo = require("lib.cairo")
local pango = require("lib.pango")

local RadioGroup = setmetatable({}, { __index = Area })
RadioGroup.__index = RadioGroup

function RadioGroup.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), RadioGroup)
    self._hover_visual = true
    self._pressed_visual = true
    self.items = opts.items or {}
    self.selected = opts.selected
    self.theme = opts.theme or {}
    self.row_h = opts.row_h or 30
    self.min_w, self.max_w = 100, 10000
    self.min_h = #self.items * self.row_h
    self.max_h = self.min_h
    return self
end

function RadioGroup:set_selected(id)
    if self.selected == id then return end
    self.selected = id
    self:damage()
end

function RadioGroup:draw(cr)
    local T = self.theme
    local w = self:getWidth()
    for i, item in ipairs(self.items) do
        local y = self.y0 + (i - 1) * self.row_h
        local sel = (item.id == self.selected)
        if sel then
            cairo.set_rgb(cr,
                T.bg_focus_rgb[1], T.bg_focus_rgb[2], T.bg_focus_rgb[3])
            cairo.rounded_rect(cr, self.x0, y + 2, w, self.row_h - 4, 6)
            cairo.fill(cr)
        end
        local cx, cy = self.x0 + 16, y + self.row_h / 2
        cairo.new_path(cr)
        cairo.set_line_width(cr, 1.5)
        cairo.set_rgb(cr,
            T.separator_rgb[1], T.separator_rgb[2], T.separator_rgb[3])
        cairo.arc(cr, cx, cy, 7, 0, 2 * math.pi)
        cairo.stroke(cr)
        if sel then
            cairo.new_path(cr)
            cairo.set_rgb(cr,
                T.accent_rgb[1], T.accent_rgb[2], T.accent_rgb[3])
            cairo.arc(cr, cx, cy, 4, 0, 2 * math.pi)
            cairo.fill(cr)
        end
        local fg = T.fg_rgb
        pango.draw_text(cr, cx + 14, y + (self.row_h - 15) / 2,
            item.label or "", "DejaVu Sans 11",
            { r = fg[1], g = fg[2], b = fg[3] })
    end
end

function RadioGroup:on_mouse_press(mx, my, button)
    if button ~= 1 then return end
    local i = math.floor(my / self.row_h) + 1
    local item = self.items[i]
    if item then
        self.selected = item.id
        self:damage()
        if self.opts.on_select then self.opts.on_select(item.id) end
    end
end

return RadioGroup
