# Notas del proyecto

Hallazgos, decisiones y cosas que rompen.

> **Nota histórica:** este proyecto se llamó `xui` hasta el
> 2026-09-24, cuando se renombró a `LaneTK`. Las entradas de esta
> crónica anteriores a esa fecha se refieren al mismo proyecto con
> el nombre antiguo.

## Dependencias

- libxcb, cairo, pango, libxkbcommon (devel)
- libxcb-util (runtime, para `xcb_aux_get_screen`)
- LuaJIT

## Decisiones

- FFI puro. Sin shims en C.
- `xcb_aux_get_screen` en lugar de `xcb_setup_roots_iterator` porque
  los iteradores de XCB son `static inline` en el header y no se exportan
  como simbolos en `libxcb.so`.
- `ffi.C.free()` para liberar los eventos (`xcb_wait_for_event`
  devuelve memoria que hay que liberar con `free`, no hay un
  `xcb_free_event`).

## Pendiente

- Verificar que `xcb_aux_get_screen` esta disponible en `libxcb-util`.
  Si no, instalar `libxcb-util-devel` y comprobar con:
      nm -D /usr/lib/libxcb-util.so.1 | grep aux_get_screen
- Anadir `xcb_aux_get_visualtype` para cuando tengamos que pasar el
  visualtype a Cairo.
- Eventos: falta `ConfigureNotify`, `ClientMessage`, `PropertyNotify`.

## Correcciones

- `EVENT` vs `EVENT_MASK`: son dos tablas distintas. `EVENT.x` son codigos
  de evento (para comparar contra `ev.response_type & 0x7f`).
  `EVENT_MASK.x` son bits de mascara (para `event_mask` al crear la ventana).
  Confundirlos da `bad argument #3 to 'bor' (number expected, got nil)`.
- `xcb-util` en Void es el paquete runtime, `xcb-util-devel` trae las
  cabeceras y el symlink `.so`. El runtime trae `libxcb-util.so.1`,
  que es lo que carga el FFI.

## free y libc

- `free` no está en libxcb, está en libc. Como LuaJIT carga `libxcb.so`
  con `ffi.load("xcb")`, el símbolo `free` no es visible desde ese
  namespace. Se declara en el cdef y se llama con `ffi.C.free(ptr)`,
  que apunta al namespace de libc que LuaJIT ya tiene cargado por
  defecto.

## Wrappers olvidados

- Regla: cada funcion que se usa en un ejemplo debe estar envuelta en
  `src/lib/cairo.lua`. El cdef solo declara el simbolo; sin el wrapper,
  `cr.move_to` no existe y LuaJIT se queja con "attempt to call field
  'move_to' (a nil value)".
- Si el error es "attempt to call field 'X' (a nil value)" casi siempre
  es esto. Revisar el wrapper antes de tocar el cdef.

## Hito: stack validado

XCB + Cairo funcionando sobre LuaJIT FFI. La ventana se dibuja, los
eventos Expose se manejan, se repinta al mover/redimensionar. El dibujo
sobrevive el ciclo de expose sin acumular estado sucio.

Esto valida:
- FFI a libxcb, libxcb-util y libcairo.
- xcb_aux_find_visual_by_id para pasar el visualtype a Cairo.
- El patron surface-for-window + context, sin recrear en cada Expose.
- ffi.C.free para liberar eventos.

## Correccion: ffi.load con guiones

Los symlinks SI existen en Void (libpango-1.0.so -> libpango-1.0.so.0).
El problema no era eso. `ffi.load("pango-1.0")` es fragil porque LuaJIT
construye el nombre como "libpango-1.0.so" y en algunos sistemas con
multiples candidatos en el path falla de forma no obvia.

Regla: pasar siempre el nombre versionado completo, tipo
`ffi.load("libpango-1.0.so.0")`. Es lo que hacen los bindings serios.
Es feo pero deterministico.

## Fontconfig y Pango

- Pango usa fontconfig por debajo. Sin `FcInit()` al arranque, Pango
  funciona pero imprime el warning:
      Fontconfig warning: using without calling FcInit()
  Se inicializa una vez al cargar el modulo pango.
- `cairo_image_surface_create` esta en libcairo, no en libpangocairo.
  Se necesita para crear surfaces dummy de 1x1 con los que medir texto
  sin tener una ventana real. Es el metodo estandar.

## Hito 2: Pango funcionando

Texto plano, markup Pango, wrapping, alignment y medicion funcionando.
FcInit() resuelve el warning de fontconfig. cairo_image_surface_create
permite medir sin ventana real. Stack completo validado:

  XCB -> window + eventos
  Cairo -> dibujo
  Pango -> texto
  FcInit -> fuentes del sistema

Siguiente bloque: clase Window para encapsular el ciclo de vida.

## Nombres de paquetes en Void

- La libreria ICCCM no se llama `xcb-icccm` en Void. El paquete es
  `xcb-util-wm` (runtime) y `xcb-util-wm-devel` (headers).
- `xcb-util-wm` provee DOS bibliotecas:
    libxcb-icccm.so.4   -> ICCCM (size hints, WM hints, protocols)
    libxcb-ewmh.so.2    -> EWMH (window types, states, desktop)
- Los nombres en otras distros varian: Debian/Ubuntu usa `libxcb-icccm4`,
  Fedora usa `xcb-util-wm`. Void sigue el nombre upstream del modulo
  (xcb-util-wm) pero el .so lleva el nombre de la libreria (icccm).
- Regla general: si `xbps-install` dice "Package not found", buscar en
  https://voidlinux.pkgs.org con el nombre de la libreria (.so) en vez
  del nombre del paquete.

## Clase Window

- Especificaciones de tamano: numero, "N%", "screen", "auto", "free".
- Aspect declarado via WM_NORMAL_HINTS con PAspect. El WM lo respeta
  al redimensionar si esta corriendo. Sin WM, hay que aplicarlo a mano.
- El tamano real vive en self.width/self.height, no en el solicitado.
  ConfigureNotify actualiza y recrea el surface de Cairo.
- Tipos: normal, dock, dialog, menu. Menu usa override_redirect
  (sin WM). Dock es para barras. Dialog es para popups con padre.
- Atoms se cachean por conexion (atom_cache, weak keys) para no
  internar de nuevo en cada ventana.
- xcb-icccm solo se carga si se usan hints. Es lazy.
- Limitacion: "auto" con on_measure se resuelve al crear. Si quieres
  dinamismo real (recalcular en cada resize), hay que redibujar
  con las medidas del momento, no reusar las iniciales.

## Regla sobre append a archivos Lua

Nunca usar `cat >>` sobre un archivo .lua que ya termina en
`return X`. El codigo pegado queda despues del return, y Lua no
permite nada despues de un return a nivel de chunk. Sintoma:

  '<eof>' expected near 'function'

Siempre reescribir el archivo completo con `cat >` si hay que añadir
algo al final. Es mas feo pero evita este tipo de bugs.

## Offsets del window id en eventos X11 (CONFIRMADO POR BYTES CRUDOS)

Todos los eventos X11 miden 32 bytes. El campo window/event esta en
uno de dos offsets:

  Offset 4  (eventos "notify"):
    Expose, ConfigureNotify, DestroyNotify, UnmapNotify,
    MapNotify, ReparentNotify, PropertyNotify, ClientMessage,
    VisibilityNotify

  Offset 12 (eventos de input):
    KeyPress, KeyRelease, ButtonPress, ButtonRelease,
    MotionNotify, EnterNotify, LeaveNotify, FocusIn, FocusOut

Ejemplos de dumps que confirman esto:

  Expose (window 0x02200003):
    0c 00 2f 00 | 03 00 20 02 | 00 00 00 00 fc 01 c4 00
    tipo  seq     window           x,y,w,h

  KeyPress (window 0x02200000, root 0x1b6):
    02 18 6f 00 3a 55 6b 00 | b6 01 00 00 | 00 00 20 02 | 00 00 20 02
    tipo kc   seq    time     root           event          child

  ClientMessage (window 0x02200002):
    a1 20 6f 00 | 02 00 20 02 | 5f 01 00 00 60 01 00 00
    tipo fmt seq  window         type        data0

a1 = 0xA1 = ClientMessage(33) | send_event(0x80).

## Leccion de metodo

Para diagnosticar eventos X11 con FFI, no adivinar structs. Volcar
los primeros 16 bytes en hex y comparar con la spec del protocolo.
El offset sale solo.

## Awesome en tiling

Las ventanas de prueba se reparten por tiling a 508x196 uniforme.
Para probar aspect ratio y resize libre, hay que ponerlas en
floating (Mod4+Control+Space con la ventana enfocada, o en la
config de Awesome). No es problema del toolkit.

## BUG CRITICO: eventos X11 NO tienen campo `length` (RESUELTO)

Los eventos X11 ocupan 32 bytes exactos en el wire:

  offset 0      : response_type
  offset 1      : detail / format / pad
  offset 2-3    : sequence
  offset 4-31   : payload (28 bytes, layout segun tipo)

NO existe `uint32_t length` en el wire de un evento. Solo los
requests y responses lo tienen. Si metes `length` en el cdef de un
evento, TODO el struct queda desplazado 4 bytes, y leeras campos
incorrectos sin error visible.

Sintomas tipicos:
- `cev.type` de un ClientMessage devuelve el valor de data[0]
  en vez del atom del tipo. La comparacion `type == WM_PROTOCOLS`
  falla siempre y las ventanas no cierran con Mod4+Shift+Q.
- `cev.width` de un ConfigureNotify devuelve border_width en vez
  de width real. Los resizes parecen funcionar por casualidad si
  border_width = 0.

Ejemplo verificado (ClientMessage de WM_DELETE_WINDOW):

  a1 20 6f 00 | 02 00 20 02 | 5f 01 00 00 | 60 01 00 00
  tipo fmt seq  window        type=WM_PROT  data[0]=WM_DEL_WIN

Con `length` mal puesto, se leia:
  type   = 0x160 (data[0] real)
  data[0]= 0x6dddf7 (data[1] real, un timestamp)

## Regla

Antes de añadir un struct de evento al cdef, verificar el layout
contra el wire del protocolo X11. Los unicos que llevan `length`
son xcb_intern_atom_reply_t y similares (son responses, no events).

## Como diagnosticar en el futuro

Cuando algo no cuadre, volcar los primeros 16 bytes en hex y
comparar contra la spec del protocolo. Es mas rapido que razonar
sobre offsets teoricos.

## BUG: orden de campos en ConfigureNotify (RESUELTO)

El wire de ConfigureNotify es:

  event (4) | window (4) | above (4) | x (2) | y (2) |
  width (2) | height (2) | border_width (2) | ovr (1) | pad (1)

Total 28 bytes de payload + 4 de header = 32. `above` va ANTES de
x, no despues. Si se pone al final, todos los campos siguientes
quedan desplazados y se leen valores basura (width=0, height=0).

Sintoma: "resize 400x250 -> 0x0", cairo falla con status=32
(INVALID_SIZE) al recrear el surface.

## Guarda defensiva

Aunque el bug esta arreglado, dejamos una guarda en Window:_dispatch:

    if cev.width < 1 or cev.height < 1 then return end

porque X11 a veces envia ConfigureNotify con datos raros (por
ejemplo durante el reparenting del WM). No queremos crashear por
eso.

## Hito 3: event loop correcto

- Dispatch por window ID con offsets correctos (4 o 12 segun tipo).
- KeyPress, ClientMessage, Expose, ConfigureNotify llegan y se procesan.
- Cierre por 'q', por Mod4+Shift+Q (WM_DELETE_WINDOW), y por
  destruccion externa (DestroyNotify).
- Server multiventana con una sola conexion XCB.
- Cierre limpio al vaciarse todas las ventanas.

## Hito 4: teclado real con xkbcommon

- on_key recibe tabla completa: keycode, sym, name, text, mods, pressed.
- Funciona con Shift, Control, Alt, Super (Mod4), F1-F12, flechas,
  Escape, Delete. Todo lo probado.
- Convencion: para teclas "sin texto" (F1, Shift, Escape con char
  de control), usar key.name. Para teclas imprimibles, usar key.text.
- El bit Mod1 (Alt) se activa en las teclas SIGUIENTES a Alt_L,
  no en Alt_L mismo. Comportamiento estandar de X11.

## Convencion de cierre con 'q'

En Window:run (y en los ejemplos), 'q' sin ctrl/alt/super cierra
la ventana. Esto es SOLO para desarrollo. En produccion, la app
decide que teclas cierran (o ninguna; se cierra con el WM).

## Regla: orden de dibujo

En Window:draw el orden es estricto:

  1. on_draw (fondo, si lo hay)
  2. root:draw (widgets encima)

Al reves, el fondo tapa los widgets. Es el equivalente a
"background painting" en cualquier toolkit. Si un widget quiere
pintar su propio fondo encima del de la ventana, lo hace el widget
en su propio draw, no el on_draw de la ventana.

## Alineacion en Text

- align  (horizontal): "left" | "center" | "right"  - default "left"
- valign (vertical):   "top"  | "center" | "bottom" - default "center"

El texto se posiciona dentro de su celda (rect asignado por el
padre via layout). El centrado horizontal y vertical se calcula en
el draw, no en el layout. Layout solo reparte el rect.

A futuro, esta logica puede vivir en un contenedor Align que
envuelva cualquier Area, no solo Text. Es util para centrar
cualquier widget dentro de una celda mas grande.

## Hito 6: Area + Group + Text con alineacion

- Text tiene align (horizontal) y valign (vertical).
- Group reparte celdas y cada hijo se posiciona dentro de su celda.
- Layout funciona a cualquier tamano de ventana (probado con resize).
- Ejemplo 06b dibuja rectangulos de debug para visualizar celdas.

## BUG: linea diagonal en anillos (RESUELTO)

Dibujar dos arcos consecutivos con cairo_arc en el mismo path hace
que Cairo los conecte con una linea recta. Sintoma tipico: un
anillo con una linea diagonal que sale desde el final del primero
hasta el inicio del segundo, cruzando el texto.

Solucion: cairo_new_sub_path() antes de cada arco que quieras
stroke independiente.

    cairo.new_sub_path(cr)
    cairo.arc(cr, cx, cy, r, a0, a1)
    cairo.stroke(cr)

Aplica a cualquier par de arcos consecutivos (arcos de progreso,
dial, pie chart). El new_sub_path tambien es importante cuando
usas rounded_rect varias veces: ya lo haciamos ahi.

## BUG: timers no disparan con os.clock (RESUELTO)

os.clock() en Lua devuelve el TIEMPO CPU del proceso, no tiempo
real. Si el proceso pasa el rato bloqueado en poll() sin quemar
CPU, os.clock() no avanza, y los timers nunca se consideran
vencidos.

Solucion: clock_gettime(CLOCK_MONOTONIC) via FFI. Vive en
lib/timer.lua con M.now_ms().

Regla: NUNCA usar os.clock() para medir tiempo real. Solo vale
para medir coste de CPU de un chunk. Para tiempo de pared, usar
os.time() (segundos) o clock_gettime via FFI (ms/ns).

## Hito 7: helpers portados

- lib/helpers/util.lua   : trim, read_file, write_file, shell_once,
                           list_files, read_conf_key, write_conf_key,
                           home.
- lib/helpers/format.lua : mb, bytes, speed, uptime, date, greeting.

Ambos son Lua puro, sin dependencias de X11 ni wibox. Migracion
casi literal desde ~/.config/awesome/widgets/helpers/.

Diferencia respecto al original: añadido M.home() en util.

Regla de diseño: si una funcion devuelve un widget, va en
lib/widgets/ o en vistas (por hacer). Si solo transforma datos,
va en helpers/.

## Bug: servidor no salia al cerrar la ultima ventana (RESUELTO)

El timer del ejemplo seguia activo despues de cerrar la ventana, y
el loop no salia porque la condicion era "n == 0 AND no hay timers".

Cambio de politica: si no hay ventanas y exit_on_empty es true,
cancelar todos los timers automaticamente y salir. Una app de UI
sin UI no tiene sentido.

Para programas sin UI (servicios, scripts headless), pasar
Server.new{ exit_on_empty = false } y llamar srv:stop() manualmente.

## Wrapping en Text/Header

Text y Header aceptan `wrap = true`. En draw, si el texto es mas
ancho que la celda, se pasa wrap_width a pango y este envuelve el
texto. Sin wrap, el texto se dibuja completo y puede salirse.

Nota: askMinMax sigue devolviendo el ancho del texto sin wrap como
minimo. Eso significa que el layout puede asignar mas espacio del
necesario, pero al menos el texto no se sale visualmente.

