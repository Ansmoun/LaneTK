local M = {}

local BACKEND

local function have(cmd)
    local h = io.popen("command -v " .. cmd .. " 2>/dev/null")
    if not h then return false end
    local l = h:read("*l")
    h:close()
    return l ~= nil and l ~= ""
end

local function detect()
    if BACKEND ~= nil then return BACKEND end
    if have("pactl") then BACKEND = "pactl"
    elseif have("wpctl") then BACKEND = "wpctl"
    elseif have("amixer") then BACKEND = "amixer"
    else BACKEND = false end
    return BACKEND or nil
end

function M.available() return detect() ~= nil end

function M.sample()
    local b = detect()
    if not b then return nil end

    if b == "pactl" then
        local p = io.popen(
            "pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | head -1")
        if not p then return nil end
        local line = p:read("*l")
        p:close()
        if not line then return nil end
        local pct = line:match("(%d+)%%")
        if not pct then return nil end
        local muted = false
        local pm = io.popen(
            "pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null")
        if pm then
            local ml = pm:read("*l")
            pm:close()
            muted = ml and ml:find("yes") ~= nil
        end
        return { pct = tonumber(pct) / 100, muted = muted }

    elseif b == "wpctl" then
        local p = io.popen(
            "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null")
        if not p then return nil end
        local line = p:read("*l")
        p:close()
        if not line then return nil end
        local v = line:match("Volume:%s*([%d%.]+)")
        local muted = line:find("MUTED") ~= nil
        if not v then return nil end
        return { pct = tonumber(v), muted = muted }
    end
    return nil
end

return M
