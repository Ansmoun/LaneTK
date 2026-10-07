-- fs.lua: helpers de sistema de archivos via libc stat. Sin
-- subprocesos, sin io.open que no distingue tipos ni errores.
--
-- API publica:
--   M.stat(path)     -> { mode, size, mtime, is_dir, is_file } | nil, err
--   M.exists(path)   -> bool
--   M.is_dir(path)   -> bool
--   M.is_file(path)  -> bool
--   M.mtime(path)    -> int epoch seconds | nil
--   M.size(path)     -> int bytes | nil

local ffi  = require("bindings.cdef.libc_stat")
local libc = ffi.load("c")

local M = {}

local S_IFMT  = 0xF000
local S_IFDIR = 0x4000
local S_IFREG = 0x8000

function M.stat(path)
    if type(path) ~= "string" or path == "" then
        return nil, "path vacio"
    end
    local buf = ffi.new("struct lanetk_stat[1]")
    -- stat() acepta paths con bytes UTF-8 tal cual; el kernel no
    -- se mete con el encoding.
    local rc = libc.stat(path, buf)
    if rc ~= 0 then
        -- ffi.errno() tras una llamada C fallida
        return nil, "stat fallo (errno=" .. tostring(ffi.errno()) .. ")"
    end
    local st = buf[0]
    local fmt = bit.band(st.st_mode, S_IFMT)
    return {
        mode    = st.st_mode,
        size    = tonumber(st.st_size),
        mtime   = tonumber(st.st_mtime_sec),
        is_dir  = (fmt == S_IFDIR),
        is_file = (fmt == S_IFREG),
    }
end

function M.exists(path)
    local s = M.stat(path)
    return s ~= nil
end

function M.is_dir(path)
    local s = M.stat(path)
    return s ~= nil and s.is_dir
end

function M.is_file(path)
    local s = M.stat(path)
    return s ~= nil and s.is_file
end

function M.mtime(path)
    local s = M.stat(path)
    return s and s.mtime or nil
end

function M.size(path)
    local s = M.stat(path)
    return s and s.size or nil
end

return M
