-- wallpaper.lua: fondo de escritorio nativo. ffmpeg + pixmap X11.
--
-- Modos soportados:
--   cover   llena la pantalla, recorta el sobrante (default)
--   contain entra entera, con bandas negras a los lados
--   stretch estira sin preservar aspect ratio
--   center  tamaño nativo, centrada, con bandas

local xcb     = require("lib.xcb")
local screens = require("lib.screens")
local log     = require("lib.log")

local M = {}

local function shquote(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function have(cmd)
    local h = io.popen("command -v " .. cmd .. " 2>/dev/null")
    if not h then return false end
    local line = h:read("*l")
    h:close()
    return line ~= nil and line ~= ""
end

local MODES = {
    cover = true, contain = true, stretch = true, center = true,
}

local function build_vf(mode, w, h)
    if mode == "cover" then
        return string.format(
            "scale=%d:%d:flags=lanczos:force_original_aspect_ratio=increase,crop=%d:%d",
            w, h, w, h)
    elseif mode == "contain" then
        return string.format(
            "scale=%d:%d:flags=lanczos:force_original_aspect_ratio=decrease," ..
            "pad=%d:%d:(ow-iw)/2:(oh-ih)/2:color=black",
            w, h, w, h)
    elseif mode == "stretch" then
        return string.format("scale=%d:%d:flags=lanczos", w, h)
    elseif mode == "center" then
        -- "center" no escala: si la imagen es mas grande que la
        -- pantalla, se recorta centrada; si es mas chica, se
        -- paddea centrada. Un solo "pad" fallaba con imagenes mas
        -- grandes porque pad no recorta. Un solo "crop" fallaba
        -- con imagenes mas chicas porque crop no paddea.
        -- La cadena crop(min(iw,W), min(ih,H)) + pad(W, H) cubre
        -- los dos casos.
        return string.format(
            "crop=w='min(iw,%d)':h='min(ih,%d)'" ..
            ":x='(iw-min(iw,%d))/2':y='(ih-min(ih,%d))/2'," ..
            "pad=%d:%d:(ow-iw)/2:(oh-ih)/2:color=black",
            w, h, w, h, w, h)
    end
    return nil
end

local function decode(path, w, h, mode)
    local vf = build_vf(mode, w, h)
    if not vf then return nil, "modo desconocido: " .. tostring(mode) end
    local cmd = string.format(
        "ffmpeg -nostdin -v error -i %s -vf %s -frames:v 1 " ..
        "-f rawvideo -pix_fmt bgra - 2>/dev/null",
        shquote(path), shquote(vf))
    local p = io.popen(cmd, "r")
    if not p then return nil, "io.popen fallo" end
    local data = p:read("*a")
    p:close()
    local expect = w * h * 4
    if not data or #data ~= expect then
        return nil, string.format("ffmpeg devolvio %d bytes, esperaba %d",
            data and #data or 0, expect)
    end
    return data
end

local function make_pixmap(srv, w, h, bgra)
    local conn  = srv.conn
    local root  = srv.screen.root
    local depth = srv.screen.root_depth

    local pid = xcb.generate_id(conn)
    local err = xcb.check_cookie(conn,
        xcb.create_pixmap_checked(conn, depth, pid, root, w, h),
        "create_pixmap")
    if err then return nil, err end

    local gc = xcb.generate_id(conn)
    err = xcb.check_cookie(conn,
        xcb.create_gc_checked(conn, gc, pid), "create_gc")
    if err then
        xcb.free_pixmap(conn, pid)
        return nil, err
    end

    err = xcb.check_cookie(conn,
        xcb.put_image_checked(conn, pid, gc, w, h, 0, 0, depth,
            xcb.IMAGE_FORMAT.ZPixmap, bgra), "put_image")
    xcb.free_gc(conn, gc)

    if err then
        xcb.free_pixmap(conn, pid)
        return nil, err
    end
    return pid
end

local function make_desktop_window(srv, mon, pid)
    local screen = srv.screen
    local wid, _, cerr = xcb.create_window(srv.conn, {
        parent = screen.root,
        x = mon.x, y = mon.y,
        width = mon.w, height = mon.h,
        border_width = 0,
        depth = screen.root_depth,
        class = xcb.WIN_CLASS.InputOutput,
        visual = screen.root_visual,
        override_redirect = true,
        background_pixmap = pid,
        event_mask = 0,
    })
    if not wid then return nil, "create_window: " .. (cerr or "?") end
    xcb.map_window(srv.conn, wid)
    xcb.configure_window(srv.conn, wid, xcb.CONFIG.Stack, { stack = 1 })
    xcb.flush(srv.conn)
    return wid
end

function M.set(srv, path, opts)
    opts = opts or {}
    local mode = opts.mode or "cover"
    if not MODES[mode] then
        return nil, "wallpaper: modo no soportado: " .. mode
    end
    if not have("ffmpeg") then
        return nil, "wallpaper: ffmpeg no esta en PATH"
    end
    if not path or path == "" then
        return nil, "wallpaper: path vacio"
    end
    local f = io.open(path, "rb")
    if not f then return nil, "wallpaper: no se puede leer: " .. tostring(path) end
    f:close()

    local mons = opts.monitor and { opts.monitor } or screens.list()
    if #mons == 0 then return nil, "wallpaper: no hay monitores" end

    log.info("wallpaper", "aplicando %s (modo %s) en %d monitor(es)",
        path, mode, #mons)

    local windows, errors = {}, {}
    for _, mon in ipairs(mons) do
        local bgra, derr = decode(path, mon.w, mon.h, mode)
        if not bgra then
            errors[#errors + 1] = string.format("%s: %s", mon.name, derr)
            log.error("wallpaper", "%s: %s", mon.name, derr)
        else
            local pid, perr = make_pixmap(srv, mon.w, mon.h, bgra)
            bgra = nil
            if not pid then
                errors[#errors + 1] = string.format("%s: %s", mon.name, perr)
                log.error("wallpaper", "%s: %s", mon.name, perr)
            else
                local wid, werr = make_desktop_window(srv, mon, pid)
                if not wid then
                    errors[#errors + 1] = string.format("%s: %s", mon.name, werr)
                    log.error("wallpaper", "%s: %s", mon.name, werr)
                    xcb.free_pixmap(srv.conn, pid)
                else
                    windows[#windows + 1] = { wid = wid, pid = pid, mon = mon }
                    log.info("wallpaper", "%s: win 0x%x (%dx%d+%d+%d)",
                        mon.name, tonumber(wid), mon.w, mon.h, mon.x, mon.y)
                end
            end
        end
    end

    collectgarbage("collect")
    xcb.flush(srv.conn)

    if #windows == 0 then
        return nil, "wallpaper: ningun monitor tuvo exito: " ..
            table.concat(errors, "; ")
    end

    return {
        windows = windows,
        errors  = errors,
        close = function()
            local conn = srv.conn
            for _, w in ipairs(windows) do
                xcb.destroy_window(conn, w.wid)
                xcb.free_pixmap(conn, w.pid)
            end
            xcb.flush(conn)
        end,
    }
end

return M
