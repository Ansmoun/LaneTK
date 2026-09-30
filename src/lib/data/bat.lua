-- data/bat: lectura de /sys/class/power_supply/BAT*/.

local U = require("lib.helpers.util")

local M = {}

local BAT_BASE = nil
local function find_base()
    if BAT_BASE ~= nil then return BAT_BASE end
    local p = io.popen("ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1")
    if not p then BAT_BASE = ""; return "" end
    local line = p:read("*l") or ""
    p:close()
    BAT_BASE = line:gsub("%s+", "")
    return BAT_BASE
end

local function read_str(path)
    local v = U.read_file(path)
    if not v then return nil end
    return (v:gsub("%s+", ""))
end

local function read_num(path)
    local v = read_str(path)
    if not v or v == "" then return nil end
    return tonumber(v)
end

function M.available()
    local base = find_base()
    return base ~= nil and base ~= ""
end

function M.sample()
    local base = find_base()
    if base == "" then return nil end

    local st = { base = base }

    st.status          = read_str(base .. "/status") or "N/A"
    st.capacity        = read_num(base .. "/capacity") or 0
    st.capacity_level  = read_str(base .. "/capacity_level") or "-"
    st.technology      = read_str(base .. "/technology") or "?"
    st.model           = read_str(base .. "/model_name") or "?"
    st.vendor          = read_str(base .. "/manufacturer") or "?"
    st.serial          = read_str(base .. "/serial_number") or "?"
    st.cycle_count     = read_num(base .. "/cycle_count")

    st.charge_now        = read_num(base .. "/charge_now") or 0
    st.charge_full       = read_num(base .. "/charge_full") or 0
    st.charge_full_design= read_num(base .. "/charge_full_design") or 0
    st.current_now       = read_num(base .. "/current_now") or 0
    st.voltage_now       = read_num(base .. "/voltage_now") or 0
    st.voltage_min_design= read_num(base .. "/voltage_min_design") or 0

    local pw = read_num(base .. "/power")
    if pw then
        st.power_w = pw / 1000000
    else
        st.power_w = (st.current_now * st.voltage_now) / 1e12
    end

    st.charge_full_pct = 0
    if st.charge_full_design > 0 then
        st.charge_full_pct = math.floor(
            st.charge_full / st.charge_full_design * 100 + 0.5)
    end

    st.time_hours = 0
    if st.current_now > 0 then
        if st.status == "Discharging" then
            st.time_hours = st.charge_now / st.current_now
        elseif st.status == "Charging" then
            st.time_hours = math.max(0,
                (st.charge_full - st.charge_now) / st.current_now)
        end
    end

    return st
end

return M
