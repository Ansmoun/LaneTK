-- MenuTree: menú jerárquico en cascada.
--
-- Soporta items con submenú. Al posar el mouse sobre un item con
-- submenú, se abre otro nivel a la derecha. Al seleccionar una
-- acción, se cierran todos los niveles y se ejecuta el callback.
--
-- Todo se dibuja en una sola ventana child. El tamaño de la
-- ventana es el bounding box de todos los niveles abiertos. Al
-- abrir o cerrar un nivel se recalcula el bounding box y se
-- reposiciona la ventana si es necesario.
--
-- Grab de puntero único: toda la cascada está bajo un solo
-- grab_pointer. Los eventos llegan a la ventana con coordenadas
-- globales, y el widget determina el nivel afectado según las
-- coordenadas.
--
-- Uso:
--   local MT = require("lib.widgets.menutree")
--   local mt = MT.new(srv, parent_win, theme)
--   mt:show(x, y, {
--       { label = "Archivo", submenu = {
--           { label = "Nueva pestaña", on_click = ... },
--           { sep = true },
--           { label = "Cerrar", on_click = ... },
--       } },
--       { label = "Editar", submenu = {...} },
--       { sep = true },
--       { label = "Salir", on_click = ... },
--   })

local Window = require("lib.window")
local cairo  = require("lib.cairo")
local pango  = require("lib.pango")
local log    = require("lib.log")
local xcb    = require("lib.xcb")

local M = {}

local MenuTree = {}
MenuTree.__index = MenuTree

-- Dimensiones
local ITEM_H     = 26
local PAD_X      = 14
local PAD_Y      = 6
local SEP_H      = 1
local MIN_W      = 180
local CHEVRON_W  = 16  -- espacio reservado a la derecha para el ›

local FONT       = "DejaVu Sans 10"
local FONT_BOLD  = "DejaVu Sans Bold 10"

-- ── Utilidades ──────────────────────────────────────────────
local function measure_items(items)
    local max_w = 0
    for _, it in ipairs(items) do
        if it.label then
            local f = it.bold and FONT_BOLD or FONT
            local w = select(1, pango.measure(it.label, f))
            if w > max_w then max_w = w end
        end
    end
    return math.max(MIN_W, max_w + PAD_X * 2 + CHEVRON_W)
end

local function measure_height(items)
    local h = PAD_Y * 2
    for _, it in ipairs(items) do
        if it.sep then h = h + SEP_H else h = h + ITEM_H end
    end
    return h
end

-- Devuelve el rect { y0, y1 } de un item.
local function item_rect_y(items, idx)
    local y = PAD_Y
    for i, it in ipairs(items) do
        if i == idx then
            local h = it.sep and SEP_H or ITEM_H
            return y, y + h
        end
        y = y + (it.sep and SEP_H or ITEM_H)
    end
    return nil
end

function M.new(srv, parent_win, theme)
    local self = setmetatable({}, MenuTree)
    self.srv        = srv
    self.parent_win = parent_win
    self.theme      = theme
    self.win        = nil
    self.levels     = {}   -- array de { items, x, y, w, h }
    self.hover      = nil  -- { level, idx } o nil
    self.win_w      = 0
    self.win_h      = 0
    self.win_x      = 0
    self.win_y      = 0
    return self
end

function M.is_available()
    return Window ~= nil
end

-- ── Ciclo de vida ───────────────────────────────────────────
function MenuTree:is_open()
    return self.win ~= nil and not self.win.destroyed
end

function MenuTree:close()
    if not self.win then return end
    local w = self.win
    local conn = w.conn
    self.win = nil
    self.levels = {}
    self.hover = nil
    xcb.ungrab_pointer(conn)
    if not w.destroyed then
        w:close("menutree cerrado")
    end
end

-- show(x, y, items, opts)
--   x, y:  posición del nivel raíz (coordenadas del padre)
--   items: array de items del nivel raíz
--   opts.on_close: callback opcional al cerrar
function MenuTree:show(x, y, items, opts)
    opts = opts or {}
    self.on_close_cb = opts.on_close

    -- Cerrar instancia previa si existe.
    if self.is_open() then self:close() end

    -- Nivel raíz.
    local w = measure_items(items)
    local h = measure_height(items)
    local px, py = math.floor(x), math.floor(y)

    -- Reposicionar si se sale del padre.
    local parent_w = self.parent_win.width
    local parent_h = self.parent_win.height
    if px + w > parent_w - 4 then px = parent_w - w - 4 end
    if py + h > parent_h - 4 then py = parent_h - h - 4 end
    if px < 4 then px = 4 end
    if py < 4 then py = 4 end

    self.levels = {
        { items = items, x = px, y = py, w = w, h = h },
    }

    self:_create_window()
end

