-- Log simple con niveles. Controlado por la variable de entorno
-- LANETK_LOG. Valores: error, warn, info, debug, trace.
-- Default: warn.
--
-- Uso:
--   local log = require("lib.log")
--   log.debug("dispatch", "etype=%d wid=%d", etype, wid)
--   log.error("no window for wid=%d", wid)

local M = {}

local LEVELS = { error = 1, warn = 2, info = 3, debug = 4, trace = 5 }

local function current_level()
    local v = os.getenv("LANETK_LOG") or "warn"
    return LEVELS[v] or LEVELS.warn
end

local function emit(level, prefix, fmt, ...)
    if LEVELS[level] > current_level() then return end
    local msg = string.format(fmt, ...)
    local ts = os.date("%H:%M:%S")
    io.stderr:write(string.format("[%s %s %s] %s\n",
        ts, level:upper(), prefix, msg))
    io.stderr:flush()
end

function M.error(prefix, fmt, ...) emit("error", prefix, fmt, ...) end
function M.warn (prefix, fmt, ...) emit("warn",  prefix, fmt, ...) end
function M.info (prefix, fmt, ...) emit("info",  prefix, fmt, ...) end
function M.debug(prefix, fmt, ...) emit("debug", prefix, fmt, ...) end
function M.trace(prefix, fmt, ...) emit("trace", prefix, fmt, ...) end

-- Nombres legibles de los tipos de evento, para los logs.
M.EVENT_NAMES = {
    [2]  = "KeyPress",
    [3]  = "KeyRelease",
    [4]  = "ButtonPress",
    [5]  = "ButtonRelease",
    [6]  = "MotionNotify",
    [7]  = "EnterNotify",
    [8]  = "LeaveNotify",
    [9]  = "FocusIn",
    [10] = "FocusOut",
    [12] = "Expose",
    [15] = "VisibilityNotify",
    [16] = "CreateNotify",
    [17] = "DestroyNotify",
    [18] = "UnmapNotify",
    [19] = "MapNotify",
    [20] = "MapRequest",
    [21] = "ReparentNotify",
    [22] = "ConfigureNotify",
    [23] = "ConfigureRequest",
    [28] = "PropertyNotify",
    [33] = "ClientMessage",
}

function M.event_name(etype)
    return M.EVENT_NAMES[etype] or ("unknown(" .. tostring(etype) .. ")")
end

return M
