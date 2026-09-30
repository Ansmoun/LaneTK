-- data/dispositivos: descubre dispositivos en la red local.
-- Síncrono con io.popen. Sin arp-scan por defecto (es lento).
-- El tab llama scan(false, cb) que solo lee `ip neigh`.

local U = require("lib.helpers.util")

local M = {}

local SEEN_FILE = os.getenv("HOME") .. "/.cache/awesome-net-seen"

local vendor_cache = {}
local hostname_cache = {}
local seen_cache = {}
local seen_loaded = false

local OUI_FALLBACK = {
    ["00:50:56"] = "VMware", ["00:0c:29"] = "VMware",
    ["00:1a:2b"] = "Intel", ["00:1b:21"] = "Intel",
    ["3c:58:c2"] = "Intel", ["44:85:00"] = "Intel",
    ["b8:27:eb"] = "Raspberry Pi", ["dc:a6:32"] = "Raspberry Pi",
    ["b0:be:76"] = "TP-Link", ["ec:08:6b"] = "TP-Link",
    ["9c:53:22"] = "Xiaomi", ["f0:b4:29"] = "Xiaomi",
    ["dc:44:6d"] = "Huawei", ["5c:7d:5e"] = "Huawei",
    ["b8:3e:59"] = "Samsung", ["cc:07:ab"] = "Samsung",
    ["f4:0f:24"] = "Apple", ["b8:41:a4"] = "Apple",
}

function M.local_macs()
    local macs = {}
    local p = io.popen("ls /sys/class/net 2>/dev/null")
    if p then
        for iface in p:lines() do
            if iface ~= "lo" then
                local f = io.open("/sys/class/net/" .. iface .. "/address", "r")
                if f then
                    local mac = f:read("*l"); f:close()
                    if mac then macs[mac:lower()] = iface end
                end
            end
        end
        p:close()
    end
    return macs
end

local function lookup_vendor(mac)
    local key = mac:lower():sub(1, 8)
    if vendor_cache[key] then return vendor_cache[key] end
    local v = OUI_FALLBACK[key]
    if not v then
        -- MAC localmente administrada: bit 0x02 del primer octeto.
        local first = tonumber(mac:sub(1, 2), 16) or 0
        v = (first % 4 >= 2) and "(local)" or "(desconocido)"
    end
    vendor_cache[key] = v
    return v
end

local function lookup_hostname(mac, ip)
    if hostname_cache[mac] then return hostname_cache[mac] end
    local name = U.trim(U.shell_once(string.format(
        "timeout 1 avahi-resolve -4 -a %s 2>/dev/null | awk '{print $2}'", ip)))
    if name == "" then
        name = U.trim(U.shell_once(string.format(
            "timeout 1 getent hosts %s 2>/dev/null | awk '{print $2}'", ip)))
    end
    if name == "" or name == ip then name = "—" end
    hostname_cache[mac] = name
    return name
end

local function load_seen()
    if seen_loaded then return end
    seen_loaded = true
    local content = U.read_file(SEEN_FILE)
    if not content then return end
    for line in content:gmatch("[^\n]+") do
        local mac, ts = line:match("^(%S+)%s+(%d+)$")
        if mac and ts then seen_cache[mac] = tonumber(ts) end
    end
end

local function fmt_seen(mac)
    local t = seen_cache[mac]
    if not t then return "—" end
    local d = os.time() - t
    if d < 60    then return "ahora" end
    if d < 3600  then return math.floor(d / 60) .. "m" end
    if d < 86400 then return math.floor(d / 3600) .. "h" end
    return math.floor(d / 86400) .. "d"
end

local function save_seen()
    local out = {}
    for mac, ts in pairs(seen_cache) do
        out[#out + 1] = mac .. " " .. tostring(ts)
    end
    U.write_file(SEEN_FILE, table.concat(out, "\n") .. "\n")
end

local function ipkey(ip)
    local a, b, c, d = ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
    if not a then return 0 end
    return tonumber(a)*16777216 + tonumber(b)*65536
         + tonumber(c)*256 + tonumber(d)
end

-- cb(entries) donde entries = { { ip, mac, iface, vendor_display,
--                                 hostname, seen_str, is_local, prio } }
function M.scan(use_arpscan, cb)
    load_seen()
    local macs = M.local_macs()

    local out = U.shell_once("ip neigh show 2>/dev/null")
    local list = {}

    for line in out:gmatch("[^\n]+") do
        local ip, dev, mac, state =
            line:match("^(%S+)%s+dev%s+(%S+)%s+lladdr%s+(%S+)%s+(%S+)")
        if ip and mac then
            mac = mac:lower()
            list[#list + 1] = {
                ip = ip, mac = mac, iface = dev, state = state,
            }
        end
    end

    local now = os.time()
    for _, e in ipairs(list) do
        e.is_local = (macs[e.mac] ~= nil)
        seen_cache[e.mac] = now
        e.prio = e.is_local and 1
                 or (e.state == "REACHABLE" and 2)
                 or (e.state == "STALE" and 3)
                 or 4
        e.vendor_display = lookup_vendor(e.mac)
        e.hostname = lookup_hostname(e.mac, e.ip)
        e.seen_str = fmt_seen(e.mac)
    end

    table.sort(list, function(a, b)
        if a.prio ~= b.prio then return a.prio < b.prio end
        return ipkey(a.ip) < ipkey(b.ip)
    end)

    save_seen()
    cb(list)
end

return M