## Hito 8: BarRow, Motors, DualSpark

- BarRow: filas [label][bar][pct][detalle]. Configurable con
  pct_width=0 y detail_width=0 para simplificar. Colores dinamicos
  con warn_at/crit_at.
- Motors: alias de BarRow con pct_width=0 y detail_width=0.
  API distinta: set(id, pct) en vez de set(id, {pct=, detail=}).
- DualSpark: dos historiales, auto_max del maximo entre ambos,
  floor_max para evitar picos planos. push_a / push_b.

## Vistas portadas

De las originales:
  [x] ring
  [x] spark
  [x] dual_spark
  [x] kv
  [x] bignum
  [x] header
  [x] bar_row / motors
  [ ] rows
  [ ] bar_multi (stacked bar con leyenda)
  [ ] actions (lista de botones con feedback)
  [ ] pills
  [ ] tab_layout (composicion de vistas)

## BarRow: colores dinamicos

Tres capas de color configurables:
- barra: _bar_color_for(row) segun warn_at/crit_at
- texto pct: _text_color_for(row) segun warn_at/crit_at
- resto: colores estaticos

text_warn controla si el texto cambia. Default true. Poner false
para que solo la barra cambie.

Text:set_color(r, g, b) compara con el actual y solo daña si
cambio. Restaurar color por defecto funciona igual.

## Leccion de patch

Python re.search().sub() con un patron que no encuentra match
puede devolver nada silenciosamente si no se maneja. En los
patches futuros, verificar con assert o devolver un error
explicito si el patron no esta.

## BarRow: colores dinamicos

Tres capas de color configurables:
- barra: _bar_color_for(row) segun warn_at/crit_at
- texto pct: _text_color_for(row) segun warn_at/crit_at
- resto: colores estaticos

text_warn controla si el texto cambia. Default true. Poner false
para que solo la barra cambie.

Text:set_color(r, g, b) compara con el actual y solo daña si
cambio. Restaurar color por defecto funciona igual.

## Leccion de patch

Python re.search().sub() con un patron que no encuentra match
puede devolver nada silenciosamente si no se maneja. En los
patches futuros, verificar con assert o devolver un error
explicito si el patron no esta.

## Hito 9: todas las vistas portadas

De las originales de ~/.config/awesome/widgets/views/:
  [x] ring
  [x] spark
  [x] dual_spark
  [x] kv
  [x] bignum
  [x] header
  [x] bar_row / motors
  [x] rows
  [x] bar_multi
  [x] actions
  [x] pills

Falta:
  [ ] tab_layout (composicion de vistas en grid)
  [ ] popup / panel coordinador
  [ ] tabs bar (indicador de tabs activos)
  [ ] scroll group (para listas grandes)

## Notas de implementacion

- Rows: 3 columnas (grupo, nombre, valor). El ancho de cada
  columna es configurable. valor se alinea a la derecha por
  defecto (valores numericos).
- BarMulti: barra apilada + leyenda. La leyenda se calcula con
  pango.measure para saber la altura de linea.
- Actions: usa os.execute. Bloquea el loop mientras corre el
  comando. Para comandos lentos, sobreescribir on_run con una
  llamada a Exec.run cuando lo tengamos.
- Pills: etiquetas con fondo redondeado. Ancho calculado con
  pango.measure al añadir.

## Correccion: drag del scrollbar con click izquierdo

Version inicial usaba boton 3. Cambiado a boton 1 por preferencia
del usuario. El scrollbar vive a la derecha del scrollview (no
encima), asi que no hay conflicto con clicks izquierdos sobre la
lista.

## Convencion de coordenadas en handlers de raton

Window:_dispatch pasa coordenadas LOCALES a los handlers:

    widget:on_mouse_move(mx - widget.x0, my - widget.y0)

La mayoria de widgets solo necesitan coordenadas locales (saben
donde estan sus hijos, o sus items, en coordenadas LOCALES).

PERO: si un widget guarda posiciones de sub-items en coordenadas
GLOBALES (por ejemplo en layout(): item.x0 = x donde x ya es
global), entonces en el hit test debe convertir de vuelta:

    local gx = mx + self.x0
    local gy = my + self.y0
    if gx >= item.x0 and ... then ...

Bug encontrado en TabsBar por saltarse esta conversion.

## BUG: orden del value_list en xcb_create_window (RESUELTO)

El value_list de xcb_create_window NO sigue el orden en que
escribimos los ifs, sino el orden de los bits del value_mask
segun el protocolo X11:

    BackPixmap (1<<0)
    BackPixel (1<<1)
    BorderPixmap (1<<2)
    BorderPixel (1<<3)
    BitGravity (1<<4)
    WinGravity (1<<5)
    BackingStore (1<<6)
    BackingPlanes (1<<7)
    BackingPixel (1<<8)
    OverrideRedirect (1<<9)
    SaveUnder (1<<10)
    EventMask (1<<11)
    DontPropagate (1<<12)
    Colormap (1<<13)
    Cursor (1<<14)

Cualquier desviacion hace que el servidor lea valores cruzados
(por ejemplo, OverrideRedirect recibe el valor de EventMask).

En ventanas top-level suele pasar desapercibido porque el servidor
es permisivo. En child windows valida estrictamente y devuelve
BadValue (error_code=2).

Regla: cada valor en value_list debe ir en el orden del bit de su
flag en value_mask. No en el orden en que se añaden al codigo.

## BUG: orden del value_list en xcb_create_window (RESUELTO)

El value_list de xcb_create_window debe seguir el orden de los
bits del value_mask del protocolo X11:

    BackPixmap, BackPixel, BorderPixmap, BorderPixel,
    BitGravity, WinGravity, BackingStore, BackingPlanes,
    BackingPixel, OverrideRedirect, SaveUnder, EventMask,
    DontPropagate, Colormap, Cursor

Cualquier desviacion hace que el servidor interprete mal los
valores (por ejemplo, OverrideRedirect recibe el valor de
EventMask). En ventanas top-level esto pasa desapercibido porque
el servidor es permisivo, pero en child windows valida
estrictamente y devuelve BadValue (error_code=2).

Regla: cada valor en value_list debe ir en el orden del bit de su
flag en value_mask. No en el orden en que se añaden al codigo.

## Diagnostico: xcb_request_check

Añadido al wrapper xcb.create_window: verifica el cookie con
xcb_request_check y devuelve (nil, screen, mensaje) si el servidor
rechaza. Esto hizo visible el bug de BadValue, que hasta ahora
fallaba silenciosamente.

## Hito 13 confirmado

Panel con 4 tabs, lazy loading verificado por log:

  cargando tab 'cpu' (lazy)  -> [cpu] construyendo widget + start
  [cpu] stop                 (al cambiar a ram)
  cargando tab 'ram' (lazy)  -> [ram] construyendo widget + start
  ...

El widget solo se construye la primera vez. Los start/stop se
ejecutan en cada cambio de tab. sys (sin stop) solo tiene start.

## Nota sobre el tamano

La ventana salio 716x957 con width="70%". Eso es porque el WM
reporta una pantalla virtual que abarca los dos monitores
apilados (LCD 600 + VGA 768 = 1368). Los porcentajes se calculan
sobre esa altura total. Para paneles reales, probablemente
conviene tamano absoluto o relativo al monitor concreto.

## BUG CRITICO: eventos huerfanos en el buffer interno de XCB (RESUELTO)

Sintoma:
  La ventana aparece vacia al arrancar. Solo se dibuja al recibir
  un input (tecla, movimiento de raton). MapNotify, Expose, etc.
  llegan con retraso o no llegan hasta el siguiente evento.

Causa:
  xcb.sync() (y en general cualquier operacion sincrona, como
  xcb_intern_atom_reply) hace un round-trip al servidor: lee del
  socket hasta recibir la respuesta que espera. Durante esa
  lectura, XCB puede recibir OTROS eventos en el mismo paquete
  del socket y guardarlos en su BUFFER INTERNO.

  Nuestro loop consultaba poll(fd) para saber si habia datos. Pero
  el socket ya estaba vacio (XCB lo habia leido durante el sync) y
  los eventos estaban en el buffer interno. Resultado: poll
  bloqueaba, los eventos nunca se procesaban.

Solucion:
  Antes de bloquearse en poll(fd), vaciar siempre el buffer interno
  con xcb_poll_for_event en bucle hasta que devuelva nil:

      while true do
          local ev = xcb.poll_event(conn)
          if ev == nil then break end
          ...procesar...
      end
      if not processed then
          poll.wait_readable(fd, timeout)
          ...procesar los que haya...
      end

  Regla general: xcb_poll_for_event consulta PRIMERO el buffer
  interno y, si esta vacio, el socket. xcb_wait_for_event siempre
  bloquea y lee del socket. NUNCA hay que asumir que poll(fd) cubre
  los eventos pendientes.

Notas:
  - Este bug es invisible si no se usa sync. Al introducir
    xcb.sync tras map_window, se manifesto de golpe.
  - Afecta a cualquier toolkit que mezcle poll() con XCB.
  - El sintoma clasico (draw solo tras input) apunta siempre a
    este problema: el flujo del evento Expose/MapNotify se ha
    perdido por el camino.

## Hito 14: Panel + sub-tabs + lazy loading end-to-end

- TabbedPanel anidado funciona: Recursos con 4 sub-tabs.
- set_window autoactiva el primer tab (momento correcto: ya hay
  window, ya se puede dibujar).
- Lazy loading verificado por log: cada factory corre una sola vez.
- start/stop al cambiar tab/sub-tab.
- El panel completo se dibuja al arrancar sin input.

## Leccion

Cuando el sintoma es "solo dibuja tras input", las causas tipicas
son (por orden de probabilidad):
  1. Eventos huerfanos en el buffer interno de XCB (este bug).
  2. Draw durante Window.new con la ventana aun no mapeada.
  3. Faltan StructureNotify / Exposure en el event_mask.
  4. Early return en draw() por damage_list vacia + force_redraw
     consumido.

## Hito 15: PanelApp con toggle por trigger

Patron de produccion:
- Proceso arranca una vez, Server vivo siempre (exit_on_empty=false).
- Panel se crea al arrancar y al recibir trigger "show"/"toggle".
- Panel se DESTRUYE al cerrarse (q, Esc, Mod4+Shift+Q, boton X).
- El proceso sigue vivo, esperando nuevo trigger.
- Al destruir, collectgarbage("collect") libera la RAM.
- Trigger por archivo: /tmp/lanetk-panel.cmd
    echo toggle > /tmp/lanetk-panel.cmd   abre si cerrado, cierra si abierto
    echo show   > /tmp/lanetk-panel.cmd
    echo hide   > /tmp/lanetk-panel.cmd
    echo quit   > /tmp/lanetk-panel.cmd

Server:watch_trigger(path, callback) - sondea cada 200ms mientras
hay trigger activo. No consume CPU en reposo: si no hay timers ni
trigger, el loop bloquea indefinidamente en poll().

Consumo:
- Proceso idle (panel cerrado): ~12 MB RSS, ~0.05% CPU.
- Panel abierto: ~17 MB RSS, CPU dependiente de los timers.
- Al cerrar panel: RAM vuelve a ~12 MB.

El atajo global lo envia el daemon de WM, no el toolkit.

## Archivos relevantes

- lib/server.lua    -> watch_trigger, _check_trigger, timeout 200ms
- lib/panelapp.lua  -> coordina Server + Panel, implementa show/hide/toggle
- examples/20-panel-toggle.lua -> demostracion completa

## Hito 16: layout con pesos + widgets que respetan su rect

Group ahora soporta weights:
- Cada hijo declara weight (default 1).
- Algoritmo: cada hijo recibe su minimo, el espacio extra se
  reparte proporcionalmente al weight.
- Si no cabe (extra < 0): escala proporcional al minimo. Los
  widgets recortan si su rect es menor que su contenido.
- weight = 0: el hijo solo recibe su minimo, no crece.

Widgets adaptados:
- Ring: max_w/max_h liberados. Crece hasta el rect. El radio se
  calcula de min(w,h).
- Text: clip si desborda y no hay wrap.
- Card: clip al area interior. El contenido no se sale.

Uso:
    Group.new {
        orientation = "horizontal",
        children = {
            { widget = sidebar, weight = 0 },   -- fijo
            { widget = content, weight = 1 },   -- crece
        },
    }
    -- o en add(child, weight)

## Primer tab real portado: Temperaturas

- lib/data/temps.lua: sampler puro (lee /sys, sin shell en lo
  posible).
- lib/tabs/temps.lua: tab { widget, start, stop } portado del
  original de Awesome.
- examples/21-tab-temps.lua: panel con el tab integrado.

Flujo completo validado:
  sampler -> vista -> tab -> panel -> ventana X11 -> pixels.

## Hito 17: reflow dinamico en leyendas (BarMulti)

Problema: con legend_cols fijo, al reducir el ancho de la ventana
los textos de la leyenda se pisaban o se volvian ilegibles, en
lugar de reacomodarse. Habia espacio vertical de sobra sin usar.

Solucion: reflow dinamico estilo CSS flex-wrap.

_compute_legend(w, avail_h) prueba de cols_max hacia abajo:
  for cols = legend_cols, legend_cols_min, -1 do
      rows = ceil(n / cols)
      col_w[c] = max(natural_w de cada item de la columna)
      total_w  = sum(col_w) + (cols-1) * legend_gap_x
      needed_h = rows * line_h + (rows-1) * legend_gap_y
      if total_w <= w and needed_h <= avail_h then
          -- encaja. repartir sobrantes.
          return { cols, rows, col_w, col_x, gap_y }
      end
  end
  -- ni con cols_min cabe: usar cols_min y clip.

Los sobrantes de ancho y alto se reparten proporcionalmente:
- ancho: se suma a la separacion entre columnas
- alto:  se suma a la separacion entre filas

Params:
  legend_cols      (maximo, default 2)
  legend_cols_min  (minimo, default 1)
  legend_gap_x     (default 12)
  legend_gap_y     (default 4)

Verificado: 3 cols en ancho, 2 cols en medio, 1 col en estrecho,
siempre con textos completos y sin solapamiento.

## Aplicar el mismo patron a otros widgets

Candidatos que sufren del mismo problema y deberian usar reflow:
- Rows (sensores en temps): con ventana estrecha, agrupar columnas.
- KV: idem.
- Pills: las etiquetas pueden caer a lineas multiples.
- Actions: los botones pueden pasar a 2 columnas si son muchos.

Los criterios de "cabe" cambian por widget (unos miden texto, otros
ancho de boton), pero el algoritmo general es el mismo: probar
configuraciones de mas a menos, elegir la primera que quepa, repartir
sobrantes.

## Reglas de max_w/max_h en widgets

Hallazgo importante de la sesion:
- Si un widget devuelve max_h = su alto natural, el padre le da
  exactamente ese alto. Nunca se estira. Resultado: huecos vacios.
- Si quieres que un widget crezca, devolver max_h = 10000.
- Si quieres centrar el contenido, valign = "center" en el draw,
  y max_h = 10000 en askMinMax.
- Si quieres que el contenido ocupe y el texto quede arriba, valign
  = "top" y max_h = 10000.

Widgets ajustados:
- Text: max_w/max_h liberados.
- KV: max_h liberado (crece en Y).
- BarMulti: askMinMax devuelve max_h = 10000.
- Rows: layout reparte filas al espacio disponible.

## BUG: particiones desaparecen tras reconstruccion (RESUELTO)

Sintoma: tras la primera actualizacion del timer (10s), las cards
de particiones desaparecian. No volvian hasta el proximo resize.

Causa: rebuild_parts() llamaba parts_row:clear() y volvia a añadir
cards, pero NO disparaba un relayout. Los hijos nuevos quedaban con
rect en 0 (x0=y0=x1=y1=0). Group:draw los recorre pero cada uno
dibuja en un rect vacio — invisibles. El relayout no ocurre hasta
el proximo ConfigureNotify (resize).

Este bug es el espejo del anterior "solo se dibuja tras input":
en aquel, faltaba dibujar; en este, falta relayoutear tras mutar
el arbol.

Fix: parts_row:invalidate_layout() al final de rebuild_parts, tras
añadir todos los hijos.

## Regla general: mutar el arbol requiere relayout explicito

Cuando un widget muta sus hijos (add, remove, clear, rebuild):

    self:invalidate_layout()   -- o el group equivalente

Sin esto, los hijos nuevos tienen rect 0 y no se dibujan, o los
viejos conservan rects obsoletos. La unica razon por la que "a
veces funciona" es que el proximo resize dispara un relayout
implicito.