function MenuTree:_create_window()
    -- Calcular bounding box de todos los niveles.
    local min_x, min_y = math.huge, math.huge
    local max_x, max_y = -math.huge, -math.huge
    for _, lv in ipairs(self.levels) do
        if lv.x < min_x then min_x = lv.x end
        if lv.y < min_y then min_y = lv.y end
        if lv.x + lv.w > max_x then max_x = lv.x + lv.w end
        if lv.y + lv.h > max_y then max_y = lv.y + lv.h end
    end

    local wx, wy = min_x, min_y
    local ww = max_x - min_x
    local wh = max_y - min_y
    self.win_x, self.win_y = wx, wy
    self.win_w, self.win_h = ww, wh

    -- Destruir ventana vieja si existe.
    if self.win and not self.win.destroyed then
        xcb.ungrab_pointer(self.win.conn)
        local old = self.win
        self.win = nil
        old:close("menutree recrear")
    end

    local self_ref = self
    local win
    win = Window.new(self.srv, {
        parent_window = self.parent_win,
        kind          = "child",
        width         = ww,
        height        = wh,
        x             = wx,
        y             = wy,
        disable_q_close = true,
        on_draw = function(cr, cw, ch)
            self_ref:_draw(cr, cw, ch)
        end,
        on_mouse = function(mx, my, button)
            self_ref:_on_mouse(mx, my, button)
        end,
        on_mouse_move = function(mx, my)
            self_ref:_on_mouse_move(mx, my)
        end,
        on_key = function(key)
            self_ref:_on_key(key)
        end,
    })
    self.win = win

    xcb.grab_pointer(self.win.conn, self.win.id)
    self.win:set_input_focus()
end

-- Crea un nuevo nivel a la derecha del item con submenú.
MenuTree:_open_submenu(level_idx, item_idx)
    local parent_level = self.levels[level_idx]
    if not parent_level then return end
    local item = parent_level.items[item_idx]
    if not item or not item.submenu then return end

    -- Cerrar niveles más profundos si existían.
    for i = #self.levels, level_idx + 1, -1 do
        table.remove(self.levels, i)
    end

    -- Calcular posición del nuevo nivel: a la derecha del padre,
    -- alineado con la parte superior del item.
    local _, y1 = item_rect_y(parent_level.items, item_idx)
    local sub_w = measure_items(item.submenu)
    local sub_h = measure_height(item.submenu)

    local nx = parent_level.x + parent_level.w - 4
    local ny = parent_level.y + y1 - ITEM_H
    if ny < 4 then ny = 4 end

    -- Si se sale por la derecha, abrir a la izquierda del padre.
    local parent_w = self.parent_win.width
    if nx + sub_w > parent_w - 4 then
        nx = parent_level.x - sub_w + 4
        if nx < 4 then nx = 4 end
    end

    -- Si se sale por abajo, subir.
    local parent_h = self.parent_win.height
    if ny + sub_h > parent_h - 4 then
        ny = parent_h - sub_h - 4
        if ny < 4 then ny = 4 end
    end

    self.levels[#self.levels + 1] = {
        items = item.submenu,
        x = nx, y = ny, w = sub_w, h = sub_h,
    }
end

-- ── Dibujo ─────────────────────────────────────────────────
function MenuTree:_draw_level(cr, lv)
    local T = self.theme
    local x, y = lv.x - self.win_x, lv.y - self.win_y

    -- Fondo del nivel
    cairo.set_rgb(cr, T.bg_card_rgb[1], T.bg_card_rgb[2],
        T.bg_card_rgb[3])
    cairo.rectangle(cr, x, y, lv.w, lv.h)
    cairo.fill(cr)

    -- Borde
    cairo.set_rgb(cr, T.separator_rgb[1], T.separator_rgb[2],
        T.separator_rgb[3])
    cairo.set_line_width(cr, 1)
    cairo.rectangle(cr, x + 0.5, y + 0.5, lv.w - 1, lv.h - 1)
    cairo.stroke(cr)
end

function MenuTree:_draw_items(cr, lv, level_idx)
    local T = self.theme
    local x0 = lv.x - self.win_x
    local y0 = lv.y - self.win_y

    local cy = y0 + PAD_Y
    for i, it in ipairs(lv.items) do
        if it.sep then
            cairo.set_rgb(cr, T.separator_rgb[1],
                T.separator_rgb[2], T.separator_rgb[3])
            cairo.rectangle(cr, x0 + PAD_X, cy,
                lv.w - PAD_X * 2, 1)
            cairo.fill(cr)
            cy = cy + SEP_H
        else
            local is_hover = self.hover
                and self.hover.level == level_idx
                and self.hover.idx == i
            local is_enabled = it.enabled ~= false

            if is_hover and is_enabled then
                cairo.set_rgba(cr, T.accent_rgb[1], T.accent_rgb[2],
                    T.accent_rgb[3], 0.25)
                cairo.rectangle(cr, x0 + 4, cy, lv.w - 8, ITEM_H)
                cairo.fill(cr)
            end

            local color
            if not is_enabled then
                color = T.muted_rgb
            elseif it.color then
                color = it.color
            else
                color = T.fg_rgb
            end

            local f = it.bold and FONT_BOLD or FONT
            local _, th = pango.measure(it.label or "", f)
            local ty = cy + (ITEM_H - th) / 2
            pango.draw_text(cr, x0 + PAD_X, ty,
                it.label or "", f,
                { r = color[1], g = color[2], b = color[3] })

            -- Chevron si tiene submenú.
            if it.submenu then
                cairo.set_rgb(cr, color[1], color[2], color[3])
                cairo.set_line_width(cr, 1.4)
                local cx = x0 + lv.w - PAD_X - 4
                local ccy = cy + ITEM_H / 2
                cairo.move_to(cr, cx, ccy - 4)
                cairo.line_to(cr, cx + 4, ccy)
                cairo.line_to(cr, cx, ccy + 4)
                cairo.stroke(cr)
            end

            cy = cy + ITEM_H
        end
    end
