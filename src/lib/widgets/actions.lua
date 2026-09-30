local Area   = require("lib.area")
local Text   = require("lib.widgets.text")
local Button = require("lib.widgets.button")
local Group  = require("lib.widgets.group")
local timer  = require("lib.timer")

local Actions = setmetatable({}, { __index = Area })
Actions.__index = Actions

-- opts:
--   actions    : array de { label, cmd, ok_msg }
--                label   : texto visible
--                cmd     : comando shell
--                ok_msg  : texto si exit code = 0 (opcional)
--   feedback_time : ms que dura el feedback (default 3000)
--   button_width  : ancho minimo de boton      (default 140)
--   row_spacing   : espacio entre botones      (default 6)
--   feedback_color: {r,g,b} color del feedback
--   feedback_error_color
--   on_run        : function(label, cmd) -> override del run
--                   (por defecto usa os.execute)
function Actions.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), Actions)

    self.feedback_time = opts.feedback_time or 3000
    self.button_width  = opts.button_width  or 140
    self.row_spacing   = opts.row_spacing   or 6
    self.feedback_color = opts.feedback_color or { 0.55, 0.85, 0.60 }
    self.feedback_error_color = opts.feedback_error_color or { 0.90, 0.40, 0.40 }
    self.on_run = opts.on_run  -- opcional

    self.buttons = {}
    self.rows = {}

    self.feedback = Text.new {
        text = "",
        font = "DejaVu Sans 10",
        r = self.feedback_color[1],
        g = self.feedback_color[2],
        b = self.feedback_color[3],
        align = "left", valign = "center",
    }
    self.feedback_timer = nil
    self.feedback_h = 0

    for _, a in ipairs(opts.actions or {}) do
        self:add_action(a.label, a.cmd, a.ok_msg)
    end
    return self
end

function Actions:_run(action)
    local cmd = action.cmd
    local ok, msg

    if self.on_run then
        ok, msg = self.on_run(action.label, cmd)
    else
        -- os.execute: true si exit 0. En LuaJIT devuelve tres valores
        -- (ok, "exit", status). Reducimos a booleano.
        local a = os.execute(cmd)
        ok = (a == true or a == 0)
        msg = action.ok_msg or (ok and "OK" or "Fallo")
    end

    self.feedback:set_text(msg or "")

    -- Color del feedback segun exito
    if ok then
        local c = self.feedback_color
        self.feedback:set_color(c[1], c[2], c[3])
    else
        local c = self.feedback_error_color
        self.feedback:set_color(c[1], c[2], c[3])
    end

    -- Cancelar timer previo
    if self.feedback_timer then
        self.feedback_timer:cancel()
    end

    -- Timer para limpiar feedback
    self.feedback_timer = (self.window and self.window.server
        and self.window.server:add_timer(self.feedback_time, function()
            self.feedback:set_text("")
            self.feedback_timer = nil
        end))
end

function Actions:add_action(label, cmd, ok_msg)
    local action = { label = label, cmd = cmd, ok_msg = ok_msg }

    local btn = Button.new {
        text = label,
        font = "DejaVu Sans 10",
        flat = true,
        padding_x = 6,
        padding_y = 3,
        corner_radius = 4,
        min_width = self.button_width,
        on_click = function()
            self:_run(action)
        end,
    }
    self.buttons[#self.buttons + 1] = btn
    self.rows[#self.rows + 1] = btn
    return action
end

function Actions:set_window(win)
    self.window = win
    for _, b in ipairs(self.buttons) do
        b.window = win
    end
    self.feedback.window = win
end

function Actions:_total_height()
    local n = #self.rows
    if n == 0 then return 0 end
    local btn_h = 28   -- aproximado del Button por defecto
    local h = n * btn_h + (n - 1) * self.row_spacing
    h = h + 8 + 14     -- feedback
    return h
end

function Actions:askMinMax(minw, minh, maxw, maxh)
    local w = self.button_width
    local h = self:_total_height()
    return minw + w, minh + h, maxw + 10000, maxh + h
end

function Actions:layout(x0, y0, x1, y1)
    Area.layout(self, x0, y0, x1, y1)
    local avail_w = x1 - x0
    local bw = math.min(self.button_width, avail_w)
    local bx = x0 + math.floor((avail_w - bw) / 2)

    local y = y0
    for _, btn in ipairs(self.buttons) do
        local h = btn.min_h
        btn:layout(bx, y, bx + bw, y + h)
        y = y + h + self.row_spacing
    end
    if y + 18 <= y1 then
        self.feedback:layout(bx, y + 4, bx + bw, y + 4 + 14)
    end
end

function Actions:draw(cr)
    for _, btn in ipairs(self.buttons) do
        btn:draw(cr)
    end
    self.feedback:draw(cr)
end

function Actions:getByXY(x, y)
    for _, btn in ipairs(self.buttons) do
        local hit = btn:getByXY(x, y)
        if hit then return hit end
    end
    if x >= self.x0 and x < self.x1 and y >= self.y0 and y < self.y1 then
        return self
    end
    return nil
end

return Actions
