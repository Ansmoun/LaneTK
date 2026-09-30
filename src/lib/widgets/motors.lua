-- Motors es una configuracion concreta de BarRow: solo label + bar.
-- Se mantiene como clase propia para que la API sea comoda.

local BarRow = require("lib.widgets.barrow")

local Motors = setmetatable({}, { __index = BarRow })
Motors.__index = Motors

function Motors.new(opts)
    opts = opts or {}
    -- Defaults historicos: sin pct ni detalle. Pero respetamos
    -- lo que venga en opts, para que un consumidor pueda pedir
    -- la columna de porcentaje sin tener que usar BarRow
    -- directamente.
    if opts.pct_width == nil    then opts.pct_width    = 0 end
    if opts.detail_width == nil then opts.detail_width = 0 end
    opts.left_width = opts.left_width or 40
    local self = setmetatable(BarRow.new(opts), Motors)
    return self
end

-- set(id, pct) -- en Motors el pct es un escalar, no tabla.
function Motors:set(id, pct)
    BarRow.set(self, id, { pct = pct })
end

-- set_animated(id, pct, duration) -- atajo animado de set.
function Motors:set_animated(id, pct, duration)
    BarRow.set_animated(self, id, { pct = pct }, duration)
end

return Motors
