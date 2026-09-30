-- TabbedPanel: TabsBar + Stack con lazy loading.
-- Sin close button (el WM o Esc se encargan). Sin padding (el
-- consumidor decide). Spacing minimo para que los tabs anidados
-- no acumulen huecos.

local Area  = require("lib.area")
local Group = require("lib.widgets.group")
local Stack = require("lib.widgets.stack")
local TabsBar = require("lib.widgets.tabsbar")
local Intro   = require("lib.widgets.intro")
local log   = require("lib.log")

local TabbedPanel = setmetatable({}, { __index = Area })
TabbedPanel.__index = TabbedPanel

function TabbedPanel.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), TabbedPanel)

    self.tabs = opts.tabs or {}
    self.tabs_by_id = {}
    for _, t in ipairs(self.tabs) do
        self.tabs_by_id[t.id] = t
    end
    self.loaded = {}
    self.active_id = nil
    self.bg = opts.bg

    self.anim = opts.anim or false
    self.anim_duration = opts.anim_duration or 300
    self.anim_fps = opts.anim_fps or 30

    -- TabsBar
    local items = {}
    for _, t in ipairs(self.tabs) do
        items[#items + 1] = { id = t.id, label = t.label, icon = t.icon }
    end
    local tb_opts = opts.tabsbar_opts or {}
    tb_opts.items = items
    tb_opts.active = self.tabs[1] and self.tabs[1].id or nil
    tb_opts.on_select = function(id) self:set_tab(id) end
    if opts.theme then tb_opts.theme = opts.theme end
    if opts.compact ~= nil then tb_opts.compact = opts.compact end
    self.tabsbar = TabsBar.new(tb_opts)

    -- Stack
    self.stack = Stack.new {}

    -- Group raiz: spacing minimo. El consumidor puede ajustar con
    -- opts.spacing pero el default es 6 para minimizar el hueco
    -- entre tabs anidados.
    self.group = Group.new {
        orientation = "vertical",
        spacing = opts.spacing or 6,
        padding = 0,
        children = {
            { widget = self.tabsbar, weight = 0 },  -- solo su minimo
            { widget = self.stack,   weight = 1 },  -- todo el resto
        },
    }

    return self
end

function TabbedPanel:_stop_active()
    if self.active_id and self.loaded[self.active_id] then
        local tab = self.loaded[self.active_id]
        if tab.stop then
            local ok, err = pcall(tab.stop)
            if not ok then
                log.error("tabbed", "stop() de '%s' fallo: %s",
                    self.active_id, tostring(err))
            end
        end
    end
end

function TabbedPanel:set_tab(id)
    if self.active_id == id then return end
    local entry = self.tabs_by_id[id]
    if not entry then return end

    self:_stop_active()

    local tab = self.loaded[id]
    if not tab then
        log.info("tabbed", "cargando '%s' (lazy)", id)
        local ok, result = pcall(entry.factory)
        if not ok then
            log.error("tabbed", "factory de '%s' fallo: %s",
                id, tostring(result))
            return
        end
        tab = result
        self.loaded[id] = tab
        self.stack:add(id, tab.widget)
    end

    if tab.start then
        local ok, err = pcall(tab.start)
        if not ok then
            log.error("tabbed", "start() de '%s' fallo: %s",
                id, tostring(err))
        end
    end

    -- Cancelar los tweens del intro del tab viejo antes de resetear
    -- el nuevo. Sin esto, si el usuario cambia de tab mientras una
    -- animacion de entrada esta corriendo, los tweens del tab viejo
    -- siguen dañando rects que ya no estan en pantalla y el sistema
    -- de tabs/subtabs se ve roto por unos segundos.
    if self.active_id and self.stack.pages[self.active_id] then
        Intro.cancel(self.stack.pages[self.active_id])
    end

    -- Resetear las animaciones de entrada del tab nuevo antes de
    -- activarlo. Asi, si el tab ya se activo antes, sus widgets
    -- vuelven al estado inicial y la animacion de entrada se ve de
    -- nuevo. Si el motor no esta listo o animate_widgets = false,
    -- Intro.reset es no-op.
    Intro.reset(tab.widget)

    -- Animación de crossfade si está habilitada y el motor listo.
    if self.anim and self.active_id and self.window then
        local anim = require("lib.anim")
        if anim.is_ready() then
            -- Snapshot del contenido, NO del TabsBar. Si el
            -- snapshot incluye el TabsBar, el overlay lleva una
            -- foto del TabsBar con el active VIEJO y lo tapa
            -- durante todo el fade. El árbol dibuja el TabsBar
            -- actualizado, pero el overlay lo pisa.
            local old_area = self.stack
            if old_area and old_area.x1 > old_area.x0
               and old_area.y1 > old_area.y0 then
                self.active_id = id
                anim.crossfade(
                    self.window,
                    old_area,
                    function() self.stack:set_active(id) end,
                    self.anim_duration,
                    {
                        fps = self.anim_fps,
                        extra_damage_area = self,
                        -- El intro corre al terminar el crossfade,
                        -- no durante: los dos efectos se verian
                        -- cargados y el overlay taparia las
                        -- animaciones de entrada.
                        on_done = function()
                            Intro.play(tab.widget)
                        end,
                    }
                )
                return
            end
        end
    end
    self.stack:set_active(id)
    self.active_id = id
    Intro.play(tab.widget)
end

function TabbedPanel:get_tab(id)  return self.loaded[id] end
function TabbedPanel:get_active() return self.active_id end

function TabbedPanel:stop()
    self:_stop_active()
end

function TabbedPanel:set_window(win)
    self.window = win
    self.group:set_window(win)
    if self.active_id == nil and self.tabs[1] then
        self:set_tab(self.tabs[1].id)
    end
end

function TabbedPanel:askMinMax(minw, minh, maxw, maxh)
    return self.group:askMinMax(minw, minh, maxw, maxh)
end

function TabbedPanel:layout(x0, y0, x1, y1)
    Area.layout(self, x0, y0, x1, y1)
    self.group:layout(x0, y0, x1, y1)
end

function TabbedPanel:draw(cr)
    if self.bg then
        local cairo = require("lib.cairo")
        cairo.set_rgb(cr, self.bg[1], self.bg[2], self.bg[3])
        cairo.paint(cr)
    end
    -- Delegar el chequeo de should_draw al Group interno. El
    -- TabbedPanel en si siempre se "dibuja" (el fondo), pero los
    -- hijos se filtran.
    self.group:draw(cr)
end

function TabbedPanel:getByXY(x, y)
    local hit = self.group:getByXY(x, y)
    if hit then return hit end
    if x >= self.x0 and x < self.x1 and y >= self.y0 and y < self.y1 then
        return self
    end
    return nil
end

return TabbedPanel
