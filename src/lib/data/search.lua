-- data/search: portado del original de Awesome. Dos fases:
--   1) fd busca paths y los escribe a stdout.
--   2) stat enriquece cada path con tamaño/mtime/tipo.
-- Ambas fases via async_shell.

local A = require("lib.helpers.async")
local U = require("lib.helpers.util")

local M = {}

local MAX_RESULTS = 500

local FD_AVAILABLE = nil
function M.has_fd()
    if FD_AVAILABLE ~= nil then return FD_AVAILABLE end
    local p = io.popen("command -v fd 2>/dev/null")
    local line = p and p:read("*l") or ""
    if p then p:close() end
    FD_AVAILABLE = (line ~= "")
    return FD_AVAILABLE
end

-- Genera el comando fd segun filtros.
local function build_fd_cmd(query, root_path, type_key, case_sensitive, multi_root, max_depth)
    local cmd
    if M.has_fd() then
        cmd = "nice -n 19 ionice -c 3 timeout 15 " ..
              "fd --color never --max-results " .. MAX_RESULTS ..
              " --absolute-path --threads 1 --hidden " ..
              "--exclude .git --exclude .cache --exclude node_modules " ..
              "--exclude .local/share/Trash " ..
              "--exclude /proc --exclude /sys --exclude /dev"

        cmd = cmd .. (case_sensitive and " --case-sensitive" or " --ignore-case")

        if type_key == "file"  then cmd = cmd .. " --type f" end
        if type_key == "dir"   then cmd = cmd .. " --type d" end
        if type_key == "image" then
            cmd = cmd .. " --extension png --extension jpg --extension jpeg " ..
                        "--extension gif --extension webp --extension bmp --extension svg"
        end
        if type_key == "audio" then
            cmd = cmd .. " --extension mp3 --extension flac --extension ogg " ..
                        "--extension wav --extension m4a"
        end
        if type_key == "video" then
            cmd = cmd .. " --extension mp4 --extension mkv --extension avi " ..
                        "--extension webm --extension mov"
        end
        if type_key == "doc" then
            cmd = cmd .. " --extension pdf --extension txt --extension md " ..
                        "--extension odt --extension docx"
        end

        cmd = cmd .. " " .. string.format("%q", query)

        if multi_root then
            cmd = cmd .. " " .. multi_root
        else
            cmd = cmd .. " " .. string.format("%q", root_path)
        end
        if max_depth then
            cmd = cmd .. " --max-depth " .. max_depth
        end
        cmd = cmd .. " 2>/dev/null"
    else
        -- Fallback: find
        cmd = "nice -n 19 ionice -c 3 timeout 15 find " ..
              string.format("%q", root_path) ..
              " -type f -iname " .. string.format("%q", "*" .. query .. "*") ..
              " 2>/dev/null | head -n " .. MAX_RESULTS
    end
    return cmd
end

-- Lanza la busqueda completa (fd + stat) y llama a cb(items).
-- cb recibe array de { path, name, size, mtime, is_dir }.
function M.search(srv, query, root_path, type_key, case_sensitive, multi_root, max_depth, cb)
    if query == "" then
        cb({})
        return
    end

    local fd_cmd = build_fd_cmd(query, root_path, type_key,
        case_sensitive, multi_root, max_depth)

    A.async_shell(srv, fd_cmd, function(code, out)
        out = out:gsub("%s+$", "")
        if out == "" then cb({}); return end

        -- Escribir los paths a un archivo temporal (uno por linea)
        -- para no desbordar argv con paths largos.
        local list_file = "/tmp/lanetk-search-paths.txt"
        local lf = io.open(list_file, "w")
        if not lf then cb({}); return end
        for line in out:gmatch("[^\n]+") do
            lf:write(line .. "\n")
        end
        lf:close()

        -- stat -c '%n|%s|%Y|%F' con xargs -d '\n'. Los paths con
        -- espacios no rompen porque separamos por salto de linea.
        local stat_cmd = "xargs -d '\\n' -r stat -c '%n|%s|%Y|%F' < " ..
                         list_file .. " 2>/dev/null"

        A.async_shell(srv, stat_cmd, function(_, stat_out)
            os.remove(list_file)

            local items = {}
            for line in stat_out:gmatch("[^\n]+") do
                local p, sz, mt, ft = line:match("^(.-)|(%d+)|(%d+)|(.+)$")
                if p and sz and mt and ft then
                    local name = p:match("([^/]+)$") or p
                    items[#items + 1] = {
                        path = p,
                        name = name,
                        size = tonumber(sz) or 0,
                        mtime = tonumber(mt) or 0,
                        is_dir = (ft == "directory" or ft == "directorio"),
                    }
                end
            end
            cb(items)
        end)
    end)
end

return M
