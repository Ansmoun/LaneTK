-- Launcher de aplicaciones: daemon con trigger file.
-- Uso:
--   echo toggle > /tmp/lanetk-launcher.cmd
--   echo show   > /tmp/lanetk-launcher.cmd
--   echo hide   > /tmp/lanetk-launcher.cmd
--   echo quit   > /tmp/lanetk-launcher.cmd
--
-- Atajo sugerido (sxhkdrc):
--   super + d
--       echo toggle > /tmp/lanetk-launcher.cmd
--
-- Cada show crea un tab nuevo (estado limpio). Cada hide lo destruye.
-- El proceso queda vivo entre shows.

local Server = require("lib.server")
local Window = require("lib.window")
local theme  = require("lib.theme")
local cairo  = require("lib.cairo")
local log    = require("lib.log")

local TRIGGER    = "/tmp/lanetk-launcher.cmd"
local W_LAUNCHER = 640
local H_LAUNCHER = 460

local srv = Server.new({ exit_on_empty = false })
local mem = require("lib.mem")
mem.attach(srv, "launcher")

local T = theme.load()
log.info("launcher", "paleta: %s", T.path)

-- Prewarm: hacer scan de apps y resolver los iconos del top 20 del
-- historial ANTES de srv:run(). Sin esto, el primer super+d paga el
-- costo entero (scan + primera construccion del indice de iconos,
-- que hace find sobre /usr/share/icons) y el usuario ve el fondo
-- sin iconos durante medio segundo.
do
    local D = require("lib.data.launcher")
    local t0 = os.time()
    log.info("launcher", "prewarm: scan...")
    local n = D.scan()
    log.info("launcher", "prewarm: scan OK (%d apps)", n or 0)
    local hist = D.history_top(20)
    local n_icons = 0
    for _, e in ipairs(hist) do
        if e.icon and e.icon ~= "" then
            D.find_icon(e.icon)
            n_icons = n_icons + 1
        end
    end
    log.info("launcher", "prewarm done: %d iconos en %ds",
        n_icons, os.time() - t0)
end

local win = nil
local tab = nil

local function do_show()
    if win then
        log.info("launcher", "ya visible, ignorando show")
        return
    end

    local launcher_mod = require("lib.tabs.launcher")
    tab = launcher_mod.new(srv, T)

    local w
    w = Window.new(srv, {
        kind = "menu",
        width  = W_LAUNCHER,
        height = H_LAUNCHER,
        x = "cursor-screen",
        y = "cursor-screen",
        disable_q_close = true,
        on_draw = function(cr, cw, ch)
            -- Marco exterior oscuro (T.bg) + interior claro (T.bg_card).
            -- Da el efecto de "popup dentro de un marco", igual que el
            -- launcher de Awesome (bg_normal exterior, bg_card interior).
            local bg  = T.bg_rgb
            local bcg = T.bg_card_rgb
            if not bg or not bcg then
                cairo.set_rgb(cr, 0.04, 0.05, 0.08)
                cairo.paint(cr)
                return
            end
            cairo.set_rgb(cr, bg[1], bg[2], bg[3])
            cairo.rounded_rect(cr, 0, 0, cw, ch, 14)
            cairo.fill(cr)
            cairo.set_rgb(cr, bcg[1], bcg[2], bcg[3])
            cairo.rounded_rect(cr, 2, 2, cw - 4, ch - 4, 12)
            cairo.fill(cr)
        end,
        on_focus_in = function()
            log.debug("launcher", "focus in")
            if tab and tab.focus then tab.focus() end
        end,
        on_close = function()
            log.info("launcher", "cerrando ventana")
            if tab and tab.stop then tab.stop() end
            tab = nil
            win = nil
        end,
    })

    w:set_root(tab.widget)
    tab.start()

    w:set_input_focus()
    if tab.focus then tab.focus() end

    win = w
    log.info("launcher", "mostrado")
end

local function do_hide()
    if not win then return end
    log.info("launcher", "cerrando")
    win:close("hide")
end

local function do_toggle()
    if win then do_hide() else do_show() end
end

-- Hot reload de paleta: si la ventana esta abierta, cerrarla y
-- reabrirla con los colores nuevos. Si esta cerrada, no hacer nada.
theme.watch(function()
    if not win then return end
    log.info("launcher", "rebuild por cambio de paleta")
    do_hide()
    local tm
    tm = srv:add_timer(80, function()
        tm:cancel()
        do_show()
    end)
end)

local reload = require("lib.reload")
reload.install(srv, function()
    log.info("launcher", "SIGUSR1: rebuild cross-process")
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
    log.info("launcher", "trigger: %s", cmd)
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
        log.warn("launcher", "comando desconocido: %s", cmd)
    end
end)

log.info("launcher", "daemon listo. trigger: %s", TRIGGER)
srv:run()
log.info("launcher", "adios")