end

function MenuTree:_draw(cr, cw, ch)
    -- Fondo neutro (por si el bounding box tiene huecos).
    -- No pintamos nada porque cada nivel pinta su propio fondo.

    for level_idx, lv in ipairs(self.levels) do
        -- Primero el fondo del nivel (para tapar los de abajo).
        self:_draw_level(cr, lv)
    end
    -- Después los items de cada nivel, de atrás hacia adelante.
    for level_idx, lv in ipairs(self.levels) do
        self:_draw_items(cr, lv, level_idx)
    end
end

-- ── Hit test ───────────────────────────────────────────────
-- Devuelve { level, idx } o nil si el punto no está en un item.
function MenuTree:_hit(mx, my)
    -- Las coordenadas son relativas a la ventana. Sumar win_x/win_y
    -- para obtenerlas en coordenadas del padre.
    local px = mx + self.win_x
    local py = my + self.win_y

    -- Buscar en niveles de mayor a menor profundidad (el más
    -- profundo se dibuja encima).
    for level_idx = #self.levels, 1, -1 do
        local lv = self.levels[level_idx]
        if px >= lv.x and px < lv.x + lv.w
           and py >= lv.y and py < lv.y + lv.h then
            -- Determinar el item bajo py
            local cy = lv.y + PAD_Y
            for i, it in ipairs(lv.items) do
                local h = it.sep and SEP_H or ITEM_H
                if py >= cy and py < cy + h then
                    if it.sep then return nil end
                    return { level = level_idx, idx = i }
                end
                cy = cy + h
            end
        end
    end
    return nil
end

-- Devuelve el nivel bajo (px, py) o nil.
function MenuTree:_hit_level(mx, my)
    local px = mx + self.win_x
    local py = my + self.win_y
    for level_idx = #self.levels, 1, -1 do
        local lv = self.levels[level_idx]
        if px >= lv.x and px < lv.x + lv.w
           and py >= lv.y and py < lv.y + lv.h then
            return level_idx
        end
    end
    return nil
end

-- ── Eventos ────────────────────────────────────────────────
function MenuTree:_on_mouse_move(mx, my)
    local hit = self:_hit(mx, my)
    local hit_level = self:_hit_level(mx, my)

    -- Actualizar hover.
    local new_hover = hit
    if new_hover ~= self.hover then
        self.hover = new_hover
        -- Si el nuevo hover tiene submenú, abrirlo.
        if new_hover then
            local lv = self.levels[new_hover.level]
            local it = lv and lv.items[new_hover.idx]
            if it and it.submenu then
                -- Cerrar niveles más profundos antes de abrir uno
                -- nuevo.
                for i = #self.levels, new_hover.level + 1, -1 do
                    table.remove(self.levels, i)
                end
                self:_open_submenu(new_hover.level, new_hover.idx)
                -- Recrear la ventana para que el bounding box
                -- incluya el nuevo nivel.
                self:_create_window()
                return
            end
        end
        -- Si el nuevo hover no tiene submenú, cerrar niveles más
        -- profundos si el mouse no está sobre uno de ellos.
        if new_hover then
            for i = #self.levels, new_hover.level + 1, -1 do
                if not hit_level or i > hit_level then
                    table.remove(self.levels, i)
                end
            end
            if #self.levels > 1 then
                self:_create_window()
            end
        end
        if self.win then
            self.win:damage_all()
        end
    end

    -- Si el mouse está fuera de todos los niveles, no cerrar.
    -- El click fuera se encarga de cerrar. Esto es intencional
    -- para permitir llegar a los submenús sin cerrar el padre.
    if not hit and not hit_level then
        -- Solo cerrar niveles más profundos si el mouse está en un
        -- nivel anterior al más profundo.
        -- Por ahora no hacemos nada: el click fuera cierra.
    end
end

function MenuTree:_on_mouse(mx, my, button)
    if button ~= 1 then return end

    local hit = self:_hit(mx, my)
    if not hit then
        -- Click fuera: cerrar todo.
        self:close()
        return
    end

    local lv = self.levels[hit.level]
    local it = lv and lv.items[hit.idx]
    if not it or it.enabled == false then return end
    if it.submenu then
        -- Click sobre un item con submenú: nada (se abre por hover).
        return
    end
    if it.on_click then
        self:close()
        it.on_click()
    end
end

function MenuTree:_on_key(key)
    if not key.pressed then return end
    if key.name == "Escape" then
        self:close()
    end
end

M.new = function(srv, parent_win, theme)
    return MenuTree.new(srv, parent_win, theme)
end

return M
