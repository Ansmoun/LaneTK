-- data/net: registro de trafico + info de interfaz.

local U = require("lib.helpers.util")

local M = {}
local TRAFFIC_DIR = os.getenv("HOME") .. "/.local/share/awesome/traffic"

local function parse_tsv_line(line)
    local ts, iface, ssid, rx, tx = line:match("^([^|]+)|([^|]+)|([^|]+)|(%d+)|(%d+)$")
    if not ts then return nil end
    return { ts = ts, iface = iface, ssid = ssid,
             rx = tonumber(rx) or 0, tx = tonumber(tx) or 0 }
end

local function sum_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local total_rx, total_tx, by_net = 0, 0, {}
    for line in f:lines() do
        local s = parse_tsv_line(line)
        if s then
            total_rx = total_rx + s.rx
            total_tx = total_tx + s.tx
            local k = s.iface
            if not by_net[k] then by_net[k] = { rx = 0, tx = 0 } end
            by_net[k].rx = by_net[k].rx + s.rx
            by_net[k].tx = by_net[k].tx + s.tx
        end
    end
    f:close()
    return { rx = total_rx, tx = total_tx, by_net = by_net }
end

local function last_n_dates(n)
    local out = {}
    local now = os.time()
    for i = 0, n - 1 do
        out[i + 1] = os.date("%Y-%m-%d", now - i * 86400)
    end
    return out
end

local function sum_dates(dates)
    local total = { rx = 0, tx = 0, by_net = {} }
    for _, d in ipairs(dates) do
        local s = sum_file(TRAFFIC_DIR .. "/" .. d .. ".tsv")
        if s then
            total.rx = total.rx + s.rx
            total.tx = total.tx + s.tx
            for k, v in pairs(s.by_net) do
                if not total.by_net[k] then
                    total.by_net[k] = { rx = 0, tx = 0 }
                end
                total.by_net[k].rx = total.by_net[k].rx + v.rx
                total.by_net[k].tx = total.by_net[k].tx + v.tx
            end
        end
    end
    return total
end

local cache = { data = nil, time = 0 }
local CACHE_TTL = 30

function M.traffic_summary()
    local now = os.time()
    if cache.data and (now - cache.time) < CACHE_TTL then
        return cache.data
    end
    cache.data = {
        hoy    = sum_dates(last_n_dates(1)),
        semana = sum_dates(last_n_dates(7)),
        mes    = sum_dates(last_n_dates(30)),
    }
    cache.time = now
    return cache.data
end

-- Info de interfaz (sincrono, ~10ms)
function M.iface_info(iface)
    local res = { iface = iface, tipo = "-", ip = "-", gw = "-", ssid = "-" }
    if not iface or iface == "" then return res end

    if iface:match("^wl") or iface:match("^wlan") then
        res.tipo = "WiFi"
    elseif iface:match("^en") or iface:match("^eth") then
        res.tipo = "Ethernet"
    else
        res.tipo = "Otro"
    end

    local ip = U.trim(U.shell_once(
        "ip -4 addr show " .. iface .. " 2>/dev/null | " ..
        "awk '/inet / {print $2; exit}'"))
    res.ip = ip:gsub("/.*$", "")

    local gw = U.trim(U.shell_once(
        "ip route show default 2>/dev/null | awk '{print $3; exit}'"))
    res.gw = gw

    local ssid = U.trim(U.shell_once("iwgetid -r 2>/dev/null"))
    res.ssid = ssid

    return res
end

-- Bytes de la interfaz (sincrono, lee /sys)
function M.iface_bytes(iface)
    if not iface or iface == "" then return nil end
    local rx = tonumber(U.trim(U.read_file(
        "/sys/class/net/" .. iface .. "/statistics/rx_bytes") or "0")) or 0
    local tx = tonumber(U.trim(U.read_file(
        "/sys/class/net/" .. iface .. "/statistics/tx_bytes") or "0")) or 0
    return { rx = rx, tx = tx }
end

return M
