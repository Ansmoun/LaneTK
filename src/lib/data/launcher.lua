-- data/launcher: escanea y parsea .desktop. Busqueda por relevancia
-- con historial.

local U = require("lib.helpers.util")

local M = {}

local APP_DIRS = {
    "/usr/share/applications",
    "/usr/local/share/applications",
    (os.getenv("HOME") or "") .. "/.local/share/applications",
}
local HISTORY_FILE = (os.getenv("HOME") or "") .. "/.cache/lanetk-launcher-history"

local cache = nil

local function parse_desktop(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local in_entry = false
    local fields = {}
    for line in f:lines() do
        if line:match("^%[Desktop Entry%]") then
            in_entry = true
        elseif line:match("^%[") then
            in_entry = false
        elseif in_entry then
            local k, v = line:match("^([%w%-]+)%s*=%s*(.*)$")
            if k and v and not fields[k] then fields[k] = v end
        end
    end
    f:close()

    if fields["NoDisplay"] == "true" then return nil end
    if fields["Hidden"] == "true" then return nil end
    if not fields["Name"] then return nil end
    if not fields["Exec"] then return nil end

    local exec = fields["Exec"]
        :gsub("%%[uUfFdDnNickvm]", "")
        :gsub("%s+$", "")

    return {
        name    = fields["Name"],
        exec    = exec,
        icon    = fields["Icon"] or "",
        comment = fields["Comment"] or "",
        path    = path,
        kind    = "app",
    }
end

function M.scan()
    local entries = {}
    local by_name = {}
    for _, dir in ipairs(APP_DIRS) do
        local p = io.popen("ls -1 " .. dir .. "/*.desktop 2>/dev/null")
        if p then
            for file in p:lines() do
                if file ~= "" then
                    local e = parse_desktop(file)
                    if e then
                        local key = e.name:lower()
                        if not by_name[key] then
                            by_name[key] = e
                            entries[#entries + 1] = e
                        end
                    end
                end
            end
            p:close()
        end
    end
    table.sort(entries, function(a, b) return a.name:lower() < b.name:lower() end)
    cache = { entries = entries, by_name = by_name }
    return #entries
end

local function ensure_cache()
    if not cache then M.scan() end
    return cache
end

local function load_history()
    local f = io.open(HISTORY_FILE, "r")
    if not f then return {} end
    local h = {}
    for line in f:lines() do
        local k, n = line:match("^(.-)\t(%d+)$")
        if k then h[k] = tonumber(n) or 1 end
    end
    f:close()
    return h
end

local function save_history(h)
    local out = {}
    for k, n in pairs(h) do
        out[#out + 1] = k .. "\t" .. tostring(n)
    end
    U.write_file(HISTORY_FILE, table.concat(out, "\n"))
end

function M.record_usage(entry)
    if not entry then return end
    local key = entry.name:lower()
    local h = load_history()
    h[key] = (h[key] or 0) + 1
    save_history(h)
end

function M.history_top(n)
    n = n or 8
    local h = load_history()
    local c = ensure_cache()
    local out = {}
    for key, count in pairs(h) do
        local e = c.by_name[key]
        if e then out[#out + 1] = { entry = e, count = count } end
    end
    table.sort(out, function(a, b) return a.count > b.count end)
    local ret = {}
    for i = 1, math.min(n, #out) do
        ret[#ret + 1] = out[i].entry
    end
    return ret
end

local function score_match(name_lower, query_lower, hist_count)
    local s = 0
    if name_lower:sub(1, #query_lower) == query_lower then
        s = 100
    elseif name_lower:find(query_lower, 1, true) then
        s = 60
    else
        local qi = 1
        for i = 1, #name_lower do
            if qi > #query_lower then break end
            if name_lower:sub(i, i) == query_lower:sub(qi, qi) then
                qi = qi + 1
            end
        end
        if qi > #query_lower then s = 20 else return nil end
    end
    if hist_count and hist_count > 0 then
        s = s + math.min(hist_count, 20)
    end
    return s
end

function M.search(query)
    query = query or ""

    if query:sub(1, 1) == ">" then
        local cmd = query:sub(2):gsub("^%s+", "")
        if cmd == "" then return {} end
        return { {
            name = cmd, exec = cmd, icon = "",
            comment = "Ejecutar: " .. cmd,
            kind = "command",
        } }
    end

    if query == "" then
        -- Sin query: primero el top del historial, y detras todas
        -- las apps ordenadas por nombre.
        local c = ensure_cache()
        local seen = {}
        local out = {}
        for _, e in ipairs(M.history_top(20)) do
            out[#out + 1] = e
            seen[e.name:lower()] = true
        end
        for _, e in ipairs(c.entries) do
            if not seen[e.name:lower()] then
                out[#out + 1] = e
            end
        end
        return out
    end

    local c = ensure_cache()
    local q = query:lower()
    local hist = load_history()

    local scored = {}
    for _, e in ipairs(c.entries) do
        local nl = e.name:lower()
        local s = score_match(nl, q, hist[nl])
        if s then scored[#scored + 1] = { entry = e, score = s } end
    end
    table.sort(scored, function(a, b) return a.score > b.score end)

    local out = {}
    for i = 1, math.min(#scored, 100) do
        out[#out + 1] = scored[i].entry
    end
    return out
end

function M.execute(entry)
    if not entry then return end
    M.record_usage(entry)
    os.execute(string.format("(%s &)", entry.exec))
end

-- Indice de iconos filtrado.
local IMG_EXTS = {
    png = true, svg = true, xpm = true, jpg = true, jpeg = true,
    bmp = true, ico = true, webp = true, gif = true, tiff = true,
}

local function strip_img_ext(s)
    local ext = s:match("%.([%w]+)$")
    if ext and IMG_EXTS[ext:lower()] then
        return s:gsub("%.[%w]+$", "")
    end
    return s
end

local icon_index = nil
local CACHE_FILE = (os.getenv("HOME") or "") .. "/.cache/lanetk-icon-index.tsv"

local function collect_needed_icons()
    local c = ensure_cache()
    local set = {}
    for _, e in ipairs(c.entries) do
        if e.icon and e.icon ~= "" then
            local key = (e.icon:match("([^/]+)$") or e.icon)
            key = strip_img_ext(key):lower()
            if key ~= "" then set[key] = true end
        end
    end
    return set
end

local function build_icon_index(needed)
    local full = {}
    local home = os.getenv("HOME") or ""
    local cmd = "find /usr/share/icons /usr/share/pixmaps " ..
                home .. "/.local/share/icons " ..
                "-type f \\( -iname '*.png' -o -iname '*.svg' -o -iname '*.xpm' \\) " ..
                "2>/dev/null"
    local p = io.popen(cmd)
    if not p then return full end
    for line in p:lines() do
        if line ~= "" then
            local base = line:match("([^/]+)$")
            if base then
                local name = strip_img_ext(base):lower()
                if name ~= "" and needed[name] then
                    local existing = full[name]
                    if not existing then
                        full[name] = line
                    else
                        local ext_new = (line:match("%.([%w]+)$") or ""):lower()
                        local ext_old = (existing:match("%.([%w]+)$") or ""):lower()
                        if ext_new == "svg" and ext_old ~= "svg" then
                            full[name] = line
                        end
                    end
                end
            end
        end
    end
    p:close()
    for name in pairs(needed) do
        if full[name] == nil then full[name] = "" end
    end
    return full
end

local function load_cache()
    local idx = {}
    local f = io.open(CACHE_FILE, "r")
    if not f then return nil end
    for line in f:lines() do
        local k, v = line:match("^(.-)\t(.*)$")
        if k and k ~= "" then idx[k] = v or "" end
    end
    f:close()
    if next(idx) == nil then return nil end
    return idx
end

local function save_cache(idx)
    local out = {}
    for k, v in pairs(idx) do
        out[#out + 1] = k .. "\t" .. (v or "")
    end
    local dir = CACHE_FILE:match("^(.+)/[^/]+$")
    if dir then os.execute("mkdir -p " .. dir) end
    local f = io.open(CACHE_FILE, "w")
    if f then
        f:write(table.concat(out, "\n"))
        f:close()
    end
end

local function get_icon_index()
    if icon_index then return icon_index end
    local needed = collect_needed_icons()

    local cached = load_cache()
    if cached then
        local covers = true
        for name in pairs(needed) do
            if cached[name] == nil then covers = false; break end
        end
        if covers then
            icon_index = cached
            return icon_index
        end
    end

    icon_index = build_icon_index(needed)
    save_cache(icon_index)
    return icon_index
end

function M.find_icon(name)
    if not name or name == "" then return nil end
    if name:sub(1, 1) == "/" then
        local f = io.open(name, "r")
        if f then f:close(); return name end
        return nil
    end
    local idx = get_icon_index()
    local key = (name:match("([^/]+)$") or name)
    key = strip_img_ext(key):lower()
    local hit = idx[key]
    if hit == nil or hit == "" then return nil end
    return hit
end

return M
