-- thumbs.lua: genera y cachea thumbnails de imagenes.
-- Cualquier formato soportado por ffmpeg -> PNG de tamaño fijo,
-- guardado en ~/.cache/lane/thumbs/.

local M = {}

local CACHE_DIR = (os.getenv("HOME") or "/tmp") .. "/.cache/lane/thumbs"
local SIZE = 128

local function hash_path(path)
    -- FNV-1a de 32 bits. Evita nombres de archivo raros.
    local h = 0x811c9dc5
    for i = 1, #path do
        h = h ~ path:byte(i)
        h = (h * 0x01000193) % 0x100000000
    end
    return string.format("%08x", h)
end

local function exists(p)
    local f = io.open(p, "r")
    if f then f:close() return true end
    return false
end

local function shq(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- Devuelve el path del PNG cacheado (aunque no exista).
function M.path_for(src)
    return CACHE_DIR .. "/" .. hash_path(src) .. ".png"
end

-- Asegura que existe el thumbnail y devuelve su path, o nil.
function M.ensure(src, size)
    size = size or SIZE
    os.execute("mkdir -p " .. shq(CACHE_DIR))
    local dst = CACHE_DIR .. "/" .. hash_path(src) .. "_" .. size .. ".png"
    if exists(dst) then return dst end
    -- Sin pad: el thumbnail queda del tamaño del aspect ratio
    -- original con el lado mas largo = size. Si lo paddeabamos,
    -- el preview del wallpaper en la app se veia con barras negras
    -- heredadas del thumbnail.
    local vf = string.format(
        "scale=%d:%d:flags=lanczos:force_original_aspect_ratio=decrease",
        size, size)
    local cmd = string.format(
        "ffmpeg -nostdin -v error -i %s -vf %s -frames:v 1 -y %s 2>/dev/null",
        shq(src), shq(vf), shq(dst))
    os.execute(cmd)
    if exists(dst) then return dst end
    return nil
end

function M.clear()
    os.execute("rm -rf " .. shq(CACHE_DIR))
end

function M.size() return SIZE end

return M
