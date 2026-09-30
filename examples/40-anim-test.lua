-- examples/40-anim-test.lua
-- Prototipo del motor de animaciones.

local Server = require("lib.server")
local Window = require("lib.window")
local W      = require("lib.widgets")
local anim   = require("lib.anim")
local log    = require("lib.log")

local srv = Server.new { exit_on_empty = true }
anim.init(srv, { fps = 30 })

local CARD_BG        = { 0.14, 0.14, 0.18 }
local CARD_BG_ACCENT = { 0.30, 0.28, 0.42 }
local RING_COLOR     = { 0.55, 0.85, 0.60 }
local RING_THICK     = 14
local TYPING_FULL    = "LaneTK — toolkit grafico en LuaJIT sobre X11."

-- ── Escenario ─────────────────────────────────────────────────

local ring = W.Ring.new {
    text = "0%", sub = "anim",
    color = { RING_COLOR[1], RING_COLOR[2], RING_COLOR[3] },
    color_bg = { 0.22, 0.22, 0.28 },
    raw_range = { 0, 100 },
    size = 200, thickness = RING_THICK,
}

local ring_card = W.Card.new {
    title = "Widget de prueba",
    content = ring,
    padding = 24,
    bg = { CARD_BG[1], CARD_BG[2], CARD_BG[3] },
    border = { 0.30, 0.30, 0.35 },
    min_width = 300,
    min_height = 300,
}

local bignum = W.Bignum.new {
    value = "0", unit = "%", caption = "count-up",
    size = 40, caption_size = 10,
    color = { 0.95, 0.95, 0.95 },
    unit_color = { 0.65, 0.65, 0.70 },
    caption_color = { 0.55, 0.55, 0.60 },
}

local typing_text = W.Text.new {
    text = "",
    font = "DejaVu Sans 10",
    align = "left", valign = "top",
    wrap = true,
}

local info_inner = W.Group.new {
    orientation = "vertical", spacing = 16, padding = 16,
    children = {
        { widget = bignum,      weight = 0 },
        { widget = typing_text, weight = 1 },
    },
}

local info_card = W.Card.new {
    title = "Info",
    content = info_inner,
    padding = 12,
    bg = { CARD_BG[1], CARD_BG[2], CARD_BG[3] },
    border = { 0.30, 0.30, 0.35 },
    min_width = 340,
    min_height = 300,
}

local function set_ring_text()
    ring.text = string.format("%d%%",
        math.floor(math.max(0, math.min(1, ring.value)) * 100))
end

local function mkbtn(label, fn)
    local b = W.Button.new {
        text = label,
        padding_x = 8, padding_y = 4,
        font = "DejaVu Sans 9",
        corner_radius = 4,
    }
    b.opts.on_click = function() fn() end
    return b
end

local function spacer() return W.Text.new { text = "" } end

local function utf8_sub(s, n_chars)
    local i, count = 1, 0
    while i <= #s and count < n_chars do
        local b = s:byte(i)
        local len = 1
        if b >= 0xF0 then len = 4
        elseif b >= 0xE0 then len = 3
        elseif b >= 0xC0 then len = 2
        end
        i = i + len
        count = count + 1
    end
    return s:sub(1, i - 1)
end

local function utf8_len(s)
    local i, count = 1, 0
    while i <= #s do
        local b = s:byte(i)
        local len = 1
        if b >= 0xF0 then len = 4
        elseif b >= 0xE0 then len = 3
        elseif b >= 0xC0 then len = 2
        end
        i = i + len
        count = count + 1
    end
    return count
end

local function ensure_arc_visible()
    if ring.value < 0.05 then
        ring.value = 0.7
        set_ring_text()
        ring:damage()
    end
end

-- ── Animaciones básicas ───────────────────────────────────────

local function anim_value(easing_name)
    local E = anim.EASE[easing_name] or anim.EASE.out_quad
    anim.stop_all()
    ring.value = 0
    set_ring_text()
    ring:damage()
    anim.tween_custom(ring, function(eased)
        ring.value = math.max(0, math.min(1, eased))
        set_ring_text()
    end, 900, E, function()
        anim.tween_custom(ring, function(eased)
            ring.value = 1 - eased
            set_ring_text()
        end, 400, anim.EASE.in_quad)
    end)
end

local function anim_thickness()
    anim.stop_all()
    anim.sequence({
        { kind = "tween", area = ring, prop = "thickness",
          from = 4,  to = 24, duration = 500, easing = anim.EASE.out_cubic },
        { kind = "tween", area = ring, prop = "thickness",
          from = 24, to = 14, duration = 500, easing = anim.EASE.out_cubic },
    })
end

