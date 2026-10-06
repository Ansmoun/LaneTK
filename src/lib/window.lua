local ffi = require("ffi")
local bit = require("bit")
local xcb    = require("lib.xcb")
local cairo  = require("lib.cairo")
local Server = require("lib.server")
local log    = require("lib.log")
local xkb    = require("lib.xkb")

local Window = {}

Window.__index = Window

local function resolve_size(spec, screen_dim, fallback)
    if spec == nil then return fallback end
    if type(spec) == "number" then return math.floor(spec) end
    if spec == "screen" then return screen_dim end
    if spec == "auto"   then return nil end
    if spec == "free"   then return 0 end
    if type(spec) == "string" then
        local pct = spec:match("^(%d+)%%$")
        if pct then return math.floor(screen_dim * tonumber(pct) / 100) end
    end
    error("Window: especificacion de tamano desconocida: " .. tostring(spec))
end

local function resolve_position(spec, screen_dim, win_dim)
    if spec == nil then return 0 end
    if type(spec) == "number" then return math.floor(spec) end
    if spec == "center" then return math.floor((screen_dim - win_dim) / 2) end
    if spec == "auto" then return 0 end
    error("Window: especificacion de posicion desconocida: " .. tostring(spec))
end

-- Calcula la posicion centrada en el monitor del cursor. Devuelve
-- (x, y) en coordenadas de pantalla absoluta.
local function resolve_cursor_screen_center(conn, win_w, win_h)
    local screens = require("lib.screens")
    local cx, cy = xcb.query_pointer(conn)
    if not cx then
        -- Fallback: centro de la pantalla virtual
        local screen = xcb.get_screen(conn, 0)
        return math.floor((screen.width_in_pixels - win_w) / 2),
               math.floor((screen.height_in_pixels - win_h) / 2)
    end
    local mon = screens.at(cx, cy)
    return mon.x + math.floor((mon.w - win_w) / 2),
           mon.y + math.floor((mon.h - win_h) / 2)
end

local function ratio_to_fraction(r)
    if r <= 0 then error("Window: aspect debe ser positivo") end
    local num = math.floor(r * 1000 + 0.5)
    local den = 1000
    local function gcd(a, b) while b ~= 0 do a, b = b, a % b end return a end
    local g = gcd(num, den)
    return num / g, den / g
end

local WINDOW_TYPE_BY_KIND = {
    normal  = "_NET_WM_WINDOW_TYPE_NORMAL",
    dock    = "_NET_WM_WINDOW_TYPE_DOCK",
    dialog  = "_NET_WM_WINDOW_TYPE_DIALOG",
    menu    = "_NET_WM_WINDOW_TYPE_MENU",
    desktop = "_NET_WM_WINDOW_TYPE_DESKTOP",
}