Candidatos a revisar que mutan hijos:
- Lister cuando cambie set_items.
- TabsBar al añadir/quitar tabs en runtime.
- Cualquier lista con contenido dinámico.

Si el widget recibe un set_items o similar y NO dispara
invalidate_layout, probablemente tenga este bug latente.

## Hito 18: tabs Batería y Discos portados

- lib/data/bat.lua + lib/tabs/bat.lua
- lib/data/disk.lua + lib/tabs/disks.lua

Bateria:
  Anillo con color segun estado (charging=accent, low=crit,
  mid=warn, normal=telemetry). Spark de 60 muestras. Tres KV
  (Hardware, Estado, Salud). Timer de 10s.

Discos:
  Particiones reconstruidas cada 10s (con invalidate_layout tras
  rebuild). SMART asincrono: smartctl corre en background a
  /tmp/lanetk-smart.tsv, el tab lo lee cada 60s. KV de SMART y
  Hardware.

SMART asincrono: os.execute con "&" para no bloquear el server.
El archivo se escribe con mv atomico (tmp -> real).

## Estado del port

Portados hasta ahora:
  [x] Recursos (4 sub-tabs)
  [x] Bateria
  [x] Discos

Pendientes:
  [ ] Red (3 sub-tabs, necesita samplers net/wifi/ping/dispositivos)
  [ ] Inicio (avatar drag/zoom, necesita mas widgets)
  [ ] Procesos (necesita Lister/tabla con orden y click)
  [ ] Buscar (necesita TextInput)
  [ ] Notas (necesita TextInput)
  [ ] Configuracion (depende de theme_loader)

## Pendiente: coneccion WiFi desde el panel no funciona

Al pulsar un SSID en Red -> Redes, se abre el prompt de contraseña
y se ejecuta `nmcli dev wifi connect`, pero la conexión no se
establece. Falta tambien boton de desconectar.

Posibles causas:
- El child popup no recibe el foco X11 que necesita nmcli.
- nmcli requiere DBus y puede que el entorno de LaneTK no lo tenga
  completo.
- El password prompt nuevo no está pasando bien el texto.

Investigar cuando se porten los ajustes de red. No bloquea el resto.

## Hito 19: tabs Procesos y Configuración portados

Procesos:
- Lista ordenable por columnas (PID, USER, PRI, CPU%, RAM, TIME, CMD).
- Click en header cambia orden (asc/desc).
- Filtro inline con TextInput embebido (sin password_prompt).
- Barra de acciones al seleccionar una fila: Terminar, Forzar,
  Pausar, Continuar.
- Refresh cada 2s con `ps -eo ... --sort=... --no-headers`.
- Sin árbol/forest (simplificación del original).

Configuración:
- Cicladores tema/paleta con botones ◀ ▶.
- Aplicar guarda en conf.lua + muta theme in-place con
  theme.reload_in_place(palette_path).
- theme.rebuild() conectado por PanelApp: cierra y reconstruye el
  panel para que los tabs recapturen los colores.
- Sin wallpapers en esta iteración (pendiente, requiere validar
  los scripts de destino).

## Patron: cambio de paleta en caliente

1. Config llama theme.reload_in_place(T, palette_path).
2. Muta campos de T en su lugar (referencias compartidas ven el
   cambio).
3. Config llama theme.rebuild() (via PanelApp).
4. PanelApp:close() + show() reconstruye el árbol con los nuevos
   colores. Preserva el tab activo.

## Pendientes

- Inicio (portada con avatar, identidad, cards, reloj).
- Buscar (984 lineas, requiere lister con paginacion).
- Notas (bloqueado por prompt, dejado para despues).
- Laboratorio (sandbox).
- Wallpapers en Config (requiere validar scripts de locker/greeter).

## Hito 20: tab Inicio portado

Avatar circular (recorte con cairo_arc + clip), identidad
(user@host + distro), cards Sistema/Sesión, reloj con segundos.

## Conversion de avatares JPEG a PNG

Cairo solo carga PNG (cairo_image_surface_create_from_png). Los
.face de AccountsService suelen ser JPEG progresivo.

Solucion sin dependencias FFI: convertir a PNG en cache con la
primera herramienta disponible (ffmpeg, magick, convert). Cache
en ~/.cache/lanetk/avatar.png. Se regenera si el original es mas
reciente (`test -nt`).

data/inicio.find_avatar() devuelve siempre un PNG (o nil).

## Pendientes

- Buscar (984 lineas del original, el mas grande).
- Notas (bloqueado por prompt, dejado para despues).
- Laboratorio (sandbox).

## Hito 21: Launcher + SVG runtime + multi-monitor + foco

### librsvg via FFI

bindings/cdef/svg.lua + src/lib/svg.lua.
- Carga librsvg-2.so.2 lazy (solo al primer svg.load()).
- Cache de surfaces renderizados por path.
- svg.clear_cache() libera los bitmaps (no descarga la .so).
- Icon widget detecta .svg por extension y usa svg.load() en vez
  de cairo.load_png_cached().

### Multi-monitor

lib/screens.lua parsea `xrandr --query` para obtener rectangulos
de cada monitor. M.at(cx, cy) devuelve el monitor que contiene el
punto. Soporta la palabra "primary" en la linea de xrandr.

xcb.query_pointer(conn) devuelve (root_x, root_y) del cursor.
Necesita el root window como argumento (no 0).

Window.new({ x = "cursor-screen", y = "cursor-screen" }) centra
la ventana en el monitor del cursor.

### Foco del teclado con dialog

Para ventanas top-level (kind = "normal" | "dialog"):
- NO llamar set_input_focus(). El WM gestiona el foco.
- El WM envia FocusIn cuando nos toca.
- on_focus_in en Window.new se llama al recibirlo.
- TextInput:set_focused(true) se autorregistra como focus_widget
  del window. Antes solo lo hacia on_mouse_press, lo que obligaba
  a hacer click.

Para child windows (kind = "child"): el WM no interviene, hay que
llamar set_input_focus() explicitamente. El sistema de child
anterior sigue funcionando.

Flujo del launcher:
1. kind="dialog" + width/height fijos + x/y = "cursor-screen".
2. on_focus_in del Window llama launcher_tab.focus() que activa
   el TextInput.
3. TextInput autorregistra focus_widget → recibe KeyPress.
4. Esc cierra. El WM devuelve el foco a la ventana previa sin
   intervencion manual.

### Bugs resueltos

- xcb_query_pointer_reply_t: la struct real tiene root + child,
  no solo child. Sin root, XCB rechaza la respuesta.
- screens.list: regex de xrandr debe ignorar "primary" entre
  "connected" y la geometria.
- TextInput:set_focused(true) autorregistra el focus_widget.

## Hito 22: Launcher funcional

lib/data/launcher.lua: escanea /usr/share/applications + local,
parsea .desktop, cache de iconos filtrado (solo los que los
.desktop declaran). Busqueda con historial.

lib/tabs/launcher.lua: ScrollView + TextInput + ScrollBar.
Muestra iconos SVG a 32px. Filtra al escribir. Enter ejecuta.
Esc cierra.

Test verificado:
- Se abre en el monitor del cursor.
- Recibe teclado al abrir (via FocusIn + autorregistro).
- Tras cerrar, la ventana anterior recupera el foco sin clicks.

## Pendientes

- Notas (necesita editor de texto + clipboard X11).
- Laboratorio.
- Clipboard X11 (necesario para editor y FM).
- Terminal (PTY + libvterm).
- File manager.
- Reproductor de musica.

## Hito 23: TabsBar con iconos + theme

- TabsBar tiene dos modos:
  - compact=false: icono arriba, texto abajo. Tabs principales.
    pad_x=10, pad_y=6, icon_size=22.
  - compact=true: icono + texto al lado. Sub-tabs.
    pad_x=8, pad_y=2, icon_size=16.
- Iconos: PNG en ~/proyectos/lanetk/icons-png/32/tab-*.png
  (convertidos de SVG con convert-icons.sh).
- Color activo: bg=theme.accent, fg=theme.bg_rgb.
  Inactivo: bg=theme.bg_rgb, fg=theme.muted_rgb.
  Iconos tintados con el fg correspondiente (draw_surface_tinted).

## Panel: bg desde theme

Panel.bg viene de theme.bg_rgb si esta disponible. Antes estaba
hardcodeado a {0.10, 0.10, 0.13} (gris oscuro) y no se veia
consistente con el bg normal del theme.

## Modo compact en temps

temps.new(srv, theme, { compact = true }) omite las cards
individuales y devuelve todo dentro de un solo Card. Usado por
general.lua.

## Hito 24: damage-aware drawing

Antes: cada vez que un widget dañaba una región, Window:draw
recorria TODO el arbol. Los píxeles fuera del damage se
descartaban con cairo_clip, pero cada pango.draw_text creaba un
PangoLayout nuevo (fontconfig + shaping + alloc) y cada
rounded_rect construia paths. Coste real de CPU aunque el
resultado visual fuera minimo.

Medido: 4.9% de CPU con el panel abierto en Inicio (donde solo
cambia el reloj 1 vez por segundo).

Solucion: Area:should_draw() consulta el damage_list del window
y devuelve true solo si el rect del widget interseca alguno de
los rectangulos dañados. Los contenedores (Group, Card, Stack,
TabbedPanel) lo usan para saltar hijos que no hay que procesar.

    function Group:draw(cr)
        for _, c in ipairs(self.children) do
            if c:should_draw() then c:draw(cr) end
        end
    end

Casos especiales:
- force_redraw en el window: should_draw devuelve true para todo.
- damage_list vacia: should_draw devuelve false.
- Widget sin rect valido (x0==x1 o y0==y1): should_draw devuelve
  true, para que el primer layout lo procese.
- Widget sin window asignado: should_draw devuelve true.

Resultado: 0.0-0.3% de CPU en idle. Antes 4.9%.

Regla para widgets nuevos: si el widget tiene hijos, filtrar con
should_draw. Si el widget no tiene hijos, no hace falta: el padre
ya lo filtra antes de llamar su draw.

Esto vale para TODOS los widgets contenedores. Candidatos que ya
lo aplican: Group, Card, Stack. Otros que deberian aplicarlo:
Lister (cuando tenga filas), ScrollView interno.

## Hito 25: ContextMenu reutilizable

Widget flotante para menus contextuales. Uso:

    local cm = W.ContextMenu.new(srv, parent_win, theme)
    cm:show(x, y, {
        { label = "Terminar", on_click = function() ... end },
        { label = "Forzar", color = {0.9,0.4,0.4}, on_click = ... },
        { sep = true },
        { label = "Propiedades", on_click = ... },
        { label = "Deshabilitado", enabled = false },
    })

Arquitectura:
- Ventana child del parent_win. Sin WM, sin decoracion.
- xcb_grab_pointer para capturar TODOS los clicks mientras esta
  abierto. Cualquier click fuera del rect lo cierra y se consume
  (no pasa al padre).
- El child pide foco para que Esc lo cierre.
- Reposiciona si se sale del parent (clamp a los bordes).

## Cambio importante en Window: hooks globales de raton

Window.opts.on_mouse / on_mouse_release / on_mouse_move ahora se
llaman SIEMPRE, sin importar si hay arbol de widgets (root).

Antes solo se llamaban si self.root era nil. Eso impedia tener
un hook global en ventanas con contenido (panel, launcher, etc.).

Nuevo flujo en ButtonPress:
  1. Si hay root, hacer hit test y enrutar al widget.
  2. Siempre, llamar opts.on_mouse con las coordenadas.

Los widgets que ya gestionan clicks por si mismos no se ven
afectados porque reciben los eventos primero. El hook global solo
sirve de fallback (context menus, atajos, diagnosticos).

Regla: si un widget necesita interceptar clicks antes del arbol,
debe hacerlo en el widget mismo. Si necesita detectar clicks que
el arbol ignora, usar opts.on_mouse.

## Widget registrado

- lib/widgets/contextmenu.lua
- Registrado en lib/widgets/init.lua como W.ContextMenu

## Hito 25: ContextMenu reutilizable

Widget flotante para menus contextuales. Uso:

    local cm = W.ContextMenu.new(srv, parent_win, theme)
    cm:show(x, y, {
        { label = "Terminar", on_click = function() ... end },
        { label = "Forzar", color = {0.9,0.4,0.4}, on_click = ... },
        { sep = true },
        { label = "Propiedades", on_click = ... },
        { label = "Deshabilitado", enabled = false },
    })

Arquitectura:
- Ventana child del parent_win. Sin WM, sin decoracion.
- xcb_grab_pointer para capturar TODOS los clicks mientras esta
  abierto. Cualquier click fuera del rect lo cierra y se consume
  (no pasa al padre).
- El child pide foco para que Esc lo cierre.
- Reposiciona si se sale del parent (clamp a los bordes).

## Cambio importante en Window: hooks globales de raton

Window.opts.on_mouse / on_mouse_release / on_mouse_move ahora se
llaman SIEMPRE, sin importar si hay arbol de widgets (root).

Antes solo se llamaban si self.root era nil. Eso impedia tener
un hook global en ventanas con contenido (panel, launcher, etc.).

Nuevo flujo en ButtonPress:
  1. Si hay root, hacer hit test y enrutar al widget.
  2. Siempre, llamar opts.on_mouse con las coordenadas.

Los widgets que ya gestionan clicks por si mismos no se ven
afectados porque reciben los eventos primero. El hook global solo
sirve de fallback (context menus, atajos, diagnosticos).

Regla: si un widget necesita interceptar clicks antes del arbol,
debe hacerlo en el widget mismo. Si necesita detectar clicks que
el arbol ignora, usar opts.on_mouse.

## Widget registrado

- lib/widgets/contextmenu.lua
- Registrado en lib/widgets/init.lua como W.ContextMenu

════════════════════════════════════════════════════════════════════
  SESION LARGA: estetica, damage tracking, context menu, pills
════════════════════════════════════════════════════════════════════

## Hito 24: TabsBar con iconos y theme

TabsBar tiene dos modos:
- compact=false (default): icono ARRIBA, texto ABAJO. Tabs
  principales del panel. pad_x=10, pad_y=6, icon_size=22.
- compact=true: icono al lado del texto. Sub-tabs.
  pad_x=8, pad_y=2, icon_size=16.

Iconos: PNG en ~/proyectos/lanetk/icons-png/32/tab-*.png. Los SVG
originales se convierten con tools/convert-icons.sh que ya
prefija "tab-" a los de ~/.config/awesome/icons/tabs/.

Colores:
- Activo: bg=theme.accent, fg=theme.bg_rgb (texto oscuro sobre
  accent).
- Inactivo: bg=theme.bg_rgb, fg=theme.muted_rgb.
- Iconos tintados con draw_surface_tinted segun el fg.

Los sub-TabbedPanel pasan compact=true y el theme, para que sus
sub-tabs sean mas pequeños y usen los colores del panel.

## Hito 25: Panel bg desde theme