local function anim_color()
    anim.stop_all()
    ensure_arc_visible()
    local from = { ring.color[1], ring.color[2], ring.color[3] }
    local to   = { 0.95, 0.40, 0.40 }
    anim.sequence({
        { kind = "tween_rgb", area = ring, prop = "color",
          from = from, to = to, duration = 700,
          easing = anim.EASE.in_out_cubic },
        { kind = "tween_rgb", area = ring, prop = "color",
          from = to, to = from, duration = 700,
          easing = anim.EASE.in_out_cubic },
    })
end

local function anim_bg()
    anim.stop_all()
    local from = { ring_card.bg[1], ring_card.bg[2], ring_card.bg[3] }
    anim.sequence({
        { kind = "tween_rgb", area = ring_card, prop = "bg",
          from = from, to = CARD_BG_ACCENT, duration = 700,
          easing = anim.EASE.in_out_cubic },
        { kind = "tween_rgb", area = ring_card, prop = "bg",
          from = CARD_BG_ACCENT, to = CARD_BG, duration = 700,
          easing = anim.EASE.in_out_cubic },
    })
end

local function anim_spring()
    anim.stop_all()
    ring.value = 0
    set_ring_text()
    ring:damage()
    anim.spring(ring, "value", 0.85, { tension = 200, friction = 18 },
        function()
            anim.spring(ring, "value", 0.0, { tension = 200, friction = 18 })
        end)
    anim.tween_custom(ring, function()
        set_ring_text()
    end, 2500, anim.EASE.linear)
end

local function anim_loop()
    anim.stop_all()
    ensure_arc_visible()
    local from = { ring.color[1], ring.color[2], ring.color[3] }
    anim.loop(ring, "thickness", RING_THICK, 22, 500,
        anim.EASE.in_out_cubic, "ping-pong")
    anim.loop(ring, "color", from, { 0.95, 0.40, 0.40 }, 700,
        anim.EASE.in_out_cubic, "ping-pong")
end

-- ── Efectos concretos ────────────────────────────────────────

local function anim_pulse()
    anim.stop_all()
    ensure_arc_visible()
    local from_color = { ring.color[1], ring.color[2], ring.color[3] }
    local to_color   = { 0.95, 0.55, 0.35 }
    anim.loop(ring, "thickness", RING_THICK, 20, 900,
        anim.EASE.in_out_cubic, "ping-pong")
    anim.loop(ring, "color", from_color, to_color, 900,
        anim.EASE.in_out_cubic, "ping-pong")
end

-- Shake del Ring. Mueve el Ring ±6 px dentro del Card y daña el
-- rect COMPLETO del Card en cada frame. Dañar solo el rango del
-- Ring dejaba rastro del border antialiasingado del Card, porque
-- el clip parcial repintaba el border solo por partes.
--
-- Coste: repinta ~300x300 px por frame. A 30 FPS son ~2.7M px/s,
-- ~1-2% de un core en un Celeron 847.
local function anim_shake()
    anim.stop_all()
    ensure_arc_visible()

    local bx0, bx1 = ring.x0, ring.x1
    local pattern   = { 6, -6, 5, -5, 3, -3, 0 }
    local durations = { 60, 60, 60, 60, 60, 60, 80 }
    local steps = {}
    local prev = 0

    -- Función auxiliar: daña el Card entero, no el rango del Ring.
    local function damage_card()
        if ring_card.window then
            ring_card.window:add_damage(
                ring_card.x0, ring_card.y0,
                ring_card.x1, ring_card.y1)
        end
    end

    for i, to_off in ipairs(pattern) do
        local from_off = prev
        local dur = durations[i]
        steps[#steps + 1] = {
            kind = "custom",
            area = nil,
            duration = dur,
            easing = anim.EASE.out_quad,
            apply = function(eased)
                local cur = from_off + (to_off - from_off) * eased
                ring.x0 = bx0 + cur
                ring.x1 = bx1 + cur
                damage_card()
            end,
        }
        prev = to_off
    end

    anim.sequence(steps, function()
        ring.x0, ring.x1 = bx0, bx1
        damage_card()
    end)
end

local function anim_highlight()
    anim.stop_all()
    local from = { ring_card.bg[1], ring_card.bg[2], ring_card.bg[3] }
    local accent = { 0.85, 0.70, 0.35 }
    anim.sequence({
        { kind = "tween_rgb", area = ring_card, prop = "bg",
          from = from, to = accent, duration = 140 },
        { kind = "tween_rgb", area = ring_card, prop = "bg",
          from = accent, to = from, duration = 450,
          easing = anim.EASE.out_cubic },
    })
end

local function anim_reveal()
    anim.stop_all()
    local target = ring.value > 0.1 and ring.value or 0.75
    ring.value = 0
    set_ring_text()
    ring:damage()
    anim.tween_custom(ring, function(eased)
        ring.value = eased * target
        set_ring_text()
    end, 700, anim.EASE.out_cubic)
