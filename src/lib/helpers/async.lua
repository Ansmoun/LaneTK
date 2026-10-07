-- async_shell: ejecuta un comando shell en background sin bloquear
-- el event loop. Cuando termina, llama a un callback con el codigo
-- de salida y el stdout.
--
-- Es el equivalente de awful.spawn.easy_async_with_shell.
--
-- Uso:
--   local A = require("lib.helpers.async")
--   A.async_shell(srv, "ls -la /tmp", function(code, out)
--       print(code, out)
--   end)

local M = {}

local counter = 0

-- Lanza el comando en background. Devuelve un handle con :cancel().
function M.async_shell(srv, cmd, cb)
    counter = counter + 1
    local tag = tostring(os.time()) .. "-" .. tostring(counter)
    local base = "/tmp/lanetk-async-" .. tag
    local sh_file   = base .. ".sh"
    local out_file  = base .. ".out"
    local err_file  = base .. ".err"
    local done_file = base .. ".done"

    -- Escribir el script
    local f = io.open(sh_file, "w")
    if not f then
        cb(-1, "", "no se pudo escribir " .. sh_file)
        return
    end
    f:write("#!/bin/sh\n")
    f:write(cmd .. " > " .. out_file .. " 2> " .. err_file .. "\n")
    f:write("echo $? > " .. done_file .. "\n")
    f:write("rm -f " .. sh_file .. "\n")
    f:close()

    -- Ejecutar en background
    os.execute("chmod +x " .. sh_file .. " 2>/dev/null; " ..
               sh_file .. " >/dev/null 2>&1 &")

    -- Poller: cada 150ms comprueba si existe .done.
    -- add_timer (periodico) es lo correcto aqui: queremos
    -- reintentar indefinidamente hasta que aparezca el archivo.
    -- NO migrar a add_timeout, que solo dispararia una vez.
    local h = {}
    h.timer = srv:add_timer(150, function()
        local df = io.open(done_file, "r")
        if not df then return end
        local code = tonumber(df:read("*l")) or 0
        df:close()

        local of = io.open(out_file, "r")
        local out = of and of:read("*a") or ""
        if of then of:close() end

        local ef = io.open(err_file, "r")
        local err = ef and ef:read("*a") or ""
        if ef then ef:close() end

        os.remove(out_file)
        os.remove(err_file)
        os.remove(done_file)

        if h.timer then h.timer:cancel(); h.timer = nil end

        local ok, e = pcall(cb, code, out, err)
        if not ok then
            io.stderr:write("async_shell callback error: " .. tostring(e) .. "\n")
        end
    end)

    h.cancel = function()
        if h.timer then h.timer:cancel(); h.timer = nil end
        os.remove(sh_file)
        os.remove(out_file)
        os.remove(err_file)
        os.remove(done_file)
    end

    return h
end

return M