Panel.bg viene de theme.bg_rgb si esta disponible. Antes estaba
hardcodeado a {0.10, 0.10, 0.13}. Se veia inconsistente con el
bg_normal del theme (que en ayu es un azul marino #0b0e14).

## Hito 26: PillRow reutilizable

Widget para filas de pills [LABEL VALOR]. Colores dinamicos por
pill. Usado por el tab de Procesos para mostrar CPU, RAM, GPU,
Temp, Bat, Net, Uptime.

Notas de implementacion:
- Reserva de ancho al añadir: mide un valor tipico ("100%") ademas
  del actual, para que el layout no quede demasiado ajustado.
- set(id, value, color): si el ancho crece mas de 4px, se
  re-layouta solo la fila (sin invalidate global).
- Gap por defecto 10px, padding interno 10x4.

## Hito 27: ContextMenu reutilizable

Widget flotante para menus contextuales.

Uso:
    local cm = W.ContextMenu.new(srv, parent_win, theme)
    cm:show(x, y, {
        { label = "Terminar", on_click = function() ... end },
        { label = "Forzar", color = {0.9,0.4,0.4}, on_click = ... },
        { sep = true },
        { label = "Propiedades", on_click = ... },
        { label = "Deshabilitado", enabled = false },
    })

Arquitectura:
- Ventana child del parent_win. Sin WM, sin decoracion.
- xcb_grab_pointer para capturar TODOS los clicks mientras esta
  abierto. Cualquier click fuera del rect lo cierra y se consume
  (no pasa al padre).
- El child pide foco para que Esc lo cierre.
- Reposiciona si se sale del parent (clamp a los bordes).

## Hito 28: hooks globales de raton en Window

Window.opts.on_mouse / on_mouse_release / on_mouse_move ahora se
llaman SIEMPRE, sin importar si hay arbol de widgets.

Antes solo se llamaban si self.root era nil. Eso impedia tener
un hook global en ventanas con contenido (panel, launcher).

Nuevo flujo en ButtonPress:
  1. Si hay root, hacer hit test y enrutar al widget.
  2. Si el arbol NO consumio el evento (no hay active_element),
     llamar opts.on_mouse.

Los widgets que ya gestionan clicks por si mismos no se ven
afectados porque reciben los eventos primero.

## Hito 29: Modo compact en temps

temps.new(srv, theme, { compact = true }) omite las cards
individuales y devuelve todo dentro de un solo Card con borde.
Usado por general.lua para evitar doble-card.

En modo compact:
- El anillo lleva "°C máxima" escrito adentro (campo sub).
- El spark y el ring van lado a lado en la mitad superior.
- La tabla de sensores va en la mitad inferior.
- Todo dentro de un unico Card.

## Tab de Procesos reescrito

Rehecho de cero con:
- Columnas con reparto uniforme (misma funcion compute_cols para
  header y filas). Fixes: pid, user, pri, cpu, time. Flex: mem,
  comm.
- Pills de telemetria (PillRow) arriba: CPU, RAM, GPU, TMP, BAT,
  NET, UP.
- Filtro inline con TextInput.
- Tabla con borde (Card que envuelve header + lista).
- ContextMenu en click derecho: Terminar, Forzar, Pausar,
  Continuar, subir/bajar prioridad.
- Comparador en ScrollView:set_items que evita repintar filas que
  no cambiaron.

## BUG CRITICO: damage tracking disparando full redraws

SINTOMA: el panel parpadeaba constantemente. Con el mouse encima
del tab de Procesos, el CPU subia a 27%.

DIAGNOSTICO:
Instrumentamos add_damage y _damage_covers_most. El log mostro:

    [BIG_DAMAGE] 492x494 at (8,94)-(500,588) from area.lua
    [FULL] union=88% count=2

Dos causas sumadas:

1. Window:_damage_covers_most disparaba full redraw si
   #damage_list > 8. Cualquier rafaga de MotionNotify (que en
   X11 llega a 100+/s) genera 8+ rects pequeños por el hover de
   widgets, y eso disparaba full redraw del panel entero aunque
   el area dañada fuera minima.

2. ScrollView:set_items dañaba TODO el rect del scrollview en
   cada refresh (2s), sin diffear los items. Con 14 filas x 450px
   = 88% del area del panel → full redraw cada 2s.

3. Ademas, en Inicio, Area:set_hover y Area:set_pressed dañaban
   el rect entero de cualquier widget al que le pasara el mouse,
   aunque el widget no tuviera visual de hover.

FIXES APLICADOS:

A) _damage_covers_most: eliminado el threshold de count. Solo se
   mide el area de la union de rects (con grid 16x16 para no
   contar solapamientos). Si la union cubre >80% del panel,
   full redraw. Por debajo, partial.

B) ScrollView:set_items con comparador opcional. Si opts.compare
   se pasa, compara items viejos vs nuevos y daña solo las filas
   visibles que cambiaron. Sin comparador, comportamiento previo
   (daña todo).

C) Area:set_hover / Area:set_pressed: ya no dañan por defecto.
   Solo si el widget declara self._hover_visual = true o
   self._pressed_visual = true. Widgets que lo marcan: Button,
   TabsBar, CloseButton, Icon.

D) proc.lua: compara procesos por (pid, user, pri, cpu, mem,
   time, comm) para no repintar filas que no cambiaron.

E) Cache de la interfaz default. net_default_iface() con TTL de
   30s, evita io.popen("ip route") cada 2s.

RESULTADO: el panel en Inicio idle: 0.0% CPU. En Procesos: ~1-2%
(por el ps -eo cada 2s). Sin parpadeo.

## Dato importante sobre ps %CPU

El campo %CPU de `ps -eo pcpu` es un PROMEDIO desde que el
proceso arrancó, no el uso instantaneo. Verificado:

    ps -eo etime,pcpu,comm | grep luajit
    00:12  5.7 luajit
    01:12  2.6 luajit   (60s despues)
    
    top -p PID -b -n 1
    0.0 %CPU   (instantaneo)

El tab de Procesos muestra el %CPU que da `ps`, que es el
promedio historico. Esto es coherente con `ps aux`, `htop` y
`btop` en su primera columna. No es un bug.

Si en el futuro se quiere el %CPU instantaneo (como la primera
columna de `top`), hay que leer /proc/PID/stat dos veces y
calcular el delta. Es lo que hace `top` internamente.

## Lecciones aprendidas

1. El damage tracking es la pieza mas delicada del toolkit. Un
   bug en el reparto de rects puede arruinar el rendimiento sin
   que el usuario lo note en el codigo.

2. Instrumentar con logs es indispensable. Adivinar sin datos
   lleva a fixes que no arreglan nada. En esta sesion, hasta que
   no añadimos [BIG_DAMAGE] y [FULL] al log, no supimos que el
   problema eran rects grandes pidiendo full redraw.

3. El threshold de "cuantos rects son demasiados" es fragil. Es
   mejor medir area de union con una grilla.

4. Las rafagas de MotionNotify son un caso normal. El damage
   tracking debe aguantar 100+ rects pequeños sin disparar full.

5. Los widgets que no tienen visual de hover/pressed no deben
   dañar al cambiar esos estados. La mayoria de contenedores
   (Group, Card, etc.) no tienen visual propio.

6. El operador ">8 rects → full" es lo que enmascaraba todos los
   problemas anteriores. Al quitarlo, los problemas reales
   (ScrollView dañando todo) se hicieron visibles.

## Archivos modificados en esta sesion

- src/lib/widgets/tabsbar.lua   (iconos, compact, theme)
- src/lib/widgets/pillrow.lua   (nuevo)
- src/lib/widgets/contextmenu.lua (nuevo)
- src/lib/widgets/init.lua      (registro de PillRow, ContextMenu)
- src/lib/widgets/scrollview.lua (comparador de items)
- src/lib/widgets/card.lua      (should_draw en contenido)
- src/lib/widgets/stack.lua     (should_draw en activo)
- src/lib/widgets/group.lua     (should_draw en hijos)
- src/lib/widgets/button.lua    (marca _hover_visual)
- src/lib/widgets/tabsbar.lua   (marca _hover_visual)
- src/lib/widgets/closebutton.lua (marca _hover_visual)
- src/lib/widgets/icon.lua      (marca _hover_visual)
- src/lib/widgets/tabbedpanel.lua (theme + compact + sin close btn)
- src/lib/widgets/textinput.lua  (auto-registro focus_widget)
- src/lib/tabs/proc.lua          (reescrito: pills + menu + cmp)
- src/lib/tabs/general.lua       (temps compact)
- src/lib/tabs/temps.lua         (modo compact)
- src/lib/tabs/sys.lua           (sub-tabs con compact)
- src/lib/tabs/resources/init.lua (sub-tabs con compact)
- src/lib/tabs/net/init.lua      (sub-tabs con compact)
- src/lib/area.lua               (set_hover/set_pressed sin daño)
- src/lib/window.lua             (hooks globales + _damage_union_ratio)
- src/lib/panel.lua              (bg desde theme, sin close btn)
- src/lib/system.lua             (iconos sin prefijo tab-)
- src/lib/xcb.lua                (grab_pointer, query_pointer)
- src/lib/screens.lua            (parser de xrandr robusto)
- bindings/cdef/xcb.lua          (grab_pointer, query_pointer)

## Lo que queda pendiente

- Bug de alineacion de columnas en Proc (header no coincide
  con las filas).
- Editor de texto + clipboard X11 para Notas.
- Barra superior como proceso aparte.
- Tab Laboratorio (sandbox).

## Hito 30: barra superior (Fase A)

Barra mínima funcional:
- Ventana con kind="menu" (override_redirect = true).
- El WM no la ve: X11 la ignora, Awesome la ignora, cualquier WM
  la ignora.
- Ancho = ancho del monitor principal (VGA-1 si está conectado,
  sino el primero).
- Alto = 24px.
- Posición = esquina superior izquierda del monitor.
- Contenido: label "lanetk-bar" a la izquierda, reloj a la derecha.

## Decisión de diseño: la barra ignora el entorno

Se probaron dos aproximaciones antes:

1. kind="dock" + _NET_WM_STRUT_PARTIAL. Awesome respeta la barra
   y reserva espacio arriba, PERO el strut mal calculado provoca
   que el WM reubique todas las ventanas a un área que puede
   quedar fuera de la vista. Resultado: pantalla en blanco, tags
   vacíos, terminal inaccesible.

2. kind="dock" sin strut. La barra aparece encima pero las
   ventanas maximizadas no respetan el espacio reservado.

3. kind="menu" (override_redirect). El WM ignora completamente la
   barra. No reserva espacio, no toca workareas. Las ventanas
   pueden solaparse con la barra, pero eso es aceptable para un
   entorno donde el propio daemon gestiona ventanas y sabe qué
   espacio tiene la barra.

**Decisión**: opción 3. Razón:

- Un WM mínimo propio no necesita struts EWMH: el mismo daemon que
  gestiona las ventanas conoce las dimensiones de la barra y las
  pasa él mismo a la lógica de tiling.
- Los struts son el mecanismo estándar cuando la barra y el WM son
  procesos distintos que se comunican por protocolo. Aquí van a ser
  el mismo proceso o procesos muy acoplados.
- Además, con override_redirect la barra no se puede romper al
  cambiar de WM. Funciona en Awesome, dwm, i3, bspwm, XMonad,
  cualquiera.

Lo único que sí pierde con override_redirect:
- No aparece en tasklists ni en _NET_CLIENT_LIST.
- No se puede enfocar con Alt+Tab.
- No recibe _NET_WM_STATE (siempre encima, sticky, etc.).

Para una barra de sistema, todas son deseables o irrelevantes.

## Bug resuelto: terminal desaparecía

Cuando se ejecutaba la barra con strut, Awesome movía la terminal
a un área fuera de la vista, y el tag activo aparecía vacío (solo
wallpaper). No era un bug de LaneTK, era comportamiento del WM ante
un strut mal calculado. Con override_redirect no ocurre.

## Lo que funciona ahora

- La barra se dibuja por encima de la barra de Awesome sin
  conflicto.
- Texto completo, sin recorte.
- Reloj actualizándose cada segundo.
- No interfiere con nada: si se cierra, el escritorio sigue igual.

## Pendiente para la barra

Fase B: layout data-driven (left/center/right, pesos, toggle groups).
Fase C: separadores.
Fase D: contraste automático.
Fase E: widgets de telemetría.
Fase F: taglist, prompt, systray (EWMH).

## Fase A.2: alto y márgenes

Alto = 24px. Suficiente para textos de 10-11pt. Padding horizontal
via margin_spacer (widget de ancho fijo con weight=0) en vez de
usar padding del Group, porque el Group no distingue ejes.

## Hito 31: barra data-driven (Fase B)

La barra ahora se monta desde una spec (layout.lua) en vez de
estar hardcodeada.

## Arquitectura

lib/bar/engine.lua:
- M.build(theme, spec, registry) -> tabla con widget, height,
  groups, instances.
- Parsea las listas left/center/right. Cada item puede ser:
    - string                      nombre de widget
    - { toggle_group = "...", default = "visible" | "hidden",
        widgets = { ... } }       grupo toggle
- Resuelve cada nombre contra el registry.
- Reparto horizontal:
    left   weight = 0  (natural)
    center weight = 1  (absorbe el resto)
    right  weight = 0  (natural)
- El center queda alineado al espacio entre left y right, no al
  centro geometrico exacto. Es lo estandar y lo que espera el
  usuario.

lib/bar/constructors.lua:
- Registry nombre -> constructor function(theme) -> Area.
- En esta fase todos son placeholders que devuelven W.Text.
- M.register(name, fn) permite añadir constructores externos.

layout.lua (spec):
- position  = "top" | "bottom"
- height    = <px>
- separator = "arrow" | ... (Fase C)
- gap       = <px>  separacion entre widgets
- left, center, right = listas de items

## Reparto de espaciado

El gap entre widgets no lo da el Group (weight 0 no reparte), sino
spacers (Text de ancho fijo, weight 0) intercalados por el engine
en build_side. Asi el gap no depende del layout del Group y es
consistente. Fase E: cuando los widgets reales traigan su propio
padding, gap podra bajar a 0.

## Estados de grupo

Cada toggle_group tiene { default = "visible" | "hidden",
visible = bool }. Si visible = false, los widgets del grupo no se
añaden al layout. Cuando se implemente el toggle en runtime
(click derecho, atajo, etc.), hay que hacer Group:clear() y
remontar el arbol (o añadir/quitar hijos individualmente).

## Pendiente Fase C

- 7 modos de separador: arrow, glyph, glyph_thick, gap, none,
  underline, island.
- Cada separador se intercala entre widgets adyacentes.
- El tipo "arrow" es el de powerarrow: una flecha triangular entre
  cada par de widgets, con el color de uno de los dos.

## Hito 32: barra data-driven + separadores + cambio en caliente

### Arquitectura

Todo viene de la spec (layout.lua) y del theme (paleta). Nada
hardcodeado en el codigo del engine.

lib/bar/geometry.lua:
- M.compute(spec, mon) -> { x, y, w, h, position }.
- position admite "top" | "bottom" | "left" | "right" | "free".
- width/height aceptan <px> | "screen" | "N%" | nil.
- margin = { top, right, bottom, left } en px.
- Para position = "free", x/y aceptan <px> | "center" | "start"
  | "end" | "N%".

lib/bar/separators.lua:
- ArrowSep: triangulo de transicion entre dos colores. Fondo
  color_from, triangulo color_to.
- GlyphSep: separador de texto ("|" o "||").
- GapSep: spacer de ancho fijo.
- Wrapper: envuelve un widget con fondo color solido, subrayado,
  o isla redondeada.
- M.luminance(hex), M.pick_fg(hex): contraste automatico.

lib/bar/engine.lua:
- M.build(theme, spec, registry) -> { widget, height, sep_style,
  groups, instances }.
- M.adjust_height(base, sep_style): suma 6px para "underline",
  8px para "island".
- Los constructores devuelven { widget, color?, set_fg? }.
- El color del constructor se usa para el fondo del widget y para
  calcular el fg por contraste.
- Modos de separador:
    "arrow"        flecha entre widgets con color distinto
    "glyph"        barra fina "|"
    "glyph_thick"  barra gruesa "||"
    "gap"          solo hueco de gap px entre colores distintos
    "none"         hueco uniforme entre todos
    "underline"    subrayado por widget, barra +6px
    "island"       fondo redondeado por widget, barra +8px

lib/bar/constructors.lua:
- Registry nombre -> fn(theme) -> { widget, color?, set_fg? }.
- Widgets sin color (clock, taglist, prompt) van con fondo
  transparente.
- Widgets con color de telemetria (cpu, mem, gpu, net, temp,
  bright, vol, bat) leen su color de theme.telemetry.<key> con
  fallback a theme.accent.

### Cambio de layout en caliente

El ejemplo define 3 presets de geometria y un boton "cambiar" que
rota entre ellos. En cada click:
1. Se cierra la ventana actual con bar_win:close().
2. Se construye una nueva con la geometria del siguiente preset.
3. Se destruye el widget tree anterior (el GC lo libera).

Importante: el rebuild es DIFERIDO con timer de 50ms, porque el
boton que dispara el cambio vive dentro de la ventana que se va a
cerrar. Destruirla dentro del callback dejaria al boton con una
referencia colgando.

### Personalizacion total

Ni posiciones, ni colores, ni widgets estan hardcodeados en el
engine. Todo viene de:
- layout.lua: geometria, separador, gap, padding, listas de
  widgets, grupos toggle.
- theme (paleta): bg, fg, separator, accent, telemetry.
- constructors.lua: los widgets en si. Se pueden override con
  M.register(name, fn).

Ejemplos de cambios sin tocar codigo:
    position = "bottom"       barra abajo
    position = "right", width = 30, orientation = "vertical"
                              barra vertical (pendiente engine)
    position = "free", width = 600, x = "center", y = 0
                              dock centrado arriba

### Limitacion conocida

Una barra con ancho menor al minimo del contenido se corta por
el clip. Pendiente: auto-calcular el ancho minimo o avisar al
usuario.

## 2026-09-24 — Renombrado del proyecto: xui → LaneTK

El proyecto pasa a llamarse LaneTK. Cambios aplicados:

