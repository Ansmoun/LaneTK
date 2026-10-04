local M = {}

local BASE = "/sys/class/backlight"
local cached

local function find_base()
    local h = io.popen("ls -1 " .. BASE .. " 2>/dev/null | head -n1")
    if not h then return nil end
    local name = h:read("*l")
    h:close()
    if not name or name == "" then return nil end
    return BASE .. "/" .. name
end

local function base()
    if cached == nil then cached = find_base() or false end
    return cached or nil
end

local function num(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local v = f:read("*n")
    f:close()
    return v
end

function M.available() return base() ~= nil end

function M.sample()
    local b = base()
    if not b then return nil end
    local cur = num(b .. "/brightness")
    local max = num(b .. "/max_brightness")
    if not cur or not max or max == 0 then return nil end
    return { pct = cur / max, cur = cur, max = max }
end

return M
