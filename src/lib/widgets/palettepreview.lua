-- PalettePreview: fila de swatches con los colores de una paleta.
local Area  = require("lib.area")
local cairo = require("lib.cairo")
local G     = require("lib.helpers.graphics")

local PalettePreview = setmetatable({}, { __index = Area })
PalettePreview.__index = PalettePreview

local _cache = {}
local function load_palette(path)
    if not path then return nil end
    if _cache[path] ~= nil then return _cache[path] or nil end
    local chunk = loadfile(path)
    if not chunk then _cache[path] = false; return nil end
    local ok, p = pcall(chunk)
    if not ok or not p or not p.colors then
        _cache[path] = false; return nil
    end
    _cache[path] = p
    return p
end

local DEFAULT_KEYS = { "bg", "bg_card", "accent", "fg", "urgent" }

function PalettePreview.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), PalettePreview)
    self.path = opts.path
    self.keys = opts.keys or DEFAULT_KEYS
    self.swatch_h = opts.swatch_h or 20
    self.gap = opts.gap or 2
    self.corner_radius = opts.corner_radius or 3
    self.min_h, self.max_h = self.swatch_h, self.swatch_h
    self.min_w, self.max_w = 40, 10000
    return self
end

function PalettePreview:set_palette(path)
    if self.path == path then return end
    self.path = path
    self:damage()
end

function PalettePreview:draw(cr)
    local p = load_palette(self.path)
    if not p then return end
    local n = #self.keys
    local w = self:getWidth()
    local sw = (w - (n - 1) * self.gap) / n
    local y = self.y0 + (self:getHeight() - self.swatch_h) / 2
    for i, key in ipairs(self.keys) do
        local hex = (p.colors and p.colors[key])
            or (p.semantic and p.semantic[key])
        if hex then
            local r, g, b = G.hex_to_rgba(hex)
            cairo.set_rgb(cr, r, g, b)
            cairo.rounded_rect(cr, self.x0 + (i - 1) * (sw + self.gap),
                y, sw, self.swatch_h, self.corner_radius)
            cairo.fill(cr)
        end
    end
end

return PalettePreview