- Directorio: `~/proyectos/xui` → `~/proyectos/lanetk`.
- Config: `~/.config/xui/palette` → `~/.config/lanetk/palette`.
- Cache: `~/.cache/xui/` → `~/.cache/lanetk/`.
  `~/.cache/xui-icon-index.tsv` → `~/.cache/lanetk-icon-index.tsv`.
  `~/.cache/xui-launcher-history` → `~/.cache/lanetk-launcher-history`.
- Archivos temporales: `/tmp/xui-*` → `/tmp/lanetk-*`.
- Variables de entorno:
    `XUI_LOG`      → `LANETK_LOG`
    `XUI_PALETTE`  → `LANETK_PALETTE`
- `class_name` en los ejemplos: `LaneTK*` → `Ltk*`
  (LtkArea, LtkButton, LtkDemo, ...). `app_name` sigue siendo
  `"lanetk"` en todos los ejemplos.
- Default de `Window.new`: `app_name = "lanetk"`,
  `class_name = "LaneTK"` (solo para ventanas genéricas).
- Backups: alias `xcb-stable` → `lane-stable`,
  `xcb-restore` → `lane-restore`. Registro de backups:
  `~/.config/backup/projects.conf` pasa de `xcb=...` a `lanetk=...`.
  Directorio de backups: `~/backups/stable/xcb/` → `~/backups/stable/lanetk/`.

El nombre `xui` se mantiene en el resto de esta crónica como
referencia histórica. Ver nota al principio del documento.

================================================================================
  2026-09-25 — PLAN DE REDISEÑO DEL DAMAGE TRACKING
================================================================================

Contexto
--------

El bug recurrente de "stale pixels" (pixeles obsoletos) en los TabsBar
durante cambios rapidos de tab/subtab viene de una decision
arquitectonica: el toolkit usa UNA sola lista de damage para dos
propositos distintos que no son el mismo:

  1. Decidir que zonas del image_surface (backing store offscreen)
     hay que redibujar en este frame.
  2. Decidir que zonas del image_surface hay que copiar al surface
     X11 (blit a pantalla).

Estos dos propositos tienen requerimientos opuestos:

  - Para (1), la lista puede ser selectiva: solo las zonas donde algo
    cambio visualmente necesitan redibujarse. Todo lo demas mantiene
    su contenido del frame anterior, que sigue siendo correcto.

  - Para (2), la lista DEBE ser la union de todas las zonas donde el
    image_surface o el X11 cambiaron. Si se omite una zona que cambio
    en el image_surface pero no en el X11, el X11 se queda con basura.

El bug ocurre cuando (1) y (2) se mezclan. En particular:

  - Un tween que daña su propio rect (por ejemplo el Motors con
    set_animated) deja el damage_list lleno de rects de esa zona.
  - El TabsBar, que cambio (nuevo tab activo), no aparece en esa
    lista porque nadie lo daño en el mismo frame.
  - should_draw filtra el TabsBar contra el damage actual. Como no
    hay interseccion, el TabsBar no se redibuja al image_surface.
  - El blit copia solo la zona del Motors. El X11 queda con el
    TabsBar en su estado VIEJO (del ultimo frame que si lo cubrio).
  - El bug persiste hasta que algun otro frame daña el TabsBar por
    casualidad.

Datos de diagnostico (instrumentacion con LANETK_DAMAGE_DEBUG=1):

  - El damage_list llega a tener 45-49 rects por frame, la mayoria
    duplicados (los mismos rects añadidos multiples veces por tweens
    que dañan self en cada tick).
  - La mayoria de los frames durante la animacion del Motors tienen
    damage concentrado en su zona. El TabsBar no aparece.
  - No hay overlay activo durante el bug: no es crossfade, es damage
    puro.
  - Reproduccion: CPU -> GPU casi siempre. General -> GPU nunca.
    CPU deja mas tweens en vuelo (cores, ring, info, spark) y al
    cancelarlos al cambiar de tab, los rects de CPU quedan en el
    damage_list del proximo frame, que ya esta dibujando GPU. Esa
    incoherencia entre "damage de tab viejo" y "contenido de tab
    nuevo" es la que rompe la coherencia image_surface/X11.

Objetivo
--------

Eliminar de raiz los stale pixels. No parchear. Rediseñar el
pipeline de dibujo para que:

  - El image_surface NUNCA tenga contenido viejo en zonas que
    deberian tener contenido nuevo.
  - El X11 NUNCA tenga contenido viejo en zonas que deberian tener
    contenido nuevo.
  - El coste (CPU y memoria) sea aceptable en hardware modesto
    (Celeron 847, 2 GB RAM).
  - El crossfade entre tabs no requiera redibujar todo el arbol.

Arquitectura propuesta
----------------------

Tres cambios estructurales, en orden de aplicacion:

### Cambio 1: Dirty tracking por widget (reemplaza el damage_list para el image_surface)

Cada Area tiene un flag self._dirty (booleano). El significado es:
"este widget, o algun descendiente suyo, cambio visualmente desde
el ultimo draw".

  - Area:damage() marca self._dirty = true y propaga hacia arriba:
    recorre parent._dirty = true recursivamente.
  - Los contenedores (Group, Card, Stack, TabbedPanel) respetan el
    flag: si un hijo no esta dirty, no lo dibujan.
  - Al final de Window:draw, se limpia el _dirty de todo el arbol
    con un walk.

Efecto: solo se redibujan los widgets que cambiaron. Los que no
cambiaron mantienen su contenido del frame anterior (que sigue
siendo correcto porque no cambio nada).

### Cambio 2: Separar el damage del image_surface del damage al X11

Window mantiene DOS listas:

  - dirty_subtrees: lista de subtrees que tienen _dirty = true.
    Determina que se redibuja al image_surface.

  - damage_rects: lista de rects que cambiaron visualmente.
    Determina que se copia al X11 en el blit.

El damage_rects es SIEMPRE un superconjunto del dirty_subtrees en
terminos de zona cubierta. Si un subtree esta dirty, su rect se
añade al damage_rects.

Adicionalmente, el damage_rects se limpia y se recalcula al
principio de cada Window:draw a partir de los _dirty actuales.
Nunca se arrastran rects de frames anteriores.

### Cambio 3: Surface cache por subtree animable (opcional, para crossfade)

Los TabbedPanel (o mejor, el Stack) mantienen un surface cacheado
del tab activo. El surface se redibuja SOLO si el subtree del tab
esta dirty. Si no, se blitea directo al image_cr del Window.

El crossfade compone dos surfaces (viejo y nuevo), sin redibujar
el arbol completo. Coste del crossfade: N composiciones (baratas,
~0.1 ms cada una) en lugar de N draws completos del arbol.

Memoria: un surface por tab activo. Panel de 716x1026 px ARGB32 =
~2.9 MB. Aceptable.

### Cambio 4 (opcional, futuro): damage fino al X11

En vez de blit full al X11 en cada frame con dirty, calcular la
union de damage_rects y aplicar clip. Reducido a un solo rect
fusionado por frame, sin duplicados.

Fases de implementacion
-----------------------

Fase 1 (esta sesion): Cambio 1 + Cambio 2.
  - Añadir self._dirty a Area.
  - Modificar Area:damage() para propagar _dirty.
  - Modificar los contenedores (Group, Card, Stack) para saltar
    hijos no-dirty en draw.
  - Separar damage_list en dirty_subtrees + damage_rects en Window.
  - Blit al X11: siempre full (opcion simple) para empezar, sin
    clip. Se puede optimizar despues (Cambio 4).
  - Limpiar _dirty al final del draw.

  Criterio de aceptacion: ningun stale pixel reproducible con
  ningun cambio de tab, ni rapido ni lento, ni entre tabs ni
  entre sub-tabs. Idle CPU igual o mejor que ahora. No mas de
  ~2 ms extra por frame con dirty.

Fase 2 (siguiente sesion): Cambio 3.
  - Surface por Stack.
  - Crossfade sin redibujar el arbol.
  - Criterio: crossfade baja el uso de CPU a la mitad o menos
    durante la animacion.

Fase 3 (futuro): Cambio 4.
  - Fusion de damage_rects antes del blit.
  - Clip al blit para reducir ancho de banda.
  - Criterio: idle CPU < 1 % con timers corriendo.

Plan de rodaje
--------------

- Backup antes de empezar: src/lib.bak-dirty-redesign.
- Implementar el Cambio 1 primero, con tests manuales:
    1. Sin tocar nada: idle CPU igual.
    2. Cambiar de tab: no hay stale pixels.
    3. Animacion del Motors: no hay stale pixels.
    4. Crossfade: sigue funcionando, quizas mas rapido.
- Si algo falla, revertir desde el backup.
- Despues el Cambio 2, mismo procedimiento.

Riesgos
-------

- Propagar _dirty hasta la raiz en cada damage() puede ser costoso
  en arboles muy profundos. Mitigacion: el arbol tiene 4-6 niveles
  tipicamente, y la propagacion se corta cuando encuentra un nodo
  ya dirty (early exit).

- Los widgets que dibujan fuera de su rect (Header con wrap, Text
  con shadow si algun dia hay) pueden dejar contenido stale en
  zonas vecinas. Mitigacion: el damage_rects se calcula de la union
  de todos los rects de los widgets dirty, no del rect del padre.

- El blit full al X11 es mas costoso que el blit parcial. En el
  Celeron 847 son ~1-2 ms por frame. A 30 fps de animacion son 30-60
  ms/segundo, aceptable. En idle no hay frames.

- Si en algun momento se añade un widget que se dibuja en un
  surface propio y luego lo blitea al padre, ese widget necesita
  su propio _dirty en el surface y marcar el padre dirty cuando
  cambia. Documentar el patron.

Estado
------

- 2026-09-25: plan documentado. Instrumentacion LANETK_DAMAGE_DEBUG
  ya en su lugar (window.lua). Pendiente removerla al terminar la
  Fase 1.


================================================================================
  2026-09-25 — ESTADO DE OPTIMIZACION DE ANIMACIONES Y REDIBUJADO
================================================================================

Contexto
--------

Sesion larga. Se cerraron varios bugs y se gano granularidad en el
sistema de animaciones. Quedan pendientes tres frentes de
optimizacion que estaban en el plan original. Esta entrada resume
en que quedamos.

Cerrado en esta sesion
----------------------

1. Bug de TabsBar negro al cambiar de tab rapido (CPU -> GPU). Causa:
   Window:draw calculaba full desde _damage_covers_most, pero
   should_draw solo entiende force_redraw. Resultado: on_draw pintaba
   el fondo sin clip, pero los widgets fuera del damage_list (TabsBar)
   no se redibujaban al image_surface. Fix de una linea: full =
   self.force_redraw. Documentado en Apendice 7.3.

2. Rigidez de hijos en Group:layout. Los hijos que declaran
   min == max en el eje principal (por ejemplo un TabsBar) ya no se
   achican cuando el espacio escasea. Los flexibles absorben el
   recorte. Fallback a escalado total si ni los rigidos caben.
   Beneficio general: separadores, badges, chrome de tabs, etc.

3. Granularidad de animaciones. Master (animate_panel) + tres
   sub-toggles (animate_tabs, animate_widgets, animate_values) en el
   tab de Configuracion. Cada uno controla una capa distinta.

4. Intro automatico por tab. lib/widgets/intro.lua recorre el arbol
   al activar un tab y dispara animaciones de entrada para widgets
   que declaran _anim_kind ("ring", "spark", "dualspark", "barrow",
   "kv"). Se apoya en TabbedPanel:set_tab. No hay que tocar cada tab.

5. Animaciones de datos:
   - Ring:animate_to(v, text, sub, duration): tween del valor.
   - BarRow:set_animated(id, data, duration): tween del pct_value.
   - Spark:push_animated(v, duration): scroll + tail (dibuja el
     ultimo segmento de izquierda a derecha mientras todo se desplaza
     1 dx).
   - DualSpark:push_a_animated(v, duration): idem para la serie A.

6. Fix del umbral en push_animated: n_antes < 1 (no < 2). El segundo
   push (el que crea el primer segmento) ahora se anima.

7. Configuracion con M.set que añade claves nuevas a conf.lua si no
   existen (antes solo sobrescribia existentes).

Revertido
---------

Fase 1 del rediseno de damage (_dirty por widget + should_draw con
dirty tracking). Se revirtio a src/lib.bak-fix-damage-all. La causa:
muchos sitios del toolkit cambian estado sin llamar damage() o sin
parent asignado, asi que should_draw devolvia false para widgets que
si cambiaron. Rompia todo. El rediseno necesita auditoria completa
antes de aplicarse. Pendiente para una sesion dedicada.

Pendiente 1: Optimizacion del crossfade
---------------------------------------

Estado actual: durante un crossfade, Window:_damage_covers_most
devuelve true (porque hay overlay). Eso fuerza full redraw en cada
frame del fade. Se redibuja TODO el arbol (~15-20% CPU en Celeron
847 durante 300 ms).

Alternativas:

  A) Cache de surface por Card o por Stack.
     - Cada Card tiene su propio image_surface.
     - Cuando algo dentro de la Card cambia, se redibuja solo ese
       surface.
     - El arbol dibuja bliteando surfaces de Cards al image_cr.
     - El crossfade compone dos surfaces cacheados sin redibujar
       nada.
     - Coste del crossfade: composicion pura (~0.1 ms por frame
       en lugar de 5-15 ms por draw completo).
     - Coste de memoria: un surface por Card. Panel de 700x1026,
       ~5-8 Cards de 300x400 cada una: ~4-8 MB extra. Aceptable en
       el presupuesto actual (~17 MB RSS idle).

  B) Reducir el full redraw del crossfade.
     - Solo el primer frame del fade es full. Los siguientes solo
       redibujan lo que cambio de verdad (damage real) y componen
       el overlay.
     - Mas simple que A. Menos ganancia (~50-70% en lugar de ~90%).

Recomendacion: empezar por B (simple, sin redisenio). Si el coste
sigue alto en el Celeron, ir a A.

Pendiente 2: Idle CPU a ~0%
---------------------------

Hoy idle consume 5-15% CPU. Causa: los timers de refresh disparan
draws completos aunque los valores no hayan cambiado. En particular:

  - Text:set_text llama _remeasure + damage aunque el string sea
    identico. Mitigacion: early-return si el string no cambio.
  - BarRow:set, KV:set, Ring:set_value, etc. ya tienen early-return
    si el valor no cambio, pero el damage de los sub-widgets internos
    (Text) no lo tiene.
  - Los samplers (cpu, ram, gpu) muestrean cada 1-2 s. El timer
    dispara aunque el valor sea identico al anterior.

Mitigacion propuesta:
  - Añadir early-return en Text:set_text y Text:set_markup cuando el
    texto es identico. Es un one-liner.
  - Añadir un flag por widget _needs_draw que solo se setea cuando
    algo cambio realmente. Los widgets que no cambiaron no dañan.
  - Los samplers podrian devolver un hash del estado; el tab compara
    y solo llama set si cambio.

Coste esperado: idle CPU baja a <1% con timers corriendo.

Pendiente 3: Rediseno del damage tracking
-----------------------------------------

Objetivo: separar "que redibujar al image_surface" (por dirty real)
de "que blitear al X11" (por damage acumulado).

Estado: Fase 1 intentada y revertida. Lecciones:

  - Hay que auditar TODOS los sitios que llaman damage(), set_* y
    invalidate_layout, y TODOS los sitios donde un widget cambia su
    contenido sin llamar damage().
  - Hay que asegurar que TODOS los sub-widgets internos tienen
    parent asignado (BarRow, KV, Actions, Rows, PillRow, Wrapper,
    etc.). Muchos no lo tenian.
  - Hay que decidir si should_draw es el unico punto de decision o
    si Window:draw tambien filtra por dirty.
  - Hay que preservar la semantica de force_redraw y overlay como
    "dibujar todo".

Para retomar: pre-auditoria de los sitios. Grep de "damage()" y
"set_text" y "set_" en widgets para entender la superficie del
problema. Solo entonces aplicar. No hacerlo a medias.

Orden de ataque propuesto
-------------------------

1. Pendiente 2 (idle CPU): barato, mucho beneficio, poco riesgo.
   Un par de one-liners en Text.
2. Pendiente 1 (crossfade, opcion B): mediano, sin redisenio.
3. Pendiente 3 (rediseno damage): grande, requiere sesion dedicada.


================================================================================
  2026-09-25 / 26 — MIGRACION DE AWESOMEWM A BSPWM
================================================================================

Contexto
--------

