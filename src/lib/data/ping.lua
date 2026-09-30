local U = require("lib.helpers.util")

local M = {}
local HOSTS_FILE    = os.getenv("HOME") .. "/.config/awesome/ping-hosts.conf"
local DEFAULT_HOSTS = { "1.1.1.1", "8.8.8.8", "google.com" }

function M.hosts()
    local content = U.read_file(HOSTS_FILE)
    if not content then
        return { list = { DEFAULT_HOSTS[1], DEFAULT_HOSTS[2], DEFAULT_HOSTS[3] },
                 active = DEFAULT_HOSTS[1] }
    end
    local list, active = {}, nil
    for line in content:gmatch("[^\n]+") do
        line = U.trim(line)
        if #line > 0 then
            if line:sub(1, 1) == "*" then
                active = line:sub(2)
                table.insert(list, active)
            else
                table.insert(list, line)
            end
        end
    end
    if #list == 0 then
        return { list = { DEFAULT_HOSTS[1], DEFAULT_HOSTS[2], DEFAULT_HOSTS[3] },
                 active = DEFAULT_HOSTS[1] }
    end
    if not active then active = list[1] end
    return { list = list, active = active }
end

function M.save(list, active)
    local out = {}
    for _, h in ipairs(list) do
        table.insert(out, (h == active) and ("*" .. h) or h)
    end
    U.write_file(HOSTS_FILE, table.concat(out, "\n") .. "\n")
end

function M.add(state, host)
    host = U.trim(host or "")
    if host == "" then return false end
    for _, h in ipairs(state.list) do
        if h == host then return false end
    end
    table.insert(state.list, host)
    state.active = host
    M.save(state.list, state.active)
    return true
end

function M.set_active(state, host)
    for _, h in ipairs(state.list) do
        if h == host then
            state.active = host
            M.save(state.list, state.active)
            return true
        end
    end
    return false
end

-- ping async: escribe resultado a un archivo temporal con timestamp.
-- El consumidor lo lee al siguiente tick.
local PING_OUT = "/tmp/lanetk-ping.txt"

function M.ping_async(host)
    os.execute(string.format(
        "(LC_ALL=C ping -c1 -W1 %s 2>/dev/null " ..
        "| grep -o 'time=[0-9.]*' | cut -d= -f2 > %s.tmp; " ..
        "echo $(date +%%s) >> %s.tmp; mv %s.tmp %s) &",
        host, PING_OUT, PING_OUT, PING_OUT, PING_OUT))
end

-- Lee el resultado del ultimo ping. Devuelve { ms = num|nil, age = seg }.
function M.ping_read(max_age)
    max_age = max_age or 5
    local content = U.read_file(PING_OUT)
    if not content then return nil end

    local lines = {}
    for l in content:gmatch("[^\n]+") do lines[#lines+1] = l end
    if #lines < 2 then return nil end

    local ms = tonumber(lines[1])
    local ts = tonumber(lines[#lines])
    if not ts then return nil end

    local age = os.time() - ts
    if age > max_age then return nil end
    return { ms = ms, age = age }
end

return M
