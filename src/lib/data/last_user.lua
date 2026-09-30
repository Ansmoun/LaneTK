local M = {}
M.FILE = "/var/lib/lefty/last-user"

function M.get()
    local f = io.open(M.FILE, "r")
    if not f then return nil end
    local name = f:read("*l")
    f:close()
    if not name then return nil end
    name = name:gsub("%s+", "")
    if name == "" then return nil end
    return name
end

function M.set(name)
    if type(name) ~= "string" or name == "" then return false end
    local f = io.open(M.FILE, "w")
    if not f then return false end
    f:write(name .. "\n")
    f:close()
    return true
end

return M
