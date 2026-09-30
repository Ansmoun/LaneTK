-- data/cpu: lectura de /proc/stat, /proc/cpuinfo, /proc/uptime,
-- /proc/loadavg y frecuencias del cpufreq.

local U = require("lib.helpers.util")

local M = {}
local prev_stat = nil

local function read_stat()
    local cur = {}
    for line in (U.read_file("/proc/stat") or ""):gmatch("[^\n]+") do
        local name, rest = line:match("^(cpu%d*)%s+(.+)$")
        if name then
            local f = {}
            for v in rest:gmatch("%d+") do table.insert(f, tonumber(v)) end
            local active = (f[1] or 0) + (f[2] or 0) + (f[3] or 0)
                         + (f[6] or 0) + (f[7] or 0) + (f[8] or 0)
            local idle   = (f[4] or 0) + (f[5] or 0)
            cur[name] = { active = active, idle = idle }
        end
    end
    return cur
end

-- Cache: path del hwmon coretemp y los archivos temp*_input
local coretemp_path = nil
local coretemp_files = nil

local function ensure_coretemp()
    if coretemp_path then return end
    -- Una sola vez: buscar el hwmon de coretemp.
    for i = 0, 9 do
        local h = "/sys/class/hwmon/hwmon" .. i
        local name = U.trim(U.read_file(h .. "/name") or "")
        if name == "coretemp" then
            coretemp_path = h
            break
        end
    end
    if not coretemp_path then
        coretemp_path = false  -- marcador: no existe
        return
    end
    -- Cache de los archivos temp*_input + label
    coretemp_files = {}
    for i = 1, 20 do
        local f = coretemp_path .. "/temp" .. i .. "_input"
        local fh = io.open(f, "r")
        if fh then
            fh:close()
            local lbl = U.trim(U.read_file(
                coretemp_path .. "/temp" .. i .. "_label") or "")
            coretemp_files[#coretemp_files + 1] = { file = f, label = lbl }
        end
    end
end

local function read_temp()
    ensure_coretemp()
    if not coretemp_path then return 0 end
    for _, e in ipairs(coretemp_files) do
        if e.label == "Package id 0" or e.label == "Core 0" then
            local val = tonumber(U.trim(U.read_file(e.file) or ""))
            if val then return math.floor(val / 1000) end
        end
    end
    return 0
end

function M.reset()
    prev_stat = nil
end

function M.sample()
    local cur = read_stat()
    local usage = 0
    local per_core = {}
    local n_cores = 0

    for name in pairs(cur) do
        if name:match("^cpu%d+$") then n_cores = n_cores + 1 end
    end

    if prev_stat then
        for name, v in pairs(cur) do
            local p = prev_stat[name]
            if p then
                local da, di = v.active - p.active, v.idle - p.idle
                local tot = da + di
                if tot > 0 then
                    local u = da / tot
                    if name == "cpu" then
                        usage = u
                    else
                        local idx = tonumber(name:match("cpu(%d+)"))
                        if idx then per_core[idx] = u end
                    end
                end
            end
        end
    end
    prev_stat = cur

    local f = tonumber(U.trim(U.read_file(
        "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq") or "0"))

    return {
        usage    = usage,
        per_core = per_core,
        n_cores  = n_cores,
        freq     = f / 1000,
        temp     = read_temp(),
    }
end

function M.info()
    local ci = U.read_file("/proc/cpuinfo") or ""
    local model = ci:match("model name%s*:%s*([^\n]+)") or "?"
    model = model:gsub("%(R%)", ""):gsub("%(TM%)", "")
                 :gsub("%s+", " ")
                 :gsub("^%s+", ""):gsub("%s+$", "")
    local uptime = tonumber((U.read_file("/proc/uptime") or "0"):match("^([%d%.]+)")) or 0
    local loadavg = (U.read_file("/proc/loadavg") or ""):match("^([%d%.]+)") or "?"
    return { model = model, uptime = uptime, loadavg = loadavg }
end

function M.freq_range()
    local min_khz = tonumber(U.trim(U.read_file(
        "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq") or "0")) or 0
    local max_khz = tonumber(U.trim(U.read_file(
        "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq") or "0")) or 0
    return {
        min = min_khz > 0 and math.floor(min_khz / 1000) or 800,
        max = max_khz > 0 and math.floor(max_khz / 1000) or 1100,
    }
end

return M
