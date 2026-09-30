-- data/temps: lectura de sensores de temperatura. CPU via hwmon
-- (coretemp), placa via thermal_zone. Sin shell para los valores:
-- lectura directa de archivos con io.open.

local U = require("lib.helpers.util")

local M = {}

function M.find_coretemp()
    local p = io.popen("ls -1d /sys/class/hwmon/hwmon* 2>/dev/null")
    if not p then return nil end
    local found = nil
    for h in p:lines() do
        local name = U.trim(U.read_file(h .. "/name") or "")
        if name == "coretemp" then
            found = h
            break
        end
    end
    p:close()
    return found
end

-- Cache de los labels leidos una sola vez (no cambian).
local coretemp_labels = nil
local coretemp_files = nil

local function scan_coretemp(path)
    if coretemp_labels and coretemp_labels.path == path then return end
    coretemp_labels = { path = path }
    coretemp_files = {}
    -- Recorremos manualmente sin popen: los archivos son
    -- temp1_input, temp2_input, ...
    for i = 1, 20 do
        local f = path .. "/temp" .. i .. "_input"
        local fh = io.open(f, "r")
        if fh then
            fh:close()
            local lbl = U.trim(U.read_file(path .. "/temp" .. i .. "_label") or "")
            coretemp_files[#coretemp_files + 1] = { file = f, label = lbl }
        end
    end
end

function M.read_coretemp(path)
    local out = { core0 = nil, core1 = nil, pkg = nil }
    if not path then return out end
    scan_coretemp(path)
    for _, e in ipairs(coretemp_files) do
        local val = tonumber(U.trim(U.read_file(e.file) or ""))
        if val then
            local t = math.floor(val / 1000)
            if     e.label == "Core 0"        then out.core0 = t
            elseif e.label == "Core 1"        then out.core1 = t
            elseif e.label == "Package id 0"  then out.pkg   = t
            end
        end
    end
    return out
end

function M.read_zones()
    local function read_num(p)
        local v = U.read_file(p)
        if not v then return nil end
        return tonumber(U.trim(v))
    end
    local out = {}
    local t0 = read_num("/sys/class/thermal/thermal_zone0/temp")
    local t1 = read_num("/sys/class/thermal/thermal_zone1/temp")
    if t0 then out.board = math.floor(t0 / 1000) end
    if t1 then out.x86   = math.floor(t1 / 1000) end
    return out
end

-- SMART: lee /tmp/disk-temp.txt si existe (lo escribe un servicio
-- en runit o cron). Callback compatible con la API original.
function M.read_smart(cb)
    local v = U.read_file("/tmp/disk-temp.txt")
    if v then
        local n = tonumber(U.trim(v))
        cb(n)
    else
        cb(nil)
    end
end

return M
