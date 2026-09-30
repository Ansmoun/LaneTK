-- TextInput: campo de texto editable minimalista.
-- Sin scroll horizontal, sin selección. Cursor en posición actual.
-- Recibe on_mouse_press para tomar foco y on_key para editar.

local Area  = require("lib.area")
local cairo = require("lib.cairo")
local pango = require("lib.pango")

local TextInput = setmetatable({}, { __index = Area })
TextInput.__index = TextInput

-- opts:
--   text           : contenido inicial
--   font
--   padding_x, padding_y
--   color_text     : {r,g,b}
--   color_cursor   : {r,g,b}
--   color_bg       : "#hex" | nil (transparente)
--   color_border   : "#hex" | nil
--   corner_radius
--   mask           : bool, reemplaza cada char con ●
--   on_submit      : function(text)
--   on_cancel      : function()
--   on_change      : function(text)
--   on_up          : function()  opcional, Up cuando tiene foco
--   on_down        : function()  opcional, Down cuando tiene foco
--   placeholder    : string opcional, texto visible cuando text == ""
--   color_placeholder : {r,g,b} opcional, color del placeholder
--   right_widget   : Area opcional, se dibuja anclado a la derecha
--                    del input, dentro de su rect
--   right_widget_width : number, ancho reservado (default 24)
--   right_widget_gap   : number, gap entre texto y widget (default 6)
function TextInput.new(opts)
    opts = opts or {}
    local self = setmetatable(Area.new(opts), TextInput)

    self.text          = opts.text or ""
    self.font          = opts.font or "DejaVu Sans 12"
    self.padding_x     = opts.padding_x or 8
    self.padding_y     = opts.padding_y or 4
    self.color_text    = opts.color_text or { 0.95, 0.95, 0.95 }
    self.color_cursor  = opts.color_cursor or { 0.95, 0.85, 0.30 }
    self.color_bg      = opts.color_bg
    self.color_border  = opts.color_border
    self.corner_radius = opts.corner_radius or 4
    self.mask          = opts.mask or false
    self.placeholder   = opts.placeholder
    self.color_placeholder = opts.color_placeholder
        or { 0.34, 0.36, 0.40 }
    self.right_widget = opts.right_widget
    self.right_widget_width = opts.right_widget_width or 24
    self.right_widget_gap   = opts.right_widget_gap or 6
    -- El ancho util del texto es el ancho total menos padding,
    -- menos el espacio reservado al right_widget.
    if self.right_widget then
        self._text_right_reserved = self.right_widget_width
            + self.right_widget_gap
    else
        self._text_right_reserved = 0
    end

    self.cursor_pos    = #self.text   -- posición del cursor
    self.focused       = false
    self._cursor_phase = 0
    self._cursor_timer = nil

    self.min_h = opts.min_height or 26
    self.min_w = opts.min_width or 100
    self.max_w = 10000
    self.max_h = 10000

    return self
end

function TextInput:set_text(t)
    self.text = t or ""
    self.cursor_pos = #self.text
    if self.opts.on_change then self.opts.on_change(self.text) end
    self:damage()
end

function TextInput:get_text()
    return self.text
end

function TextInput:set_window(win)
    self.window = win
    if self.right_widget then
        if self.right_widget.set_window then
            self.right_widget:set_window(win)
        else
            self.right_widget.window = win
        end
    end
end

function TextInput:set_focused(v)
    v = v and true or false
    if self.focused == v then return end
    self.focused = v

    if v then
        -- Autorregistrarse como el widget que recibe las teclas del
        -- window. Antes esto solo se hacia desde on_mouse_press, lo
        -- que obligaba a hacer click en el input. Al registrarse en
        -- set_focused(true), basta con activarlo programaticamente.
        if self.window and self.window.set_focus_widget
           and self.window.focus_widget ~= self then
            self.window:set_focus_widget(self)
        end
        self._cursor_timer = self.window
            and self.window.server
            and self.window.server:add_timer(500, function()
                self._cursor_phase = (self._cursor_phase + 1) % 2
                self:damage()
            end)
    else
        if self._cursor_timer then
            self._cursor_timer:cancel()
            self._cursor_timer = nil
        end
        self._cursor_phase = 0
        -- Si eramos el focus_widget del window, desregistrarnos.
        if self.window and self.window.focus_widget == self then
            self.window.focus_widget = nil
        end
    end
    self:damage()
