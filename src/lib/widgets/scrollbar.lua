-- ScrollBar vertical u horizontal. Se ata a un ScrollView (o a
-- cualquier fuente con offset/offset_max) via callbacks.
--
-- Convenio de interaccion:
--   - Click izquierdo + drag mueve el handle.
--   - Rueda del raton: mueve offset por step.
--   - Auto-oculto: si offset_max == 0, no se dibuja ni captura.

local Area  = require("lib.area")
local cairo = require("lib.cairo")
local G     = require("lib.helpers.graphics")

local ScrollBar = setmetatable({}, { __index = Area })
ScrollBar.__index = ScrollBar

-- opts:
--   orientation  : "vertical" | "horizontal"  (default vertical)
--   length       : longitud del track en px   (default 200)
--   width        : grosor del area            (default 20)
--   thickness    : grosor del track           (default 4)
--   handle_r     : radio del handle           (default 5)
--   step         : paso de la rueda           (default 60)
--   color_track  : "#hex"
--   color_handle : "#hex"
--   auto_hide    : bool. Default true.
--   on_change    : function(new_offset)
function ScrollBar.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), ScrollBar)

    self.orientation  = opts.orientation or "vertical"
    self.vertical     = (self.orientation == "vertical")
    self.width        = opts.width     or 20
    self.thickness    = opts.thickness or 4
    self.handle_r     = opts.handle_r  or 5
    self.step         = opts.step      or 60
    self.color_track  = opts.color_track  or "#504945"
    self.color_handle = opts.color_handle or "#8ec07c"
    self.auto_hide    = opts.auto_hide
    if self.auto_hide == nil then self.auto_hide = true end

    self.length = opts.length or 200

    self.offset     = 0
    self.offset_max = 0
    self.dragging   = false
    self.drag_base  = 0
    self.drag_mouse = 0

    self.change_cbs = {}
    if opts.on_change then self.change_cbs[1] = opts.on_change end

    if self.vertical then
        self.min_w, self.max_w = self.width, self.width
        self.min_h, self.max_h = self.length, self.length
    else
        self.min_w, self.max_w = self.length, self.length
        self.min_h, self.max_h = self.width, self.width
    end

    return self
end

function ScrollBar:on_change(fn)
    self.change_cbs[#self.change_cbs + 1] = fn
end

function ScrollBar:_notify(silent)
    if silent then return end
    for _, fn in ipairs(self.change_cbs) do fn(self.offset) end
end

function ScrollBar:is_visible()
    if not self.auto_hide then return true end
    return self.offset_max > 0
end

function ScrollBar:set_offset(px, silent)
    if px < 0 then px = 0 end
    if px > self.offset_max then px = self.offset_max end
    if math.abs(px - self.offset) < 0.01 then return end
    self.offset = px
    self:damage()
    self:_notify(silent)
end

function ScrollBar:set_offset_max(px)
    local old_visible = self:is_visible()
    self.offset_max = math.max(0, px)
    if self.offset > self.offset_max then self.offset = self.offset_max end
    self:damage()
    if old_visible ~= self:is_visible() then
        if self.window then
            self.window:add_damage(self.x0, self.y0, self.x1, self.y1)
        end
    end
end

function ScrollBar:set_step(px) self.step = px end
function ScrollBar:get_offset()     return self.offset end
function ScrollBar:get_offset_max() return self.offset_max end

function ScrollBar:layout(x0, y0, x1, y1)
    Area.layout(self, x0, y0, x1, y1)
    if self.vertical then
        self.length = y1 - y0
    else
        self.length = x1 - x0
    end
end

function ScrollBar:draw(cr)
    if not self:is_visible() then return end

    local x, y = self.x0, self.y0
    local w, h = self:getWidth(), self:getHeight()

    local range
    if self.vertical then
        range = h - 2 * self.handle_r - 4
    else
        range = w - 2 * self.handle_r - 4
    end
    if range <= 0 then return end

    -- Limpiar cualquier path residual antes de empezar. Sin esto,
    -- el primer arc del handle se une con el path pendiente del
    -- on_draw de la ventana y se rellena un triangulo deformado.
    cairo.new_path(cr)

    -- Track (rounded_rect ya hace new_sub_path internamente)
    G.set_color(cr, self.color_track)
    if self.vertical then
        cairo.rounded_rect(cr,
            x + w / 2 - self.thickness / 2,
            y + self.handle_r + 2,
            self.thickness, range,
            self.thickness / 2)
    else
        cairo.rounded_rect(cr,
            x + self.handle_r + 2,
            y + h / 2 - self.thickness / 2,
            range, self.thickness,
            self.thickness / 2)
    end
    cairo.fill(cr)
    cairo.new_path(cr)   -- limpiar despues del fill

    -- Handle
    local pct = 0
    if self.offset_max > 0 then
        pct = self.offset / self.offset_max
    end
    if pct < 0 then pct = 0 elseif pct > 1 then pct = 1 end

    G.set_color(cr, self.color_handle)
    cairo.new_sub_path(cr)
    if self.vertical then
        cairo.arc(cr,
            x + w / 2,
            y + self.handle_r + 2 + range * pct,
            self.handle_r, 0, 2 * math.pi)
    else
        cairo.arc(cr,
            x + self.handle_r + 2 + range * pct,
            y + h / 2,
            self.handle_r, 0, 2 * math.pi)
    end
    cairo.fill(cr)
    cairo.new_path(cr)   -- dejar el cr limpio para el proximo widget
end

function ScrollBar:on_mouse_press(mx, my, button)
    if button ~= 1 then return end
    if not self:is_visible() then return end
    self.dragging = true
    self.drag_base = self.offset
    self.drag_mouse = self.vertical and my or mx
end

function ScrollBar:on_mouse_move(mx, my)
    if not self.dragging then return end
    local pos = self.vertical and my or mx
    local delta = pos - self.drag_mouse

    local range
    if self.vertical then
        range = self:getHeight() - 2 * self.handle_r - 4
    else
        range = self:getWidth() - 2 * self.handle_r - 4
    end
    if range <= 0 or self.offset_max <= 0 then return end

    self:set_offset(self.drag_base + (delta / range) * self.offset_max)
end

function ScrollBar:on_mouse_release(mx, my, button)
    if button == 1 then
        self.dragging = false
    end
end

function ScrollBar:on_wheel(direction)
    if not self:is_visible() then return end
    if direction == 4 then
        self:set_offset(self.offset - self.step)
    elseif direction == 5 then
        self:set_offset(self.offset + self.step)
    end
end

return ScrollBar
