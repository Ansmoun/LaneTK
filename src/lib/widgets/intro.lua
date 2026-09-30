-- Intro: animaciones de entrada automaticas para widgets animables.
--
-- El TabbedPanel llama Intro.reset(widget) y Intro.play(widget) al
-- activar un tab. Intro recorre el arbol recursivamente y, para cada
-- widget que declara self._anim_kind, dispara la animacion
-- correspondiente.
--
-- Tipos soportados:
--   "ring"   -> tween reveal 0 -> 1 (el arco se dibuja progresivamente)
--   "spark"  -> setea _anim_pending; el tween alpha/reveal lo dispara
--               el primer push del spark (cuando ya hay >= 2 puntos)
--   "barrow" -> stagger por fila sobre row.reveal
--   "kv"     -> tween_custom sobre set_alpha
--
-- Si el motor no esta listo o animate_widgets = false, reset y play
-- son no-op.

local M = {}

-- Guarda un handle en el widget para poder cancelarlo luego.
local function push_handle(w, h)
    if not h then return end
    if not w._intro_handles then w._intro_handles = {} end
    w._intro_handles[#w._intro_handles + 1] = h
end

local function get_opts()
    local Config = require("lib.data.config")
    return Config.get_anim_opts()
end

-- Devuelve los hijos directos de un widget. Cubre los contenedores
-- del toolkit: Group y KV exponen children; Card expone content;
-- Stack expone pages (solo activa); TabbedPanel expone group.
local function children_of(w)
    local out = {}
    if w.children then
        for _, c in ipairs(w.children) do out[#out+1] = c end
    end
    if w.content then out[#out+1] = w.content end
    if w.pages and w.active and w.pages[w.active] then
        out[#out+1] = w.pages[w.active]
    end
    if w.group and w.group ~= w then out[#out+1] = w.group end
    return out
end

local function reset_widget(w)
    local kind = w._anim_kind
    if not kind then return end
    if kind == "ring" then
        w.reveal = 0
    elseif kind == "spark" then
        w.alpha = 0
        w.reveal = 0
        w._anim_pending = true
    elseif kind == "dualspark" then
        w.alpha = 0
        w.reveal = 0
        w._anim_pending = true
    elseif kind == "barrow" then
        for _, row in ipairs(w.rows or {}) do row.reveal = 0 end
    elseif kind == "kv" then
        if w.set_alpha then w:set_alpha(0) end
    end
end

local function play_widget(w, anim)
    local kind = w._anim_kind
    if not kind then return end
    if kind == "ring" then
        push_handle(w, anim.tween(w, "reveal", 0, 1, 700, anim.EASE.out_cubic))
    elseif kind == "spark" then
        -- El tween lo dispara Spark:push cuando llega el primer dato
        -- real (>= 2 puntos). Si el spark ya tiene datos, lo lanzamos
        -- aqui directamente para no esperar al siguiente push.
        if #w.history:get() >= 2 then
            w._anim_pending = false
            push_handle(w, anim.tween(w, "alpha", 0, 1, 600, anim.EASE.out_quad))
            push_handle(w, anim.tween(w, "reveal", 0, 1, 900, anim.EASE.out_cubic))
        end
    elseif kind == "dualspark" then
        local na = #w.history_a:get()
        local nb = #w.history_b:get()
        if na >= 2 or nb >= 2 then
            w._anim_pending = false
            push_handle(w, anim.tween(w, "alpha", 0, 1, 600, anim.EASE.out_quad))
            push_handle(w, anim.tween(w, "reveal", 0, 1, 900, anim.EASE.out_cubic))
        end
    elseif kind == "barrow" then
        for i, row in ipairs(w.rows or {}) do
            -- Guardamos el delay tambien: es un handle cancelable.
            push_handle(w, anim.delay((i - 1) * 35, function()
                push_handle(w, anim.tween_custom(w, function(e)
                    row.reveal = e
                    if w.damage then w:damage() end
                end, 450, anim.EASE.out_cubic))
            end))
        end
    elseif kind == "kv" then
        push_handle(w, anim.tween_custom(w, function(e)
            w:set_alpha(e)
        end, 500, anim.EASE.out_quad))
    end
end

local function walk(w, fn, seen)
    if not w or seen[w] then return end
    seen[w] = true
    fn(w)
    for _, c in ipairs(children_of(w)) do
        walk(c, fn, seen)
    end
end

-- Cancela los tweens de intro de un widget. Se llama al cambiar
-- de tab para que los tweens del intro viejo no sigan dañando
-- rects que ya no estan en pantalla. Bug: si cambias de tab
-- mientras el reveal esta en efecto, los rects viejos seguian
-- recibiendo damage y el sistema de tabs/subtabs se veia roto
-- por unos segundos.
local function cancel_widget(w)
    if w._intro_handles then
        for _, h in ipairs(w._intro_handles) do
            if h and h.cancel then h:cancel() end
        end
        w._intro_handles = nil
    end
    -- Handles internos de widgets animables.
    if w._anim_handle then
        w._anim_handle:cancel()
        w._anim_handle = nil
    end
    if w._push_handle then
        w._push_handle:cancel()
        w._push_handle = nil
    end
    if w.rows then
        for _, row in ipairs(w.rows) do
            if row._anim_handle then
                row._anim_handle:cancel()
                row._anim_handle = nil
            end
        end
    end
end

-- Cancela todos los tweens de intro del arbol. Llamar al cambiar
-- de tab antes de reset+play del tab nuevo.
function M.cancel(root)
    if not root then return end
    walk(root, cancel_widget, {})
end

-- Pone los campos de animacion a su estado inicial.
function M.reset(root)
    local A = get_opts()
    if not A.widgets then return end
    local anim = require("lib.anim")
    if not anim.is_ready() then return end
    walk(root, reset_widget, {})
end

-- Dispara las animaciones de entrada.
function M.play(root)
    local A = get_opts()
    if not A.widgets then return end
    local anim = require("lib.anim")
    if not anim.is_ready() then return end
    walk(root, function(w) play_widget(w, anim) end, {})
end

return M
