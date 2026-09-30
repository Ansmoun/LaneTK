-- data/inicio: samplers estáticos del tab Inicio.

local U = require("lib.helpers.util")

local M = {}

function M.user()
    return os.getenv("USER") or "user"
end

function M.host()
    return U.trim(U.shell_once("hostname"))
end

function M.distro()
    local content = U.read_file("/etc/os-release") or ""
    return content:match('PRETTY_NAME="([^"]+)"') or "?"
end

function M.kernel()
    return U.trim(U.shell_once("uname -r"))
end

function M.uptime_secs()
    local content = U.read_file("/proc/uptime") or "0"
    return tonumber(content:match("^([%d%.]+)")) or 0
end

function M.ip_local()
    local ip = U.trim(U.shell_once(
        "ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}'"))
    return ip ~= "" and ip or "sin red"
end

function M.screens()
    local out = U.shell_once("xrandr --query 2>/dev/null")
    local n = 0
    for _ in out:gmatch(" connected") do n = n + 1 end
    return n
end

function M.shell_name()
    local sh = os.getenv("SHELL") or "?"
    return sh:match("[^/]+$") or "?"
end

-- Devuelve true si el archivo empieza con cabecera PNG.
local function is_png(path)
    local f = io.open(path, "rb")
    if not f then return false end
    local first = f:read(4)
    f:close()
    return first == "\x89PNG"
end

-- Cache: convierte JPEG/BMP/lo-que-sea a PNG en ~/.cache/lanetk/avatar.png.
-- Reutiliza el PNG cacheado si es mas reciente que el original.
local function convert_to_png(src, username)
    local HOME = os.getenv("HOME") or ""
    local cache_dir = HOME .. "/.cache/lanetk"
    os.execute("mkdir -p " .. cache_dir .. " 2>/dev/null")
    -- Cache por usuario. Si no se pasa username, un nombre generico.
    -- Sin esto, cuando el greeter muestra varios usuarios, todos
    -- comparten el mismo avatar.png y se pisan.
    local cache = cache_dir .. "/avatar-"
        .. (username or "default") .. ".png"

    local sf = io.open(src, "rb")
    if not sf then return nil end
    sf:close()

    local f1 = io.open(src, "rb")
    local f2 = io.open(cache, "rb")
    if f1 and f2 then
        local ok = os.execute(string.format(
            "test -f '%s' -a '%s' -nt '%s'", cache, cache, src))
        f1:close(); f2:close()
        if ok == true or ok == 0 then
            return cache
        end
    end

    local cmds = {
        string.format("ffmpeg -y -i '%s' '%s' >/dev/null 2>&1", src, cache),
        string.format("magick '%s' '%s' 2>/dev/null", src, cache),
        string.format("convert '%s' '%s' 2>/dev/null", src, cache),
    }
    for _, cmd in ipairs(cmds) do
        os.execute(cmd)
        if is_png(cache) then return cache end
    end
    return nil
end

-- Busca avatar y garantiza que el archivo devuelto sea PNG.
-- find_avatar(username?)
-- Busca el avatar del usuario dado. Si se omite, usa $USER.
--
-- IMPORTANTE: cuando el proceso corre como un usuario distinto al
-- que se va a autenticar (por ejemplo el greeter corriendo como
-- "greeter" pero mostrando el avatar de "ansmoun"), hay que pasar
-- el username explicito. $USER del proceso no sirve.
function M.find_avatar(username)
    local HOME = os.getenv("HOME") or ""
    local user = username or M.user()
    local paths = {
        HOME .. "/.face",
        HOME .. "/.face.icon",
        "/var/lib/AccountsService/icons/" .. user,
    }
    for _, p in ipairs(paths) do
        local f = io.open(p, "rb")
        if f then
            f:close()
            if is_png(p) then
                return p
            else
                local converted = convert_to_png(p, user)
                if converted then return converted end
            end
        end
    end
    return nil
end

return M
