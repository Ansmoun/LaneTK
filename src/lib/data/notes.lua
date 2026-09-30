-- data/notes: gestión de notas en ~/.config/awesome/notes/*.md
-- Formato: primera línea "[ ] Título" o "[x] Título", resto cuerpo.

local U = require("lib.helpers.util")

local M = {}

M.DIR    = os.getenv("HOME") .. "/.config/awesome/notes"
M.LEGACY = os.getenv("HOME") .. "/.config/awesome/notes.txt"

local function ensure_dir()
    os.execute("mkdir -p " .. M.DIR .. " 2>/dev/null")
end

local function slugify(title)
    local s = tostring(title or ""):lower()
    s = s:gsub("[áàäâã]", "a"):gsub("[éèëê]", "e"):gsub("[íìïî]", "i")
         :gsub("[óòöôõ]", "o"):gsub("[úùüû]", "u"):gsub("ñ", "n")
    s = s:gsub("[^%w%s%-_]", "")
    s = s:gsub("%s+", "-"):gsub("%-+", "-")
    s = s:gsub("^%-+", ""):gsub("%-+$", "")
    if s == "" then s = "nota" end
    if #s > 60 then s = s:sub(1, 60) end
    return s
end

local function unique_path(title)
    local base = slugify(title)
    local path = M.DIR .. "/" .. base .. ".md"
    local i = 2
    while io.open(path, "r") do
        path = M.DIR .. "/" .. base .. "-" .. i .. ".md"
        i = i + 1
    end
    return path
end

local function parse_content(content)
    content = content or ""
    local first_line, rest = content:match("^([^\n]*)\n?(.*)$")
    first_line = first_line or ""
    local mark, title = first_line:match("^%[([ xX])%]%s*(.*)$")
    if mark then
        return {
            done  = (mark:lower() == "x"),
            title = title ~= "" and title or "(sin título)",
            body  = rest or "",
        }
    end
    return {
        done  = false,
        title = first_line ~= "" and first_line or "(sin título)",
        body  = rest or "",
    }
end

local function format_content(done, title, body)
    local mark = done and "x" or " "
    local out = "[" .. mark .. "] " .. title .. "\n"
    if body and body ~= "" then
        out = out .. body
        if out:sub(-1) ~= "\n" then out = out .. "\n" end
    end
    return out
end

local function read_note(path)
    local content = U.read_file(path)
    if not content then return nil end
    local p = parse_content(content)
    p.path = path
    return p
end

local function write_note(path, done, title, body)
    U.write_file(path, format_content(done, title, body))
end

function M.list()
    ensure_dir()
    local files = {}
    local p = io.popen("ls -t -1 " .. M.DIR .. "/*.md 2>/dev/null")
    if p then
        for line in p:lines() do
            if line ~= "" then table.insert(files, line) end
        end
        p:close()
    end

    local pending, done_list = {}, {}
    for _, path in ipairs(files) do
        local n = read_note(path)
        if n then
            local preview = U.trim((n.body:gsub("\n.*$", "")))
            if #preview > 90 then preview = preview:sub(1, 88) .. "…" end
            local note = {
                path = path, title = n.title, done = n.done,
                body = n.body, preview = preview,
            }
            if n.done then done_list[#done_list + 1] = note
            else pending[#pending + 1] = note end
        end
    end

    local out = {}
    for _, n in ipairs(pending)   do out[#out + 1] = n end
    for _, n in ipairs(done_list) do out[#out + 1] = n end
    return out
end

function M.create(title)
    ensure_dir()
    title = U.trim(tostring(title or ""))
    if title == "" then title = "Nueva nota" end
    local path = unique_path(title)
    write_note(path, false, title, "")
    return path
end

function M.delete(path) os.remove(path) end

function M.toggle_done(path)
    local n = read_note(path)
    if not n then return end
    write_note(path, not n.done, n.title, n.body)
end

function M.read(path) return read_note(path) end

function M.migrate_legacy()
    local content = U.read_file(M.LEGACY)
    if not content then return false end
    ensure_dir()

    local current = nil
    local function flush()
        if current then
            local path = unique_path(current.title)
            write_note(path, current.done, current.title, current.body)
            current = nil
        end
    end

    if content:sub(-1) ~= "\n" then content = content .. "\n" end
    for line in content:gmatch("(.-)\n") do
        if not line:match("^#") then
            local mark, title = line:match("^%[([ xX])%]%s*(.+)$")
            if mark then
                flush()
                current = { done = (mark:lower() == "x"),
                            title = title, body = "" }
            elseif current then
                if line == "" then flush()
                else
                    if current.body ~= "" then
                        current.body = current.body .. "\n" .. line
                    else current.body = line end
                end
            end
        end
    end
    flush()

    os.rename(M.LEGACY, M.LEGACY .. ".migrated")
    return true
end

return M