end

function TextInput:_display_text()
    if not self.mask then return self.text end
    -- Reemplaza cada codepoint por ●
    local n = 0
    for _ in self.text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        n = n + 1
    end
    return string.rep("●", n)
end

-- Cuenta chars UTF-8 en self.text hasta cursor_pos
function TextInput:_cursor_display_index()
    local i = 0
    local byte_pos = 0
    for c in self.text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        byte_pos = byte_pos + #c
        if byte_pos > self.cursor_pos then break end
        i = i + 1
    end
    return i
end

function TextInput:_byte_index_of_char_index(char_idx)
    local i = 0
    local byte_pos = 0
    for c in self.text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if i >= char_idx then break end
        byte_pos = byte_pos + #c
        i = i + 1
    end
    return byte_pos
end

function TextInput:insert_char(ch)
    if ch == "" then return end
    local before = self.text:sub(1, self.cursor_pos)
    local after  = self.text:sub(self.cursor_pos + 1)
    self.text = before .. ch .. after
    self.cursor_pos = self.cursor_pos + #ch
    if self.opts.on_change then self.opts.on_change(self.text) end
    self:damage()
end

function TextInput:backspace()
    if self.cursor_pos <= 0 then return end
    -- Encontrar el byte index del char anterior
    local before = self.text:sub(1, self.cursor_pos)
    local ch_start = before:match("()[%z\1-\127\194-\244][\128-\191]*$")
    if not ch_start then return end
    local new_text = self.text:sub(1, ch_start - 1) ..
                     self.text:sub(self.cursor_pos + 1)
    self.text = new_text
    self.cursor_pos = ch_start - 1
    if self.opts.on_change then self.opts.on_change(self.text) end
    self:damage()
end

function TextInput:delete()
    if self.cursor_pos >= #self.text then return end
    local after = self.text:sub(self.cursor_pos + 1)
    local _, ch_end = after:find("^[%z\1-\127\194-\244][\128-\191]*")
    if not ch_end then return end
    self.text = self.text:sub(1, self.cursor_pos) ..
                after:sub(ch_end + 1)
    if self.opts.on_change then self.opts.on_change(self.text) end
    self:damage()
end

function TextInput:move_left()
    if self.cursor_pos <= 0 then return end
    local before = self.text:sub(1, self.cursor_pos)
    local ch_start = before:match("()[%z\1-\127\194-\244][\128-\191]*$")
    if ch_start then
        self.cursor_pos = ch_start - 1
        self:damage()
    end
end

function TextInput:move_right()
    if self.cursor_pos >= #self.text then return end
    local after = self.text:sub(self.cursor_pos + 1)
    local _, ch_end = after:find("^[%z\1-\127\194-\244][\128-\191]*")
    if ch_end then
        self.cursor_pos = self.cursor_pos + ch_end
        self:damage()
    end
end

function TextInput:move_home()
    self.cursor_pos = 0
    self:damage()
end

function TextInput:move_end()
    self.cursor_pos = #self.text
    self:damage()
end

-- Devuelve true si el widget consumio la tecla (no se debe propagar).
function TextInput:on_key(key)
    if not self.focused then return false end
    if not key.pressed then return false end

    if key.name == "Return" then
        if self.opts.on_submit then self.opts.on_submit(self.text) end
        return true
    elseif key.name == "Escape" then
        if self.opts.on_cancel then self.opts.on_cancel() end
        return true
    elseif key.name == "BackSpace" then
        self:backspace(); return true
    elseif key.name == "Delete" then
        self:delete(); return true
    elseif key.name == "Left" then
        self:move_left(); return true
    elseif key.name == "Right" then
        self:move_right(); return true
    elseif key.name == "Home" then
        self:move_home(); return true
    elseif key.name == "End" then
        self:move_end(); return true
    elseif key.name == "Up" then
        if self.opts.on_up then
            self.opts.on_up()
            return true
        end
        return false
    elseif key.name == "Down" then
        if self.opts.on_down then
            self.opts.on_down()
            return true
        end
        return false
    end

    -- Cualquier otro char imprimible
    if key.text and #key.text > 0 then
        local byte = key.text:byte(1)
        if byte >= 32 then
            self:insert_char(key.text)
            return true
        end
    end
    return false