Primera migracion real de awesome a bspwm como WM. LaneTK sigue siendo
el toolkit para los paneles. El objetivo fue dejar un entorno
funcional con bspwm + sxhkd + superpanel de LaneTK, portando los
atajos y comportamientos que ya existian en awesome. La migracion
quedo funcional pero dejo al descubierto bugs del toolkit que no
aparecian en awesome (single-monitor distinto, jerarquias de
servicios de sesion, tamanos calculados sobre la pantalla virtual).

Arranque
--------

- greetd -> bspwm.desktop -> "startx /usr/bin/env bspwm"
  Como consecuencia, ~/.xinitrc NO se ejecuta. Hay que tener esto
  en cuenta para cualquier setup que dependa de ese archivo.
- .xinitrc limpio con traps para matar huerfanos (terminology, scrcpy).
  Se aplica solo si algun dia se cambia el metodo de arranque.

Configuracion creada
--------------------

~/.config/bspwm/bspwmrc:
  - Export de DBUS_SESSION_BUS_ADDRESS y XDG_RUNTIME_DIR al principio.
    Sin DBUS, terminology y otros clientes EFL entran en bucle.
  - xrdb -merge ~/.Xresources + xsetroot -cursor_name left_ptr.
  - sxhkd en background (pgrep para no duplicar).
  - sh/monitores.sh (xrandr) + monitors.sh --watch (reparto de
    workspaces por monitor, reactivo a hotplug).
  - Configuracion visual: border 2px, gap 10px, split_ratio 0.52,
    borderless_monocle, gapless_monocle.
  - focus_follows_pointer true (ver nota abajo sobre su efecto en
    multi-monitor).
  - Regla: scrcpy state=floating.
  - Superpanel de LaneTK lanzado como daemon con pgrep guard.

~/.config/bspwm/monitors.sh:
  - Reparte workspaces: impares en VGA-1, pares en LVDS-1. Si VGA-1
    no esta conectado, los 9 van a LVDS-1.
  - --watch con bspc subscribe monitor para reaccionar al hotplug.

~/.config/bspwm/maximize.sh:
  - Toggle de maximizado. Tiled -> fullscreen. Floating -> maximiza
    respetando aspect ratio, anclado arriba-izquierda del monitor.
  - Usa xdotool getmouselocation --shell para encontrar el WINDOW
    bajo el cursor (no itera por bspc: el orden de stacking no es
    fiable en bspc query -N).
  - Usa xdotool windowsize + windowmove, NO bspc node -v (que solo
    mueve relativo).
  - Compensa el borde del frame con MX+2*BORDER y resta 2*BORDER+2
    del area util para no comerse 1px en el borde inferior.

~/.config/bspwm/scratchpad.sh:
  - Toggle de scrcpy (configurable con SCRATCH_CLASS / SCRATCH_CMD).
  - Busca por className en bspc query -T de cada nodo.
  - La primera vez que se invoca sin scratchpad, lanza SCRATCH_CMD.

~/.config/sxhkd/sxhkdrc:
  - Puerto completo de ~/.config/awesome/core/keys.lua adaptado a
    bspwm. Los comandos que no tienen equivalente (layout box,
    tags dinamicos, scratchpad propio de awesome, etc.) se omitieron.
  - Se agrego super+m -> maximize.sh.
  - Se agrego super+i -> trigger del superpanel.

Backups
-------

Se registraron dos proyectos en el sistema de backups existente
(~/.config/backup/projects.conf):

  bspwm=/home/ansmoun/.config/bspwm
  sxhkd=/home/ansmoun/.config/sxhkd

Con los atajos wm-stable / wm-restore / wm-list en ~/sh/aliases.sh.
No se automatiza: el usuario lo corre a mano cuando cambia algo.

Bugs del entorno encontrados y resueltos
----------------------------------------

1. Monitores lado a lado en lugar de apilados.
   Causa: bspwm no setea posiciones xrandr por si solo. Awesome
   probablemente tenia un script que si lo hacia.
   Fix: llamar ~/sh/monitores.sh (xrandr) al inicio del bspwmrc.

2. Cursor invisible.
   Causa: X sin theme de cursor aplicado en el root.
   Fix: xrdb -merge ~/.Xresources + xsetroot -cursor_name left_ptr
   en el bspwmrc. Ademas export de XCURSOR_THEME y XCURSOR_SIZE en
   el arranque si se quiere cubrir tambien clientes GTK.

3. Workspaces 1-5 en VGA, 6-9 en LVDS.
   Causa: super+N usaba bspc desktop -f ^N. El ^N es "N-esimo
   desktop por indice global", no "el desktop llamado N". Con los
   desktops ordenados 1,3,5,7,9,2,4,6,8, el indice 7 es el
   desktop llamado "4".
   Fix: quitar el ^. bspc desktop -f N busca por nombre.

4. focus_follows_pointer pisa el foco del atajo en multi-monitor.
   Con true, mover el mouse a otro monitor devuelve el foco a la
   ventana bajo el cursor, ignorando el cambio de foco que hizo el
   atajo super+N. En este setup se dejo en true (comportamiento
   esperado) pero hay que saber que el "salto de monitor por
   atajo" se ve inmediatamente revertido si el mouse esta en el
   otro monitor.

5. Terminology 100% CPU.
   Causa: DBUS_SESSION_BUS_ADDRESS no exportada (greetd + startx
   con comando explicito no ejecuta .xinitrc). Terminology entra
   en bucle de reconexion al bus.
   Fix: export en bspwmrc al inicio. Verifica con:
   tr '\0' '\n' < /proc/<pid>/environ | grep DBUS

6. super+m anclaba mal la ventana flotante.
   Causa: bspc node -v solo mueve relativo; xdotool windowmove
   posiciona el CONTENIDO del cliente (no el borde del frame).
   Fix: xdotool windowsize + windowmove, compensando 2*border_width
   en X/Y, y restando 2*border_width + 2 del area util para
   garantizar 1-2px de margen contra el borde del monitor.

7. Tamanos porcentuales de ventana calculados sobre la pantalla
   virtual.
   Causa: en multi-monitor con la pantalla virtual 1024x1368 y una
   ventana con width="70%", height="75%", el toolkit calculaba
   716x1026. Esa ventana no cabe en ningun monitor individual
   (VGA-1 es 1024x768, LVDS-1 es 1024x600). Cairo falla al crear
   el surface con status 11 (CAIRO_STATUS_INVALID_SIZE).
   Fix temporal: usar tamanos fijos + x="cursor-screen" en el
   ejemplo del superpanel. Fix real: window.lua deberia resolver
   porcentajes sobre el monitor actual, no sobre la pantalla
   virtual. PENDIENTE.

Bugs del toolkit descubiertos (pendientes)
------------------------------------------

A. Superpanel busy loop al cerrar el panel.
   Sintoma: el daemon consume 30-90% de CPU en idle despues de
   cerrar el panel. STAT=Rl, girando sin dormir.
   Diagnostico con strace -c: 12.240 access (todos fallando) +
   12.240 poll por segundo. El Server:_loop no duerme.
   Hipotesis probable: al cerrar el panel, los timers de los tabs
   (cpu, ram, gpu) no se cancelan. Quedan con next_at ya vencido.
   _next_timer_delay() devuelve 0. poll(fd, 0) retorna
   inmediatamente. El loop gira hasta cancelar.
   NO CONFIRMADO. Antes de tocar hay que:
     1. Verificar si Panel:close -> Window:_shutdown cancela los
        timers de los tabs (o si los tabs nunca reciben stop()).
     2. Verificar que _run_timers reprograma bien next_at.
     3. Instrumentar Server:_loop con un print del timeout para
        confirmar que es 0.
   Fix candidato: llamar server:cancel_all_timers() en el
   panel_opts.on_close de PanelApp:show. Una linea. Pero hay que
   confirmar la causa antes de aplicarlo.

B. Terminology busy loop con EFL/Efreet.
   Sintoma: terminology 80%+ CPU aun con DBUS exportada. Thread
   efreetd como huerfano del proceso. strace: 12.679 pselect6 +
   12.679 getpid por segundo. Busy loop interno de EFL.
   Causa probable: EFREET espera un servicio de Enlightenment que
   no existe en bspwm. Awesome probablemente lo lanzaba o
   satisfied la dependencia de otro modo.
   Workaround: usar st como terminal por defecto hasta investigar.
   Fix real: identificar que demonio de EFL falta y lanzarlo en el
   bspwmrc.

C. Sizing de window con porcentajes en multi-monitor (ver arriba,
   bug 7). Fix real pendiente.

Pendientes funcionales
----------------------

- Launcher de apps (examples/31-launcher.lua):
  * Navegacion con flechas arriba/abajo dentro de la lista de
    resultados.
  * super+d debe alternar: abrir si cerrado, cerrar si ya abierto.

- Panel de logout (port de ~/.config/awesome/widgets/logout.lua):
  * Grid 2x2 + franja inferior ancha: bloquear, cerrar sesion,
    reiniciar, apagar, suspender.
  * Iconos SVG (~/.config/awesome/icons/logout/).
  * Animacion de hover con lerp RGB (200 ms).
  * Cierre con click fuera (grab_pointer en X11) o Esc.
  * Cierra sesion con loginctl / awesome.quit -> bspc quit.

- Widget de captura de pantalla:
  * Panel flotante al pulsar Print o super+Print.
  * Pregunta foto o video, resolucion, pantalla completa o area.
  * Se puede implementar como primer "app" del toolkit sobre el
    entorno nuevo.

- Barra superior de LaneTK (Fase E):
  * Los constructores siguen siendo placeholders.
  * Los atajos apuntan al superpanel, no hay barra activa.

Estado del toolkit tras la migracion
------------------------------------

Todo lo referente al toolkit quedo PARQUEADO durante la migracion.
No hay cambios en src/ desde el commit anterior. El unico cambio en
examples/ fue el fix temporal del tamano del superpanel (32-superpanel.lua).

Prioridad para la proxima sesion de toolkit (a decidir):
  1. Bug A del superpanel (busy loop). Bloquea tener el panel como
     daemon permanente.
  2. Bug C del sizing (window.lua). Bloquea usar porcentajes en
     multi-monitor.
  3. Bug B de terminology (para dejar de depender de st).
  4. Launcher con flechas + toggle.
  5. Panel de logout.

Nota sobre disciplina de cambios
--------------------------------

En esta sesion se toco codigo del toolkit en dos momentos (fix de
tamano del superpanel, intento de kind="menu" en el launcher) sin
tener confirmado el diagnostico completo. Aprendizaje: en el
toolkit, NUNCA aplicar cambios sin (a) tener el bug reproducido,
(b) haber diagnosticado la causa con datos (strace, logs, inspeccion
del codigo), (c) haber confirmado el fix con el usuario. Aplicar
primero, despues preguntar, es la fuente de los rebotes y del
desorden. Esta nota es para futuras sesiones.


================================================================================
  2026-09-26 — BUG: SUPERPANEL CONSUME CPU TRAS CIERRE BRUSCO
================================================================================

Sintoma
-------

El daemon del superpanel consumia 30-90% de CPU en idle despues de
cerrar la ventana del panel. No importaba el WM (se reprodujo igual
en awesome y en bspwm). Stat=Rl (running todo el tiempo).

Diagnostico
-----------

Instrumentacion en tres pasos:

1. Server:_loop con LANETK_SERVER_DEBUG=1 imprimiendo timeout y
   cantidad de timers. Resultado: timeout=200 (correcto), 2 timers
   (correcto), 24.000 iteraciones por segundo. El timeout no era el
   problema; poll no estaba durmiendo sus 200 ms.

2. poll.wait_readable con LANETK_POLL_DEBUG=1 imprimiendo el retorno
   de poll(pfd, 1, timeout) y pfd[0].revents. Resultado contundente:
   205.219 llamadas con n=1 revents=0x11 en 5 segundos. Los otros
   11 eventos previos son los utiles.

   revents=0x11 = POLLIN (0x1) | POLLHUP (0x10). El socket esta en
   HUP: el otro extremo (Xorg) cerro la conexion. poll retorna
   inmediatamente cada vez. xcb_poll_for_event no consume nada porque
   POLLHUP no es un evento.

Causa raiz
----------

`bspc node -k` y `xdotool windowkill` usan XKillClient. XKillClient
no cierra una ventana: cierra TODA la conexion X del cliente. Como
el toolkit comparte la conexion XCB entre el Server y todas las
Windows, la conexion entera queda muerta. El proceso luajit sigue
corriendo sin saberlo, con el socket en POLLHUP.

En awesome, el equivalente de "cerrar ventana" (c:kill() de la API
de awesome) envia WM_DELETE_WINDOW, no XKillClient. Por eso el bug
no aparecia en awesome: el cierre era limpio.

En sxhkdrc teniamos:
    super + shift + q
        bspc node -k

`-k` es Kill (XKillClient). `-c` es Close (WM_DELETE_WINDOW). El
primero es agresivo, el segundo es correcto para cerrar ventanas.

Fix
---

Dos cambios, uno defensivo y uno de comportamiento:

1. lib/poll.lua: wait_readable ahora devuelve DOS valores:
       local readable, broken = poll.wait_readable(fd, timeout)
   `broken` es true si revents tiene POLLHUP, POLLERR o POLLNVAL.
   El consumidor debe dejar de usar el fd cuando broken es true.
   Es un cambio incompatible en la firma (antes era solo un valor)
   pero el unico consumidor es server.lua, que se actualiza en el
   mismo commit.

2. lib/server.lua Server:_loop: si broken, loguear y salir del loop
   (self.running = false; break). El daemon cierra limpio en lugar
   de girar hasta que lo maten.

3. sxhkdrc: super+shift+q y super+shift+c pasan de `bspc node -k`
   a `bspc node -c`. El cierre normal ahora es limpio.

Resultado
---------

Test 1 (cierre limpio, WM_DELETE_WINDOW via xdotool windowclose):
  El daemon sigue vivo, CPU 4.5%, responde a triggers. Correcto.

Test 2 (cierre brusco, XKillClient via xdotool windowkill):
  El daemon detecta el HUP, loguea "fd de XCB roto (POLLHUP/POLLERR),
  cerrando" y se cierra solo. Ya no gira al 100%. Correcto.

Aprendizaje
-----------

Cuando el event loop de un toolkit que comparte conexion XCB se
queda en un busy loop, la primera sospecha no son los timers: es el
fd del socket. XKillClient deja el socket en un estado terminal que
poll reporta como readable sin serlo. La deteccion de POLLHUP en el
wrapper es defensiva y evita que cualquier cliente externo que use
XKillClient (o un X server que se cae) deje el daemon girando.

Nota: mismo problema aplica a otras bibliotecas que comparten
conexion X (Cairo-XCB en particular). Si cairo_xcb_surface_create
falla con un fd en HUP, el toolkit deberia salir igual. Hoy no lo
hace explicitamente, pero el server sale primero al detectar el
broken en poll.wait_readable.

================================================================================
  2026-09-26 — LOGOUT MENU + LAUNCHER (mejoras) + SCREENSHOT WIDGET
================================================================================

Esta sesion cubre tres cosas:

1. Reorganizacion de apps/
   -----------------------
   examples/31-launcher.lua  -> apps/launcher.lua
   examples/32-superpanel.lua -> apps/superpanel.lua

   Se creo apps/ para productos finales. examples/ queda para
   prototipos de la API. sxhkdrc y bspwmrc actualizados.

2. Logout menu (port de awesome)
   -----------------------------
   - src/lib/widgets/logoutbutton.lua (nuevo widget reutilizable)
     * Fondo redondeado, icono PNG arriba, label abajo o al lado.
     * Hover anima hover_t de 0 a 1 en 200 ms via anim.tween_custom.
     * Interpola fondo, texto, y cambia icono light/dark en 0.5.
     * Sin XShape: las esquinas se ven redondeadas pero son
       rectangulares al click. Anotado en pendientes.
   - apps/logout.lua (daemon con trigger file)
     * Estados: idle/panel via toggle simple.
     * Atajo: super+shift+e -> echo toggle a /tmp/lanetk-logout.cmd.
     * Grid 2x2 + franja ancha: bloquear, cerrar sesion,
       reiniciar, suspender, apagar.
     * Cierra con Esc o click fuera (grab_pointer como ContextMenu).
     * cmd de cerrar sesion: loginctl terminate-session con
       fallback a terminate-user.
   - Iconos: SVG 48x48 convertidos a PNG 88x88 en
     icons-png/88/logout/ con rsvg-convert. Evita cargar librsvg
     en memoria para 10 iconos chicos.

