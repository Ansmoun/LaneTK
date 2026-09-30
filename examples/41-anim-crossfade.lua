-- examples/41-anim-crossfade.lua
-- Crossfade entre dos páginas de un Stack. Demuestra
-- anim.crossfade(window, old_area, swap_fn, duration).
--
-- Correr:
--   LANETK_LOG=info ./run examples/41-anim-crossfade.lua

local Server = require("lib.server")
local Window = require("lib.window")
local W      = require("lib.widgets")
local anim   = require("lib.anim")

local srv = Server.new { exit_on_empty = true }
anim.init(srv, { fps = 30 })

-- ── Página A: Ring grande ────────────────────────────────────

local ring = W.Ring.new {
    text = "50%", sub = "página A",
    color = { 0.55, 0.85, 0.60 },
    color_bg = { 0.22, 0.22, 0.28 },
    raw_range = { 0, 100 },
    size = 260, thickness = 18,
}
ring.value = 0.5

local page_a = W.Card.new {
    title = "Página A",
    content = ring,
    padding = 20,
    bg = { 0.16, 0.22, 0.18 },
    border = { 0.40, 0.70, 0.50 },
    min_width = 400, min_height = 400,
}

-- ── Página B: Bignum + texto ─────────────────────────────────

local bignum = W.Bignum.new {
    value = "75", unit = "%", caption = "página B",
    size = 72, caption_size = 14,
    color = { 0.95, 0.85, 0.65 },
    unit_color = { 0.85, 0.70, 0.45 },
    caption_color = { 0.75, 0.55, 0.35 },
}

local page_b_inner = W.Group.new {
    orientation = "vertical",
    spacing = 20,
    padding = 40,
    children = {
        { widget = W.Text.new { text = "" }, weight = 1 },
        { widget = bignum, weight = 0 },
        { widget = W.Text.new { text = "" }, weight = 1 },
    },
}

local page_b = W.Card.new {
    title = "Página B",
    content = page_b_inner,
    padding = 20,
    bg = { 0.22, 0.18, 0.16 },
    border = { 0.70, 0.55, 0.40 },
    min_width = 400, min_height = 400,
}

-- ── Stack con las dos páginas ────────────────────────────────

local stack = W.Stack.new {}
stack:add("a", page_a)
stack:add("b", page_b)

-- ── Botón de swap ────────────────────────────────────────────

local win

local swapping = false

local function current_page()
    local name = stack:get_active()
    return stack:get(name)
end

local function swap()
    if swapping then return end
    local from = current_page()
    if not from then return end

    local to_name = (stack:get_active() == "a") and "b" or "a"
    swapping = true

    anim.crossfade(
        win,
        from,
        function() stack:set_active(to_name) end,
        300,
        { fps = 20, easing = anim.EASE.out_quad,
          on_done = function() swapping = false end }
    )
end

local btn = W.Button.new {
    text = "swap (crossfade 350ms)",
    padding_x = 14, padding_y = 6,
    font = "DejaVu Sans 10",
}
btn.opts.on_click = function() swap() end

local btn_instant = W.Button.new {
    text = "swap instantáneo",
    padding_x = 14, padding_y = 6,
    font = "DejaVu Sans 10",
    flat = true,
}
btn_instant.opts.on_click = function()
    if swapping then return end
    local to_name = (stack:get_active() == "a") and "b" or "a"
    stack:set_active(to_name)
end

local bar = W.Group.new {
    orientation = "horizontal",
    spacing = 10,
    padding = 10,
    children = {
        { widget = btn,         weight = 0 },
        { widget = btn_instant, weight = 0 },
        { widget = W.Text.new { text = "" }, weight = 1 },
    },
}

local layout = W.Group.new {
    orientation = "vertical",
    spacing = 0,
    children = {
        { widget = bar,   weight = 0 },
        { widget = stack, weight = 1 },
    },
}

win = Window.new(srv, {
    width = 600, height = 520,
    x = "center", y = "center",
    title = "Crossfade test",
    app_name = "lanetk",
    class_name = "LtkCrossfadeTest",
    disable_q_close = true,
    on_key = function(key)
        if key.pressed and key.name == "Escape" then
            win:close("escape")
        elseif key.pressed and key.text == " " then
            swap()
        end
    end,
})

win:set_root(layout)

anim.delay(50, function() stack:set_active("a") end)

srv:run()