end

function TextInput:draw(cr)
    local x, y = self.x0, self.y0
    local w, h = self:getWidth(), self:getHeight()

    -- Reducir el ancho util del texto si hay right_widget.
    -- El fondo se pinta con el ancho completo; el texto y el cursor
    -- se limitan al ancho menos el right_widget.

    -- Fondo
    if self.color_bg then
        local G = require("lib.helpers.graphics")
        local r, g, b = G.hex_to_rgba(self.color_bg)
        cairo.set_rgb(cr, r, g, b)
        cairo.rounded_rect(cr, x, y, w, h, self.corner_radius)
        cairo.fill(cr)
    end

    -- Borde
    if self.color_border then
        local G = require("lib.helpers.graphics")
        local r, g, b = G.hex_to_rgba(self.color_border)
        cairo.set_rgb(cr, r, g, b)
        cairo.set_line_width(cr, 1)
        cairo.rounded_rect(cr, x + 0.5, y + 0.5,
            w - 1, h - 1, self.corner_radius)
        cairo.stroke(cr)
    end

    -- Texto
    local disp = self:_display_text()
    local c = self.color_text
    if disp == "" and self.placeholder then
        disp = self.placeholder
        c = self.color_placeholder
    end
    local ty = y + (h - select(2, pango.measure(disp, self.font))) / 2
    pango.draw_text(cr, x + self.padding_x, ty, disp, self.font,
        { r = c[1], g = c[2], b = c[3] })

    -- Cursor: alto = alto del texto, centrado verticalmente.
    if self.focused and self._cursor_phase == 0 then
        local idx = self:_cursor_display_index()
        local before
        if self.mask then
            -- En modo mask, cada ● ocupa 3 bytes (U+25CF).
            -- _byte_index_of_char_index opera sobre el texto
            -- ORIGINAL, no sobre la mascara. Por eso hay que
            -- construirlo a mano para que pango.measure reciba
            -- UTF-8 valido.
            before = string.rep("\u{25CF}", idx)
        else
            before = disp:sub(1, self:_byte_index_of_char_index(idx))
        end
        local bw = pango.measure(before, self.font)
        local _, text_h = pango.measure(disp ~= "" and disp or "X", self.font)
        local cursor_h = text_h + 4
        if cursor_h > h - 4 then cursor_h = h - 4 end
        local cursor_y = y + (h - cursor_h) / 2
        local cc = self.color_cursor
        cairo.set_rgb(cr, cc[1], cc[2], cc[3])
        cairo.rectangle(cr, x + self.padding_x + bw,
            cursor_y, 1.5, cursor_h)
        cairo.fill(cr)
    end

    -- Right widget (por ejemplo un toggle de ojo).
    if self.right_widget and self.right_widget.draw then
        self.right_widget:draw(cr)
    end
end

function TextInput:layout(x0, y0, x1, y1)
    Area.layout(self, x0, y0, x1, y1)
    if self.right_widget then
        local rw = self.right_widget_width
        local rh = self:getHeight() - self.padding_y * 2
        if rh < 1 then rh = 1 end
        local rx0 = self.x1 - self.padding_x - rw
        local ry0 = self.y0 + self.padding_y
        local rx1 = self.x1 - self.padding_x
        local ry1 = ry0 + rh
        self.right_widget:layout(rx0, ry0, rx1, ry1)
    end
end

function TextInput:on_mouse_press(mx, my, button)
    -- Si hay right_widget y el click cae dentro de su rect,
    -- delegar a el. Sin esto, el click sobre el ojo tomaria foco
    -- del input y no dispararia el on_click del icono.
    if self.right_widget then
        local rw = self.right_widget
        local gx = self.x0 + mx
        local gy = self.y0 + my
        if gx >= rw.x0 and gx < rw.x1 and gy >= rw.y0 and gy < rw.y1 then
            if rw.on_mouse_press then
                rw:on_mouse_press(gx - rw.x0, gy - rw.y0, button)
            end
            return
        end
    end

    if button == 1 then
        -- Pedir foco al window. Esto quita el foco de cualquier
        -- otro widget y lo pone aqui.
        if self.window and self.window.set_focus_widget then
            self.window:set_focus_widget(self)
        end
        if self.opts.on_focus_request then
            self.opts.on_focus_request(self)
        end
    end
end

return TextInput
