-- data/ram: lectura de /proc/meminfo, /proc/swaps, swappiness y
-- modulos fisicos (dmidecode).

local U = require("lib.helpers.util")

local M = {}

function M.sample()
    local mi = U.read_file("/proc/meminfo") or ""
    local function v(k) return tonumber(mi:match(k .. ":%s+(%d+)")) or 0 end

    local total   = v("MemTotal")
    local free    = v("MemFree")
    local buffers = v("Buffers")
    local cached  = v("Cached")
    local srecl   = v("SReclaimable")
    local shmem   = v("Shmem")
    local avail   = v("MemAvailable")
    if avail == 0 then avail = free + buffers + cached end
    local used = total - avail
    local pct  = total > 0 and used / total or 0

    local sw = U.read_file("/proc/swaps") or ""
    local st, su = sw:match("^[^\n]+\n[^\n]+%s+(%d+)%s+(%d+)")
    local swap_total = tonumber(st) or 0
    local swap_used  = tonumber(su) or 0
    local swap_pct   = swap_total > 0 and swap_used / swap_total or 0

    return {
        total = total, free = free, avail = avail, used = used,
        cached = cached, buffers = buffers, srecl = srecl, shmem = shmem,
        pct = pct,
        swap_total = swap_total, swap_used = swap_used, swap_pct = swap_pct,
    }
end

function M.swappiness()
    local v = U.read_file("/proc/sys/vm/swappiness")
    if not v then return 60 end
    return tonumber((v:gsub("%s+", ""))) or 60
end

function M.set_swappiness(v)
    v = math.max(0, math.min(100, math.floor(v + 0.5)))
    os.execute("sudo -n sysctl -w vm.swappiness=" .. v .. " >/dev/null 2>&1 &")
    return v
end

function M.modules()
    local out = U.shell_once("sudo -n /usr/bin/dmidecode -t memory 2>/dev/null")
    if not out or #out < 50 then
        out = U.shell_once("sudo -n /usr/sbin/dmidecode -t memory 2>/dev/null")
    end
    if not out or #out < 50 then return nil, #(out or "") end

    local modules = {}
    for block in out:gmatch("Memory Device\n(.-)\n\n") do
        local size = block:match("Size:%s*([^\n]+)")
        if size and size ~= "No Module Installed"
           and not size:match("^%s*0") and not size:match("Unknown") then
            table.insert(modules, {
                size  = size:gsub("^%s+", ""):gsub("%s+$", ""),
                type  = (block:match("Type:%s*([^\n]+)") or "?"):gsub("^%s+", ""),
                speed = (block:match("Speed:%s*([^\n]+)") or "?"):gsub("^%s+", ""),
                manuf = (block:match("Manufacturer:%s*([^\n]+)") or "?"):gsub("^%s+", ""),
                part  = (block:match("Part Number:%s*([^\n]+)") or "?"):gsub("^%s+", ""),
            })
        end
    end
    return modules, #out
end

return M
