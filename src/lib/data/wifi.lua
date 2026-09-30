local U = require("lib.helpers.util")

local M = {}

function M.iface()
    return U.trim(U.shell_once(
        "ip route show default 2>/dev/null | awk '{print $5; exit}'"))
end

function M.wifi_iface()
    local iface = U.trim(U.shell_once(
        "iw dev 2>/dev/null | awk '/Interface/ {print $2; exit}'"))
    if iface == "" then
        iface = U.trim(U.shell_once(
            "ls /sys/class/net 2>/dev/null | grep -E '^(wl|wlan)' | head -n1"))
    end
    return iface
end

function M.ssid()
    return U.trim(U.shell_once("iwgetid -r 2>/dev/null"))
end

function M.signal_bars(sig)
    local n = math.floor(sig / 20 + 0.5)
    if n > 5 then n = 5 end
    if n < 0 then n = 0 end
    return string.rep("▮", n) .. string.rep("▯", 5 - n) ..
           string.format("  %3d%%", math.floor(sig))
end

function M.find_saved(ssid)
    local out = U.shell_once(
        "nmcli -t -f NAME,TYPE connection show 2>/dev/null")
    for line in out:gmatch("[^\n]+") do
        local name, kind = line:match("^(.+):([^:]+)$")
        if name == ssid and kind == "802-11-wireless" then
            return name
        end
    end
    return nil
end

return M