3. Launcher: flechas + toggle + estetica
   -------------------------------------
   - TextInput: nuevos opts.on_up / opts.on_down. Sin ellos, el
     comportamiento anterior. Con ellos, consumen la tecla.
   - apps/launcher.lua reescrito como daemon con trigger file.
     Atajo: super+d -> echo toggle a /tmp/lanetk-launcher.cmd.
     Prewarm al arrancar: D.scan() + find_icon del top 20 del
     historial, antes de srv:run(). Sin esto, el primer super+d
     pagaba el scan + indice de iconos en el primer frame.
   - tabs/launcher.lua: move_selection + scroll_to_selected.
     Sin esto las flechas no hacian nada (TextInput no las
     manejaba, Window tampoco).
   - Estetica: marco exterior T.bg_rgb + interior T.bg_card_rgb
     con 2px de offset (popup dentro de marco). Input pill con
     corner_radius 22 y color_bg = theme.bg_focus. Sin footer
     (el contador "N resultados" quedo pendiente de decidir, hoy
     sin footer).
   - Colores hardcodeados eliminados: ahora todos vienen de la
     paleta activa via theme.*_rgb.

4. Screenshot widget (nuevo)
   --------------------------
   - src/lib/tabs/screenshot.lua: panel con dos tabs (Foto, Video).
     Cada tab lista los modos: Pantalla completa, cada monitor
     (via screens.list()), Area (slop o scrot -s), Ventana.
   - apps/screenshot.lua: daemon con maquina de estados:
       idle -> panel -> (foto | recording) -> done -> idle
     Atajo: Print y super+Print -> echo toggle a
     /tmp/lanetk-screenshot.cmd.
   - Foto: scrot para full/monitor/area, scrot -a para window
     tras leer xwininfo. Fallback a `import -window <wid>` si
     scrot falla.
   - Video: ffmpeg x11grab con -video_size region.w x region.h.
     Width/height redondeados a par (libx264 + yuv420p exige par).
     Indicador flotante arriba-derecha del monitor elegido.
   - Cierre: SIGINT a ffmpeg, se espera a que termine con un
     timer one-shot que llama on_recording_done.
   - Preview de resultado: PreviewArea custom (Area que reserva
     PREV_THUMB_H de alto y dibuja la miniatura con aspect ratio)
     + titulo + info (tamano, duracion) + path + botones:
     Abrir / Copiar ruta / Mostrar carpeta / Borrar / Cerrar.
   - Auto-cierre a los 15 s de inactividad.
   - Destinos: ~/Imágenes/Capturas/ y ~/Videos/Capturas/.
     Nombres YYYY-MM-DD_HHMMSS.png / .mp4.

5. Bugs encontrados en esta sesion
   --------------------------------
   - TextInput: on_up/on_down para flechas (implementado).
   - Widgets que reciben strings de color donde se espera tabla
     (r, g, b): Button y CloseButton tienen ese contrato. Todo
     debe pasar por theme.*_rgb.
   - srv:add_timer se REPROGRAMA SOLO. Los callbacks que se
     llaman una sola vez (do_foto_mode, do_video_mode, check
     de stop_recording) deben cancelar el timer en la primera
     llamada. Sin esto, bucle infinito.
   - xwininfo puede dar coords negativas cuando la ventana esta
     parcialmente fuera del viewport (ej. borde del monitor de
     abajo). ffmpeg x11grab falla con BadMatch. Fix: clamp_region
     ajusta la region a la interseccion con la pantalla virtual.

6. Pendientes anotados
   --------------------
   - XShape: ventanas con forma arbitraria (mencionado en
     pendientes.txt, INTEGRACIONES).
   - XComposite / XDamage: captura real de ventana, para que el
     video siga a la ventana aunque se mueva. Anotado en
     pendientes.txt.

Pendientes inmediatos de la app screenshot:
  - La decoracion del panel y de la preview aun no esta afinada.
  - El modo Video -> Ventana captura una region fija al momento
    del click. Si la ventana se mueve, la region no la sigue.

================================================================================
  2026-09-26 — CAMBIOS A LA API (resumen de la sesion)
================================================================================

Modulos NUEVOS en src/lib/:

- lib/icon_theme.lua
    Resuelve iconos del tema GTK activo. Detecta el tema desde
    ~/.config/gtk-3.0/settings.ini (o gtk-4, gtk-2, default
    hicolor). Respeta la cadena Inherits del index.theme. Busca
    en categorias estandar (mimetypes, places, actions, ...) en
    tamanos conocidos (16, 22, 24, 32, 48, 64, 96, 128, 256) y en
    scalable/. Caches en memoria (path y surface) por (name, size).
    API:
      M.theme()               -> nombre del tema activo
      M.parents()             -> cadena de herencia
      M.find_path(name, size) -> ruta al SVG/PNG, o nil
      M.resolve(name, size)   -> surface cairo listo para dibujar
      M.clear_cache()

- lib/widgets/cardbutton.lua
    Widget de tarjeta: icono PNG grande arriba, titulo y subtitulo
    debajo. Hover animado con anim.tween_custom (180 ms out_cubic),
    interpolando fondo, color de texto y color de icono. Tinte del
    icono via cairo.draw_surface_tinted sobre el fg interpolado.
    Soporta selected (borde accent de 2px).
    API:
      CardButton.new { icon, icon_dir, icon_size, title, subtitle,
                       bg_color, hover_color, fg_color,
                       fg_dark_color, fg_sub_color, border_color,
                       accent_color, corner_radius, font_title,
                       font_sub, width, height, on_click }
      .selected (boolean)
    Uso: grids de opciones (panel de screenshot, y futuro file
    manager, config, etc.)

Modulos REESCRITOS:

- lib/svg.lua
    ANTES: wrapper FFI sobre librsvg-2.so.2 (~20 MB de RSS al
    cargar la libreria). renderizaba siempre a 64x64 fijo y el
    consumidor escalaba al blitear.
    AHORA: wrapper FFI sobre libresvg.so.0.48 (~3 MB de RSS). El
    SVG se renderiza al tamano exacto que pide el consumidor.
    Cero cache de disco, cache solo en memoria.
    API:
      M.load(path, w?, h?) -> surface cairo ARGB32, o nil, err
      M.invalidate(path)
      M.clear_cache()
    Notas tecnicas:
      - resvg_render con transform identidad dibuja al tamano
        intrinseco del SVG en la esquina superior izquierda del
        pixmap. Hay que construir la matriz de escala (sx, sy)
        explicitamente. Leccion: el doc de resvg no lo aclara,
        hay que probarlo.
      - resvg devuelve RGBA premultiplicado. Cairo ARGB32 en
        little-endian espera BGRA. Hay que swapear R<->B al copiar
        el buffer al surface.
      - ffi.load necesita path absoluto cuando el soname no esta
        en la cache de ldconfig. Usar "/usr/lib/libresvg.so.0.48"
        (Void no crea el symlink libresvg.so.0).

- lib/widgets/textinput.lua
    Nuevos opts:
      on_up     : function()  -- llamado en Up cuando tiene foco.
                                Si esta definido, consume la tecla.
      on_down   : function()  -- idem Down.
      placeholder : string    -- texto visible cuando text == ""
      color_placeholder : {r,g,b} -- color del placeholder
    Sin on_up/on_down, Up/Down retornan false y se propagan a la
    Window (comportamiento anterior). Retrocompatible.

- lib/widgets/text.lua
    Text:set_text ahora protege contra nil: self.text = text or "".
    Sin esto, pango_layout_set_text escupia Pango-CRITICAL cuando
    algun consumidor pasaba nil.

- lib/widgets/scrollview.lua
    Fix de stale pixels: el contrato de draw_row ahora exige que
    el callback pinte SIEMPRE el fondo de la fila, con o sin
    hover. Documentado en Apendice(E).txt 7.5.

Cambios en apps/:

- apps/files.lua (NUEVO)
    File manager minimo. Ventana normal (no daemon). Se invoca
    desde el launcher o sxhkd. Arranca en $HOME por defecto, o en
    el path del primer argumento.
    Features:
      - Listado con iconos del tema activo (via icon_theme).
      - Columnas: Nombre, Tamano, Modificado, Tipo.
      - Navegacion: historial (back/forward), up, home.
      - Filtro de directorio en TextInput (abajo).
      - Ctrl+H oculta/muestra archivos ocultos.
      - "/" enfoca el filtro. Escape limpia el filtro o cierra.
      - Filtro recursivo con prefijo "**" (usa fd).
      - Click en carpeta entra, click en archivo xdg-open.
    Pendiente: renombrar, borrar, papelera (trash-put), crear
    carpeta, seleccion multiple, preview, grid view.

Cambios en el panel de screenshot (esta sesion):

- tabs/screenshot.lua reescrito:
    - Grid 3xN de CardButtons para elegir modo.
    - Cada modo con su color de hover.
    - Tab Video con fila de calidad (Baja/Media/Alta/Custom).
    - Boton "Avanzado" integrado en la grid del tab Video.
    - Sub-panel modal con preset de ffmpeg + CRF, persistido en
      ~/.config/lanetk/screenshot.conf.
    - Iconos PNG en icons-png/88/screenshot/ (SVG fuente en
      icons-src/screenshot/).

Lecciones aprendidas (para notes.md y Apendice E):

1. draw_row que solo pinta cuando hay hover: stale pixels. Ver
   entrada 7.5 del Apendice E.

2. srv:add_timer se REPROGRAMA SOLO. Los callbacks one-shot deben
   cancelar el timer en su primera ejecucion. Bug ya visto en
   screenshot y en files.

3. `for _, e in ipairs(x)` sin chequear el tipo cuando el mismo
   callback puede venir del ScrollView (item real) Y del Window
   (widget como primer argumento). Filtrar por campos presentes
   (item.path and item.name) antes de usarlo.

4. TextInput consume on_up/on_down si estan definidos. Sin ellos,
   las flechas se propagan a la Window (que las ignora si no hay
   on_key global). Esto resolvio el bug del launcher.

5. cairo.set_source_rgb recibe strings, no tablas. Los widgets
   del toolkit tienen convenciones distintas: Button/CloseButton
   quieren strings (theme.fg_normal, theme.bg_focus),
   CardButton/LogoutButton quieren tablas {r,g,b}
   (theme.fg_rgb). Verificar el contrato de cada widget antes de
   pasarle un color.

6. Filtro recursivo con prefijo explicito ("**") en lugar de
   siempre recursivo: la mayoria de las busquedas son locales, y
   fd en un HOME grande tarda.

================================================================================
  2026-09-27 — AUDITORIA DE MEMORIA
================================================================================

Objetivo: identificar leaks reales en los modulos con cache, medir el
impacto del GC de LuaJIT, y decidir si hace falta un LRU en los caches
de surfaces.

Metodo
------

Script Lua que mide RSS (via /proc/self/status) y collectgarbage("count")
en puntos clave. Tres ciclos:
  1. Cargar 100 iconos distintos via icon_theme.resolve.
  2. Llamar a los tres clear_cache (icon_theme, svg, cairo).
  3. Repetir 3 veces.

Resultados
----------

- RSS inicial del proceso: ~1.4 MB.
- Despues de requires (cairo, svg, icon_theme): ~4.3 MB.
  (La mayoria de ese salto son las .so C: libcairo, libresvg, libxcb.)
- Despues de cargar 100 iconos de 22x22: ~8.2 MB.
  (~38 KB por icono: pixels crudos son 2 KB, el resto es overhead
   de structs de cairo, buffer intermedio de resvg, y fragmentacion.)
- Ciclo 2 (recargar + limpiar): +140 KB.
- Ciclo 3 (recargar + limpiar): +8 KB.
- GC en pico: ~220 KB. Despues de collect: ~177 KB.

Conclusiones
------------

1. NO hay leak lineal. Los ciclos 2 y 3 se estabilizan (~+8 KB), lo
   que indica fragmentacion, no acumulacion.
2. El GC de LuaJIT esta sano: libera los cdata de resvg correctamente.
3. Los clear_cache SI liberan los recursos C (el cdata de Lua se
   libera solo). El RSS no baja inmediatamente porque glibc retiene
   los bloques liberados en lugar de devolverlos al kernel. Es el
   comportamiento normal del allocator, no un leak.
4. Bug real encontrado: icon_theme.clear_cache vaciaba la tabla pero
   no destruia los surfaces de cairo. Los cdata de Lua se liberaban
   (y con ellos las referencias desde Lua), pero el cairo_surface_t*
   subyacente quedaba vivo hasta que el proceso terminara. Fix
   aplicado: clear_cache ahora itera y llama cairo.destroy_surface
   antes de vaciar la tabla.

Decisiones
----------

- NO agregar LRU a los caches de svg/cairo. Un LRU con surfaces
  compartidos es peligroso sin refcounts: si el cache destruye un
  surface que un widget todavia referencia, el proximo draw usa
  memoria liberada. El peor caso realista (usuario navega 50
  directorios con iconos unicos) son ~3-5 MB, y los procesos son
  one-shot (mueren al cerrar la app).
  Si en el futuro un consumidor de larga vida (por ejemplo el
  superpanel con el file manager adentro) acumula MBs reales, se
  implementa refcount en ese momento, con evidencia concreta.

- NO agregar warning por tamano de cache. El umbral que se barajo
  (500 iconos = ~19 MB) no es alarmante en un sistema con 2 GB y
  procesos one-shot. El warn seria ruido.

Cambios en la API
-----------------

- lib/icon_theme.lua: clear_cache ahora destruye los surfaces de
  cairo antes de vaciar las tablas. Doc actualizado en README-lib.md.
- lib/mem.lua (NUEVO): instrumentacion opcional de memoria. Timer
  de 60 s que loguea RSS + GC si LANETK_MEM_DEBUG=1. No-op sin la
  variable. Doc en README-lib.md.
