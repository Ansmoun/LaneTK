-- data/gpu: lee /tmp/gpu-status.txt escrito por el servicio runit.
-- Formato: freq|rc6|power|irqs|render|blitter|video
-- No bloquea: lee un archivo local.

local U = require("lib.helpers.util")

local M = {}

function M.status()
    local content = U.read_file("/tmp/gpu-status.txt")
    if not content then return nil end
    local line = content:match("^([^\n]+)")
    if not line then return nil end
    local freq, rc6, power, irqs, render, blitter, video =
        line:match("([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)")
    if not freq then return nil end
    return {
        freq = tonumber(freq) or 0,   rc6     = tonumber(rc6) or 0,
        power = tonumber(power) or 0, irqs    = tonumber(irqs) or 0,
        render = tonumber(render) or 0, blitter = tonumber(blitter) or 0,
        video = tonumber(video) or 0,
    }
end

function M.specs()
    local spec = { min = 350, max = 1000, boost = 1000 }
    local function read_int(p)
        local v = U.read_file(p)
        if not v then return nil end
        return tonumber(U.trim(v))
    end
    local m = read_int("/sys/class/drm/card0/gt_min_freq_mhz")
    local x = read_int("/sys/class/drm/card0/gt_max_freq_mhz")
    local b = read_int("/sys/class/drm/card0/gt_boost_freq_mhz")
    if m and m > 0 then spec.min = m end
    if x and x > 0 then spec.max = x end
    if b and b > 0 then spec.boost = b end
    return spec
end

return M
