-- Logout menu: daemon con trigger file /tmp/lanetk-logout.cmd.
-- Uso:
--   echo toggle > /tmp/lanetk-logout.cmd
--   echo show   > /tmp/lanetk-logout.cmd
--   echo hide   > /tmp/lanetk-logout.cmd
--   echo quit   > /tmp/lanetk-logout.cmd
--
-- Atajo sugerido (sxhkdrc):
--   super + shift + e
--       echo toggle > /tmp/lanetk-logout.cmd
--
-- Layout: 2x2 de botones + franja ancha abajo (apagar).
-- Cierre: Esc, o click fuera de la ventana (grab_pointer).

local Server = require("lib.server")
local Window = require("lib.window")
local theme  = require("lib.theme")
local log    = require("lib.log")
local anim   = require("lib.anim")
local cairo  = require("lib.cairo")
local xcb    = require("lib.xcb")
local W      = require("lib.widgets")
local LogoutButton = require("lib.widgets.logoutbutton")

local HOME       = os.getenv("HOME")
local ICON_DIR   = HOME .. "/proyectos/lanetk/icons-png/88/logout/"
local LOCK       = HOME .. "/.local/bin/lock"
local TRIGGER    = "/tmp/lanetk-logout.cmd"

local BTN_W      = 120
local BTN_H      = 100
local BAND_H     = 80
local BTN_GAP    = 8
local POP_MARGE  = 14
local ICON_SIZE  = 44
local RADIUS     = 6

local CONTENT_W  = BTN_W * 2 + BTN_GAP
local CONTENT_H  = BTN_H * 2 + BAND_H + BTN_GAP * 2
local WIN_W      = CONTENT_W + POP_MARGE * 2
local WIN_H      = CONTENT_H + POP_MARGE * 2

local ITEMS = {
    { id = "lock",    icon = "lock",    label = "Bloquear",
      cmd = LOCK, hover = "#83a598", wide = false },
    { id = "logout",  icon = "logout",  label = "Cerrar sesion",
      cmd = 'loginctl terminate-session "$XDG_SESSION_ID" || loginctl terminate-user "$USER"',
      hover = "#d65d0e", wide = false },
    { id = "reboot",  icon = "reboot",  label = "Reiniciar",
      cmd = "loginctl reboot",   hover = "#b8bb26", wide = false },
    { id = "suspend", icon = "suspend", label = "Suspender",
      cmd = "loginctl suspend",  hover = "#b16286", wide = false },
    { id = "power",   icon = "power",   label = "Apagar",
      cmd = "loginctl poweroff", hover = "#fb4934", wide = true  },
}

local srv = Server.new({ exit_on_empty = false })
local mem = require("lib.mem")
mem.attach(srv, "logout")

local T = theme.load()
log.info("logout", "paleta: %s", T.path)

anim.init(srv, { fps = 30 })

local win = nil

local function make_button(item)
    local w = item.wide and CONTENT_W or BTN_W
    local h = item.wide and BAND_H    or BTN_H
    return LogoutButton.new {
        icon         = item.icon,
        label        = item.label,
        icon_dir     = ICON_DIR,
        width        = w,
        height       = h,
        wide         = item.wide,
        bg_color     = "#1a1a1a",
        hover_color  = item.hover,
        fg_color     = "#ebdbb2",
        fg_dark      = "#000000",
        border_color = "#333333",
        icon_size    = ICON_SIZE,
        corner_radius = RADIUS,
        font         = "DejaVu Sans 10",
        on_click = function()
            if win then win:close("click") end
            if item.cmd then
                os.execute("(" .. item.cmd .. ") >/dev/null 2>&1 &")
            end
        end,
    }
end

local function build_root()
    local row1 = W.Group.new {
        orientation = "horizontal",
        spacing = BTN_GAP,
        children = { make_button(ITEMS[1]), make_button(ITEMS[2]) },
    }
    local row2 = W.Group.new {
        orientation = "horizontal",
        spacing = BTN_GAP,
        children = { make_button(ITEMS[3]), make_button(ITEMS[4]) },
    }
    local band = make_button(ITEMS[5])

    return W.Group.new {
        orientation = "vertical",
        spacing = BTN_GAP,
        padding = POP_MARGE,
        children = { row1, row2, band },
    }
end

local function do_show()
    if win then
        log.info("logout", "ya visible, ignorando show")
        return
    end

    local bg  = T.bg_rgb or { 0.06, 0.06, 0.06 }
    local sep = T.separator_rgb or { 0.2, 0.2, 0.2 }

    local w
    w = Window.new(srv, {
        kind = "menu",
        width  = WIN_W,
        height = WIN_H,
        x = "cursor-screen",
        y = "cursor-screen",
        disable_q_close = true,
        title = "Logout",
        on_draw = function(cr, cw, ch)
            cairo.set_rgb(cr, bg[1], bg[2], bg[3])
            cairo.rounded_rect(cr, 0, 0, cw, ch, RADIUS)
            cairo.fill(cr)

            cairo.set_rgb(cr, sep[1], sep[2], sep[3])
            cairo.set_line_width(cr, 1)
            cairo.rounded_rect(cr, 0.5, 0.5, cw - 1, ch - 1, RADIUS)
            cairo.stroke(cr)
        end,
        on_key = function(key)
            if key.pressed and key.name == "Escape"
               and not key.mods.ctrl and not key.mods.alt
               and not key.mods.super then
                w:close("escape")
            end
        end,
        on_mouse = function(x, y, button)
            if button ~= 1 then return end
            if x < 0 or y < 0 or x >= WIN_W or y >= WIN_H then
                w:close("click fuera")
            end
        end,
        on_close = function()
            xcb.ungrab_pointer(srv.conn)
            win = nil
        end,
    })

    w:set_root(build_root())
    xcb.grab_pointer(srv.conn, w.id)
    w:set_input_focus()

    win = w
    log.info("logout", "mostrado")
end

local function do_hide()
    if not win then return end
    log.info("logout", "cerrando")
    win:close("hide")
end

local function do_toggle()
    if win then do_hide() else do_show() end
end

-- Hot reload de paleta: si el menu esta abierto, cerrarlo y
-- reabrirlo con los colores nuevos.
theme.watch(function()
    if not win then return end
    log.info("logout", "rebuild por cambio de paleta")
    do_hide()
    local tm
    tm = srv:add_timer(80, function()
        tm:cancel()
        do_show()
    end)
end)

local reload = require("lib.reload")
reload.install(srv, function()
    log.info("logout", "SIGUSR1: rebuild cross-process")
    theme.reload_in_place(T)
    if win then
        do_hide()
        local tm
        tm = srv:add_timer(80, function()
            tm:cancel()
            do_show()
        end)
    end
end)

srv:watch_trigger(TRIGGER, function(cmd)
    log.info("logout", "trigger: %s", cmd)
    if cmd == "toggle" or cmd == "" then
        do_toggle()
    elseif cmd == "show" then
        do_show()
    elseif cmd == "hide" then
        do_hide()
    elseif cmd == "quit" then
        do_hide()
        srv:stop()
    else
        log.warn("logout", "comando desconocido: %s", cmd)
    end
end)

log.info("logout", "daemon listo. trigger: %s", TRIGGER)
srv:run()
log.info("logout", "adios")
