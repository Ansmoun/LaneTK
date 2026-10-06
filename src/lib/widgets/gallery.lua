-- Gallery: grid de thumbnails clickeables.

local Area  = require("lib.area")
local cairo = require("lib.cairo")

local Gallery = setmetatable({}, { __index = Area })
Gallery.__index = Gallery

function Gallery.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), Gallery)
    self._hover_visual  = true
    self._pressed_visual = true
    self.items = opts.items or {}
    self.item_size = opts.item_size or 110
    self.gap = opts.gap or 6
    self.theme = opts.theme or {}
    self.selected = opts.selected
    self.hover_idx = -1
    self.cols = 1
    self.min_w, self.max_w = self.item_size, 10000
    self.min_h, self.max_h = self.item_size, 10000
    return self
end

function Gallery:_recalc()
    local w = self:getWidth()
    if w <= 0 then w = self.min_w end
    local step = self.item_size + self.gap
    self.cols = math.max(1, math.floor((w + self.gap) / step))
    local n = #self.items
    local rows = math.max(1, math.ceil(n / self.cols))
    local h = rows * self.item_size + (rows - 1) * self.gap
    self.min_h, self.max_h = h, h
end

function Gallery:set_items(items)
    self.items = items or {}
    self.hover_idx = -1
    self:_recalc()
    self:invalidate_layout()
end

function Gallery:set_selected(path)
    if self.selected == path then return end
    self.selected = path
    self:damage()
end

function Gallery:layout(x0, y0, x1, y1)
    Area.layout(self, x0, y0, x1, y1)
    self:_recalc()
end

function Gallery:_rect_for(i)
    local col = (i - 1) % self.cols
    local row = math.floor((i - 1) / self.cols)
    local step = self.item_size + self.gap
    local x = self.x0 + col * step
    local y = self.y0 + row * step
    return x, y, self.item_size, self.item_size
end

function Gallery:_idx_at(mx, my)
    local step = self.item_size + self.gap
    local col = math.floor(mx / step)
    local row = math.floor(my / step)
    if col < 0 or col >= self.cols then return -1 end
    local i = row * self.cols + col + 1
    if i < 1 or i > #self.items then return -1 end
    local gx = mx - col * step
    local gy = my - row * step
    if gx >= self.item_size or gy >= self.item_size then return -1 end
    return i
end

function Gallery:draw(cr)
    local T = self.theme
    for i, item in ipairs(self.items) do
        local x, y, w, h = self:_rect_for(i)
        local is_sel = (item.path == self.selected)
        local is_hov = (i == self.hover_idx)
        if is_sel then
            cairo.set_rgb(cr, T.accent_rgb[1], T.accent_rgb[2], T.accent_rgb[3])
        elseif is_hov then
            cairo.set_rgb(cr, T.bg_focus_rgb[1], T.bg_focus_rgb[2], T.bg_focus_rgb[3])
        else
            cairo.set_rgb(cr, T.bg_card_rgb[1], T.bg_card_rgb[2], T.bg_card_rgb[3])
        end
        cairo.rounded_rect(cr, x, y, w, h, 5)
        cairo.fill(cr)

        local surf = item.thumb and cairo.load_png_cached(item.thumb)
        if surf then
            local tw = cairo.surface_width(surf)
            local th = cairo.surface_height(surf)
            local scale = math.min((w - 8) / tw, (h - 8) / th)
            local dw, dh = tw * scale, th * scale
            cairo.draw_surface(cr, surf,
                x + (w - dw) / 2, y + (h - dh) / 2, dw, dh)
        end
    end
end

function Gallery:on_mouse_move(mx, my)
    local idx = self:_idx_at(mx, my)
    if idx ~= self.hover_idx then
        self.hover_idx = idx
        self:damage()
    end
end

function Gallery:on_mouse_press(mx, my, button)
    if button ~= 1 then return end
    local idx = self:_idx_at(mx, my)
    if idx < 0 then return end
    local item = self.items[idx]
    if item then
        self.selected = item.path
        self:damage()
        if self.opts.on_select then self.opts.on_select(item.path) end
    end
end

return Gallery
