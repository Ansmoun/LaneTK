local M = {}

local ALLOWED_SHELLS = {
    ["/bin/bash"]      = true, ["/usr/bin/bash"]  = true,
    ["/bin/sh"]        = true, ["/usr/bin/sh"]    = true,
    ["/bin/zsh"]       = true, ["/usr/bin/zsh"]   = true,
    ["/bin/dash"]      = true, ["/usr/bin/dash"]  = true,
    ["/bin/fish"]      = true, ["/usr/bin/fish"]  = true,
}

local DEFAULT_BLACKLIST = { greeter = true, nobody = true }

function M.list(opts)
    opts = opts or {}
    local blacklist = {}
    for k in pairs(DEFAULT_BLACKLIST) do blacklist[k] = true end
    if opts.blacklist then
        for _, name in ipairs(opts.blacklist) do blacklist[name] = true end
    end
    local users = {}
    local f = io.open("/etc/passwd", "r")
    if not f then return users end
    for line in f:lines() do
        local name, uid, gid, gecos, home, shell =
            line:match("^([^:]+):[^:]*:(%d+):(%d+):([^:]*):([^:]*):(.+)$")
        uid = tonumber(uid)
        if name and uid and uid >= 1000 and uid < 60000
           and ALLOWED_SHELLS[shell] and not blacklist[name] then
            local display = gecos and gecos:match("^([^,]*)") or ""
            if not display or display == "" then display = name end
            users[#users + 1] = {
                username = name, uid = uid, gid = gid,
                home = home, shell = shell, display = display,
            }
        end
    end
    f:close()
    table.sort(users, function(a, b)
        return a.username:lower() < b.username:lower()
    end)
    return users
end

return M