- apps/*.lua (los 4 daemons): llaman mem.attach(srv, "<nombre>")
  al arrancar. Sin efecto si LANETK_MEM_DEBUG no esta activa.

Pendientes que se derivan
-------------------------

- [ ] Fix del auto-show en apps/superpanel.lua: el daemon abre el
       panel al arrancar (por un app:show() que quedo del script de
       prueba original). Deberia arrancar en idle y esperar el
       primer trigger. Menor.

- [ ] Si en el futuro un daemon de larga vida acumula cientos de
       MBs, implementar refcount en los caches de surfaces. Por
       ahora no hace falta.

================================================================================
  2026-09-27 — SEPARACION DEL SUPERPANEL + APPS STANDALONE
================================================================================

Contexto
--------

El superpanel nacio como laboratorio: un solo proceso con todos los tabs
(Inicio, Configuracion, Recursos, Red, Bateria, Discos, Procesos, Buscar)
en un TabbedPanel grande. Fue util para iterar rapido sobre la API de
tabs y widgets, pero mezcla dos cosas distintas: un hub de informacion
y una app de configuracion del entorno.

Se decidio separarlo: cada tab ahora vive en su propia app standalone,
one-shot. El hub desaparece. El launcher cumple la funcion de hub (buscas
"Sysmon" y te la abre).

Modelo de cada app
------------------

Todas siguen el mismo skeleton:

  - Un Server propio (exit_on_empty default = true).
  - Una Window kind="normal" (respeta el WM; el WM la gestiona como
    cualquier otra ventana).
  - anim.init(srv, { fps = 30 }) para que las animaciones de entrada
    de los widgets (Intro) funcionen.
  - Window:set_root(tab.widget).
  - tab.start() / tab.stop() segun corresponda.
  - Esc cierra la ventana.
  - disable_q_close = true (no queremos que la 'q' cierre; el usuario
    puede estar escribiendo en un filtro).

No son daemons: no tienen trigger file, no esperan nada. Arrancan,
muestran, se cierran, el proceso muere.

Apps creadas
------------

  apps/config.lua     700x560   lib.tabs.config
  apps/inicio.lua     700x560   lib.tabs.inicio
  apps/sysmon.lua     900x560   lib.tabs.resources
  apps/network.lua    800x500   lib.tabs.net
  apps/battery.lua    500x560   lib.tabs.bat
  apps/disks.lua      800x500   lib.tabs.disks
  apps/procs.lua      900x600   lib.tabs.proc
  apps/search.lua     900x600   lib.tabs.search

Ya existian: apps/files.lua, apps/launcher.lua, apps/logout.lua,
apps/screenshot.lua. Esos se quedan como estan (files es one-shot,
los otros tres son daemons con trigger).

Archivos archivados
-------------------

  src/lib/system.lua         -> .bak-20260927
  src/lib/tabs/sys.lua       -> .bak-20260927
  apps/superpanel.lua        -> .bak-20260927

system.lua y tabs/sys.lua eran los agregadores especificos del
superpanel. panel.lua y panelapp.lua se quedan: son infraestructura
generica de "daemon con trigger file", reusable por cualquier app.

El bloque del superpanel en bspwmrc y el atajo super+i en sxhkdrc
se eliminaron.

.desktop files
--------------

Cada app tiene un .desktop en ~/.local/share/applications/lanetk-*.desktop.
Ahora el launcher las lista automaticamente (el sampler de
lib/data/launcher escanea los .desktop del usuario).

Los daemons (launcher, logout, screenshot) NO se invocan directamente
desde el .desktop. Se invoca un wrapper:

  tools/lanetk-trigger.sh <app> <trigger-file>

El wrapper:
  1. Comprueba si el daemon esta corriendo (pgrep -f apps/<app>.lua).
  2. Si no esta, lo arranca en background.
  3. Escribe "toggle" al trigger file.

Asi, un click en "LaneTK - Launcher" desde el launcher abre el panel,
aunque el daemon no estuviera corriendo (por ejemplo, primer arranque
de sesion donde bspwmrc aun no lo lanzo, o el usuario lo mato).

Apps totales del entorno: 12
  Archivos, Bateria, Buscar, Config, Discos, Inicio, Launcher,
  Logout, Procesos, Red, Screenshot, Sysmon

Cambios menores de config
-------------------------

  - bspwmrc: eliminado el bloque del superpanel.
  - sxhkdrc: eliminado super+i (era toggle del superpanel).
  - tools/lanetk-trigger.sh: nuevo.

Doc
---

  - README-tabs.md: eliminado el bloque sys.lua. Corregidas las
    menciones a sys.lua y PanelApp en la intro, en la nota de
    inicio.lua, en el bloque de config.lua (pasos y anti-patrones).
  - README-lib.md: eliminadas las menciones a PanelApp y superpanel
    en theme.lua y mem.lua. Los ejemplos de mem ahora usan
    <daemon> como placeholder.
  - Los apps NO se documentan en los README: son productos finales,
    no API. La API de tabs sigue siendo cada lib/tabs/*.lua, que ya
    estan documentados. apps/*.lua son consumidores.

Pendiente inmediato
-------------------

  - El tab de configuracion hoy solo cicla paleta + animaciones.
    Falta convertirlo en la app de configuracion del entorno: WM,
    tema de iconos del sistema, atajos, apps de arranque, barra.
    Es la base del ENTORNO DE ESCRITORIO MODULAR (ver pendientes.txt).

================================================================================
  2026-09-27 — EWMH (lectura)
================================================================================

Objetivo: habilitar el lector de propiedades EWMH del root y de las
ventanas. Es la base para el selector de WM, el taglist y el tasklist.

Cambios
-------

- bindings/cdef/xcb.lua: agregadas las declaraciones de
  xcb_get_property, xcb_get_property_reply_t,
  xcb_get_property_value, xcb_get_property_value_length y
  xcb_change_window_attributes.

- src/lib/xcb.lua:
    * get_property(conn, win, prop, ptype, long_length): lee una
      propiedad. Devuelve { type, format, data } o nil. Maneja
      format 8 (string) y 16/32 (tabla de enteros).
    * change_window_attributes(conn, win, mask): cambia el
      event_mask de una ventana existente. Necesario para
      suscribir PropertyChange en el root.

- src/lib/server.lua:
    * Nuevo metodo _process_events(). Antes habia dos bloques
      identicos en _loop que hacian el dispatch a ventanas
      registradas. Se extrajeron a un metodo unico. El metodo
      ahora tambien enruta los eventos del root al hook
      opcional self.on_root_event.

- src/lib/ewmh.lua (NUEVO):
    * M.new(srv) interna los atomos EWMH por conexion.
    * Getters: wm_name, supported, client_list,
      client_list_stacking, active_window, current_desktop,
      desktop_count, desktop_names, window_name.
    * subscribe(cb) / unsubscribe(): registra un handler de
      PropertyNotify del root. El callback recibe (atom, wid).
    * Solo admite un suscriptor a la vez.

Verificacion
------------

Script de prueba contra bspwm:
  wm_name:         bspwm
  desktop_count:   9
  current_desktop: 5
  desktop_names:   1, 3, 5, 7, 9, 2, 4, 6, 8
  client_list:     2 ventanas (scrcpy, st)
  window_name:     funciona (devuelve el titulo de cada ventana)

Escritura
---------

Agregado el mismo dia:

- bindings/cdef/xcb.lua: xcb_send_event.
- src/lib/xcb.lua: send_event() y send_client_message_root().
- src/lib/ewmh.lua: metodos
    * set_current_desktop(n)   -- client message _NET_CURRENT_DESKTOP
    * activate_window(wid)     -- client message _NET_ACTIVE_WINDOW
    * close_window(wid)        -- client message _NET_CLOSE_WINDOW
    * move_window_to_desktop(wid, n)  -- change_property _NET_WM_DESKTOP
    * wm_state(wid, action, s1, s2)   -- client message _NET_WM_STATE

Verificado contra bspwm:
  set_current_desktop(0) mueve al primer escritorio, el cambio es
  visible en la barra del WM. Volver con set_current_desktop(4)
  tambien funciona.

Pendiente
---------

- El taglist y el selector de WM consumen este modulo. Todavia no
  existen; el modulo queda como API disponible.
- _NET_MOVERESIZE_WINDOW, _NET_RESTACK_WINDOW, _NET_WM_MOVERESIZE:
  agregar cuando haga falta.
- No hay verificacion de que el atomo este en supported() antes de
  enviar. El WM ignora silenciosamente si no lo soporta. Un helper
  del tipo ewmh:supports(atom) seria util.

================================================================================
  2026-09-27 — HOT RELOAD ENTRE PROCESOS + FIX DE WORKSPACE
================================================================================

Objetivo: que un cambio de paleta aplicado en apps/config.lua se vea
en vivo en todas las demas apps del entorno, sin reiniciar nada.

Problema
--------

Cada app es un proceso separado con su propia copia del theme en
memoria. theme.reload_in_place cambia el theme DEL PROCESO QUE LA
LLAMA. Los demas procesos ni se enteran.

Ademas, los widgets copian los colores en su constructor
(self.rgb = theme.bg_rgb) y no los releen. Aunque el theme cambie
en el proceso, los widgets ya construidos siguen con los colores
viejos. Reconstruir el arbol es obligatorio.

Solucion
--------

1. Hot reload cross-process con SIGUSR1 + signalfd.

   El primer intento uso signal() con un handler Lua. LuaJIT no
   permite reentrar su runtime desde un signal handler: el proceso
   muere con "PANIC: unprotected error in call to Lua API (bad
   callback)".

   El fix es signalfd. SIGUSR1 se bloquea con sigprocmask, se crea
   un signalfd, y el fd se registra en el Server con add_fd. El
   Server lo pollea junto con el fd de XCB. Cuando llega una señal,
   el fd se marca legible, el callback hace read() para drenar, y
   despues llama a los callbacks en contexto normal.

2. Server: add_fd generico.

   El Server ahora acepta fds externos con add_fd(fd, cb). Los
   pollea con wait_multi (nueva funcion en poll.lua que reemplaza
   wait_readable cuando hay mas de un fd). Esto sirve para signalfd
   y para futuros casos (sockets, inotify, etc.).

3. App:rebuild in-place (sin cerrar la ventana).

   El primer intento de rebuild cerraba la Window vieja y creaba
   una nueva. Como la nueva se mapeaba en el workspace activo
   (donde estaba el cursor), la app se "teletransportaba" entre
   workspaces. El fix correcto no es mover la ventana al workspace
   original despues de crearla (parche que se probo y funciona
   pero roba el foco). El fix correcto es NO CERRAR LA VENTANA:
   reconstruir el tab y hacer win:set_root(tab.widget) en la misma
   Window. El id X no cambia, X no dispara MapNotify, el WM no
   reubica nada.

4. apps/config.lua: watch_theme = true + broadcast.

   Config es la unica app que hace reload_in_place por si misma
   (cuando el usuario pulsa Aplicar). Con watch_theme = true, ese
   reload_in_place local dispara tambien el rebuild del arbol.
   Despues llama a reload.broadcast() para avisar a los demas.

5. config.lua (tab): escribe tambien ~/.config/lanetk/palette.

   D.set("palette", ...) escribe a conf.lua del awesome original
   (~/.config/awesome/conf.lua). theme.find_palette_path() lee de
   ~/.config/lanetk/palette. Son dos archivos distintos. Ahora el
   tab escribe los dos.

Cambios de API
--------------

- bindings/cdef/xcb.lua: signalfd, sigprocmask, sigemptyset,
  sigaddset, signalfd_siginfo, getpid, kill, read.

- lib/poll.lua: wait_multi(fd_list, timeout). Devuelve
  (any_readable, any_broken, ready) donde ready[i] indica si el
  i-esimo fd esta listo. wait_readable sigue existiendo.

- lib/server.lua:
    * add_fd(fd, cb): registra un fd externo.
    * extra_fds: lista de fds externos.
    * _process_extra_fds: llama a los callbacks de los fds listos.
    * _loop usa wait_multi cuando hay fds externos.

- lib/reload.lua (NUEVO):
    * install(srv, cb): bloquea SIGUSR1, crea signalfd, registra cb.
    * broadcast(): SIGUSR1 a todos los apps/*.lua vivos excepto este.

- lib/ewmh.lua: window_desktop(wid).

- lib/app.lua:
    * reload.install en el constructor.
    * opts.watch_theme (bool): si true, tambien theme.watch.
    * App:rebuild reconstruye el tab y llama win:set_root en la
      misma Window (no cierra la Window).

Fix colateral
-------------

- ~/.config/bspwm/bspwmrc: LANETK_DIR no estaba definida. Cuando se
  elimino el bloque del superpanel hace dias, un regex se llevo
  tambien la definicion de la variable. Los tres if [ -d
  "$LANETK_DIR" ] evaluaban [ -d "" ], false, y los daemons nunca
  arrancaban al iniciar sesion. Restaurada.

Pendiente
---------

- El rebuild in-place asume que cada tab cancela sus timers en
  stop(). Si un tab tiene un timer propio y no lo cancela, sigue
  disparando sobre widgets muertos. Contrato ya documentado, pero
  vale auditarlo cuando se agreguen tabs con timers.

================================================================================
  2026-09-28 — GREETER LEFTY (proyecto downstream) + MODULOS NUEVOS
================================================================================

Lefty es un greeter construido sobre LaneTK. Vive en su propio
repositorio (~/proyectos/lefty) y consume la API pública del toolkit
como cualquier otra aplicación. La sesión de desarrollo cubrió:

Modulos NUEVOS en LaneTK
------------------------

- lib/greetd.lua
    Cliente del protocolo de greetd. JSON line-delimited sobre Unix
    socket. Los cuatro mensajes del protocolo: create_session,
    post_auth_message_response, start_session, cancel_session.
    Ver README-lib.md para la API completa.

    Nota crítica: start_session NO espera respuesta. greetd solo
    procesa el mensaje, mata al greeter, y lanza la sesión del
    usuario. Un callback ahí es deadlock. El metodo cierra el socket
    inmediatamente despues de mandar el mensaje.

- lib/data/users.lua
    Descubre usuarios reales del sistema desde /etc/passwd. Filtra
    uid >= 1000, shell de login valida, y blacklist (greeter, nobody).

- lib/data/last_user.lua
    Persiste el ultimo usuario autenticado en /var/lib/lefty/last-user.
    Lee y escribe. Sin dependencia del toolkit.

Cambios en modulos existentes
-----------------------------

- lib/data/inicio.lua
    * find_avatar(username?) ahora acepta username explicito. Antes
      usaba $USER siempre, lo cual fallaba en un greeter que corre
      como "greeter" pero muestra el avatar de otro usuario.
    * convert_to_png(src, username?) cambia la firma y el cache pasa
      de "avatar.png" a "avatar-<username>.png". Cada usuario tiene
      su propio cache, sin pisarse.

- lib/server.lua
    Server:_process_events extraido del loop. Antes habia dos bloques
    identicos de dispatch; ahora es un metodo unico con hook
    on_root_event para eventos del root.

- lib/ewmh.lua
    Agregado window_desktop(wid). Util para preservar el escritorio
    actual al reconstruir ventanas en caliente.

Decisiones de diseno de la sesion
---------------------------------

- Lefty es un proyecto separado.
    El toolkit provee la API. Las aplicaciones del entorno (lefty,
    launcher, screenshot, etc.) son downstream. Esto permite que
    cada app tenga su propio README, su propia instalacion, su
    propio ciclo de releases.

- Un solo README para lefty, sin notes.md ni apendices.
    El proyecto es chico. Un README extenso alcanza.

- Instalacion en /opt para el greeter.
    El usuario "greeter" no puede leer /home/ansmoun/proyectos/. Los
    proyectos se copian a /opt/lanetk y /opt/lefty con permisos de
    lectura para todos. En desarrollo se sigue editando en
    ~/proyectos/; install.sh sincroniza cuando hace falta.

- Config del greeter en /etc/greetd/lefty.conf.
    El proceso corre como "greeter", su $HOME es /home/.greeter, no
    puede leer la config del usuario final. La config del sistema va
    en /etc/greetd/.

- Test con Xephyr.
    Correr el greeter en Xorg requiere VT y politicas de consola.
    Xephyr permite probar la UI en una ventana anidada, sin sudo, sin
    reiniciar la sesion. Ver tools/test-greeter.sh de lefty.

Bugs encontrados en la sesion
-----------------------------

1. Deadlock en start_session.
    Sintoma: al autenticar, la pantalla se congela, todos los
    procesos del greeter quedan vivos, greetd no lanza la sesion.
    Causa: el cliente esperaba una respuesta que greetd nunca envia.
    Fix: start_session no recibe callback. Cierra el socket despues
    de mandar el mensaje. El consumidor debe salir con os.exit(0).

2. Fds heredados de greetd.
    Sintoma: mismo cuelgue, pero incluso despues del fix 1. En
    /proc/<pid>/fd de todos los procesos del greeter aparece el
    mismo socket (el del session-worker de greetd). Greetd no puede
    cerrar el worker hasta que TODOS cierren el socket.
    Fix: pendiente. La solucion correcta es llamar close_range(3,
    ~0, CLOSE_RANGE_UNSHARE) desde FFI antes del exec del cliente.
    NO hacerlo desde el shell: cerrar el fd del propio script
    cuelga el sistema sin acceso a TTYs.

3. Forward references en Lua sin declaracion.
    get_current_username se usaba en un closure antes de estar
    definida. Se resolvia como global, nil al ejecutarse, crash.
    Fix: forward declaration local + asignacion abajo.

4. $HOME = /root con sudo.
    install.sh usaba $HOME para resolver paths del proyecto, pero
    sudo cambia HOME a /root. Fix: leer SUDO_USER y consultar
    /etc/passwd.

5. Xorg.wrap bloqueando usuarios no-console.
    Correr Xorg desde una sesion X existente falla con "Only console
    users are allowed to run the X server". Fix: /etc/X11/Xwrapper.config
    con allowed_users = anybody. O usar Xephyr para tests.

6. Cursor invisible en Xephyr.
    Xephyr necesita -sw-cursor y XCURSOR_THEME en el entorno.

7. Terminal trabada en ST luego de un Ctrl+Shift+V.
    No es del toolkit. ST quedo en un estado raro. Se recupera con
    kill desde otra terminal.

Estado del greeter lefty
------------------------

Funcional:
- Conexion XCB, ventana de login.
- Deteccion de usuarios, sesiones, avatar.
- Flujo de autenticacion greetd (con el fix 1).
- Layouts centered y win10.
- Instalacion en /opt.
- Test aislado con Xephyr.

Pendiente:
- Fix del bug 2 (fds heredados). Bloquea el reemplazo del greeter
  actual de nwg-hello.
- Corregir la posicion de la card en pantalla completa.
- Wallpaper, fondo del card, layouts win8 y gnome.

Sistema (fuera del toolkit)
---------------------------

- /etc/X11/Xwrapper.config con allowed_users = anybody.
- Usuario greeter con home en /home/.greeter.
- /etc/greetd/lefty.conf con layout = win10.
- /opt/lanetk y /opt/lefty instalados.
- /var/lib/lefty/last-user creado por install.sh.

El wrapper de produccion en /etc/greetd/start-greeter.sh quedo con la
version del backup de la sesion anterior. La version nueva con el fix
de fds esta pendiente de aplicar.

