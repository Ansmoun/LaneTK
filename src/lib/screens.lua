-- screens.lua: información de monitores del X server.
-- Parsea `xrandr --query` para obtener los rectángulos de cada
-- monitor activo. Sin dependencias extra.

local U = require("lib.helpers.util")

local M = {}

local cached = nil

function M.list()
    if cached then return cached end
    local out = U.shell_once("xrandr --query 2>/dev/null")
    local list = {}
    for line in out:gmatch("[^\n]+") do
        -- Lineas ejemplo:
        --   VGA-1 connected primary 1024x768+0+0 (normal ...)
        --   LVDS-1 connected 1024x600+0+768 (normal ...)
        -- La palabra "primary" es opcional. Extraemos nombre y
        -- geometria buscando la primera aparicion de WxH+X+Y.
        local name = line:match("^(%S+)%s+connected")
        if name then
            local geom = line:match("(%d+x%d+%+%-?%d+%+%-?%d+)")
            if geom then
                local ww, hh, xx, yy =
                    geom:match("(%d+)x(%d+)%+(%-?%d+)%+(%-?%d+)")
                if ww then
                    list[#list + 1] = {
                        name = name,
                        x = tonumber(xx),
                        y = tonumber(yy),
                        w = tonumber(ww),
                        h = tonumber(hh),
                    }
                end
            end
        end
    end
    cached = list
    return list
end

function M.invalidate()
    cached = nil
end

-- Devuelve el rectángulo del monitor que contiene el punto (cx, cy).
-- Si ninguno lo contiene, devuelve el primero.
function M.at(cx, cy)
    local list = M.list()
    for _, s in ipairs(list) do
        if cx >= s.x and cx < s.x + s.w
           and cy >= s.y and cy < s.y + s.h then
            return s
        end
    end
    return list[1]
end

-- Devuelve el centro (cx, cy) de un monitor.
function M.center(s)
    return s.x + math.floor(s.w / 2), s.y + math.floor(s.h / 2)
end

return M
