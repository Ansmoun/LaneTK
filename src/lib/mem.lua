-- mem.lua: instrumentacion opcional de memoria.
--
-- Uso:
--   local mem = require("lib.mem")
--   mem.attach(srv, "launcher")   -- registra un timer que loguea
--                                  -- RSS + GC cada 60s si la env
--                                  -- LANETK_MEM_DEBUG=1 esta activa.
--   ...
--   mem.detach()  -- cancela el timer (opcional; el server lo
--                 -- cancela al parar de todos modos).
--
-- Si la variable no esta seteada, attach es un no-op.

local log = require("lib.log")

local M = {}

local _timer = nil

local function rss_kb()
    local f = io.open("/proc/self/status")
    if not f then return 0 end
    for line in f:lines() do
        local v = line:match("^VmRSS:%s+(%d+)")
        if v then f:close(); return tonumber(v) end
    end
    f:close()
    return 0
end

local function enabled()
    local v = os.getenv("LANETK_MEM_DEBUG")
    return v == "1" or v == "true"
end

function M.attach(srv, label)
    if not enabled() then return end
    if _timer then _timer:cancel(); _timer = nil end
    label = label or "?"
    log.info("mem", "[%s] monitor activo (cada 60s)", label)
    _timer = srv:add_timer(60000, function()
        local rss = rss_kb()
        local gc = collectgarbage("count")
        log.info("mem", "[%s] RSS=%d KB  GC=%.1f KB", label, rss, gc)
    end)
end

function M.detach()
    if _timer then _timer:cancel(); _timer = nil end
end

function M.rss_kb() return rss_kb() end

return M