end

local function anim_count_up()
    anim.stop_all()
    bignum:set("0")
    anim.tween_custom(bignum, function(eased)
        bignum:set(string.format("%d", math.floor(eased * 100)))
    end, 900, anim.EASE.out_cubic, function()
        bignum:set("100")
    end)
end

local function anim_typing()
    anim.stop_all()
    typing_text:set_text("")
    local total = utf8_len(TYPING_FULL)
    anim.tween_custom(typing_text, function(eased)
        local n = math.floor(eased * total)
        typing_text:set_text(utf8_sub(TYPING_FULL, n))
    end, 1800, anim.EASE.linear, function()
        typing_text:set_text(TYPING_FULL)
    end)
end

local function anim_reset()
    anim.stop_all()
    ring.value = 0
    ring.thickness = RING_THICK
    ring.color = { RING_COLOR[1], RING_COLOR[2], RING_COLOR[3] }
    ring_card.bg = { CARD_BG[1], CARD_BG[2], CARD_BG[3] }
    bignum:set("0")
    typing_text:set_text("")
    set_ring_text()
    ring:damage()
    ring_card:damage()
    bignum:damage()
    typing_text:damage()
end

-- ── Filas de botones ──────────────────────────────────────────

local row_value = W.Group.new {
    orientation = "horizontal", spacing = 6,
    children = {
        { widget = mkbtn("linear",
            function() anim_value("linear") end), weight = 0 },
        { widget = mkbtn("out_cubic",
            function() anim_value("out_cubic") end), weight = 0 },
        { widget = mkbtn("elastic",
            function() anim_value("out_elastic") end), weight = 0 },
        { widget = mkbtn("bounce",
            function() anim_value("out_bounce") end), weight = 0 },
        { widget = spacer(), weight = 1 },
    },
}

local row_props = W.Group.new {
    orientation = "horizontal", spacing = 6,
    children = {
        { widget = mkbtn("thickness",
            function() anim_thickness() end), weight = 0 },
        { widget = mkbtn("color",
            function() anim_color() end), weight = 0 },
        { widget = mkbtn("bg card",
            function() anim_bg() end), weight = 0 },
        { widget = mkbtn("spring",
            function() anim_spring() end), weight = 0 },
        { widget = mkbtn("loop",
            function() anim_loop() end), weight = 0 },
        { widget = spacer(), weight = 1 },
    },
}

local row_effects = W.Group.new {
    orientation = "horizontal", spacing = 6,
    children = {
        { widget = mkbtn("pulse",
            function() anim_pulse() end), weight = 0 },
        { widget = mkbtn("shake",
            function() anim_shake() end), weight = 0 },
        { widget = mkbtn("highlight",
            function() anim_highlight() end), weight = 0 },
        { widget = mkbtn("reveal",
            function() anim_reveal() end), weight = 0 },
        { widget = mkbtn("count-up",
            function() anim_count_up() end), weight = 0 },
        { widget = mkbtn("typing",
            function() anim_typing() end), weight = 0 },
        { widget = spacer(), weight = 1 },
        { widget = mkbtn("reset",
            function() anim_reset() end), weight = 0 },
    },
}

local header = W.Group.new {
    orientation = "vertical", spacing = 6, padding = 10,
    children = { row_value, row_props, row_effects },
}

local body = W.Group.new {
    orientation = "horizontal", spacing = 12, padding = 12,
    children = {
        { widget = spacer(),  weight = 1 },
        { widget = ring_card, weight = 0 },
        { widget = info_card, weight = 0 },
        { widget = spacer(),  weight = 1 },
    },
}

local footer = W.Text.new {
    text = "30 FPS · Esc cierra · pool idle = 0 timers",
    font = "DejaVu Sans 9",
    align = "center",
    r = 0.55, g = 0.55, b = 0.60,
}

local footer_wrap = W.Group.new {
    orientation = "horizontal", padding = 8,
    children = { { widget = footer, weight = 1 } },
}

local layout = W.Group.new {
    orientation = "vertical", spacing = 0,
    children = {
        { widget = header,      weight = 0 },
        { widget = body,        weight = 1 },
        { widget = footer_wrap, weight = 0 },
    },
}

local win
win = Window.new(srv, {
    width = 960, height = 640,
    x = "center", y = "center",
    title = "Anim test",
    app_name = "lanetk",
    class_name = "LtkAnimTest",
    disable_q_close = true,
    on_key = function(key)
        if key.pressed and key.name == "Escape" then
            win:close("escape")
        end
    end,
})

win:set_root(layout)
srv:run()
