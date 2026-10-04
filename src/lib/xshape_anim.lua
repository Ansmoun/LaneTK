-- xshape_anim.lua: reveal de cortina con XShape, reutilizable.
-- Extraido de launcher/logout tras el tercer uso identico.

local xcb = require("lib.xcb")
local ffi = require("ffi")
ffi.cdef[[int usleep(unsigned int usec);]]

local M = {}

local function build_rounded_rects(w, h, r, visible_h)
    if visible_h < 1 then return {} end
    r = math.min(r or 0, math.floor(h / 2), math.floor(w / 2))
    local y_start = h - visible_h
    local r2 = r * r
    local rects = {}

    local function dx_at(y)
        local dx = 0
        if y < r then
            local dy = r - y - 0.5
            local sq = r2 - dy * dy
            if sq > 0 then dx = r - math.floor(math.sqrt(sq) + 0.5) end
        elseif y >= h - r then
            local dy = y - (h - r) + 0.5
            local sq = r2 - dy * dy
            if sq > 0 then dx = r - math.floor(math.sqrt(sq) + 0.5) end
        end
        if dx < 0 then dx = 0 end
        return dx
    end

    local prev_dx, run_y0 = nil, nil
    local function flush_run(y_end)
        if prev_dx ~= nil then
            local rw = w - 2 * prev_dx
            if rw > 0 then
                rects[#rects + 1] = { prev_dx, run_y0, rw, y_end - run_y0 }
            end
        end
    end

    local y = y_start
    while y < h and y < r do
        local dx = dx_at(y)
        if dx ~= prev_dx then
            if prev_dx ~= nil then flush_run(y) end
            prev_dx, run_y0 = dx, y
        end
        y = y + 1
    end
    local flat_end = h - r - 1
    if y <= flat_end then
        if prev_dx ~= 0 then
            if prev_dx ~= nil then flush_run(y) end
            prev_dx, run_y0 = 0, y
        end
        y = flat_end + 1
    end
    while y < h do
        local dx = dx_at(y)
        if dx ~= prev_dx then
            if prev_dx ~= nil then flush_run(y) end
            prev_dx, run_y0 = dx, y
        end
        y = y + 1
    end
    if prev_dx ~= nil then flush_run(h) end
    return rects
end

-- M.attach{ srv, win, w, h, radius, ms?, steps? } -> handle
-- handle:show()   -- anima de 0 a 1
-- handle:hide()   -- anima de 1 a 0
-- handle:reset()  -- mascara vacia instantanea
-- handle:visible() -- bool
function M.attach(opts)
    local srv = opts.srv
    local win = opts.win
    local w, h = opts.w, opts.h
    local radius = opts.radius or 12
    local ms = opts.ms or 240
    local steps = opts.steps or 16

    local self = {
        win = win, w = w, h = h, radius = radius,
        ms = ms, steps = steps,
        current = 0, target = 0, last = -1,
    }

    local function apply(visible_h, input_too)
        if not win or win.destroyed then return end
        if visible_h == self.last and not input_too then return end
        self.last = visible_h
        local rects = build_rounded_rects(w, h, radius, visible_h)
        xcb.shape_rectangles(srv.conn, win.id, rects,
            { kind = xcb.SHAPE_KIND.Bounding })
        if input_too then
            xcb.shape_rectangles(srv.conn, win.id, rects,
                { kind = xcb.SHAPE_KIND.Input })
        end
        xcb.flush(srv.conn)
    end

    function self:reset()
        self.current = 0
        self.target = 0
        self.last = -1
        apply(0, true)
    end

    function self:animate(to)
        if self.target == to and self.current == to then return end
        local from = self.current
        self.target = to
        xcb.flush(srv.conn)
        local step_ms = ms / steps
        for i = 1, steps do
            local t = i / steps
            local e = t * t * (3 - 2 * t)
            self.current = from + (to - from) * e
            local vis = math.floor(self.current * h + 0.5)
            apply(vis, i == steps)
            if i < steps then
                ffi.C.usleep(math.floor(step_ms * 1000))
            end
        end
        self.current = to
    end

    function self:show()
        if self.target == 1 then return end
        self:animate(1)
    end

    function self:hide()
        if self.target == 0 then return end
        self:animate(0)
    end

    function self:visible()
        return self.target == 1
    end

    self:reset()
    return self
end

return M
