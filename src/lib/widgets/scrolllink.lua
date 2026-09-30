-- Coordina un ScrollView con un ScrollBar. Cablea el flujo
-- bidireccional sin bucles:
--   list:on_change -> sb:set_offset(silent) + sb:set_offset_max
--   sb:on_change   -> list:set_offset

local M = {}

function M.link(list, sb)
    list:on_change(function(off, max)
        sb:set_offset(off, true)
        sb:set_offset_max(max)
    end)
    sb:on_change(function(new_off)
        list:set_offset(new_off)
    end)
end

return M
