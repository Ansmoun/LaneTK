-- Motor de barra. Portado de ui/bar.lua (Awesome).
-- Lee una spec puro dato, monta el arbol de widgets, y aplica
-- separadores segun el modo declarado.

local W = require("lib.widgets")
local Sep = require("lib.bar.separators")
local log = require("lib.log")

local M = {}


-- Normaliza una entrada de lista (string o toggle_group).
local function normalize_entry(entry)
    if type(entry) == "string" then
        return { kind = "widget", name = entry }
    end
    if type(entry) == "table" and entry.toggle_group then
        return {
            kind = "group",
            group = entry.toggle_group,
            default = entry.default or "visible",
            widgets = entry.widgets or {},
        }
    end
    return nil
end

local function flatten_list(list)
    local out = {}
    local groups = {}
    for _, entry in ipairs(list or {}) do
        local e = normalize_entry(entry)
        if e and e.kind == "widget" then
            out[#out + 1] = { name = e.name, group = nil }
        elseif e and e.kind == "group" then
            groups[e.group] = {
                default = e.default,
                visible = (e.default == "visible"),
            }
            for _, wname in ipairs(e.widgets) do
                out[#out + 1] = { name = wname, group = e.group }
            end
        end
    end
    return out, groups
end

-- Construye un lado (left/center/right) segun el modo de separador.
local function build_side(theme, list, registry, groups, opts)
    opts = opts or {}
    local sep_style = opts.separator or "arrow"
    local gap       = opts.gap or 12
    local bar_h     = opts.bar_h or 22

    local T       = theme or {}
    local bg_hex  = T.bg_rgb and Sep.rgb_to_hex(T.bg_rgb) or "#000000"
    local sep_col = T.separator or "#333333"

    local children = {}
    local instances = {}
    local current_color = bg_hex

    local function insert_separator(prev_color, next_color)
        if sep_style == "arrow" then
            children[#children + 1] = {
                widget = Sep.ArrowSep.new(prev_color, next_color, T),
                weight = 0,
            }
        elseif sep_style == "glyph" then
            children[#children + 1] = {
                widget = Sep.GlyphSep("│", sep_col, T.font),
                weight = 0,
            }
        elseif sep_style == "glyph_thick" then
            children[#children + 1] = {
                widget = Sep.GlyphSep("┃", sep_col, T.font),
                weight = 0,
            }
        elseif sep_style == "gap" then
            children[#children + 1] = {
                widget = Sep.GapSep(gap),
                weight = 0,
            }
        end
        -- "none", "underline", "island" no insertan separador.
    end

    local function emit(name, wrapper)
        -- El color viene del constructor. Si no lo da, el widget
        -- va con fondo transparente (bg_hex del theme).
        local color = wrapper.color

        local widget = wrapper.widget or wrapper
        local set_fg = wrapper.set_fg

        -- Calcular el fg del widget segun el color del fondo.
        local widget_fg
        if sep_style == "underline" then
            widget_fg = T.fg_normal or "#FEFEFE"
        elseif color then
            widget_fg = Sep.pick_fg(color)
        else
            widget_fg = T.fg_normal or "#FEFEFE"
        end
        if set_fg then set_fg(widget_fg) end

        -- Modo underline: envolver con subrayado, sin separadores.
        if sep_style == "underline" then
            children[#children + 1] = {
                widget = Sep.UnderlineBox(widget, color),
                weight = 0,
            }
            return
        end

        -- Modo island: envolver con fondo redondeado.
        if sep_style == "island" then
            children[#children + 1] = {
                widget = Sep.IslandBox(widget, color, 4),
                weight = 0,
            }
            return
        end

        -- Modos con fondo por widget (arrow, glyph, gap, none).
        if color then
            if current_color ~= color then
                insert_separator(current_color, color)
            end
            children[#children + 1] = {
                widget = Sep.ColorBox(widget, color),
                weight = 0,
            }
            current_color = color
        else
            if current_color ~= bg_hex then
                insert_separator(current_color, "alpha")
            end
            children[#children + 1] = {
                widget = widget,
                weight = 0,
            }
            current_color = bg_hex
        end
    end

    -- Para modos sin sistema de color, insertar gaps simples entre
    -- todos los widgets (none y modos sin separadores).
    local simple_gap_mode = (sep_style == "none")

    for _, item in ipairs(list) do
        local ctor = registry[item.name]
        if not ctor then
            log.warn("bar", "constructor no encontrado: %s", item.name)
        else
            local ok, res = pcall(ctor, theme)
            if not ok or not res then
                log.error("bar", "constructor %s fallo: %s",
                    item.name, tostring(res))
            else
                instances[item.name] = res

                -- Visibilidad por grupo
                local visible = true
                if item.group then
                    local g = groups[item.group]
                    if g and not g.visible then visible = false end
                end

                if visible then
                    -- Gap simple para modo "none" (o "arrow" sin
                    -- color de telemetria, cuando no cambia).
                    if #children > 0 and simple_gap_mode and gap > 0 then
                        children[#children + 1] = {
                            widget = Sep.GapSep(gap),
                            weight = 0,
                        }
                    end

                    -- Normalizar el resultado del constructor
                    local wrapper
                    if type(res) == "table" and res.widget then
                        wrapper = res
                    else
                        wrapper = { widget = res }
                    end

                    emit(item.name, wrapper)
                end
            end
        end
    end

    local grp = W.Group.new {
        orientation = "horizontal",
        spacing = 0,
        padding = 0,
        children = children,
    }
    return { group = grp, instances = instances }
end

-- Ajusta el alto de la barra segun el modo de separador.
function M.adjust_height(base_h, sep_style)
    if sep_style == "underline" then return base_h + 6 end
    if sep_style == "island"    then return base_h + 8 end
    return base_h
end

-- Monta la barra completa.
function M.build(theme, spec, registry)
    spec = spec or {}
    local sep_style = spec.separator or "arrow"
    local base_h    = spec.height or 22
    local bar_h     = M.adjust_height(base_h, sep_style)
    local gap       = spec.gap or 12

    local left_list,  left_groups  = flatten_list(spec.left)
    local center_list, center_groups = flatten_list(spec.center)
    local right_list, right_groups = flatten_list(spec.right)

    local groups = {}
    for k, v in pairs(left_groups)   do groups[k] = v end
    for k, v in pairs(center_groups) do groups[k] = v end
    for k, v in pairs(right_groups)  do groups[k] = v end

    local side_opts = {
        separator = sep_style,
        gap = gap,
        bar_h = bar_h,
    }

    local left_b   = build_side(theme, left_list,   registry, groups, side_opts)
    local center_b = build_side(theme, center_list, registry, groups, side_opts)
    local right_b  = build_side(theme, right_list,  registry, groups, side_opts)

    local root = W.Group.new {
        orientation = "horizontal",
        spacing = 0,
        padding = 0,
        children = {
            { widget = left_b.group,   weight = 0 },
            { widget = center_b.group, weight = 1 },
            { widget = right_b.group,  weight = 0 },
        },
    }

    local instances = {}
    for k, v in pairs(left_b.instances)   do instances[k] = v end
    for k, v in pairs(center_b.instances) do instances[k] = v end
    for k, v in pairs(right_b.instances)  do instances[k] = v end

    return {
        widget = root,
        height = bar_h,
        sep_style = sep_style,
        groups = groups,
        instances = instances,
    }
end

return M
