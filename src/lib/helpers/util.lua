-- Utilidades sin dependencias. Testeables con luajit -e fuera del WM.

local M = {}

-- Recorta espacios en blanco al inicio y final. Si no es string,
-- devuelve tal cual.
function M.trim(s)
    if type(s) ~= "string" then return s end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Lee un archivo completo. nil si no existe o no se puede abrir.
function M.read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

-- Escribe un archivo (sobrescribe). true/false.
function M.write_file(path, content)
    local f = io.open(path, "w")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

-- Ejecuta un comando shell y devuelve stdout como string.
-- "" si falla. BLOQUEA el event loop mientras corre: para
-- comandos rapidos (<50ms) es aceptable. Para dmidecode,
-- smartctl y similares usar Servers:add_timer + popen en
-- hilo aparte, o Exec.run cuando esté disponible.
function M.shell_once(cmd)
    local f = io.popen(cmd, "r")
    if not f then return "" end
    local out = f:read("*a")
    f:close()
    return out or ""
end

-- Lista archivos con la extension dada en un directorio. Devuelve
-- solo el nombre base (sin extension), sin "README", ordenado
-- alfabeticamente.
function M.list_files(dir, ext)
    ext = ext or "lua"
    local handle = io.popen(
        string.format("ls -1 '%s' 2>/dev/null", dir:gsub("'", "'\\''"))
    )
    if not handle then return {} end
    local result = {}
    for line in handle:lines() do
        local name = line:match("^(.*)%.%w+$")
        local e = line:match("%.(%w+)$")
        if name and e == ext and name ~= "README" then
            result[#result + 1] = name
        end
    end
    handle:close()
    table.sort(result)
    return result
end

-- Busca `key = "valor"` en un archivo Lua plano y devuelve el valor.
-- No evalua el Lua, solo hace match de texto.
function M.read_conf_key(file, key)
    local content = M.read_file(file)
    if not content then return nil end
    local pattern = key .. '%s*=%s*"([^"]*)"'
    return content:match(pattern)
end

-- Reescribe el valor de la clave (debe ser string). Si la clave
-- no existe, devuelve false sin tocar el archivo.
function M.write_conf_key(file, key, value)
    local content = M.read_file(file)
    if not content then return false end
    local pattern = "(" .. key .. '%s*=%s*")([^"]*)(")'
    local new_content, n = content:gsub(
        pattern,
        "%1" .. value .. "%3"
    )
    if n == 0 then return false end
    return M.write_file(file, new_content)
end

-- Devuelve $HOME (o "/" si por algun motivo no existe).
function M.home()
    return os.getenv("HOME") or "/"
end

return M