function Window.new(a, b)
    local server, opts
    if type(a) == "table" and a.conn and a.windows then
        server, opts = a, b or {}
    else
        server = Server.new()
        opts = a or {}
    end

    local self = setmetatable({}, Window)
    self.server = server
    self.opts = opts
    self.conn = server.conn
    self.screen = server.screen
    self.visualtype = server.visualtype
    self.atoms = server.atoms

    local sw = server.screen.width_in_pixels
    local sh = server.screen.height_in_pixels

    local w = resolve_size(opts.width, sw, 400)
    local h = resolve_size(opts.height, sh, 300)

    if w == nil or h == nil then
        local mw, mh = 200, 100
        if opts.on_measure then mw, mh = opts.on_measure() end
        if w == nil then w = mw end
        if h == nil then h = mh end
    end

    if opts.aspect then
        if type(opts.width) == "number" and type(opts.height) ~= "number" then
            h = math.floor(w / opts.aspect)
        elseif type(opts.height) == "number" and type(opts.width) ~= "number" then
            w = math.floor(h * opts.aspect)
        end
    end

    local function resolve_bound(spec, screen_dim)
        if spec == nil then return 0 end
        if type(spec) == "number" then return math.floor(spec) end
        if spec == "screen" then return screen_dim end
        if spec == "free" then return 0 end
        error("Window: bound desconocido: " .. tostring(spec))
    end

    local min_w = resolve_bound(opts.min_width,  sw)
    local min_h = resolve_bound(opts.min_height, sh)
    local max_w = resolve_bound(opts.max_width,  sw)
    local max_h = resolve_bound(opts.max_height, sh)

    if min_w > 0 and w < min_w then w = min_w end
    if min_h > 0 and h < min_h then h = min_h end
    if max_w > 0 and w > max_w then w = max_w end
    if max_h > 0 and h > max_h then h = max_h end

    local x, y
    if opts.x == "cursor-screen" or opts.y == "cursor-screen" then
        x, y = resolve_cursor_screen_center(self.conn, w, h)
    else
        x = resolve_position(opts.x, sw, w)
        y = resolve_position(opts.y, sh, h)
    end
    self.width, self.height = w, h
    self.x, self.y = x, y

    local event_mask = opts.event_mask or bit.bor(
        xcb.EVENT_MASK.Exposure,
        xcb.EVENT_MASK.KeyPress,
        xcb.EVENT_MASK.KeyRelease,
        xcb.EVENT_MASK.ButtonPress,
        xcb.EVENT_MASK.ButtonRelease,
        xcb.EVENT_MASK.PointerMotion,
        xcb.EVENT_MASK.EnterWindow,
        xcb.EVENT_MASK.LeaveWindow,
        xcb.EVENT_MASK.StructureNotify,
        xcb.EVENT_MASK.PropertyChange
    )

    local is_child = (opts.kind == "child" and opts.parent_window ~= nil)
    local is_transient = (opts.kind == "transient" and opts.parent_window ~= nil)
    local override = opts.override_redirect
    if override == nil then
        override = (opts.kind == "menu" or opts.kind == "desktop") or is_child
    end
    local kind = opts.kind or "normal"

    -- Para child: parent es la ventana padre (X11 child window).
    -- Para el resto: parent es root.
    local xcb_parent = nil
    if is_child then
        xcb_parent = tonumber(opts.parent_window.id)
    end

    local wid, _screen, cerr = xcb.create_window(self.conn, {
        width = w, height = h,
        x = x, y = y,
        parent = xcb_parent,
        event_mask = event_mask,
        override_redirect = override,
        background_pixmap = opts.background_pixmap,
        background_pixel  = opts.background_pixel,
        backing_store     = opts.backing_store,
    })
    if wid == nil then
        log.error("window", "create_window fallo: %s", cerr or "(sin detalle)")
        log.error("window", "  parent=%s visual=0x%x depth=%d",
            xcb_parent and string.format("0x%x", xcb_parent) or "root",
            tonumber(self.screen.root_visual), self.screen.root_depth)
        error("Window.new: no se pudo crear la ventana X11: " .. (cerr or "?"))
    end
    self.id = wid
    log.info("window", "creada id=0x%x %dx%d+%d+%d kind=%s",
        tonumber(wid), w, h, x, y, opts.kind or "normal")

    local hints_flags = 0
    local hints = {}
    if min_w > 0 or min_h > 0 then
        hints_flags = bit.bor(hints_flags, xcb.ICCCM.P_MIN_SIZE)
        hints.min_width  = min_w
        hints.min_height = min_h
    end
    if max_w > 0 or max_h > 0 then
        hints_flags = bit.bor(hints_flags, xcb.ICCCM.P_MAX_SIZE)
        hints.max_width  = max_w
        hints.max_height = max_h
    end
    if opts.aspect then
        hints_flags = bit.bor(hints_flags, xcb.ICCCM.P_ASPECT)
        local num, den = ratio_to_fraction(opts.aspect)
        hints.min_aspect_num = num
        hints.min_aspect_den = den
        hints.max_aspect_num = num
        hints.max_aspect_den = den
    end
    hints.flags = hints_flags
    if hints_flags ~= 0 then
        xcb.set_wm_normal_hints(self.conn, wid, hints)
    end

    -- Una ventana desktop nunca debe recibir foco de teclado.
    local wants_input = (kind ~= "desktop")
    xcb.set_wm_hints(self.conn, wid, {
        flags = xcb.ICCCM.WM_HINT_INPUT,
        input = wants_input,
    })

    local instance = opts.app_name   or "lanetk"
    local class    = opts.class_name or "LaneTK"
    local buf = ffi.new("uint8_t[?]", #instance + 1 + #class + 1)
    ffi.copy(buf, instance, #instance)
    buf[#instance] = 0
    ffi.copy(buf + #instance + 1, class, #class)
    buf[#instance + 1 + #class] = 0
    xcb.change_property(self.conn, wid,
        self.atoms.WM_CLASS, self.atoms.STRING, 8,
        #instance + 1 + #class + 1, buf)

    -- Si es child o transient y hay parent_window, marcar la relacion.
    local parent_win = opts.parent_window
    if (kind == "child" or kind == "transient") and parent_win then
        local parent_id = tonumber(parent_win.id)
        local transient_atom = xcb.intern_atom(self.conn, "WM_TRANSIENT_FOR")
        local arr = ffi.new("uint32_t[1]", parent_id)
        xcb.change_property(self.conn, wid,
            transient_atom, 4, 32, 1, arr)
        self.parent_window = parent_win
    end

    -- Child/transient no llevan _NET_WM_WINDOW_TYPE.
    -- El WM las ignora igual.
    if kind ~= "child" then
        local type_atom_name = WINDOW_TYPE_BY_KIND[kind]
        if type_atom_name then
            local type_atom = self.atoms[type_atom_name]
            if type_atom and type_atom ~= 0 then
                local arr = ffi.new("uint32_t[1]", type_atom)
                xcb.change_property(self.conn, wid,
                    self.atoms._NET_WM_WINDOW_TYPE, 4, 32, 1, arr)
            end
        end
    end

    if opts.title then
        local bytes = ffi.cast("const uint8_t*", opts.title)
        xcb.change_property(self.conn, wid,
            self.atoms._NET_WM_NAME, self.atoms.UTF8_STRING, 8,
            #opts.title, bytes)
        xcb.change_property(self.conn, wid,
            self.atoms.WM_NAME, self.atoms.STRING, 8,
            #opts.title, bytes)
    end

    local proto_arr = ffi.new("uint32_t[1]", self.atoms.WM_DELETE_WINDOW)
    xcb.change_property(self.conn, wid,
        self.atoms.WM_PROTOCOLS, 4, 32, 1, proto_arr)

    -- STRUT: reserva espacio en el borde de la pantalla. Necesario
    -- para dock windows (barras). Sin esto, el WM deja que las
    -- ventanas normales se solapen con la barra.
    -- opts.strut = { left = N, right = N, top = N, bottom = N,
    --                left_start_y, left_end_y, right_start_y,
    --                right_end_y, top_start_x, top_end_x,
    --                bottom_start_x, bottom_end_x }
    -- Los *_start/end son opcionales; sin ellos se usa 0, screen_h-1
    -- (o screen_w-1 para top/bottom).
    if opts.strut then
        local s = opts.strut
        local l = s.left   or 0
        local r = s.right  or 0
        local t = s.top    or 0
        local b = s.bottom or 0

        local sw = self.screen.width_in_pixels
        local sh = self.screen.height_in_pixels

        -- STRUT simple (4 valores, formato antiguo).
        local simple = ffi.new("uint32_t[4]", l, r, t, b)
        xcb.change_property(self.conn, wid,
            self.atoms._NET_WM_STRUT, 6, 32, 4, simple)

        -- STRUT_PARTIAL (12 valores): reserva solo el rango
        -- *_start..*_end en cada borde. Necesario en multi-monitor
        -- para que el WM solo reserve en la zona correcta.
        local partial = ffi.new("uint32_t[12]",
            l, r, t, b,
            s.left_start_y   or 0, s.left_end_y   or (sh - 1),
            s.right_start_y  or 0, s.right_end_y  or (sh - 1),
            s.top_start_x    or 0, s.top_end_x    or (sw - 1),
            s.bottom_start_x or 0, s.bottom_end_x or (sw - 1))
        xcb.change_property(self.conn, wid,
            self.atoms._NET_WM_STRUT_PARTIAL, 6, 32, 12, partial)
    end

    xcb.map_window(self.conn, wid)

    -- Sincronizar con el servidor: garantiza que la ventana esta
    -- mapeada ANTES de dibujar. Sin esto, el primer draw() escribe
    -- a una ventana aun no mapeada y X descarta los pixeles.
    xcb.sync(self.conn)

    -- X11 surface (destino final) + contexto para el blit.
    self.surface = cairo.surface_for_window(self.conn, wid,
                                            self.visualtype, w, h)
    self.cr = cairo.context(self.surface)

    -- Backing store: imagen offscreen donde dibujan los widgets.
    -- Se blitea a self.surface por regiones dañadas.
    self.image_surface = cairo.image_surface_create(w, h, cairo.FORMAT.RGB24)
    self.image_cr = cairo.context(self.image_surface)

    self.xkb = xkb.new_state()

    self.hover_element  = nil
    self.active_element = nil

    self.damage_list = {}
    self.overlay = nil
    self.force_redraw = true

    self.running = true
    self.destroyed = false

    -- Primer draw. Sin esto, ventanas sin set_root (solo on_draw)
    -- tampoco se pintarian hasta el primer Expose.
    if opts.on_draw or self.root then
        self:draw()
    end

    server:add_window(self)
    return self
end

function Window:set_root(area)
    self.root = area
    if area.set_window then
        area:set_window(self)
    else
        area.window = self
    end
    self:_relayout()
    -- Forzar un draw inmediato. Sin esto, la ventana queda sin
    -- contenido hasta que llegue un Expose, que para child windows
    -- puede no llegar nunca (sobre todo si el WM reparenta).
    self:draw()
end

function Window:_relayout()
    if not self.root then return end
    self.root:askMinMax(0, 0, 0, 0)
    self.root:layout(0, 0, self.width, self.height)
end

function Window:set_input_focus()
    -- Guardar la ventana con foco actual para poder restaurarla al
    -- cerrar. Solo la primera vez que pedimos foco.
    if not self._prev_focus then
        self._prev_focus = xcb.get_input_focus(self.conn)
    end
    xcb.set_input_focus(self.conn, self.id)
end

function Window:restore_input_focus()
    if self._prev_focus and self._prev_focus ~= 0 then
        xcb.set_input_focus(self.conn, self._prev_focus)
        self._prev_focus = nil
    else
        -- Fallback: devolver el foco al root con RevertToParent.
        xcb.set_input_focus_revert(self.conn)
    end
end

function Window:restore_parent_focus()
    if self.parent_window then
        self.parent_window:set_input_focus()
    end
end

-- Mueve la ventana a la posicion (x, y). Para top-level es una
-- peticion al WM (que puede honrarla o no). Para child es una
-- orden directa al servidor: se aplica inmediatamente.
function Window:move(x, y)
    x = math.floor(x)
    y = math.floor(y)
    if x == self.x and y == self.y then return end
    self.x, self.y = x, y
    xcb.configure_window(self.conn, self.id,
        xcb.CONFIG.X + xcb.CONFIG.Y,
        { x = x, y = y })
    xcb.flush(self.conn)
end

-- Mueve la ventana relativa a su posicion actual.
function Window:move_by(dx, dy)
    self:move(self.x + dx, self.y + dy)
end

function Window:set_title(title)
    local bytes = ffi.cast("const uint8_t*", title)
    xcb.change_property(self.conn, self.id,
        self.atoms._NET_WM_NAME, self.atoms.UTF8_STRING, 8, #title, bytes)
    xcb.change_property(self.conn, self.id,
        self.atoms.WM_NAME, self.atoms.STRING, 8, #title, bytes)
    xcb.flush(self.conn)
end

function Window:add_damage(x0, y0, x1, y1)
        self.damage_list[#self.damage_list + 1] = { x0, y0, x1, y1 }
end

function Window:damage_all()
    self.force_redraw = true
    self.damage_list = {}
end

-- Fusiona los rects de damage y devuelve el area de la union
-- (sin contar solapamientos). Algoritmo simple: dividir el area
-- total en una grilla gruesa y marcar celdas cubiertas.
-- La grilla es 16x16 celdas. Precision suficiente para decidir
-- entre "partial" y "full" sin gastar CPU.
local GRID = 16
function Window:_damage_union_ratio()
    if #self.damage_list == 0 then return 0 end
    if #self.damage_list == 1 then
        local r = self.damage_list[1]
        return ((r[3] - r[1]) * (r[4] - r[2])) / (self.width * self.height)
    end

    local gw = self.width / GRID
    local gh = self.height / GRID
    local covered = 0
    -- Tabla de celdas cubiertas
    local cells = {}
    for _, r in ipairs(self.damage_list) do
        local c0 = math.floor(r[1] / gw)
        local c1 = math.floor((r[3] - 1) / gw)
        local r0 = math.floor(r[2] / gh)
        local r1 = math.floor((r[4] - 1) / gh)
        if c0 < 0 then c0 = 0 end
        if r0 < 0 then r0 = 0 end
        if c1 >= GRID then c1 = GRID - 1 end
        if r1 >= GRID then r1 = GRID - 1 end
        for cy = r0, r1 do
            for cx = c0, c1 do
                local key = cy * GRID + cx
                if not cells[key] then
                    cells[key] = true
                    covered = covered + 1
                end
            end
        end
    end
    return covered / (GRID * GRID)
end

function Window:_damage_covers_most()
    if self.force_redraw then return true end
    -- Si hay overlay, full redraw SIEMPRE. El overlay se compone
    -- sobre el contenido limpio del arbol y no tiene sentido
    -- clipear parcialmente: si el rect del overlay no cubre todo
    -- el arbol, should_draw filtra widgets fuera del damage (por
    -- ejemplo el TabsBar encima del Stack) y esos widgets NO se
    -- redibujan al image_surface. El resultado es que se ven los
    -- pixeles del frame anterior en esa zona. Este era el bug del
    -- sub-TabsBar en pantallas grandes.
    if self.overlay then return true end
    if #self.damage_list == 0 then return false end
    -- Solo medir el area de la union. El count ya no importa: una
    -- rafaga de MotionNotify puede generar 30 rects pequeños que
    -- juntos no cubren ni el 10% del panel. Decidir full redraw
    -- por count es un error.
    return self:_damage_union_ratio() > 0.8
end

function Window:_apply_clip(cr)
    cairo.new_path(cr)
    for _, r in ipairs(self.damage_list) do
        cairo.rectangle(cr, r[1], r[2], r[3] - r[1], r[4] - r[2])
    end
    cairo.clip(cr)
end


-- Overlay: un surface dibujado ENCIMA del árbol. Uso típico: crossfade
-- de tabs. Mientras hay overlay, el draw siempre es full (no hay clip
-- parcial), así que el overlay se compone sobre el contenido limpio.
-- Overlay: un surface dibujado ENCIMA del árbol. Uso típico: crossfade
-- de tabs. Añade el rect del overlay al damage_list para que el
-- próximo draw lo repinte junto con el resto. NO limpia la lista,
-- para no perder los damage que otros widgets (por ejemplo el
-- TabsBar) hayan añadido justo antes.
function Window:set_overlay(surface, x, y, alpha)
    self.overlay = {
        surface = surface,
        x = x or 0,
        y = y or 0,
        alpha = alpha or 1.0,
    }
    local cairo = require("lib.cairo")
    local w = cairo.surface_width(surface)
    local h = cairo.surface_height(surface)
    self:add_damage(self.overlay.x, self.overlay.y,
                    self.overlay.x + w, self.overlay.y + h)
end

function Window:clear_overlay()
    self.overlay = nil
    self:damage_all()
end

-- Redibuja solo si hay damage. Renderiza al backing store offscreen
-- y luego blitea la region dañada a X11 en una sola operacion. Esto
-- elimina el parpadeo de "dibujar base, luego contenido".
function Window:draw()
    -- Flag de relayout pendiente
    if self._needs_relayout then
        self._needs_relayout = false
        self:_relayout()
        self.force_redraw = true
        self.damage_list = {}
    end

    -- Relayout silencioso: recalcula rects pero NO toca force_redraw
    -- ni damage_list. Lo usan los widgets que cambian de tamano
    -- mientras otros ya acumularon damage. Sin esto, cualquier
    -- animacion de tamanio obliga a un full redraw de toda la
    -- ventana en cada frame.
    if self._pending_relayout_silent then
        self._pending_relayout_silent = false
        self:_relayout()
    end

    if not self.force_redraw and #self.damage_list == 0 then
        return
    end

    -- full = true SOLO cuando force_redraw esta activo. El criterio
    -- anterior (_damage_covers_most) causaba stale pixels: cuando el
    -- damage cubria >80%, full=true, se llamaba a on_draw sin clip
    -- (pintaba TODO el fondo del image_surface con el color de
    -- fondo), pero should_draw seguia filtrando los widgets fuera
    -- del damage_list (por ejemplo el TabsBar). El image_surface
    -- quedaba con el fondo en esas zonas, el blit full copiaba eso
    -- al X11, y como el damage no cambiaba en los frames siguientes
    -- el TabsBar quedaba negro permanente hasta que un hover dañaba
    -- su rect.
    --
    -- Regla: full=true solo cuando force_redraw tambien lo es, porque
    -- es la unica condicion en la que should_draw devuelve true para
    -- TODO el arbol. En cualquier otro caso, full=false, clip al
    -- damage, on_draw solo pinta la zona dañada, y los widgets fuera
    -- del damage conservan sus pixeles del frame anterior (que son
    -- correctos porque no cambiaron).
    local full = self.force_redraw

    self._in_draw = true

    -- 1) Render al backing store
    local cr = self.image_cr
    cairo.save(cr)
    if not full then
        self:_apply_clip(cr)
    end
    if self.opts.on_draw then
        self.opts.on_draw(cr, self.width, self.height)
    end
    if self.root then
        self.root:draw(cr)
    end

    if self.overlay then
        local ov = self.overlay
        cairo.save(cr)
        cairo.set_operator(cr, cairo.OPERATOR.OVER)
        cairo.set_source_surface(cr, ov.surface, ov.x, ov.y)
        cairo.paint_with_alpha(cr, ov.alpha)
        cairo.restore(cr)
    end

    cairo.restore(cr)
    cairo.flush_surface(self.image_surface)

    -- 2) Blit al surface X11 (solo la region dañada)
    local cr2 = self.cr
    cairo.save(cr2)
    cairo.set_operator(cr2, cairo.OPERATOR.SOURCE)
    cairo.set_source_surface(cr2, self.image_surface, 0, 0)
    if not full then
        self:_apply_clip(cr2)
    end
    cairo.paint(cr2)
    cairo.restore(cr2)

    self.damage_list = {}
    self.force_redraw = false
    self._in_draw = false
    -- Si durante el draw alguien pidio relayout, dejarlo armado
    -- para el proximo ciclo.
    if self._pending_relayout then
        self._pending_relayout = false
        self._needs_relayout = true
    end

    cairo.flush_surface(self.surface)
    xcb.flush(self.conn)
end

function Window:close(reason)
    if self.destroyed then return end
    log.info("window", "close id=0x%x (razon: %s)",
        tonumber(self.id), reason or "manual")
    if self.opts.on_close then self.opts.on_close() end
    self.running = false
    self:_shutdown()
end

function Window:_shutdown()
    if self.destroyed then return end
    self.destroyed = true
    self.running = false
    -- Liberar el grab del puntero si esta ventana lo tenia activo.
    -- Sin esto, cerrar una ventana con grab deja al cliente
    -- capturando el puntero globalmente. Las demás ventanas dejan
    -- de recibir clicks.
    pcall(function()
        xcb.ungrab_pointer(self.conn)
    end)
    self.server:remove_window(self)
    if self.image_cr then cairo.destroy_context(self.image_cr) end
    if self.image_surface then cairo.destroy_surface(self.image_surface) end
    cairo.destroy_context(self.cr)
    cairo.destroy_surface(self.surface)
    xcb.destroy_window(self.conn, self.id)
    xcb.flush(self.conn)
    if self.xkb then self.xkb:destroy() end
    -- Solo restaurar foco si es child (el WM no lo gestiona).
    -- Para top-level, el WM decide. Si pedimos foco manualmente,
    -- tambien lo devolvemos manualmente.
    if self.parent_window and not self.parent_window.destroyed then
        self.parent_window:set_input_focus()
    elseif self._prev_focus then
        self:restore_input_focus()
    end
    log.info("window", "shutdown id=0x%x", tonumber(self.id))
end

function Window:run()
    self.server:run()
end

function Window:_set_hover(element)
    if self.hover_element == element then return end
    if self.hover_element then self.hover_element:set_hover(false) end
    self.hover_element = element
    if element then element:set_hover(true) end
end

function Window:_set_active(element)
    if self.active_element == element then return end
    if self.active_element and self.active_element ~= element then
        self.active_element:set_pressed(false)
    end
    self.active_element = element
    if element then element:set_pressed(true) end
end

function Window:set_focus_widget(widget)
    if self.focus_widget == widget then return end
    if self.focus_widget and self.focus_widget.set_focused then
        self.focus_widget:set_focused(false)
    end
    self.focus_widget = widget
    if widget and widget.set_focused then
        widget:set_focused(true)
    end
end

function Window:clear_focus_widget()
    self:set_focus_widget(nil)
end

function Window:_dispatch(etype, ev)

    if etype == xcb.EVENT.Expose then
        self:damage_all()
        self:draw()

    elseif etype == xcb.EVENT.ConfigureNotify then
        local cev = ffi.cast("xcb_configure_notify_event_t*", ev)
        if cev.width < 1 or cev.height < 1 then return end
        -- Actualizar x/y también. El WM puede mover la ventana tras
        -- el map inicial (política de tiling), y sin esta
        -- actualización self.x/self.y quedan con los valores
        -- originales. Eso rompe cualquier cálculo de coordenadas
        -- relativas a la ventana, como el posicionamiento de
        -- menús contextuales.
        self.x, self.y = cev.x, cev.y
        if cev.width ~= self.width or cev.height ~= self.height then
            self.width, self.height = cev.width, cev.height

            cairo.destroy_context(self.cr)
            cairo.destroy_surface(self.surface)
            self.surface = cairo.surface_for_window(self.conn, self.id,
                                                    self.visualtype,
                                                    self.width, self.height)
            self.cr = cairo.context(self.surface)

            cairo.destroy_context(self.image_cr)
            cairo.destroy_surface(self.image_surface)
            self.image_surface = cairo.image_surface_create(
                self.width, self.height, cairo.FORMAT.RGB24)
            self.image_cr = cairo.context(self.image_surface)

            self:damage_all()
            self:_relayout()
            if self.opts.on_resize then
                self.opts.on_resize(self.width, self.height)
            end
            self:draw()
        end

    elseif etype == xcb.EVENT.KeyPress then
        local kev = ffi.cast("xcb_key_press_event_t*", ev)
        local key = self.xkb:make_event(kev.detail, kev.state, true)

        -- 1. Si hay un widget con foco, mandarle la tecla.
        --    El widget decide si la consume (return true) o no.
        local consumed = false
        if self.focus_widget and self.focus_widget.on_key then
            consumed = self.focus_widget:on_key(key)
        end

        -- 2. Si no la consumio, pasarla al handler general.
        if not consumed and self.opts.on_key then
            self.opts.on_key(key)
        end

        -- 3. Atajo global: q cierra. Solo si no esta desactivado.
        if not self.opts.disable_q_close
           and key.text == "q"
           and not key.mods.ctrl and not key.mods.alt and not key.mods.super
           and not consumed then
            self:close("tecla q")
        end

    elseif etype == xcb.EVENT.KeyRelease then
        local kev = ffi.cast("xcb_key_press_event_t*", ev)
        local key = self.xkb:make_event(kev.detail, kev.state, false)
        if self.focus_widget and self.focus_widget.on_key then
            self.focus_widget:on_key(key)
        end
        if self.opts.on_key then self.opts.on_key(key) end

    elseif etype == xcb.EVENT.MotionNotify then
        local mev = ffi.cast("xcb_motion_notify_event_t*", ev)
        local x, y = mev.event_x, mev.event_y

        -- 1. Arbol de widgets.
        if self.active_element then
            local el = self.active_element
            el:on_mouse_move(x - el.x0, y - el.y0)
        elseif self.root then
            local hit = self.root:getByXY(x, y)
            self:_set_hover(hit)
            if hit then
                hit:on_mouse_move(x - hit.x0, y - hit.y0)
            end
        end

        -- 2. Hook global.
        if self.opts.on_mouse_move then
            self.opts.on_mouse_move(x, y)
        end

    elseif etype == xcb.EVENT.ButtonPress then
        local bev = ffi.cast("xcb_button_press_event_t*", ev)
        local x, y = bev.event_x, bev.event_y

        -- 1. Enrutar por el arbol de widgets si existe.
        if self.root then
            local hit = self.root:getByXY(x, y)
            if hit then
                if bev.detail == 4 or bev.detail == 5 then
                    hit:on_wheel(bev.detail)
                else
                    self:_set_hover(hit)
                    self:_set_active(hit)
                    hit:on_mouse_press(x - hit.x0, y - hit.y0, bev.detail)
                end
            end
        end

        -- 2. Hook global de la ventana. Solo si el arbol no
        -- consumio el evento (nada de widgets recibio el click).
        if self.opts.on_mouse and not self.active_element then
            self.opts.on_mouse(x, y, bev.detail, bev.state)
        end

    elseif etype == xcb.EVENT.ButtonRelease then
        local bev = ffi.cast("xcb_button_press_event_t*", ev)
        local x, y = bev.event_x, bev.event_y

        -- 1. Arbol de widgets.
        if self.root then
            local active = self.active_element
            if active then
                active:on_mouse_release(x - active.x0, y - active.y0, bev.detail)
                local hit = self.root:getByXY(x, y)
                if hit == active and active.opts.on_click then
                    active.opts.on_click(active, bev.detail)
                end
                active:set_pressed(false)
                self.active_element = nil
            end
        end

        -- 2. Hook global.
        if self.opts.on_mouse_release then
            self.opts.on_mouse_release(x, y, bev.detail, bev.state)
        end

    elseif etype == xcb.EVENT.LeaveNotify then
        self:_set_hover(nil)

    elseif etype == xcb.EVENT.ClientMessage then
        local cev = ffi.cast("xcb_client_message_event_t*", ev)
        if cev.type == self.atoms.WM_PROTOCOLS
           and cev.data[0] == self.atoms.WM_DELETE_WINDOW then
            self:close("WM_DELETE_WINDOW")
        end

    elseif etype == xcb.EVENT.MapNotify then
        -- Confirmacion de X de que la ventana esta mapeada. Este es
        -- el momento correcto para el primer draw real: el arbol de
        -- widgets ya esta construido y la ventana ya es visible.
        -- Sin esto, el primer draw (hecho durante Window.new) se
        -- descarta porque la ventana no esta mapeada, y X no envia
        -- Expose posterior. La ventana queda vacia hasta el input.
        log.info("window", "MapNotify, primer draw real")
        self:damage_all()
        self:draw()

    elseif etype == xcb.EVENT.FocusIn then
        if self.opts.on_focus_in then
            self.opts.on_focus_in()
        end

    elseif etype == xcb.EVENT.FocusOut then
        if self.opts.on_focus_out then
            self.opts.on_focus_out()
        end

    elseif etype == xcb.EVENT.DestroyNotify then
        self:_shutdown()
    end
end

return Window
