# LaneTK — Documentación

Toolkit gráfico en LuaJIT sobre X11. Reemplaza wibox + gears + beautiful
de AwesomeWM. Los bindings son FFI puro sobre XCB, Cairo, Pango,
xkbcommon y librsvg.

Esta documentación describe la API activa del toolkit, organizada por
carpeta del código fuente. Cada README-*.md corresponde a una carpeta
de `src/lib/`.

## Estructura

| Documento | Cubre | Carpeta fuente |
|---|---|---|
| `README-lib.md` | Núcleo gráfico + infraestructura | `src/lib/` |
| `README-widgets.md` | Árbol de widgets | `src/lib/widgets/` |
| `README-bar.md` | Motor de barra superior | `src/lib/bar/` |
| `README-data.md` | Samplers del sistema | `src/lib/data/` |
| `README-tabs.md` | Tabs del panel | `src/lib/tabs/` |
| `README-helpers.md` | Utilidades sin dependencias | `src/lib/helpers/` |

## Documentos complementarios

| Documento | Contenido |
|---|---|
| `notes.md` | Crónica del proyecto. Decisiones, bugs resueltos, hitos. Referencia histórica, no guía de uso. |
| `Apendice(E).txt` | Anti-patrones consolidados por tema. Checklist antes de tocar el toolkit. |
| `pendientes.txt` | Catálogo de cosas por hacer. No es un plan cerrado. |

## Índice por módulo

### README-lib.md — Núcleo gráfico e infraestructura

**Núcleo gráfico** (bindings FFI sobre las librerías C):

- `xcb.lua` — conexión XCB, ventanas, eventos, átomos, hints, foco.
- `cairo.lua` — superficies, contextos, primitivas de dibujo, PNG.
- `pango.lua` — texto plano, markup, medición, entidades HTML.
- `xkb.lua` — keycodes a keysym, nombre, texto, modificadores.
- `svg.lua` — render de SVG en runtime vía librsvg.

**Infraestructura** (servicios de alto nivel):

- `log.lua` — logging con niveles, controlado por `LANETK_LOG`.
- `theme.lua` — carga de paletas, colores derivados, reload en caliente.
- `server.lua` — event loop con `poll()`, timers, trigger file.
- `window.lua` — ventana X11 con doble buffer, damage tracking, foco.
- `screens.lua` — lista de monitores vía `xrandr`.
- `anim.lua` — motor de animaciones, tweens, springs, crossfades.

### README-widgets.md — Árbol de widgets

Todos los widgets heredan de `Area`. Documentados por orden de complejidad:

- `area.lua` — clase base. Contrato `askMinMax`, `layout`, `draw`, `getByXY`, `should_draw`.
- `widgets/init.lua` — registry `W.*`.

**Contenedores:** `group.lua`, `stack.lua`, `card.lua`, `tabbedpanel.lua`.

**Primitivos visuales:** `text.lua`, `header.lua`, `bignum.lua`, `button.lua`, `icon.lua`, `closebutton.lua`, `rowparse.lua`.

**Datos y gráficos:** `ring.lua`, `spark.lua`, `dualspark.lua`, `kv.lua`, `barrow.lua`, `motors.lua`, `rows.lua`, `barmulti.lua`, `pills.lua`, `pillrow.lua`.

**Acciones y listas:** `actions.lua`, `scrollview.lua`, `scrollbar.lua`, `scrolllink.lua`.

**Navegación y entrada:** `tabsbar.lua`, `textinput.lua`, `contextmenu.lua`.

### README-bar.md — Barra superior

Motor data-driven. La spec (`layout.lua`) describe qué widgets van en cada
sección; el engine los monta.

- `engine.lua` — lee la spec, arma el árbol, aplica separadores.
- `geometry.lua` — resuelve posición y tamaño sobre un monitor.
- `separators.lua` — primitivas de separadores (Arrow, Glyph, Gap, Wrapper).
- `constructors.lua` — registry de constructores de widgets de barra.

### README-data.md — Samplers

Módulos que leen del sistema. Sin dependencia del toolkit.

- `init.lua` — registry de los samplers principales.
- `cpu.lua`, `ram.lua`, `gpu.lua`, `temps.lua` — telemetría de recursos.
- `disk.lua`, `net.lua`, `wifi.lua`, `ping.lua` — almacenamiento y red.
- `bat.lua` — batería.
- `config.lua` — lectura y escritura de `conf.lua`.
- `inicio.lua` — datos estáticos del tab Inicio.
- `notes.lua` — gestión de notas en Markdown.
- `dispositivos.lua` — descubrimiento de dispositivos en la red local.
- `launcher.lua` — escaneo y búsqueda de aplicaciones `.desktop`.
- `search.lua` — búsqueda de archivos asíncrona con `fd`.

### README-tabs.md — Tabs del panel

Cada tab es un módulo con `M.new(srv, theme)` que devuelve `{ widget, start, stop }`.

- `sys.lua` — agregador de Inicio + Configuración.
- `resources/init.lua` — agregador de Recursos (General, CPU, RAM, GPU).
- `net/init.lua` — agregador de Red (Conexión, Registro, Redes).
- `inicio.lua`, `config.lua`, `general.lua`, `cpu.lua`, `ram.lua`,
  `gpu.lua`, `temps.lua`, `bat.lua`, `disks.lua`, `proc.lua`,
  `search.lua`, `launcher.lua`, `notes.lua`.

### README-helpers.md — Helpers

Utilidades sin dependencias de X11 ni del árbol de widgets.

- `util.lua` — strings, archivos, shell, config.
- `format.lua` — formateo de tamaños, tiempos, fechas.
- `async.lua` — comandos shell en background.
- `graphics.lua` — primitivas de dibujo Cairo (barras, anillos, sparklines).
- `init.lua` — reexporta `util` y `format`.

## Convenciones

Los README siguen una plantilla uniforme por módulo:

- **Propósito** — qué hace, en una línea.
- **Alcance** — qué cubre y qué no.
- **Cómo funciona** — mecánica interna y decisiones de diseño.
- **API** — constantes, funciones, métodos, callbacks.
- **Patrón** — ejemplo de uso correcto.
- **Anti-patrón** — errores comunes, con referencia al Apéndice E.
- **Notas** — detalles sueltos.

Los anti-patrones consolidados viven en `Apendice(E).txt`, agrupados
por tema en lugar de por módulo. Consultar antes de tocar el toolkit.

## README-lib.md

#

## README-lib.md

### Núcleo gráfico

Bindings FFI sobre las librerías C. Ningún módulo de esta sección conoce el concepto de "widget".

#### xcb.lua

**Propósito.**
Wrapper FFI sobre `libxcb`, `libxcb-util.so.1` y, de forma lazy, `libxcb-icccm.so.4`. Expone las operaciones de X11 que usa el toolkit como funciones planas; la conexión viaja como primer argumento.

**Alcance.**
Cubre conexión, creación y configuración de ventanas, eventos, átomos, propiedades, hints ICCCM y foco. No cubre el event loop, ni el cacheo de átomos por conexión, ni el enrutado de eventos a ventanas concretas: eso vive en `server.lua`. No cubre EWMH: solo ICCCM más los átomos que el toolkit interna explícitamente.

**Cómo funciona.**

Al cargar, hace `ffi.load("xcb")` y `ffi.load("libxcb-util.so.1")`. `libxcb-icccm.so.4` se carga la primera vez que se llama a `set_wm_normal_hints` o `set_wm_hints`: si el programa nunca usa hints, la librería no se abre.

`create_window` arma el `value_list` en el orden de los bits del `value_mask` del protocolo X11: `BackPixmap`, `BackPixel`, `BorderPixmap`, `BorderPixel`, `BitGravity`, `WinGravity`, `BackingStore`, `BackingPlanes`, `BackingPixel`, `OverrideRedirect`, `SaveUnder`, `EventMask`, `DontPropagate`, `Colormap`, `Cursor`. El orden lo marca el protocolo, no el orden en el que el programador escribe los `if`. Cualquier desviación hace que el servidor interprete mal los valores y devuelva `BadValue`. Por eso la función usa `xcb_create_window_checked` seguido de `xcb_request_check`: si el servidor rechaza la petición, `create_window` devuelve `nil, screen, mensaje` en vez de un id que fallaría más tarde de forma opaca.

Los structs ICCCM (`xcb_size_hints_t`, `xcb_wm_hints_t`) se construyen a partir de tablas Lua campo por campo. El campo `flags` acumula los bits de `ICCCM.*` correspondientes a los campos presentes. Sin `flags`, el servidor ignora el hint completo.

`query_pointer` exige un window id válido. El módulo pasa siempre el root de la pantalla 0; pasar `0` hace que el servidor rechace la petición.

`grab_pointer` captura botones y motion con `owner_events = 0` (todos los eventos van a la ventana que hizo el grab) y `pointer_mode = keyboard_mode = 1` (async). Lo usa `ContextMenu` para detectar clicks fuera del menú sin pasar por el árbol de widgets.

`intern_atom` devuelve `0` si la petición falla. No lanza error y no reintenta.

**API.**

**Constantes.**

- `CW` — bits del `value_mask` de `create_window`. Uso: `bit.bor(CW.BackPixel, CW.EventMask)`.
- `CONFIG` — bits del `value_mask` de `configure_window`.
- `PROP_MODE` — `Replace`, `Prepend`, `Append`.
- `EVENT_MASK` — bits de máscara para `opts.event_mask` en `create_window`.
- `EVENT` — códigos numéricos de evento X11. Se comparan contra `ev.response_type` enmascarado con `0x7f`.
- `WIN_CLASS` — `InputOutput`, `InputOnly`, `CopyFromParent`.
- `ICCCM` — bits de `WM_NORMAL_HINTS` y `WM_HINTS`.

**Conexión.**

| Función | Retorno | Notas |
|---|---|---|
| `connect(displayname?)` | `conn, screen_num` | Lanza `error` si falla la conexión. |
| `disconnect(conn)` | — | |
| `flush(conn)` | — | |
| `sync(conn)` | — | Round-trip. Fuerza al servidor a procesar lo pendiente. |
| `get_file_descriptor(conn)` | `fd` | Para usar con `poll()`. |
| `generate_id(conn)` | `id` | |

**Pantalla y visual.**

| Función | Retorno |
|---|---|
| `get_screen(conn, idx?)` | `xcb_screen_t*`. `idx` default 0. |
| `get_visualtype(conn, screen_idx, visual_id)` | `xcb_visualtype_t*`. |

**Ventanas.**

| Función | Retorno | Notas |
|---|---|---|
| `create_window(conn, opts)` | `wid, screen` o `nil, screen, err` | Hace `request_check`. |
| `map_window(conn, wid)` | — | Hace `flush`. |
| `unmap_window(conn, wid)` | — | |
| `destroy_window(conn, wid)` | — | |
| `configure_window(conn, wid, mask, values)` | — | `values` es tabla con `x`, `y`, `width`, `height`, `border`, `sibling`, `stack`. |

Campos de `opts` en `create_window`:

| Campo | Default | Descripción |
|---|---|---|
| `screen` | `0` | Índice de pantalla. |
| `parent` | root de la pantalla | |
| `x`, `y` | `0`, `0` | |
| `width`, `height` | `400`, `300` | |
| `border_width` | `0` | |
| `depth` | `root_depth` | |
| `class` | `InputOutput` | `WIN_CLASS.*`. |
| `visual` | `root_visual` | |
| `background_pixel` | — | uint32. |
| `border_pixel` | — | uint32. |
| `override_redirect` | — | Booleano. |
| `event_mask` | — | OR de `EVENT_MASK.*`. |

**Átomos y propiedades.**

| Función | Retorno |
|---|---|
| `intern_atom(conn, name, only_if_exists?)` | `atom` o `0` si falla. |
| `change_property(conn, win, prop, ptype, format, data_len, data)` | — (siempre en modo `Replace`). |

**Hints y foco.**

| Función | Notas |
|---|---|
| `set_wm_normal_hints(conn, win, hints)` | `hints` es tabla con campos opcionales: `x`, `y`, `width`, `height`, `min_width`, `min_height`, `max_width`, `max_height`, `width_inc`, `height_inc`, `min_aspect_num`, `min_aspect_den`, `max_aspect_num`, `max_aspect_den`, `base_width`, `base_height`. |
| `set_wm_hints(conn, win, hints)` | `hints.input` booleano. |
| `set_input_focus(conn, wid, revert_to?)` | `revert_to` default `2` (Parent). |
| `get_input_focus(conn)` | Window id con foco, o `0`. |
| `set_input_focus_revert(conn)` | Devuelve el foco a PointerRoot. |
| `query_pointer(conn)` | `x, y` en coordenadas raíz, o `nil, nil`. |
| `grab_pointer(conn, window)` | Botones y motion al `window` del grab. |
| `ungrab_pointer(conn)` | Libera la captura. |

**Patrón.**

El flujo habitual es `Server.new`, que internamente llama `xcb.connect`, y desde ahí operar contra `server.conn`. La conexión no se cierra hasta que `server:run()` termina.

Para `create_window`, revisar siempre el tercer valor:

    local wid, screen, err = xcb.create_window(conn, opts)
    if not wid then
        log.error("xcb", "create_window fallo: %s", err)
        return
    end

Ver `examples/01-window.lua` para el ciclo mínimo de conexión, ventana y evento.

**Anti-patrón.**

- **Ignorar el tercer retorno de `create_window`.** Un `value_list` desordenado produce `BadValue` silencioso: el servidor rechaza la petición y XCB no lanza error. Documentado en `notes.md`, entrada "value_list orden de bits en xcb_create_window".
- **Pasar `0` a `query_pointer`.** El primer argumento debe ser un window id válido. Documentado en `notes.md`, hito del launcher.
- **Añadir un struct de evento al cdef sin verificar el wire.** Los eventos X11 no llevan campo `length`; solo los requests y responses lo llevan. Un `length` mal puesto desplaza todos los campos siguientes y el programa lee basura sin error visible. Documentado en `notes.md`, entrada "eventos X11 NO tienen campo length".
- **Asumir que `EVENT` y `EVENT_MASK` son intercambiables.** Son tablas distintas con propósitos distintos: códigos de evento y bits de máscara. Ver la sección Notas.

**Notas.**

- `EVENT` y `EVENT_MASK` son tablas distintas con propósitos distintos. `EVENT.x` son códigos para comparar contra `ev.response_type & 0x7f`; `EVENT_MASK.x` son bits para el `event_mask` al crear una ventana. Confundirlos da `bad argument #3 to 'bor' (number expected, got nil)`.
- Los eventos devueltos por `xcb_wait_for_event` y `xcb_poll_for_event` se liberan con `ffi.C.free`. No existe `xcb_free_event`.
- El offset del window id dentro del evento depende del tipo: 4 para eventos "notify" (Expose, ConfigureNotify, ClientMessage, etc.) y 12 para eventos de input (KeyPress, ButtonPress, MotionNotify, etc.). La distinción la hace `server.lua:extract_window_id`.
- En Void Linux el paquete `xcb-util-wm` provee dos bibliotecas: `libxcb-icccm.so.4` (ICCCM) y `libxcb-ewmh.so.2` (EWMH). Este módulo solo carga la primera. `notes.md` documenta el hallazgo.
- Los symlinks versionados son obligatorios en `ffi.load`. Pasar `"pango-1.0"` es frágil; pasar `"libpango-1.0.so.0"` es determinista. `notes.md` lo documenta bajo "ffi.load con guiones".

#### cairo.lua

**Propósito.**
Wrapper FFI sobre `libcairo.so.2`. Expone superficies, contextos, atajos de dibujo, formas predefinidas, carga de PNG y dibujo de imágenes con y sin tintado.

**Alcance.**
Cubre lo que el toolkit necesita para pintar widgets: creación de superficies XCB e imagen, contexto, primitivas de path, colores, formas redondeadas, carga y dibujo de PNG (con cache), y tintado de iconos monocromo. No cubre texto: Pango vive en `pango.lua`. No cubre carga de SVG: vive en `svg.lua`. No expone todas las operaciones de Cairo; solo las que usa el toolkit.

**Cómo funciona.**

Todas las funciones de creación de superficies y contextos verifican el status de Cairo inmediatamente después de la llamada. Si el status es distinto de 0, lanzan `error`. Esto convierte lo que en Cairo puro sería un surface inválido silencioso en un fallo temprano y visible.

`load_png_cached` mantiene una tabla global `_surface_cache` (ruta → surface). La primera llamada carga el PNG del disco; las siguientes devuelven el mismo surface. `clear_surface_cache` destruye todos los surfaces cacheados y vacía la tabla.

`draw_surface` escala el surface origen al rectángulo destino con `cairo_scale`. El filtro por defecto es GOOD (interpolación bilineal), suficiente para iconos. Si `w` o `h` son `nil`, usa el tamaño nativo del surface.

`draw_surface_tinted` construye una superficie temporal ARGB32 del tamaño natural del icono. Sobre esa superficie aplica primero el icono con operador OVER (queda con su alpha original sobre fondo transparente) y luego aplica un color sólido con operador IN. El operador IN multiplica el color de fuente por el alpha del destino, así que el color solo aparece donde el icono tiene píxeles. Finalmente blitea la superficie temporal al destino con OVER, escalada si hace falta. Sin la superficie temporal, el IN se aplicaría sobre el fondo opaco del destino y pintaría el área completa.

`rounded_rect` clampa el radio a la mitad del menor lado y construye el path con cuatro arcos y `new_sub_path` previo, más `close_path` al final. Es el único path del módulo que gestiona su propio `new_sub_path`; el resto de funciones de dibujo no lo tocan.

Las funciones `arc`, `rectangle`, `move_to` y `line_to` añaden al path actual sin resetearlo. `new_path` y `new_sub_path` son explícitos.

**API.**

**Constantes.**

- `OPERATOR` — valores de `cairo_operator_t`: `CLEAR`, `SOURCE`, `OVER`, `IN`, `OUT`, `ATOP`, `DEST`, `DEST_OVER`, `DEST_IN`, `DEST_OUT`, `DEST_ATOP`, `XOR`, `ADD`, `SATURATE`, `MULTIPLY`.
- `FORMAT` — valores de `cairo_format_t`: `ARGB32` (0), `RGB24` (1), `A8` (2), `A1` (3).

**Superficies y contexto.**

| Función | Retorno | Notas |
|---|---|---|
| `surface_for_window(conn, drawable, visualtype, w, h)` | surface | Superficie XCB para dibujar a una ventana. Lanza `error` si el status no es 0. |
| `image_surface_create(w, h, format?)` | surface | `format` default `ARGB32`. |
| `context(surface)` | `cairo_t*` | Lanza `error` si el status no es 0. |
| `destroy_context(cr)` | — | |
| `destroy_surface(s)` | — | |
| `flush_surface(s)` | — | Fuerza flush. Necesario tras escribir a mano a la memoria del surface. |
| `surface_width(s)` | `int` | |
| `surface_height(s)` | `int` | |

**Atajos de dibujo.**

Todas son envoltorios directos de las funciones de Cairo del mismo nombre, con la firma `(cr, ...)`. No añaden comportamiento.

- Colores: `set_rgb(cr, r, g, b)`, `set_rgba(cr, r, g, b, a)`, `set_line_width(cr, w)`.
- Path: `new_path(cr)`, `new_sub_path(cr)`, `move_to(cr, x, y)`, `line_to(cr, x, y)`, `rectangle(cr, x, y, w, h)`, `arc(cr, xc, yc, r, a1, a2)`, `close_path(cr)`.
- Pintar: `paint(cr)`, `fill(cr)`, `stroke(cr)`.
- Estado: `save(cr)`, `restore(cr)`, `clip(cr)`, `clip_preserve(cr)`, `translate(cr, tx, ty)`, `set_source_surface(cr, surface, x, y)`, `set_operator(cr, op)`.

**Formas.**

| Función | Notas |
|---|---|
| `rounded_rect(cr, x, y, w, h, r)` | Rectángulo redondeado. Clampea `r` a la mitad del menor lado. Usa `new_sub_path` internamente y cierra el path. |

**Imágenes.**

| Función | Retorno | Notas |
|---|---|---|
| `load_png(path)` | surface o `nil, mensaje` | Carga desde disco. No cachea. |
| `load_png_cached(path)` | surface o `nil, mensaje` | Cache global por ruta. |
| `clear_surface_cache()` | — | Destruye todos los surfaces cacheados y vacía el cache. |
| `write_png(surface, path)` | `bool` | |
| `draw_surface(cr, s, x, y, w?, h?)` | — | Si `w` o `h` son `nil`, usa el tamaño nativo. Escala con filtro GOOD. |
| `draw_surface_tinted(cr, s, x, y, w, h, r, g, b)` | — | Tinta con un color sólido preservando el alpha del origen. Pensado para iconos monocromo. |

**Patrón.**

El ciclo habitual de dibujo de un widget es: obtener el `cr` que le pasa el `Window`, guardar estado si se modifica el path o el color, dibujar, restaurar. Las formas redondeadas se hacen siempre con `rounded_rect`, nunca a mano:

    cairo.set_source_rgb(cr, 0.2, 0.2, 0.2)
    cairo.rounded_rect(cr, x, y, w, h, 6)
    cairo.fill(cr)

Para iconos monocromo, cargar el PNG una vez y tintar en cada draw:

    local surface = cairo.load_png_cached("icons-png/32/cpu.png")
    cairo.draw_surface_tinted(cr, surface, x, y, 16, 16, 1, 1, 1)

Para iconos en color, `draw_surface` sin tintar. Ver `examples/02-text.lua` y `examples/10-icon.lua`.

**Anti-patrón.**

- **Llamar `arc` sin `new_path` antes y después.** `arc` añade al path actual. Si hay arcos previos sin consumir, Cairo los conecta con una línea recta entre el final del primero y el inicio del segundo. El síntoma clásico es una línea diagonal cruzando un anillo. Documentado en `notes.md`, entrada "línea diagonal en anillos".
- **Usar `draw_surface_tinted` sobre iconos en color.** El operador IN colapsa el icono a un solo color, perdiendo toda la información de color original.
- **Llamar `load_png_cached` en un bucle por frame después de recargar iconos en caliente.** El cache no se invalida al cambiar el archivo en disco. Tras un cambio de tema o de set de iconos, llamar `clear_surface_cache()`.
- **Llamar `draw_surface` con `w` y `h` distintos del nativo en cada frame.** Cada llamada escala el surface en GPU/CPU. Para iconos con tamaño fijo, dejar el tamaño nativo o cachear el resultado escalado.

**Notas.**

- `rounded_rect` con `r = 0` cae a `cairo_rectangle` sin redondeo. Con `r` mayor que la mitad del menor lado, clampa. No lanza error.
- `load_png` devuelve `nil` más un mensaje descriptivo si el archivo no existe o no es PNG válido. No lanza error.
- El cache de `load_png_cached` es global al módulo. Dos widgets que cargan el mismo PNG comparten el mismo surface.
- `write_png` está pensado para debug y tests, no se usa en el flujo normal.

#### cairo.lua

**Propósito.**
Wrapper FFI sobre `libcairo.so.2`. Expone superficies, contextos, atajos de dibujo, formas predefinidas, carga de PNG y dibujo de imágenes con y sin tintado.

**Alcance.**
Cubre lo que el toolkit necesita para pintar widgets: creación de superficies XCB e imagen, contexto, primitivas de path, colores, formas redondeadas, carga y dibujo de PNG (con cache), y tintado de iconos monocromo. No cubre texto: Pango vive en `pango.lua`. No cubre carga de SVG: vive en `svg.lua`. No expone todas las operaciones de Cairo; solo las que usa el toolkit.

**Cómo funciona.**

Todas las funciones de creación de superficies y contextos verifican el status de Cairo inmediatamente después de la llamada. Si el status es distinto de 0, lanzan `error`. Esto convierte lo que en Cairo puro sería un surface inválido silencioso en un fallo temprano y visible.

`load_png_cached` mantiene una tabla global `_surface_cache` (ruta → surface). La primera llamada carga el PNG del disco; las siguientes devuelven el mismo surface. `clear_surface_cache` destruye todos los surfaces cacheados y vacía la tabla.

`draw_surface` escala el surface origen al rectángulo destino con `cairo_scale`. El filtro por defecto es GOOD (interpolación bilineal), suficiente para iconos. Si `w` o `h` son `nil`, usa el tamaño nativo del surface.

`draw_surface_tinted` construye una superficie temporal ARGB32 del tamaño natural del icono. Sobre esa superficie aplica primero el icono con operador OVER (queda con su alpha original sobre fondo transparente) y luego aplica un color sólido con operador IN. El operador IN multiplica el color de fuente por el alpha del destino, así que el color solo aparece donde el icono tiene píxeles. Finalmente blitea la superficie temporal al destino con OVER, escalada si hace falta. Sin la superficie temporal, el IN se aplicaría sobre el fondo opaco del destino y pintaría el área completa.

`rounded_rect` clampa el radio a la mitad del menor lado y construye el path con cuatro arcos y `new_sub_path` previo, más `close_path` al final. Es el único path del módulo que gestiona su propio `new_sub_path`; el resto de funciones de dibujo no lo tocan.

Las funciones `arc`, `rectangle`, `move_to` y `line_to` añaden al path actual sin resetearlo. `new_path` y `new_sub_path` son explícitos.

**API.**

**Constantes.**

- `OPERATOR` — valores de `cairo_operator_t`: `CLEAR`, `SOURCE`, `OVER`, `IN`, `OUT`, `ATOP`, `DEST`, `DEST_OVER`, `DEST_IN`, `DEST_OUT`, `DEST_ATOP`, `XOR`, `ADD`, `SATURATE`, `MULTIPLY`.
- `FORMAT` — valores de `cairo_format_t`: `ARGB32` (0), `RGB24` (1), `A8` (2), `A1` (3).

**Superficies y contexto.**

| Función | Retorno | Notas |
|---|---|---|
| `surface_for_window(conn, drawable, visualtype, w, h)` | surface | Superficie XCB para dibujar a una ventana. Lanza `error` si el status no es 0. |
| `image_surface_create(w, h, format?)` | surface | `format` default `ARGB32`. |
| `context(surface)` | `cairo_t*` | Lanza `error` si el status no es 0. |
| `destroy_context(cr)` | — | |
| `destroy_surface(s)` | — | |
| `flush_surface(s)` | — | Fuerza flush. Necesario tras escribir a mano a la memoria del surface. |
| `surface_width(s)` | `int` | |
| `surface_height(s)` | `int` | |

**Atajos de dibujo.**

Todas son envoltorios directos de las funciones de Cairo del mismo nombre, con la firma `(cr, ...)`. No añaden comportamiento.

- Colores: `set_rgb(cr, r, g, b)`, `set_rgba(cr, r, g, b, a)`, `set_line_width(cr, w)`.
- Path: `new_path(cr)`, `new_sub_path(cr)`, `move_to(cr, x, y)`, `line_to(cr, x, y)`, `rectangle(cr, x, y, w, h)`, `arc(cr, xc, yc, r, a1, a2)`, `close_path(cr)`.
- Pintar: `paint(cr)`, `fill(cr)`, `stroke(cr)`.
- Estado: `save(cr)`, `restore(cr)`, `clip(cr)`, `clip_preserve(cr)`, `translate(cr, tx, ty)`, `set_source_surface(cr, surface, x, y)`, `set_operator(cr, op)`.

**Formas.**

| Función | Notas |
|---|---|
| `rounded_rect(cr, x, y, w, h, r)` | Rectángulo redondeado. Clampea `r` a la mitad del menor lado. Usa `new_sub_path` internamente y cierra el path. |

**Imágenes.**

| Función | Retorno | Notas |
|---|---|---|
| `load_png(path)` | surface o `nil, mensaje` | Carga desde disco. No cachea. |
| `load_png_cached(path)` | surface o `nil, mensaje` | Cache global por ruta. |
| `clear_surface_cache()` | — | Destruye todos los surfaces cacheados y vacía el cache. |
| `write_png(surface, path)` | `bool` | |
| `draw_surface(cr, s, x, y, w?, h?)` | — | Si `w` o `h` son `nil`, usa el tamaño nativo. Escala con filtro GOOD. |
| `draw_surface_tinted(cr, s, x, y, w, h, r, g, b)` | — | Tinta con un color sólido preservando el alpha del origen. Pensado para iconos monocromo. |

**Patrón.**

El ciclo habitual de dibujo de un widget es: obtener el `cr` que le pasa el `Window`, guardar estado si se modifica el path o el color, dibujar, restaurar. Las formas redondeadas se hacen siempre con `rounded_rect`, nunca a mano:

    cairo.set_source_rgb(cr, 0.2, 0.2, 0.2)
    cairo.rounded_rect(cr, x, y, w, h, 6)
    cairo.fill(cr)

Para iconos monocromo, cargar el PNG una vez y tintar en cada draw:

    local surface = cairo.load_png_cached("icons-png/32/cpu.png")
    cairo.draw_surface_tinted(cr, surface, x, y, 16, 16, 1, 1, 1)

Para iconos en color, `draw_surface` sin tintar. Ver `examples/02-text.lua` y `examples/10-icon.lua`.

**Anti-patrón.**

- **Llamar `arc` sin `new_path` antes y después.** `arc` añade al path actual. Si hay arcos previos sin consumir, Cairo los conecta con una línea recta entre el final del primero y el inicio del segundo. El síntoma clásico es una línea diagonal cruzando un anillo. Documentado en `notes.md`, entrada "línea diagonal en anillos".
- **Usar `draw_surface_tinted` sobre iconos en color.** El operador IN colapsa el icono a un solo color, perdiendo toda la información de color original.
- **Llamar `load_png_cached` en un bucle por frame después de recargar iconos en caliente.** El cache no se invalida al cambiar el archivo en disco. Tras un cambio de tema o de set de iconos, llamar `clear_surface_cache()`.
- **Llamar `draw_surface` con `w` y `h` distintos del nativo en cada frame.** Cada llamada escala el surface en GPU/CPU. Para iconos con tamaño fijo, dejar el tamaño nativo o cachear el resultado escalado.

**Notas.**

- `rounded_rect` con `r = 0` cae a `cairo_rectangle` sin redondeo. Con `r` mayor que la mitad del menor lado, clampa. No lanza error.
- `load_png` devuelve `nil` más un mensaje descriptivo si el archivo no existe o no es PNG válido. No lanza error.
- El cache de `load_png_cached` es global al módulo. Dos widgets que cargan el mismo PNG comparten el mismo surface.
- `write_png` está pensado para debug y tests, no se usa en el flujo normal.

#### cairo.lua

**Propósito.**
Wrapper FFI sobre `libcairo.so.2`. Expone superficies, contextos, atajos de dibujo, formas predefinidas, carga de PNG y dibujo de imágenes con y sin tintado.

**Alcance.**
Cubre lo que el toolkit necesita para pintar widgets: creación de superficies XCB e imagen, contexto, primitivas de path, colores, formas redondeadas, carga y dibujo de PNG (con cache), y tintado de iconos monocromo. No cubre texto: Pango vive en `pango.lua`. No cubre carga de SVG: vive en `svg.lua`. No expone todas las operaciones de Cairo; solo las que usa el toolkit.

**Cómo funciona.**

Todas las funciones de creación de superficies y contextos verifican el status de Cairo inmediatamente después de la llamada. Si el status es distinto de 0, lanzan `error`. Esto convierte lo que en Cairo puro sería un surface inválido silencioso en un fallo temprano y visible.

`load_png_cached` mantiene una tabla global `_surface_cache` (ruta → surface). La primera llamada carga el PNG del disco; las siguientes devuelven el mismo surface. `clear_surface_cache` destruye todos los surfaces cacheados y vacía la tabla.

`draw_surface` escala el surface origen al rectángulo destino con `cairo_scale`. El filtro por defecto es GOOD (interpolación bilineal), suficiente para iconos. Si `w` o `h` son `nil`, usa el tamaño nativo del surface.

`draw_surface_tinted` construye una superficie temporal ARGB32 del tamaño natural del icono. Sobre esa superficie aplica primero el icono con operador OVER (queda con su alpha original sobre fondo transparente) y luego aplica un color sólido con operador IN. El operador IN multiplica el color de fuente por el alpha del destino, así que el color solo aparece donde el icono tiene píxeles. Finalmente blitea la superficie temporal al destino con OVER, escalada si hace falta. Sin la superficie temporal, el IN se aplicaría sobre el fondo opaco del destino y pintaría el área completa.

`rounded_rect` clampa el radio a la mitad del menor lado y construye el path con cuatro arcos y `new_sub_path` previo, más `close_path` al final. Es el único path del módulo que gestiona su propio `new_sub_path`; el resto de funciones de dibujo no lo tocan.

Las funciones `arc`, `rectangle`, `move_to` y `line_to` añaden al path actual sin resetearlo. `new_path` y `new_sub_path` son explícitos.

**API.**

**Constantes.**

- `OPERATOR` — valores de `cairo_operator_t`: `CLEAR`, `SOURCE`, `OVER`, `IN`, `OUT`, `ATOP`, `DEST`, `DEST_OVER`, `DEST_IN`, `DEST_OUT`, `DEST_ATOP`, `XOR`, `ADD`, `SATURATE`, `MULTIPLY`.
- `FORMAT` — valores de `cairo_format_t`: `ARGB32` (0), `RGB24` (1), `A8` (2), `A1` (3).

**Superficies y contexto.**

| Función | Retorno | Notas |
|---|---|---|
| `surface_for_window(conn, drawable, visualtype, w, h)` | surface | Superficie XCB para dibujar a una ventana. Lanza `error` si el status no es 0. |
| `image_surface_create(w, h, format?)` | surface | `format` default `ARGB32`. |
| `context(surface)` | `cairo_t*` | Lanza `error` si el status no es 0. |
| `destroy_context(cr)` | — | |
| `destroy_surface(s)` | — | |
| `flush_surface(s)` | — | Fuerza flush. Necesario tras escribir a mano a la memoria del surface. |
| `surface_width(s)` | `int` | |
| `surface_height(s)` | `int` | |

**Atajos de dibujo.**

Todas son envoltorios directos de las funciones de Cairo del mismo nombre, con la firma `(cr, ...)`. No añaden comportamiento.

- Colores: `set_rgb(cr, r, g, b)`, `set_rgba(cr, r, g, b, a)`, `set_line_width(cr, w)`.
- Path: `new_path(cr)`, `new_sub_path(cr)`, `move_to(cr, x, y)`, `line_to(cr, x, y)`, `rectangle(cr, x, y, w, h)`, `arc(cr, xc, yc, r, a1, a2)`, `close_path(cr)`.
- Pintar: `paint(cr)`, `fill(cr)`, `stroke(cr)`.
- Estado: `save(cr)`, `restore(cr)`, `clip(cr)`, `clip_preserve(cr)`, `translate(cr, tx, ty)`, `set_source_surface(cr, surface, x, y)`, `set_operator(cr, op)`.

**Formas.**

| Función | Notas |
|---|---|
| `rounded_rect(cr, x, y, w, h, r)` | Rectángulo redondeado. Clampea `r` a la mitad del menor lado. Usa `new_sub_path` internamente y cierra el path. |

**Imágenes.**

| Función | Retorno | Notas |
|---|---|---|
| `load_png(path)` | surface o `nil, mensaje` | Carga desde disco. No cachea. |
| `load_png_cached(path)` | surface o `nil, mensaje` | Cache global por ruta. |
| `clear_surface_cache()` | — | Destruye todos los surfaces cacheados y vacía el cache. |
| `write_png(surface, path)` | `bool` | |
| `draw_surface(cr, s, x, y, w?, h?)` | — | Si `w` o `h` son `nil`, usa el tamaño nativo. Escala con filtro GOOD. |
| `draw_surface_tinted(cr, s, x, y, w, h, r, g, b)` | — | Tinta con un color sólido preservando el alpha del origen. Pensado para iconos monocromo. |

**Patrón.**

El ciclo habitual de dibujo de un widget es: obtener el `cr` que le pasa el `Window`, guardar estado si se modifica el path o el color, dibujar, restaurar. Las formas redondeadas se hacen siempre con `rounded_rect`, nunca a mano:

    cairo.set_source_rgb(cr, 0.2, 0.2, 0.2)
    cairo.rounded_rect(cr, x, y, w, h, 6)
    cairo.fill(cr)

Para iconos monocromo, cargar el PNG una vez y tintar en cada draw:

    local surface = cairo.load_png_cached("icons-png/32/cpu.png")
    cairo.draw_surface_tinted(cr, surface, x, y, 16, 16, 1, 1, 1)

Para iconos en color, `draw_surface` sin tintar. Ver `examples/02-text.lua` y `examples/10-icon.lua`.

**Anti-patrón.**

- **Llamar `arc` sin `new_path` antes y después.** `arc` añade al path actual. Si hay arcos previos sin consumir, Cairo los conecta con una línea recta entre el final del primero y el inicio del segundo. El síntoma clásico es una línea diagonal cruzando un anillo. Documentado en `notes.md`, entrada "línea diagonal en anillos".
- **Usar `draw_surface_tinted` sobre iconos en color.** El operador IN colapsa el icono a un solo color, perdiendo toda la información de color original.
- **Llamar `load_png_cached` en un bucle por frame después de recargar iconos en caliente.** El cache no se invalida al cambiar el archivo en disco. Tras un cambio de tema o de set de iconos, llamar `clear_surface_cache()`.
- **Llamar `draw_surface` con `w` y `h` distintos del nativo en cada frame.** Cada llamada escala el surface en GPU/CPU. Para iconos con tamaño fijo, dejar el tamaño nativo o cachear el resultado escalado.

**Notas.**

- `rounded_rect` con `r = 0` cae a `cairo_rectangle` sin redondeo. Con `r` mayor que la mitad del menor lado, clampa. No lanza error.
- `load_png` devuelve `nil` más un mensaje descriptivo si el archivo no existe o no es PNG válido. No lanza error.
- El cache de `load_png_cached` es global al módulo. Dos widgets que cargan el mismo PNG comparten el mismo surface.
- `write_png` está pensado para debug y tests, no se usa en el flujo normal.

#### pango.lua

**Propósito.**
Wrapper FFI sobre `libpango-1.0.so.0`, `libpangocairo-1.0.so.0`, `libgobject-2.0.so.0`, `libcairo.so.2` y `libfontconfig.so.1`. Expone dibujo y medición de texto con Pango sobre un contexto Cairo, más utilidades para markup.

**Alcance.**
Cubre texto plano, markup Pango, wrapping, alignment y medición. Cubre también la traducción de entidades HTML con nombre a Unicode y el escapado de caracteres especiales de markup. No cubre layout de texto en columnas, selección, cursor ni edición: eso vive en widgets como `Text` o `TextInput`. No cubre fuentes embebidas ni carga de fuentes desde archivo: usa las del sistema vía fontconfig.

**Cómo funciona.**

Al cargar el módulo, llama a `fontconfig.FcInit()` una sola vez. Sin esta llamada, Pango funciona pero imprime el warning "Fontconfig warning: using without calling FcInit()" cada vez que resuelve una fuente. `notes.md` documenta el hallazgo.

`measure` y las dos funciones de dibujo (`draw_text`, `draw_markup`) crean un `PangoLayout` por llamada. `measure` crea además un `cairo_image_surface` de 1×1 como destino, para tener un contexto Cairo sobre el que construir el layout sin depender de una ventana. El patrón es el estándar para medir texto en Pango: el layout no necesita un destino real, solo un contexto.

El layout se libera con `g_object_unref`. La `PangoFontDescription` (si se pasó `font`) se libera con `pango_font_description_free`. El contexto y la superficie dummy se destruyen al final. Todos los recursos se liberan dentro de la misma llamada; no hay estado que persista entre llamadas.

La `font` es un string en el formato de Pango: `"Cantarell 10"`, `"monospace bold 9"`, `"Sans Italic 12"`. Se convierte a `PangoFontDescription` con `pango_font_description_from_string`. Si `font` es `nil`, se usa la fuente por defecto de Pango.

`html_entities` recorre la cadena buscando el patrón `&nombre;`. Para cada coincidencia, consulta la tabla `HTML_ENTITIES`. Si el nombre es una de las cinco entidades XML básicas (`amp`, `lt`, `gt`, `quot`, `apos`), deja la entidad tal cual: Pango ya las conoce y las interpreta. Si el nombre está en la tabla, lo reemplaza por el carácter Unicode correspondiente. Si no está, deja la entidad sin tocar (Pango avisará). La tabla cubre alrededor de 50 entidades: signos tipográficos, flechas, letras griegas, símbolos matemáticos.

`escape` sustituye `&`, `<` y `>` por sus entidades XML. Es la operación inversa conceptual: `html_entities` traduce entidades HTML a Unicode para que Pango las entienda; `escape` traduce caracteres especiales a entidades XML para que Pango no los interprete como markup.

El color del texto se pasa en `opts.r`, `opts.g`, `opts.b` como floats `[0,1]`. Se aplican con `cairo_set_source_rgb` antes de dibujar. Si no se pasa ninguno, el default es blanco (`1.0, 1.0, 1.0`).

**API.**

**Constantes.**

- `ALIGN` — `LEFT` (0), `CENTER` (1), `RIGHT` (2). Valores de `PangoAlignment`.
- `WRAP` — `WORD` (0), `CHAR` (1), `WORD_CHAR` (2). Valores de `PangoWrapMode`.

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `measure(text, font?)` | `w, h` | Ancho y alto en píxeles. Crea un surface 1×1 temporal. |
| `draw_text(cr, x, y, text, font?, opts?)` | — | Texto plano. No interpreta markup. |
| `draw_markup(cr, x, y, markup, font?, opts?)` | — | Markup Pango. Pasa la cadena por `html_entities` antes de entregarla. |
| `html_entities(s)` | string | Traduce entidades HTML con nombre a Unicode. Respeta las cinco XML básicas. |
| `escape(s)` | string | Escapa `&`, `<`, `>` para markup. |

Campos de `opts` en `draw_text` y `draw_markup`:

- `r`, `g`, `b` — color del texto, floats `[0,1]`. Default `1.0, 1.0, 1.0`.
- `wrap_width` — ancho de wrap en píxeles. Sin este campo, no hay wrap.
- `wrap` — modo de wrap: `WRAP.WORD`, `WRAP.CHAR` o `WRAP.WORD_CHAR`. Default `WRAP.WORD` si hay `wrap_width`.
- `align` — alineación dentro del wrap: `ALIGN.LEFT`, `ALIGN.CENTER`, `ALIGN.RIGHT`. Sin este campo, el layout usa el default de Pango.

**Patrón.**

Para dibujar texto, medir primero fuera de `draw` si el ancho importa para el layout, y dibujar dentro de `draw`:

    local w, h = pango.measure(text, font)
    widget.min_w = w
    widget.min_h = h

    function widget:draw(cr)
        pango.draw_text(cr, self.x0, self.y0, text, font, {
            r = 0.9, g = 0.9, b = 0.9,
        })
    end

Para texto con color y markup:

    local safe = pango.escape(user_text)
    pango.draw_markup(cr, x, y,
        "<b>" .. safe .. "</b>", font, { r = 1, g = 0.8, b = 0 })

Ver `examples/02-text.lua` para texto plano y `examples/12-markup.lua` para markup.

**Anti-patrón.**

- **Llamar `measure` dentro de `on_draw`.** Cada llamada crea un surface, un contexto, un layout y libera los tres. Repetido por frame, es trabajo que se puede hacer una vez al construir el widget o al cambiar el texto. Ver `Text:_remeasure` en `widgets/text.lua`, que hace exactamente esto.
- **Pasar texto del usuario a `draw_markup` sin `escape`.** Un `<`, un `&` o un `>` sin escapar rompe el layout o se interpreta como etiqueta. El síntoma va desde texto mal renderizado hasta error de Pango por markup inválido. Si el markup lo construye el toolkit desde strings conocidos, no hace falta escapar. Si viene de fuera (config, usuario, archivo), escapar siempre.
- **Llamar `draw_text` o `draw_markup` sin haber creado el contexto Cairo.** El `cr` debe ser un contexto válido. En el toolkit siempre se obtiene del `Window`; nunca se crea ad-hoc para dibujar texto.

**Notas.**

- `measure` no tiene en cuenta el `wrap_width`: mide el texto como una sola línea. Si se mide un texto que luego se va a envolver, el ancho devuelto es el ancho natural sin envolver.
- La `font` es opcional en todas las funciones. Sin ella, Pango usa la fuente por defecto del sistema. En la práctica, el toolkit siempre pasa una.
- `html_entities` no soporta entidades numéricas (`&#NNN;` o `&#xHHH;`). Solo entidades con nombre.
- Las entidades XML básicas pasan tal cual. Si un widget usa `draw_markup` con `&amp;` en el texto del usuario, Pango lo interpretará como `&`. Si se quiere el literal `&amp;` en pantalla, hay que escapar el `&` primero con `escape`.

#### xkb.lua

**Propósito.**
Wrapper FFI sobre `libxkbcommon.so.0`. Traduce keycodes de X11 a keysym, nombre de tecla, texto UTF-8 y modificadores decodificados. Encapsula el estado de teclado en un objeto `State`.

**Alcance.**
Cubre la traducción de keycodes a información legible y la decodificación del campo `state` de los eventos KeyPress/KeyRelease. No cubre captura de teclas (vive en `window.lua`), ni dispatch a widgets, ni hotkeys globales, ni composición de caracteres con dead keys. No gestiona cambios de layout en runtime: el layout se fija al crear el `State`.

**Cómo funciona.**

`M.new_state` crea tres objetos internos de xkbcommon: un contexto (`xkb_context_new`), un keymap (`xkb_keymap_new_from_names`) y un estado (`xkb_state_new`). El contexto es el punto de entrada a la librería; el keymap describe la disposición física más el layout; el estado es la parte mutable que se actualiza con cada tecla.

Si `names` es `nil`, el keymap se construye a partir de las variables de entorno `XKB_DEFAULT_RULES`, `XKB_DEFAULT_MODEL`, `XKB_DEFAULT_LAYOUT`, `XKB_DEFAULT_VARIANT` y `XKB_DEFAULT_OPTIONS`. Si ninguna está definida, se usan los defaults internos de xkbcommon (layout `us`). Si `names` es una tabla, se leen los campos `rules`, `model`, `layout`, `variant`, `options` de ahí.

Cada uno de los tres objetos se verifica tras crearse. Si alguno falla, se liberan los ya creados y se lanza `error` con un mensaje que apunta al layout como causa probable.

El `State` mantiene un buffer `char[32]` reutilizable para las llamadas a `xkb_state_key_get_utf8` y `xkb_keysym_get_name`. Ambas escriben una cadena UTF-8 o un nombre de keysym en el buffer y devuelven la longitud escrita. El buffer se reutiliza entre llamadas para no alocar en cada tecla.

`update_key` llama a `xkb_state_update_key` con la dirección de la tecla (`KEY_DOWN` o `KEY_UP`). Actualiza el estado interno de modificadores: si el usuario pulsa Shift y luego `a`, el estado sabe que Shift está activo y `key_utf8("a")` devuelve `"A"`. Si no se llama `update_key`, el estado no cambia y Shift no tiene efecto. `notes.md` documenta este comportamiento como la principal fuente de bugs.

`decode_mods` recibe el campo `state` de un evento X11 (un número) y devuelve una tabla con booleanos por modificador: `shift`, `lock`, `ctrl`, `alt`, `num`, `mod3`, `super`, `mod5`. Los bits que no encajan en ninguna categoría conocida se exponen con su nombre crudo (`mod3`, `mod5`). El mapeo `MOD1 → alt` y `MOD4 → super` es convención, no viene impuesto por X11.

`make_event` combina las operaciones anteriores en una sola llamada: actualiza el estado con la tecla, extrae keysym, nombre, texto y modificadores, y devuelve una tabla con todos ellos más `keycode`, `raw_mods` (el valor crudo de `state`) y `pressed`. Es la función que usan los consumidores en `on_key`; no hay que llamar a `update_key` por separado antes.

El keysym numérico se obtiene con `xkb_state_key_get_one_sym`, que devuelve el símbolo principal de la tecla. El nombre se obtiene con `xkb_keysym_get_name`. El texto con `xkb_state_key_get_utf8`. Para teclas que no producen texto (Shift, Ctrl, F1), `key_utf8` devuelve `""` y `key_name` devuelve algo como `"Shift_L"` o `"F1"`.

`destroy` libera los tres objetos xkbcommon. Sin `destroy`, el proceso filtra memoria hasta cerrarse; el toolkit lo llama desde `Window:_shutdown`.

**API.**

**Constantes.**

- `KEY_UP` (0), `KEY_DOWN` (1) — direcciones para `update_key`.
- `X11_MOD` — máscaras X11: `SHIFT` (1), `LOCK` (2), `CTRL` (4), `MOD1` (8), `MOD2` (16), `MOD3` (32), `MOD4` (64), `MOD5` (128).
- `SYM` — keysyms comunes por nombre: `RETURN`, `ESCAPE`, `BACKSPACE`, `TAB`, `SPACE`, `DELETE`, `HOME`, `END`, `PAGE_UP`, `PAGE_DOWN`, `LEFT`, `UP`, `RIGHT`, `DOWN`, `F1` a `F12`. La tabla no es exhaustiva: para keysyms fuera de ella, usar `from_name`.

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `new_state(names?)` | `State` | Lanza `error` si falla la creación. |
| `from_name(name)` | keysym numérico | Convierte un nombre de keysym a su valor. |

**Métodos de `State`.**

| Método | Retorno | Notas |
|---|---|---|
| `update_key(keycode, direction)` | — | `direction` es `KEY_UP` o `KEY_DOWN`. |
| `key_sym(keycode)` | keysym numérico | `0` si la tecla no está mapeada. |
| `key_name(keycode)` | string | `"Return"`, `"a"`, `"F1"`, `"Shift_L"`. |
| `key_utf8(keycode)` | string UTF-8 | `""` si la tecla no produce texto. |
| `decode_mods(x11_state)` | tabla | Devuelve booleanos por modificador. |
| `make_event(keycode, x11_state, pressed)` | tabla | Actualiza el estado y devuelve el evento completo. |
| `destroy()` | — | Libera contexto, keymap y estado. |

Campos de la tabla devuelta por `make_event`:

- `keycode` — el keycode X11.
- `sym` — keysym numérico.
- `name` — nombre del keysym.
- `text` — texto UTF-8, o `""`.
- `mods` — tabla de modificadores booleanos.
- `raw_mods` — el campo `state` del evento X11 crudo.
- `pressed` — booleano.

**Patrón.**

El `State` se crea una vez por ventana (`Window` lo hace en su constructor). El dispatch de KeyPress y KeyRelease construye el evento y lo pasa al widget con foco primero, al handler global después:

    local key = self.xkb:make_event(kev.detail, kev.state, true)
    if self.focus_widget and self.focus_widget.on_key then
        local consumed = self.focus_widget:on_key(key)
        if consumed then return end
    end
    if self.opts.on_key then
        self.opts.on_key(key)
    end

Comparar teclas imprimibles por `key.text`:

    if key.text == "q" and not key.mods.ctrl then
        self:close()
    end

Comparar teclas no imprimibles por `key.name`:

    if key.name == "Escape" then ... end

Ver `examples/05-keyboard.lua` para el ciclo completo.

**Anti-patrón.**

- **Llamar `key_utf8` sin haber pasado por `make_event` o `update_key`.** El estado interno del `State` no refleja las teclas que se han pulsado si no se le avisa. Shift+a devuelve `"a"` en vez de `"A"`, o combinaciones con Alt/Ctrl no se resuelven. Documentado en `notes.md`.
- **Crear un `State` por cada pulsación.** La creación es costosa (contexto, keymap, parsing de layout). Un `State` por ventana es lo correcto. Si varias ventanas comparten teclado, se puede compartir el `State` entre ellas; el toolkit no lo hace hoy.
- **Ignorar `destroy`.** Los tres objetos de xkbcommon (`ctx`, `keymap`, `state`) se liberan con `unref`. Sin `destroy`, se filtran al cerrar la ventana.
- **Asumir que `text` siempre está presente.** Teclas como F1, Shift, Ctrl o flechas devuelven `""`. Comparar por `name` en esos casos.

**Notas.**

- `key_name` devuelve `""` si `xkb_keysym_get_name` falla o el keysym es `0`. No lanza error.
- El buffer interno de 32 bytes se reutiliza entre llamadas. Si se guarda la referencia a un string devuelto y se hace otra llamada al mismo `State`, el string sigue válido: `ffi.string` copia. El buffer solo se machaca durante la llamada.
- `decode_mods` no distingue modificadores por keysym concreto (Left Shift vs Right Shift). Solo indica si el modificador está activo.
- El mapeo `MOD1 → alt` y `MOD4 → super` es convención de la mayoría de los WM. Un usuario con un layout personalizado puede haber remapeado esos bits. La tabla `X11_MOD` expone los nombres crudos también.

#### svg.lua

**Propósito.**
Wrapper FFI sobre `libresvg.so.0.48`. Renderiza un archivo SVG a un `cairo_image_surface` al tamaño exacto que pida el consumidor, con cache en memoria.

**Alcance.**
Cubre la carga de SVG en runtime desde disco con soporte completo de SVG estático (paths, gradientes, máscaras, filtros, texto, imágenes referenciadas). Cubre cache en memoria por `(path, w, h)` y liberación explícita. No cubre SVG animado ni SVG que dependa de scripts: resvg renderiza un estado estático. No cubre cache en disco: cada proceso renderiza en el primer uso, y los siguientes hits salen de memoria. No cubre carga lazy de la librería: `libresvg.so.0.48` se carga al hacer `require("lib.svg")`.

**Cómo funciona.**

Al cargar el módulo hace `ffi.load("/usr/lib/libresvg.so.0.48")` con path absoluto. El soname exacto varía según la versión de resvg instalada; en Void Linux `libresvg0-0.48.1` instala `/usr/lib/libresvg.so.0.48` y no crea el symlink `libresvg.so.0`. Pasar el path absoluto es más robusto que confiar en el nombre corto. La librería pesa ~3 MB de RSS al cargarse, contra los ~20 MB de librsvg. Sus dependencias son solo `libgcc`, `libm`, `libc`: no arrastra fontconfig, freetype, glib, ni harfbuzz.

`render` es la función interna que hace el trabajo:

1. Crea las opciones con `resvg_options_create`. El objeto se destruye con `resvg_options_destroy` al terminar el parse.
2. Parsea el SVG con `resvg_parse_tree_from_file`. Devuelve un `resvg_error` (0 = OK).
3. Lee el tamaño intrínseco con `resvg_get_image_size`.
4. Calcula el tamaño de render según los parámetros:
   - `w` y `h` presentes → tamaño exacto.
   - Solo `w` → alto calculado respetando el aspect ratio.
   - Solo `h` → ancho calculado respetando el aspect ratio.
   - Ninguno → tamaño intrínseco.
5. Construye una matriz de escala `resvg_transform` con `a = rw/iw`, `d = rh/ih`, resto en 0. **Importante**: `resvg_render` con transform identidad dibuja al tamaño intrínseco en la esquina superior izquierda del pixmap, dejando el resto vacío. Hay que pasar la escala explícita.
6. Llama a `resvg_render(tree, transform, rw, rh, buf)`. El buffer es de `rw * rh * 4` bytes en formato RGBA premultiplicado.
7. Destruye el árbol con `resvg_tree_destroy`.
8. Crea un `cairo_image_surface` ARGB32 de `rw × rh` con `cairo_image_surface_create`.
9. Copia el buffer de resvg al surface de Cairo, **swapeando R↔B**. resvg devuelve RGBA; Cairo ARGB32 en little-endian espera BGRA. Sin el swap los colores salen invertidos (azul por rojo).
10. Marca el surface como sucio con `cairo_surface_mark_dirty`.

El cache es una tabla global `_cache` con clave `"<path>:<w>x<h>"` y valores `surface` o `false` (para no reintentar cargas fallidas). `M.load` consulta primero el cache; si hay un valor distinto de `nil`, lo devuelve tal cual (`false` se convierte a `nil`). Si no hay entrada, llama a `render`, guarda el resultado (o `false` si falló) y lo devuelve.

Los errores se loguean con `log.warn` y `M.load` devuelve `nil`. Los errores posibles: la librería no se puede cargar, `resvg_options_create` devuelve `nil`, el parse falla (`RESVG_ERROR_FILE_OPEN_FAILED`, `RESVG_ERROR_PARSING_FAILED`, etc.), el tamaño intrínseco es inválido, o `cairo_image_surface_get_data` devuelve `nil`.

`invalidate(path)` recorre el cache y destruye todos los surfaces cuya clave empieza por `path .. ":"`. Útil si el archivo cambia en disco.

`clear_cache()` destruye todos los surfaces cacheados y reinicia la tabla. No descarga la librería (una vez cargada, queda).

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `load(path, w?, h?)` | surface o `nil` | Cachea por `(path, w, h)`. Si `w` y `h` son `nil`, usa el tamaño intrínseco. Loguea un `warn` si falla. |
| `invalidate(path)` | — | Destruye todos los surfaces cacheados para esa ruta. |
| `clear_cache()` | — | Destruye todos los surfaces cacheados y vacía el cache. |

**Patrón.**

Icono al tamaño de dibujo final, sin escalado posterior:

    local svg = require("lib.svg")
    local s = svg.load("icons/runtime/custom-logo.svg", 32, 32)
    if s then
        cairo.draw_surface(cr, s, x, y, 32, 32)
    end

Icono de barra con tamaño calculado al primer uso, cacheado para el resto:

    local surface = svg.load(path, 22, 22)

Dos tamaños distintos del mismo SVG conviven en el cache sin pisarse:

    local small = svg.load("logo.svg", 16, 16)
    local large = svg.load("logo.svg", 64, 64)

Ver `lib/icon_theme.lua` para el uso real con temas de iconos del sistema.

**Anti-patrón.**

- **Llamar `load` en cada `draw` sin guardar la referencia.** El cache de `svg.lua` evita el re-render, pero cada llamada hace string formatting para armar la clave y consulta una tabla. En un `draw` de 60 Hz con 50 iconos son 3000 lookups por segundo. Guardar la referencia en el widget al construirlo.
- **Llamar `load` sin tamaño y esperar nitidez en pantalla.** Sin `w` y `h`, se usa el tamaño intrínseco del SVG. Los SVG de temas de iconos suelen ser 22×22 o 48×48. Si el consumidor los dibuja a 64×64 desde ese surface, cairo interpola y se ve borroso. Pasar siempre el tamaño de dibujo final.
- **Ignorar el segundo retorno.** `M.load` devuelve `surface, err` en caso de fallo. Un consumidor que solo mire el primer valor verá `nil` sin saber por qué. Útil para debug con `LANETK_LOG=warn`.
- **Llamar `clear_cache` mientras hay widgets dibujando.** Los surfaces se destruyen y los widgets que los tienen referenciados dibujan basura o fallan. Solo llamar al desmontar todo el árbol.
- **Asumir que `libresvg.so.0.48` existe.** El path absoluto a `/usr/lib/libresvg.so.0.48` funciona en Void con `libresvg0-0.48.x`. En otras versiones o distros, ajustar. Si en el futuro se empaqueta un `libresvg.so.0` (symlink), se puede volver al nombre corto.
- **Renderizar SVG en un bucle sin cache.** `render` es ~1-2 ms por icono. Un grid de 100 iconos = 200 ms la primera vez. Después el cache sirve. Pero si el consumidor llama `invalidate` en cada frame, se pierde la ventaja.

**Notas.**

- La `.so` no se descarga una vez cargada. `clear_cache` libera los bitmaps pero mantiene la librería abierta.
- El surface devuelto es ARGB32, soporta alpha.
- El buffer intermedio de resvg es RGBA premultiplicado. El swap R↔B preserva el alpha tal cual (el cuarto byte va directo).
- Los SVG con recursos externos (imágenes referenciadas por href a archivos, fuentes externas) buscan los recursos usando el directorio del SVG como base. `resvg_options_load_system_fonts` está disponible en la API pero `svg.lua` no la llama: los SVG de iconos rara vez usan texto, y cargar todas las fuentes del sistema es caro. Si un SVG con texto se renderiza sin glifos, agregar esa llamada.
- Si el SVG tiene `width` y `height` en el header pero un `viewBox` distinto, resvg prioriza el `viewBox` para el aspect ratio. Los SVG de temas de iconos suelen ser consistentes entre ambos.

#### icon_theme.lua

**Propósito.**
Resuelve nombres de iconos del tema activo de GTK a superficies Cairo listas para dibujar. Puente entre el vocabulario freedesktop de nombres de iconos y las primitivas de dibujo del toolkit.

**Alcance.**
Cubre la detección del tema activo (gtk-3, gtk-4, gtk-2, default `hicolor`), la cadena de herencia declarada en `index.theme`, la búsqueda de un nombre por categoría y tamaño, el render de SVG vía `lib/svg.lua`, y el cache en memoria. No cubre el listado de todos los iconos de un tema (el toolkit solo resuelve nombres puntuales). No cubre escritura al cache en disco. No cubre actualización en caliente si el usuario cambia de tema mientras un proceso está corriendo: hay que llamar `clear_cache()` y volver a resolver.

**Cómo funciona.**

La detección del tema activo lee los archivos de configuración de GTK en orden de preferencia: `~/.config/gtk-3.0/settings.ini`, `~/.config/gtk-4.0/settings.ini`, `~/.gtkrc-2.0`. En cada uno busca la línea `gtk-icon-theme-name=`. El valor se limpia de comillas y espacios. Si ninguno define el tema, cae a `hicolor`. El resultado se cachea en una variable local; `clear_cache()` lo resetea.

La cadena de herencia se construye leyendo el `Inherits=` del `index.theme` de cada tema, recursivamente. El tema activo va primero, después sus padres declarados, después los padres de los padres, hasta agotar o encontrar ciclos (la tabla `seen` protege contra loops). El orden importa: `find_path` prueba cada tema en orden, y el primero que tenga el icono gana.

La búsqueda de un path (`find_in_theme`) itera por cada tamaño candidato y cada categoría candidata. Los tamaños son: el pedido por el consumidor (si es número), `scalable`, y después una lista fija `16, 22, 24, 32, 48, 64, 96, 128, 256`. Las categorías son: `mimetypes`, `places`, `actions`, `categories`, `devices`, `apps`, `applications`, `emblems`, `panel`, `status`, `stock`, `filetypes`, `filesystems`, `symbolic`. Para cada combinación `(tamaño, categoría)` prueba primero `.svg` y después `.png`. La primera coincidencia gana.

Los directorios se buscan en dos rutas: `~/.local/share/icons/<theme>` y `/usr/share/icons/<theme>`. La del usuario tiene prioridad. La verificación de existencia de directorio se hace con `os.execute("test -d ...")`, que es más lento que un `io.open` pero funciona uniformemente en directorios y archivos.

`resolve(name, size)` combina `find_path` con el render. Si el path termina en `.svg`, llama a `svg.load(path, size, size)` (que cachea el surface por `(path, size)` en su propio cache). Si termina en `.png`, llama a `cairo.load_png_cached(path)` (cache global de PNGs del módulo `cairo`). El resultado se guarda en `_surface_cache` con clave `"<name>:<size>"`. Los fallos se cachean como `false` para no reintentar.

Los caches de `icon_theme` son dos: `_path_cache` (name:size → path) y `_surface_cache` (name:size → surface). Ambos se invalidan con `clear_cache()`.

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `theme()` | string | Nombre del tema activo. Cacheado. |
| `parents()` | tabla de strings | Cadena de herencia, empezando por el tema activo. Cacheada. |
| `find_path(name, size)` | string o `nil` | Path absoluto al SVG/PNG. Cacheado por `(name, size)`. |
| `resolve(name, size)` | surface o `nil` | Surface Cairo listo para dibujar. Cacheado. |
| `clear_cache()` | — | Destruye los surfaces de Cairo cacheados, vacía las tablas y resetea el tema detectado. Solo llamar al desmontar. |

**Patrón.**

Icono genérico de archivo de texto:

    local icon_theme = require("lib.icon_theme")
    local s = icon_theme.resolve("text-x-generic", 22)
    if s then
        cairo.draw_surface(cr, s, x, y, 22, 22)
    end

Icono de carpeta:

    local s = icon_theme.resolve("folder", 22)

Diagnóstico del tema activo y su herencia:

    print(icon_theme.theme())
    for _, p in ipairs(icon_theme.parents()) do
        print("  " .. p)
    end

Ver `lib/tabs/files.lua` para el uso real: mapea extensiones de archivo a nombres de mimetype freedesktop y llama a `resolve`.

**Anti-patrón.**

- **Confundir el nombre del icono con un path.** `resolve("folder", 22)` espera un nombre freedesktop sin extensión, sin directorio. Pasar `"folder.svg"` o `"/usr/share/icons/Vimix/folder.svg"` no funciona. Si ya se tiene un path, usar `svg.load` o `cairo.load_png_cached` directamente.
- **Asumir que el tema tiene un nombre específico.** `resolve` funciona con cualquier tema que respete el estándar freedesktop. Pero los nombres concretos (por ejemplo, `text-x-python` o `text-rust`) pueden no existir en todos los temas. `resolve` devuelve `nil` en ese caso. Tener un fallback a un nombre más genérico (`text-x-generic`, `application-x-executable`).
- **Llamar `resolve` en cada `draw_row`.** El cache en memoria lo hace rápido (~1 μs), pero sigue siendo una consulta por fila. En un `ScrollView` con 50 filas por frame son 50 consultas por frame. Guardar la referencia en el item al construir la lista, o al menos en un cache del consumidor.
- **Asumir que el tamaño solicitado se respeta al píxel.** Si el tema no tiene un directorio `22/` pero tiene `24/`, `find_in_theme` cae a `24/` y después `resolve` renderiza a 22×22 (SVG) o usa el PNG nativo (24×24 escalado al dibujar). Para SVG es exacto; para PNG, el consumidor debe escalar al dibujar.
- **Llamar `clear_cache` sin volver a resolver los iconos de los widgets en pantalla.** Igual que en `svg.lua`: los surfaces se destruyen y los widgets que los tenían referenciados dibujan basura. Solo al desmontar.
- **Asumir que `theme()` refleja un cambio reciente del usuario.** El tema se lee al primer uso y queda cacheado. Si el usuario cambia el tema en `settings.ini` mientras un proceso corre, hay que llamar `clear_cache()` para que se relea.

**Notas.**

- El orden de preferencia de categorías prioriza `mimetypes` sobre `places` y `actions`. Esto significa que un nombre como `folder` (que existe en `places` y puede existir en `mimetypes`) se resuelve primero por `mimetypes` si el tema lo tiene ahí. En la práctica, `folder` solo existe en `places`.
- La verificación de existencia de directorios con `os.execute("test -d ...")` es más lenta que un `io.open`, pero en `find_path` el resultado se cachea por `(name, size)`. La primera consulta de cada nombre paga el costo; las siguientes son instantáneas.
- Los temas pueden tener dos variantes de un mismo icono (color y `-symbolic`). `icon_theme` no distingue: pide el nombre exacto. Si un consumidor quiere la variante symbolic, debe pedir el nombre con sufijo.
- La cadena de herencia respeta el orden declarado en `Inherits=`. Un tema como `Vimix-dark` que declara `Inherits=Papirus,Numix-Circle,Adwaita,hicolor` va a resolver primero en Vimix-dark, después en Papirus, etc. El primer acierto gana.
- `clear_cache` destruye los surfaces de Cairo antes de vaciar las tablas. Sin embargo, el RSS del proceso puede no bajar inmediatamente: el allocator de libc retiene los bloques liberados en lugar de devolverlos al kernel. La memoria sí queda disponible para futuras allocations del mismo proceso.
- **Contrato de `clear_cache`:** solo llamar cuando ningún widget tenga referencias a los surfaces ya devueltos por `resolve()`. Si un widget guardó un surface en un campo propio y después alguien llama `clear_cache`, el widget dibuja con un surface destruido. La convención del toolkit es que cada consumidor limpia su cache al desmontar su árbol, no a mitad de vida.

### Infraestructura

00a0

Servicios que usan los widgets y las aplicaciones: logging, paleta, event loop, ventana, monitores y utilidades varias. Viven en `src/lib/` porque son el pegamento entre los bindings y las clases de alto nivel.

#### mem.lua

**Propósito.**
Instrumentación opcional de memoria. Registra un timer que loguea RSS y uso del heap de Lua cada 60 segundos, si la variable de entorno `LANETK_MEM_DEBUG` está activa. Sin la variable, todas las funciones son no-ops y no se registra ningún timer.

**Alcance.**
Cubre la instrumentación básica para diagnosticar crecimiento de memoria en daemons de larga vida. No cubre profile detallado de allocations ni tracing de objetos. No cubre límites automáticos ni presión de GC: solo lectura y logging.

**Cómo funciona.**

`M.attach(srv, label)` lee `LANETK_MEM_DEBUG`. Si el valor no es `"1"` ni `"true"`, retorna sin hacer nada. Si está activa, cancela cualquier timer previo y registra uno nuevo de 60 segundos sobre el `Server` recibido. El timer lee `/proc/self/status` para extraer `VmRSS` y `collectgarbage("count")` para el heap de Lua, y emite una línea `log.info` con formato `[label] RSS=N KB  GC=N KB`.

`M.detach()` cancela el timer. Es opcional: el `Server` cancela los timers al parar. Pero sirve para apagar el monitor en runtime sin matar el proceso.

`M.rss_kb()` devuelve el RSS actual. Útil para scripts de diagnóstico que quieran medir sin registrar un timer.

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `attach(srv, label)` | — | Registra un timer de 60 s. No-op si `LANETK_MEM_DEBUG` no está activa. |
| `detach()` | — | Cancela el timer. |
| `rss_kb()` | int | RSS en KB leído de `/proc/self/status`. |

**Patrón.**

Instrumentar un daemon:

    local srv = Server.new({ exit_on_empty = false })
    local mem = require("lib.mem")
    mem.attach(srv, "mi-daemon")

Correr el daemon con la instrumentación activa:

    LANETK_MEM_DEBUG=1 LANETK_LOG=info ./run apps/<daemon>.lua 2>&1 | grep mem

Sin la variable, no se registra timer y el daemon funciona igual que sin `mem.attach`.

**Anti-patrón.**

- **Dejar `LANETK_MEM_DEBUG=1` en producción.** El timer corre cada 60 s y genera una línea de log cada vez. Es trivial en costo pero es ruido. La variable se activa a mano cuando se quiere diagnosticar.
- **Usar `mem.rss_kb()` como medida de "cuánta memoria usa LaneTK".** El RSS incluye la memoria compartida de las librerías C (`libcairo`, `libresvg`, `libpango`, `libxcb`) que el proceso tiene mapeadas. La comparación honesta contra otro proceso (por ejemplo `picom`) es contra el mismo RSS, no contra el heap de Lua.
- **Asumir que el RSS baja inmediatamente después de liberar memoria.** El allocator de libc retiene los bloques liberados en lugar de devolverlos al kernel. Un `collectgarbage("collect")` seguido de `clear_surface_cache` puede no bajar el RSS aunque sí libere los recursos C. La métrica útil es la tendencia a lo largo del tiempo, no el valor absoluto.
- **Llamar `attach` más de una vez sin `detach`.** El segundo `attach` cancela el timer anterior. No se acumulan, pero si dos módulos distintos llaman `attach` con labels distintos, solo queda el último. El módulo es un singleton, no multiplexa.

**Notas.**

- El intervalo está fijo en 60 s. Cambiarlo requiere editar el módulo.
- La lectura de `/proc/self/status` es específica de Linux. En otros sistemas el módulo devuelve 0 KB.
- El formato del log es `[<label>] RSS=<N> KB  GC=<N> KB` con dos espacios entre campos, para alinear en el log.
- El timer no se cancela al parar el `Server` con `srv:stop()` hasta que el server efectivamente pare el loop. En la práctica es instantáneo.

#### ewmh.lua

**Propósito.**
Lectura de propiedades EWMH (Extended Window Manager Hints) del root y de las ventanas. Da acceso a información que el WM publica por protocolo: nombre del WM, lista de clientes, escritorio actual, nombres de escritorios, propiedades de cada ventana.

**Alcance.**
Cubre lectura de propiedades EWMH del root y de ventanas individuales, suscripción a eventos `PropertyNotify` del root, y envío de client messages al WM (`_NET_CURRENT_DESKTOP`, `_NET_ACTIVE_WINDOW`, `_NET_CLOSE_WINDOW`, `_NET_WM_STATE`, `_NET_WM_DESKTOP`). No cubre `_NET_MOVERESIZE_WINDOW` ni `_NET_RESTACK_WINDOW` (se agregan si hacen falta). No cubre `_NET_WM_PID` ni `_NET_WM_WINDOW_TYPE` con wrappers dedicados: se leen con `xcb.get_property` directamente.

**Cómo funciona.**

`M.new(srv)` interna una lista fija de átomos EWMH (`_NET_SUPPORTED`, `_NET_CLIENT_LIST`, `_NET_ACTIVE_WINDOW`, `_NET_CURRENT_DESKTOP`, `_NET_WM_NAME`, etc.) por conexión y los guarda en `self.atoms`. Los interna una sola vez: es un round-trip al servidor X, y la lista es fija.

Cada getter lee su propiedad con `xcb.get_property` y devuelve el resultado ya parseado a tipos Lua:

- `wm_name()` lee `_NET_SUPPORTING_WM_CHECK` del root, que apunta a una ventana child. Después lee `_NET_WM_NAME` de esa ventana. Un WM que respeta EWMH debe publicar esa cadena; si no lo hace, devuelve `nil`.
- `supported()` devuelve el array de átomos que el WM declara soportar. Es una tabla de números (los átomos en sí), no de strings. Para comparar contra el nombre de un átomo, usar `self.atoms._NET_WM_STATE` y comparar contra el número.
- `client_list()` y `client_list_stacking()` devuelven la lista de window ids de clientes gestionados por el WM. `client_list` está ordenada por orden de mapeo; `client_list_stacking` por orden de apilado (útil para compositores).
- `active_window()` devuelve el window id activo o `nil`.
- `current_desktop()` y `desktop_count()` devuelven números.
- `desktop_names()` devuelve un array de strings. EWMH especifica que `_NET_DESKTOP_NAMES` viene como strings UTF-8 separados por `\0`. El módulo los divide.
- `window_name(wid)` prueba primero `_NET_WM_NAME` (UTF-8, preferido por GTK/Qt/apps modernas) y cae a `WM_NAME` (STRING, apps viejas).

`subscribe(cb)` registra `cb(property_atom, wid)` como handler de `PropertyNotify` del root. Para eso:

1. Marca la ventana root con `PropertyChange` + `SubstructureNotify` vía `xcb.change_window_attributes`.
2. Define `srv.on_root_event` con un closure que llama al callback cuando el evento es del root.

Solo admite un suscriptor a la vez: llamar `subscribe` dos veces reemplaza el callback anterior. Si dos consumidores necesitan reaccionar a eventos del root, hay que coordinar desde afuera (un dispatcher propio que llame a los dos).

`Server:_process_events` (agregado en el mismo cambio) enruta los eventos: si el window id corresponde a una `Window` registrada, va a `Window:_dispatch`; si corresponde al root y hay `on_root_event`, va al hook; si no, se descarta.

Los métodos de escritura (`set_current_desktop`, `activate_window`, `close_window`, `wm_state`) construyen un `xcb_client_message_event_t` y lo envían al root con `xcb.send_client_message_root`, que usa la máscara estándar de EWMH (`SubstructureRedirect | SubstructureNotify`). No esperan respuesta: el WM lo procesa o lo ignora. Después de cada envío se hace `xcb.flush`.

`move_window_to_desktop` es la excepción: en lugar de un client message, escribe directamente la propiedad `_NET_WM_DESKTOP` de la ventana con `xcb.change_property`. Es la forma canónica según EWMH (algunos WMs aceptan ambos; otros solo la propiedad directa).

**API.**

**Construcción.**

- **`M.new(srv)`** — devuelve una instancia. Interna los átomos EWMH por conexión. Si se abre una segunda conexión X, hay que crear otra instancia.

**Métodos.**

| Método | Retorno | Notas |
|---|---|---|
| `wm_name()` | string o `nil` | Nombre del WM activo. `nil` si no hay EWMH. |
| `supported()` | tabla de números | Átomos soportados por el WM. Vacía si no hay EWMH. |
| `client_list()` | tabla de window ids | Orden de mapeo. |
| `client_list_stacking()` | tabla de window ids | Orden de apilado. |
| `active_window()` | window id o `nil` | |
| `current_desktop()` | int o `nil` | |
| `desktop_count()` | int o `nil` | |
| `desktop_names()` | tabla de strings | División por `\0`. |
| `window_name(wid)` | string o `nil` | `_NET_WM_NAME` con fallback a `WM_NAME`. |
| `subscribe(cb)` | — | `cb(property_atom, wid)`. Reemplaza el callback anterior. |
| `unsubscribe()` | — | Quita el handler del root. |
| `set_current_desktop(n)` | — | Client message al WM. `n` 0-based. |
| `activate_window(wid, source?)` | — | Pide al WM que active (levante y enfoque) una ventana. `source` 0 por defecto. |
| `close_window(wid)` | — | Pide al WM que cierre una ventana (equivale a click en la X). |
| `window_desktop(wid)` | int o `nil` | Escritorio EWMH de una ventana. `nil` si no tiene o es sticky (`0xFFFFFFFF`). |
| `move_window_to_desktop(wid, n)` | — | Cambia `_NET_WM_DESKTOP` de una ventana. `n` 0-based. |
| `wm_state(wid, action, state1, state2?)` | — | Cambia `_NET_WM_STATE` de una ventana. `action`: 0=remove, 1=add, 2=toggle. |

**Campos.**

- `atoms` — tabla de `nombre → atom`. Útil para comparar contra los átomos devueltos por `supported()`.

**Patrón.**

Leer la información del WM activo:

    local ewmh = require("lib.ewmh").new(srv)
    print(ewmh:wm_name())
    print(ewmh:desktop_count())

Listar los nombres de ventanas activas:

    for _, wid in ipairs(ewmh:client_list()) do
        local name = ewmh:window_name(wid)
        if name then
            print(string.format("0x%x: %s", wid, name))
        end
    end

Reaccionar a cambios del escritorio actual:

    local prop = ewmh.atoms._NET_CURRENT_DESKTOP
    ewmh:subscribe(function(atom, wid)
        if atom == prop then
            local d = ewmh:current_desktop()
            print("escritorio actual:", d)
        end
    end)

Cambiar de escritorio y activar una ventana:

    ewmh:set_current_desktop(2)
    ewmh:activate_window(some_wid)
    ewmh:close_window(other_wid)

Poner una ventana en fullscreen (add de _NET_WM_STATE_FULLSCREEN):

    ewmh:wm_state(wid, 1, ewmh.atoms._NET_WM_STATE_FULLSCREEN)

Quitar el estado de "always on top":

    ewmh:wm_state(wid, 0, ewmh.atoms._NET_WM_STATE_ABOVE)

**Anti-patrón.**

- **Asumir que `wm_name()` devuelve algo.** En un entorno sin WM (o con un WM que no respeta EWMH como `dwm` sin parches), devuelve `nil`. En ese caso `supported()` también devuelve una tabla vacía, y el resto de getters devuelven `nil` o listas vacías.
- **Asumir que los métodos de escritura funcionan siempre.** Enviar un client message no garantiza que el WM haga lo pedido. Si el WM no declaró el átomo en `supported()`, lo ignora silenciosamente. Antes de usar una funcionalidad de escritura, verificar que el átomo esté en `supported()`.
- **Llamar `set_current_desktop` con un índice fuera de rango.** EWMH usa 0-based. Los índices válidos van de 0 a `desktop_count() - 1`. Un valor fuera de rango puede ser rechazado por el WM o interpretado de forma rara (algunos WMs lo clampean, otros ignoran).
- **Confundir el índice EWMH con el número de escritorio visual.** EWMH numera los escritorios del 0 al N-1 en orden de creación. El "5" que muestra el taglist de bspwm puede ser un nombre arbitrario que el usuario asignó, no el índice EWMH. Para mapear entre ambos, usar `desktop_names()` (que devuelve los nombres en orden EWMH).
- **Llamar `wm_state` con `action` que no sea 0, 1 o 2.** Cualquier otro valor tiene comportamiento indefinido. Los valores son `_NET_WM_STATE_REMOVE = 0`, `_NET_WM_STATE_ADD = 1`, `_NET_WM_STATE_TOGGLE = 2`.
- **Llamar a los getters en un bucle por frame.** Cada getter es un round-trip al servidor X. En un draw de 60 Hz son 60 round-trips por segundo por getter. Cachear el resultado y refrescar con `subscribe` cuando cambie.
- **Asumir que `client_list()` está en orden de apilado.** El orden de apilado (para z-order) lo da `client_list_stacking()`. `client_list()` está en orden de mapeo y es más estable para mostrar en UI.
- **Confundir `active_window()` con "la ventana con foco del toolkit".** El primero es del WM (una ventana X arbitraria); el segundo es `window.focus_widget` (un `Area`). Son conceptos distintos.
- **Modificar la lista devuelta por `desktop_names()` o `client_list()`.** Cada llamada devuelve una tabla nueva; mutarla no afecta al WM ni al estado interno del módulo. Correcto.
- **Olvidar llamar `unsubscribe` al cerrar.** Si un consumidor subscribe y después se destruye, `srv.on_root_event` sigue apuntando a un closure que puede tener referencias a widgets muertos. Llamar `unsubscribe` en el `on_close` o `stop`.

**Notas.**

- El módulo vive en `src/lib/` porque es infraestructura: lo usan tabs, widgets, y eventualmente el taglist. No depende del árbol de widgets.
- `Server:_process_events` fue agregado junto con `ewmh.lua` para tener un solo punto de dispatch. Antes había dos bloques idénticos en `_loop` que procesaban eventos sin pasar por el hook.
- Los átomos son números opacos. Comparar contra `self.atoms.<NOMBRE>` es la forma correcta; comparar contra strings no funciona.
- Si el WM cambia de "no-EWMH" a "EWMH" mientras un proceso corre (por ejemplo, cambio en caliente de WM), los getters empezarán a devolver datos. No hay que re-instanciar `ewmh`. Pero conviene llamar `subscribe` de nuevo: los eventos `PropertyNotify` del root solo llegan después de marcar `PropertyChange`.
- `_NET_WM_STATE` se puede leer con este módulo (es una propiedad del cliente), pero no hay wrapper específico: usar `xcb.get_property` directamente sobre el átomo que quieras.

#### reload.lua

**Propósito.**
Hot reload entre procesos. Permite que un proceso (por ejemplo la app de Configuración) avise a los demás procesos del entorno que algo cambió, y que cada uno recargue su estado y reconstruya su UI sin intervención del usuario.

**Alcance.**
Cubre la señalización inter-proceso con `SIGUSR1` y su entrega por `signalfd`, y el broadcast a todos los procesos `apps/*.lua` vivos. No cubre el transporte de datos entre procesos: si hace falta pasar un payload (por ejemplo, "este es el nuevo nombre de paleta"), se hace con archivos o sockets. El módulo solo notifica "algo cambió, recargá lo tuyo".

**Cómo funciona.**

El mecanismo usa `signalfd`, que es la forma canónica en Linux de convertir una señal en un fd legible. La razón por la que no se usa un handler de señal con una función Lua es que LuaJIT no permite reentrar su runtime desde un signal handler. El síntoma cuando se intenta es `PANIC: unprotected error in call to Lua API (bad callback)` seguido de la muerte del proceso.

`M.install(srv, cb)` hace cuatro cosas:

1. Bloquea `SIGUSR1` en el proceso con `sigprocmask(SIG_BLOCK)`. Mientras está bloqueada, la señal no interrumpe el proceso: queda pendiente en el kernel.
2. Crea un `signalfd` con esa máscara. Devuelve un fd.
3. Registra el fd en el `Server` con `srv:add_fd(fd, handler)`. El Server lo pollea junto con el fd de XCB.
4. El handler hace `read()` sobre el fd (drena todas las señales pendientes) y después llama a los callbacks registrados, en contexto normal.

`M.broadcast()` recorre `pgrep -f 'apps/.*\.lua'`, excluye el propio PID, y manda `SIGUSR1` a cada uno con `kill`. No bloquea, no espera respuesta.

El módulo es un singleton por proceso: `install` se puede llamar varias veces, pero el `signalfd` se crea solo la primera vez y el callback se agrega a una lista.

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `install(srv, cb)` | fd o `nil` | Instala el signalfd (una sola vez por proceso) y registra el callback. |
| `broadcast()` | int | Manda SIGUSR1 a todos los `apps/*.lua` vivos excepto este proceso. Devuelve cuántos recibieron. |

**Patrón.**

En una app que quiere reaccionar a cambios externos:

    local reload = require("lib.reload")
    reload.install(srv, function()
        theme.reload_in_place(my_theme)
        rebuild_my_ui()
    end)

En el proceso que origina el cambio (por ejemplo, la app de Configuración al pulsar Aplicar):

    local reload = require("lib.reload")
    local n = reload.broadcast()
    log.info("config", "avisados %d procesos", n)

El contrato del callback es: recargar el estado global que se haya podido modificar (típicamente la paleta), y reconstruir la UI. No hay payload, no hay orden garantizado.

**Anti-patrón.**

- **Usar `signal()` con un handler Lua.** LuaJIT no permite reentrar su runtime desde un signal handler. El síntoma es `PANIC: unprotected error in call to Lua API (bad callback)`. Por eso se usa `signalfd`.
- **Llamar `broadcast()` desde un callback de `install`.** Entra en bucle: el proceso A manda SIGUSR1 a B, B manda a A, A manda a B... El `broadcast` está pensado para un solo origen (típicamente un proceso de control), no para todos los receptores.
- **Asumir que los callbacks corren en orden entre procesos.** `broadcast` dispara señales sin esperar respuesta. Cada proceso las recibe cuando puede.
- **No bloquear `SIGUSR1`.** Si el proceso arranca con un handler default y llega la señal antes de que `install` bloquee, el proceso muere. En la práctica `install` se llama al arrancar, pero es un caso a tener en cuenta si el proceso hace trabajo pesado antes.
- **Olvidar llamar `read()` sobre el fd en el callback.** Aunque `signalfd` permite el read a nivel Lua con `ffi.C.read`, si el callback no drena el fd, el `poll` vuelve a marcarlo como legible en la próxima iteración y el callback se llama en bucle. El handler del módulo ya drena, pero si un consumidor agrega otro callback que intercepte antes, tiene que drenar él.

**Notas.**

- `signalfd` es Linux-específico. En otros sistemas habría que usar un self-pipe.
- El `signalfd` se crea con `SFD_NONBLOCK | SFD_CLOEXEC`: no bloquea si hay varias señales en cola y no se hereda al `exec`.
- El `Server` expone `add_fd(fd, cb)` para cualquier fd externo. No es específico de `reload`: sirve para sockets, inotify, etc. El Server los pollea junto con el fd de XCB y llama al callback cuando alguno se vuelve legible.

#### log.lua

**Propósito.**
Logging con niveles, escrito a `stderr`. Relee la variable de entorno `LANETK_LOG` en cada emisión para permitir cambiar el nivel en caliente sin reiniciar el proceso.

**Alcance.**
Cubre emisión de mensajes formateados a `stderr` con timestamp, nivel y prefijo. Cubre también un mapeo de códigos de evento X11 a nombres legibles, usado por `server.lua` y `window.lua` cuando loguean tipos de evento. No cubre escritura a archivo, ni rotación, ni envío por red. No cubre niveles por módulo: el nivel es global al proceso.

**Cómo funciona.**

El módulo tiene una tabla `LEVELS` que mapea nombre de nivel a número: `error = 1`, `warn = 2`, `info = 3`, `debug = 4`, `trace = 5`. Cada llamada relee `os.getenv("LANETK_LOG")` y consulta esa tabla. Si el nivel del mensaje es mayor que el configurado, la llamada retorna sin escribir nada.

El default es `warn`. Un valor desconocido en `LANETK_LOG` (por ejemplo `LANETK_LOG=verbose`) también cae a `warn` porque `LEVELS[v]` devuelve `nil` y el `or` toma el fallback.

La función interna `emit` formatea el mensaje con `string.format`, construye un prefijo `[HH:MM:SS LEVEL prefijo]` con la hora local y escribe a `stderr` con `io.stderr:write`. Llama a `flush` inmediatamente, para que los mensajes aparezcan en el terminal en tiempo real incluso si la salida está redirigida a un pipe.

`EVENT_NAMES` es una tabla con los códigos de evento que el toolkit maneja. `event_name` la consulta y devuelve el nombre, o `"unknown(N)"` si el código no está en la tabla. Es puramente cosmético: los eventos se procesan por código numérico, no por nombre.

**API.**

**Constantes.**

- `EVENT_NAMES` — tabla `código numérico -> nombre`. Incluye los eventos que el toolkit maneja: KeyPress, KeyRelease, ButtonPress, ButtonRelease, MotionNotify, EnterNotify, LeaveNotify, FocusIn, FocusOut, Expose, VisibilityNotify, CreateNotify, DestroyNotify, UnmapNotify, MapNotify, MapRequest, ReparentNotify, ConfigureNotify, ConfigureRequest, PropertyNotify, ClientMessage.

**Funciones.**

| Función | Notas |
|---|---|
| `error(prefix, fmt, ...)` | Nivel 1. |
| `warn(prefix, fmt, ...)` | Nivel 2. Nivel default. |
| `info(prefix, fmt, ...)` | Nivel 3. |
| `debug(prefix, fmt, ...)` | Nivel 4. |
| `trace(prefix, fmt, ...)` | Nivel 5. |
| `event_name(etype)` | Devuelve el nombre del tipo de evento X11, o `"unknown(N)"`. |

Todas las funciones de emisión aceptan `prefix` (string sin espacios, típicamente el nombre del módulo emisor) más un formato `string.format` con sus argumentos.

**Patrón.**

Usar el nombre del módulo como prefijo, para que los logs sean filtrables con `grep`:

    local log = require("lib.log")
    log.info("server", "conexion ok. screen=%d, root=0x%x", num, root)
    log.debug("dispatch", "etype=%d wid=0x%x", etype, wid)
    log.error("create_window", "fallo: %s", err)

Para desarrollo, arrancar con el nivel deseado:

    LANETK_LOG=debug ~/proyectos/lanetk/run examples/03-events.lua

Para ver todo el detalle del dispatch de eventos, con `trace`:

    LANETK_LOG=trace ~/proyectos/lanetk/run examples/03-events.lua 2>&1 | grep dispatch

**Anti-patrón.**

- **Asumir que `LANETK_LOG=info` muestra los `debug`.** La jerarquía es estricta: `info` (3) filtra todo lo de nivel 4 y 5. Para ver `debug`, hay que poner `LANETK_LOG=debug`. Documentado en `notes.md`.
- **Loguear en bucle por frame.** Cada llamada hace `os.getenv`, `string.format` y `write`. Un `log.debug` dentro de `draw` multiplica el coste. Si hace falta instrumentar el draw, hacerlo con contador y loguear cada N frames.
- **Usar `print` en lugar de `log`.** `print` va a `stdout` sin timestamp ni nivel y no respeta `LANETK_LOG`. Los scripts que parsean `stdout` pueden romperse.

**Notas.**

- El nivel se relee en cada emisión. Cambiar `LANETK_LOG` en el entorno del proceso en runtime no afecta: la variable se consulta desde el propio proceso, no desde el shell que lo lanzó. Para cambiar el nivel en caliente habría que exponer un setter, que no existe.
- Los mensajes van a `stderr`, no a `stdout`. Los scripts que quieran capturar logs deben redirigir `2>`.
- El timestamp es `HH:MM:SS`, sin fecha ni milisegundos.
- No hay buffering: cada mensaje se escribe y se flushea. Para procesos con logging intenso, esto puede ser costoso. No es el caso del toolkit.


##### Detección de fd roto (2026-09-26)

`Server:_loop` monitorea el socket XCB con `poll.wait_readable`, que
devuelve **dos valores**: `readable, broken`.

`broken` es `true` si el `revents` de `poll` incluye `POLLHUP`,
`POLLERR` o `POLLNVAL`. Cuando eso pasa, el otro extremo del socket
(Xorg) cerró la conexión, y el fd ya no sirve para nada. `poll`
retorna inmediatamente en cada llamada, y `xcb_poll_for_event` no
consume nada porque HUP no es un evento.

`Server:_loop` detecta el flag y sale limpio (loguea y hace
`self.running = false`). Sin esto, el loop gira a decenas de miles de
iteraciones por segundo hasta que alguien mate el proceso.

Caso típico de HUP: un cliente X usa `XKillClient` (por ejemplo
`bspc node -k` o `xdotool windowkill`) sobre una ventana. Esto NO
cierra la ventana: cierra **toda la conexión X del cliente**. Si el
toolkit comparte esa conexión, el socket queda muerto y sin esto el
daemon gira al 100%.

El atajo `super+shift+q` de bspwm usa `bspc node -c` (Close =
WM_DELETE_WINDOW) en lugar de `-k` para evitar el HUP en el caso
normal. La detección de `broken` es la red de seguridad para
cualquier XKillClient externo.

#### theme.lua

**Propósito.**
Carga una paleta desde `palettes/` y la expone como la tabla `theme` que consumen widgets y tabs. Resuelve la ruta de la paleta a usar por orden de preferencia, la carga, y deriva campos adicionales (colores en formato `{r, g, b}` listos para Cairo).

**Alcance.**
Cubre resolución de ruta, carga desde archivo, conversión de colores hex a floats, listado de paletas disponibles, y recarga en caliente. No cubre el rebuild de la UI tras un cambio de paleta: eso lo coordina el consumidor que quiera hacerlo (ver `theme.rebuild` abajo). No cubre el editor de paletas: las paletas son archivos `.lua` que el usuario edita a mano.

**Cómo funciona.**

La carpeta `palettes/` se localiza subiendo desde el directorio del propio `theme.lua` hasta seis niveles, buscando un subdirectorio llamado `palettes/`. Así funciona tanto desde el repo fuente (`~/proyectos/lanetk/src/lib/theme.lua` → `~/proyectos/lanetk/palettes/`) como instalado en otro layout. La comprobación usa `io.popen("test -d ...")`, sin FFI, para no depender de `<sys/stat.h>`.

La resolución de la paleta sigue tres pasos. Primero consulta `LANETK_PALETTE`: si es ruta absoluta y el archivo existe, la usa; si es un nombre, busca `<PALETTE_DIR>/<nombre>.lua`. Segundo, consulta `~/.config/lanetk/palette`, un archivo de una sola línea con el nombre de la paleta. Tercero, cae al default `gruvbox-warm.lua`. Si ninguno existe, lanza `error`.

Cada paleta es un archivo Lua que devuelve una tabla con tres secciones: `colors` (colores base), `semantic` (colores con significado) y `telemetry` (colores por clave de widget de barra). `theme.load` verifica que `colors` y `semantic` existan; si falta cualquiera, lanza `error` con un mensaje que indica la ruta del archivo problemático. La sección `telemetry` es opcional: si no está, `theme.telemetry` queda como tabla vacía.

La tabla devuelta por `load` aplaná las secciones: los colores quedan como campos directos (`t.bg`, `t.accent`, `t.muted`, etc.) y también se derivan versiones `_rgb` con la forma `{r, g, b}` (floats `[0,1]`) listos para `cairo.set_rgb`. Los valores originales quedan como strings `#rrggbb`. Ambas representaciones conviven.

`reload_in_place` reescribe los campos de una tabla existente en lugar de crear una nueva. Quien tenga referencia a la tabla (por ejemplo, un widget que la guardó en su constructor) ve los cambios. No repinta nada por sí sola: los widgets que ya capturaron colores específicos en construcción siguen con los viejos hasta que se reconstruyan. Por eso existe el hook opcional `theme.rebuild`: si el consumidor lo define, se llama tras un `reload_in_place` para que reconstruya su árbol.

**API.**

**Constantes.**

- `PALETTE_DIR` — ruta absoluta al directorio de paletas.
- `CONFIG_FILE` — ruta a `~/.config/lanetk/palette`.

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `find_palette_path()` | ruta absoluta | Orden: `LANETK_PALETTE` → `CONFIG_FILE` → `gruvbox-warm.lua`. Lanza `error` si no encuentra nada. |
| `list_palettes()` | tabla de strings | Nombres sin `.lua`, ordenados alfabéticamente. |
| `load(palette_path?)` | tabla `theme` | Sin argumento, usa `find_palette_path()`. Lanza `error` si la paleta no tiene estructura esperada. |
| `palette_path(name)` | ruta absoluta | Concatenación directa. No comprueba existencia. |
| `reload_in_place(T, palette_path?)` | `true` o `false, msg` | Muta `T` en su lugar. |

**Campos de la tabla `theme`.**

Colores base (strings `#rrggbb`):

- `path` — ruta absoluta de la paleta cargada.
- `bg`, `bg_card`, `bg_focus`, `fg_normal`, `fg_on_color`, `accent`, `urgent`.

Colores semánticos (strings `#rrggbb`):

- `muted`, `ghost`, `separator`, `usage_warn`, `usage_crit`.

Colores de telemetría:

- `telemetry` — tabla libre (viene de la paleta). Mapea claves como `cpu`, `mem`, `gpu` a strings `#rrggbb`. Los constructores de la barra la consultan con fallback.

Colores derivados (`{r, g, b}` con floats `[0,1]`):

- `bg_rgb`, `bg_card_rgb`, `bg_focus_rgb`, `fg_rgb`, `separator_rgb`, `accent_rgb`, `urgent_rgb`, `muted_rgb`.

**Patrón.**

Cargar la paleta una vez al arrancar y pasarla a los consumidores:

    local theme = require("lib.theme")
    local T = theme.load()
    local panel = Panel.new { theme = T, tabs = ... }

Cuando un consumidor construye un widget y guarda colores, guardarlos ya extraídos del theme:

    local card = W.Card.new {
        bg     = T.bg_card_rgb,
        title  = "CPU",
    }

Cambio de paleta en caliente (con rebuild del árbol):

    theme.reload_in_place(T, theme.palette_path("nord"))
    if T.rebuild then T.rebuild() end  -- hook opcional del consumidor

**Anti-patrón.**

- **Llamar `find_palette_path()` en bucle.** Cada llamada hace `io.popen` con `test -d` varias veces. Resolver la ruta una vez al arrancar.
- **Asumir que `reload_in_place` repinta la UI.** Solo actualiza la tabla. Los widgets que capturaron `theme.bg_rgb` en su constructor siguen con el valor viejo. Hay que reconstruir el árbol.
- **Editar `theme.bg` esperando que se propague.** Mismo motivo: los widgets guardan valores, no referencias al theme. Para cambio en caliente, usar `reload_in_place` y rebuild.
- **Mezclar `theme.bg` (string) y `theme.bg_rgb` (tabla) en el mismo consumidor.** Los `_rgb` son tablas `{r, g, b}`, no floats sueltos. Para pasar a Cairo hay que indexar o usar `G.set_color(cr, t.bg)`, que acepta el string.

**Notas.**

- Los campos `bg_card` y `bg_focus` caen en cascada: si la paleta no define `bg_card`, se usa `bg_focus` o `bg`. `load` y `reload_in_place` aplican esta cascada al cargar.
- `telemetry` es una tabla libre: cada paleta puede definir las claves que quiera. Los constructores de barra leen `theme.telemetry.cpu` con fallback a `theme.accent`.
- La paleta default es `gruvbox-warm.lua`. El proyecto distribuye 14 paletas copiadas del proyecto Awesome original.
- `list_palettes` lee el directorio con `ls -1`. Si `PALETTE_DIR` no existe, devuelve tabla vacía sin error.
- La conversión hex → rgb la hace `helpers/graphics.hex_to_rgba`, que acepta `#RRGGBB` y `#RGB`. El cuarto valor (alpha) se ignora en los campos `_rgb`: solo se guardan los tres primeros.


#### Reglas de damage tracking (2026-09-25)

Desde el fix del bug de TabsBar negro (Apéndice 7.3), el sistema de
damage sigue dos reglas estrictas:

- **`full = force_redraw`, nunca inferido del damage.** El criterio
  anterior (`_damage_covers_most`, >80% del área) pintaba el fondo sin
  clip pero dejaba `should_draw` filtrando widgets fuera del
  `damage_list`. Resultado: stale pixels permanentes en los TabsBar.
  Con `full = self.force_redraw` la decisión es binaria y coherente:
  o todo (con force_redraw, `should_draw` devuelve `true` para todos)
  o parcial (con clip al damage, los widgets fuera conservan sus
  píxeles del frame anterior, que siguen siendo correctos porque no
  cambiaron).

- **`Window:damage_all` NO limpia `damage_list`.** Solo setea
  `force_redraw = true`. La lista se limpia al final de `Window:draw`,
  después de aplicar el clip y blitear al X11. Si se limpia antes, los
  rects que otros widgets añadieron en el mismo tick (por ejemplo
  `TabsBar:set_active` antes de un `invalidate_layout`) se pierden, y
  en el próximo frame el blit parcial deja esos rects con basura.

Las funciones `_damage_covers_most` y `_damage_union_ratio` siguen en
`window.lua` pero ya no se usan. Se pueden borrar sin riesgo.

#### Niveles de animación (2026-09-25)

El toolkit tiene cuatro niveles de animación, independientes:

- **`animate_panel`** (master). Si está en `false`, no se inicializa el
  motor y ninguno de los tres sub-toggles tiene efecto.
- **`animate_tabs`**. Crossfade entre tabs.
- **`animate_widgets`**. Animaciones de entrada (`Intro.play`).
- **`animate_values`**. Animaciones de datos (`Ring:animate_to`,
  `Spark:push_animated`, `BarRow:set_animated`, etc.).

Se leen con `lib.data.config.get_anim_opts()` y se persisten en
`~/.config/awesome/conf.lua`. El tab Configuración los expone como
toggles y el botón Aplicar los escribe + reconstruye el panel.

#### server.lua

**Propósito.**
Conexión XCB con event loop basado en `poll()`. Enruta eventos X11 a las ventanas registradas, gestiona timers periódicos y observa un archivo de trigger. Es el motor que mantiene vivo un proceso con UI.

**Alcance.**
Cubre apertura de conexión, cacheo de átomos por conexión, enrutado de eventos a ventanas por window id, timers, y observación de un trigger file. No cubre dibujo ni dispatch interno de cada ventana: eso vive en `window.lua`. No cubre captura de foco ni gestión de teclado: vive en `window.lua` y `xkb.lua`.

**Cómo funciona.**

`Server.new` abre la conexión XCB con `xcb.connect`, obtiene el `screen`, el `visualtype`, interna un conjunto fijo de átomos EWMH/ICCCM (`WM_PROTOCOLS`, `WM_DELETE_WINDOW`, `_NET_WM_NAME`, `_NET_WM_WINDOW_TYPE*`, `_NET_WM_STRUT*`, `UTF8_STRING`, `STRING`) y guarda el file descriptor del socket. Los átomos se cachean una sola vez por conexión: `intern_atom` es un round-trip, así que hacerlo por ventana sería costoso.

El loop de `_loop` se ejecuta mientras `self.running` sea true. En cada iteración:

1. Si `exit_on_empty` es true y no hay ventanas registradas, cancelar todos los timers y salir.
2. Vaciar el buffer interno de XCB con `xcb.poll_event` en bucle hasta que devuelva `nil`, enrutando cada evento a su ventana vía `extract_window_id`.
3. Si en el paso 2 no se procesó nada, calcular el timeout para el próximo timer (o 200 ms si hay trigger activo, o bloqueo indefinido si no hay nada) y llamar a `poll.wait_readable(fd, timeout)`.
4. Si el socket es legible, vaciar de nuevo el buffer interno con `xcb.poll_event`.
5. Ejecutar los timers vencidos.
6. Comprobar el trigger file.
7. Recorrer todas las ventanas y llamar `win:draw()`.

El paso 2 antes del `poll` es crítico. `xcb.sync` (que llama `map_window` internamente) hace un round-trip al servidor: durante la lectura del socket, XCB puede recibir otros eventos y guardarlos en su buffer interno. Si el loop solo consulta `poll(fd)`, esos eventos quedan invisibles hasta que llegue algo nuevo al socket. El síntoma es una ventana que aparece vacía hasta el primer input. Documentado en `notes.md`, entrada "eventos huérfanos en el buffer interno de XCB".

`extract_window_id` conoce el offset del window id dentro del evento según su tipo: 4 para eventos "notify" (Expose, ConfigureNotify, ClientMessage, DestroyNotify, UnmapNotify, MapNotify, ReparentNotify, PropertyNotify, VisibilityNotify) y 12 para eventos de input (KeyPress, KeyRelease, ButtonPress, ButtonRelease, MotionNotify, EnterNotify, LeaveNotify, FocusIn, FocusOut). Si el tipo no está en ninguna de las dos listas, devuelve `nil` y el evento se descarta sin enrutar. `notes.md` tiene los dumps hex que confirman los offsets.

Los timers se guardan en una tabla `self.timers` como conjunto (handle → true). Cada handle tiene `interval`, `next_at`, `callback` y `cancelled`. `add_timer` devuelve un objeto con método `:cancel()`. Los timers no se repiten automáticamente: al dispararse, se reprograma `next_at = now + interval`. Si el callback tarda más que el intervalo, el siguiente disparo ocurre inmediatamente después. `_run_timers` recolecta primero los vencidos en una lista y los ejecuta después, para que un callback pueda añadir o cancelar timers sin mutar la tabla durante el `pairs`.

El trigger file se observa con `watch_trigger(path, callback)`. Cada 200 ms, `_check_trigger` comprueba con `ffi.C.access` si el archivo existe. Si existe, lo lee, lo borra, y llama al callback con su contenido (o `"toggle"` si está vacío). El callback se ejecuta con `pcall`; si lanza, se loguea y el loop sigue.

`_next_timer_delay` devuelve el número de milisegundos hasta el próximo timer, o 200 si hay trigger activo sin timers, o `-1` (bloqueo indefinido) si no hay timers ni trigger.

`run` envuelve `_loop` en un `pcall` para capturar el error `"interrupted!"` que LuaJIT lanza con SIGINT. Si la interrupción es por SIGINT, sale limpio; si es un error real, limpia las ventanas, desconecta y relanza.

**API.**

**Construcción.**

- **`Server.new(opts)`** — Abre conexión XCB, cachea átomos, inicializa tablas de ventanas y timers.
  - `opts.displayname` — nombre del display (opcional).
  - `opts.exit_on_empty` — default `true`. Si no hay ventanas, el loop termina.

**Campos públicos.**

- `conn` — conexión XCB (`xcb_connection_t*`).
- `screen_num` — índice de la pantalla.
- `screen` — `xcb_screen_t*` de la pantalla.
- `visualtype` — `xcb_visualtype_t*` del root.
- `atoms` — tabla de átomos internados.
- `fd` — file descriptor del socket.
- `windows` — tabla `window_id -> Window`.
- `timers` — conjunto de handles activos.
- `running` — booleano. Poner en `false` termina el loop.
- `exit_on_empty` — booleano.
- `trigger_path` — ruta del trigger file o `nil`.
- `trigger_callback` — callback registrado.

**Métodos.**

| Método | Retorno | Notas |
|---|---|---|
| `add_window(win)` | — | Registra por `win.id`. |
| `remove_window(win)` | — | Desregistra. |
| `count()` | `int` | Nº de ventanas registradas. |
| `stop()` | — | Pone `running = false`. |
| `flush()` | — | `xcb.flush`. |
| `add_timer(interval_ms, callback)` | handle | Devuelve `{ cancel = function() ... end }`. |
| `watch_trigger(path, callback)` | — | Registra observación del archivo. |
| `cancel_all_timers()` | — | Vacía la tabla de timers. |
| `run()` | — | Ejecuta el loop. Bloquea hasta `stop()`, cierre de última ventana (con `exit_on_empty`), o SIGINT. |

**Patrón.**

Uso típico compartido entre varias ventanas:

    local Server = require("lib.server")
    local srv = Server.new { exit_on_empty = false }
    local win1 = Window.new(srv, { ... })
    local win2 = Window.new(srv, { ... })
    srv:run()

Para daemons que esperan trigger:

    local srv = Server.new { exit_on_empty = false }
    srv:watch_trigger("/tmp/lanetk-panel.cmd", function(cmd)
        if cmd == "toggle" then panel:toggle() end
    end)
    srv:run()

Timers desde dentro de un widget:

    self.timer = srv:add_timer(2000, function()
        self:refresh()
    end)
    -- al destruir el widget:
    if self.timer then self.timer:cancel() end

Ver `examples/20-panel-toggle.lua` para el flujo completo de daemon con trigger.

**Anti-patrón.**

- **Bloquear el loop dentro de un callback.** `Server:_loop` es single-thread. Un callback de timer o trigger que haga `os.execute` sobre un comando lento congela el repintado y todos los eventos X11. Para comandos lentos, usar `helpers/async.lua` o `io.popen` desde un proceso separado.
- **Consultar solo `poll(fd)` sin vaciar el buffer interno antes.** Los eventos leídos por un `xcb.sync` previo quedan atrapados en el buffer interno. El loop parece dormido aunque haya eventos pendientes. Documentado en `notes.md`.
- **Registrar muchos timers de intervalo muy corto.** El `poll` se reprograma con el más cercano, pero con muchos timers pequeños el loop no descansa. Intervalos menores a 50 ms solo para animaciones reales.
- **Ignorar `exit_on_empty` al escribir un daemon.** El default `true` hace que el proceso muera cuando se cierra la última ventana. Para daemons hay que pasar `exit_on_empty = false` y llamar `srv:stop()` explícitamente.
- **Asumir que `xcb.wait_event` cubre el caso.** `wait_for_event` bloquea y lee solo del socket. `poll_for_event` consulta primero el buffer interno. El loop usa `poll_for_event` siempre. `notes.md` documenta el patrón.

**Notas.**

- El cache de átomos se crea con `atoms_for(conn)` en el constructor. Solo los átomos que el toolkit usa hoy. Para añadir nuevos, editar esa función.
- Los callbacks de timer se ejecutan con `pcall`. Un error en el callback no detiene el loop: se loguea y sigue.
- `_run_timers` recolecta los vencidos antes de ejecutarlos, así que un callback que cancele otro timer no interfiere con la iteración.
- `_check_trigger` usa `ffi.C.access` para comprobar existencia sin abrir el archivo. Es más rápido y evita race conditions con `io.open`.
- El trigger file se borra tras leerlo, así que un trigger solo dispara una vez. Para triggers repetidos, el emisor debe reescribir el archivo.
- El loop llama `win:draw()` a todas las ventanas en cada iteración, incluso si no hubo eventos. `Window:draw` decide si hay algo que hacer consultando `force_redraw` y `damage_list`. Si no hay damage, retorna sin dibujar. Ver `window.lua`.
- `cancel_all_timers` no llama a los callbacks pendientes: los descarta. Es lo correcto al salir.

#### window.lua

**Propósito.**
Ventana X11 con doble buffer, damage tracking, dispatch de eventos a un árbol de widgets opcional y gestión de foco de teclado. Es la clase que usan las aplicaciones para tener algo visible en pantalla.

**Alcance.**
Cubre creación de ventanas top-level y child, hints ICCCM, struts, título, atributos de WM_CLASS, dispatch de eventos X11 al árbol de widgets o a hooks globales, doble buffer con backing store, damage tracking, y gestión del foco de teclado. No cubre el event loop: vive en `server.lua`, y `Window` se registra en él. No cubre el árbol de widgets en sí: vive en `area.lua` y `widgets/`. No cubre el redimensionado reactivo del árbol más allá del relayout de `ConfigureNotify`.

**Cómo funciona.**

Cada `Window` mantiene dos superficies Cairo en paralelo. `surface` es la superficie XCB, destino real. `image_surface` es un surface de imagen RGB24 del mismo tamaño que la ventana, usado como backing store. El árbol de widgets dibuja siempre sobre `image_cr` (el contexto de `image_surface`); al terminar el frame, `Window:draw` blitea la región con damage al `surface` X11 con operador `SOURCE`. El blit es una sola operación sobre la región marcada. Este doble buffer elimina el parpadeo que aparecería dibujando directamente sobre X11 en cada frame.

El constructor `Window.new` acepta dos formas. `Window.new(opts)` crea su propio `Server` (útil para scripts simples). `Window.new(server, opts)` reutiliza un `Server` existente (necesario para múltiples ventanas o daemons).

Los especificadores de tamaño y posición se resuelven antes de crear la ventana. Tamaño: número (píxeles), `"screen"` (dimensión completa de la pantalla), `"auto"` (llama a `opts.on_measure` para obtener el valor), `"free"` (0, el WM decide), o `"N%"` (porcentaje). Posición: número, `"center"` (centrado en la pantalla) o `"cursor-screen"` (centrado en el monitor donde está el cursor, calculado con `lib.screens`). Los bounds (`min_*`, `max_*`) aceptan número, `"screen"` o `"free"`.

Tras crear la ventana X11 con `xcb.create_window`, el constructor publica una serie de propiedades X11. `WM_CLASS` con `app_name` y `class_name`. `WM_NORMAL_HINTS` con `PMinSize`, `PMaxSize` y `PAspect` si se pidieron. `WM_HINTS` con `input = true`. `WM_PROTOCOLS` con `WM_DELETE_WINDOW`. `_NET_WM_WINDOW_TYPE` con el tipo (`normal`, `dock`, `dialog`, `menu`), excepto para child/transient. `WM_TRANSIENT_FOR` para child y transient, apuntando al `parent_window`. Título con `_NET_WM_NAME` y `WM_NAME` si se pasó. Struts con `_NET_WM_STRUT` y `_NET_WM_STRUT_PARTIAL` si se pasó `opts.strut`.

El tipo `kind` determina el comportamiento. `"normal"` es ventana top-level estándar. `"dock"` es top-level con `_NET_WM_WINDOW_TYPE_DOCK`. `"dialog"` es top-level con `_NET_WM_WINDOW_TYPE_DIALOG`. `"menu"` es top-level con `override_redirect` y `_NET_WM_WINDOW_TYPE_MENU`. `"child"` es una ventana X11 hija de `parent_window`, con `override_redirect`, sin `_NET_WM_WINDOW_TYPE`, y con `WM_TRANSIENT_FOR` apuntando al padre. `"transient"` es como `"child"` pero sin ser child X11: es top-level con `WM_TRANSIENT_FOR`.

Tras crear la ventana, `xcb.map_window` más `xcb.sync` garantizan que el servidor la ha mapeado antes del primer `draw`. Sin el sync, el primer draw escribe a una ventana aún no mapeada y X descarta los píxeles. Luego se crean `surface`, `cr`, `image_surface` e `image_cr`, y se inicializa el `xkb.State`.

El damage tracking acumula rectángulos `{x0, y0, x1, y1}` en `damage_list`. `add_damage` añade uno; `damage_all` marca `force_redraw = true` **sin limpiar `damage_list`** (la lista se limpia al final de `Window:draw`). En `draw`, la decisión entre partial y full es binaria: `full = force_redraw`. El criterio anterior (`_damage_covers_most`, área de la unión de rects > 80%) causaba stale pixels permanentes en los TabsBar: cuando decidía `full=true`, `on_draw` pintaba el fondo sin clip pero `should_draw` seguía filtrando widgets fuera del `damage_list`, dejando el image_surface con el fondo en esas zonas. Ver la sección "Reglas de damage tracking" arriba y el Apéndice 7.3.

`_apply_clip` construye un path con todos los rects del damage y aplica `cairo.clip`. Se usa tanto al dibujar al backing store como al blitear a X11, para que solo se pinten las regiones dañadas. Con `force_redraw = true`, no se aplica clip: se redibuja todo.

El ciclo de `draw` es: si `_needs_relayout` está pendiente, hacer relayout y marcar force_redraw. Si no hay force_redraw ni damage, retornar. Si hay algo, `_in_draw = true`, guardar estado de Cairo, aplicar clip si es partial (partial = `not force_redraw`), llamar a `opts.on_draw` (fondo), llamar a `root:draw` si existe, componer overlay si lo hay, restaurar, flush del `image_surface`. Después, blit al `surface` X11 con operador SOURCE y clip si es partial. Resetear `damage_list` y `force_redraw`, `_in_draw = false`. Si durante el draw alguien pidió `_pending_relayout`, moverlo a `_needs_relayout` para el próximo ciclo. Flush final a X11.

El dispatch de eventos (`_dispatch`) recibe el tipo y el evento crudo. `Expose` marca damage_all y dibuja. `ConfigureNotify` actualiza `width`/`height` si cambiaron, recrea `surface` y `image_surface`, relayout, dibuja. `KeyPress` construye el evento con `xkb:make_event`, lo pasa al `focus_widget` si lo hay; si el widget no lo consume, lo pasa a `opts.on_key`. La tecla `q` cierra la ventana si `disable_q_close` no está activo y ningún modificador está pulsado y ningún widget la consumió. `KeyRelease` análogo sin cerrar. `MotionNotify` enruta al `active_element` si hay drag, o al widget bajo el cursor, más el hook global. `ButtonPress` enruta al widget bajo el cursor vía `root:getByXY`; si hay `root` pero no se consumió (no hay `active_element`), llama a `opts.on_mouse`. `ButtonRelease` cierra el ciclo: si hay `active_element` y el release cae sobre él, dispara `on_click` del widget. `LeaveNotify` limpia hover. `ClientMessage` cierra si es `WM_DELETE_WINDOW`. `MapNotify` marca damage_all y dibuja (el primer draw real, tras confirmar mapeo). `FocusIn` y `FocusOut` llaman a sus hooks. `DestroyNotify` llama `_shutdown`.

El foco de teclado se gestiona con tres niveles. `focus_widget` es el widget que recibe KeyPress primero; se cambia con `set_focus_widget`. `_set_hover` y `_set_active` mantienen referencias al widget bajo el cursor y al que tiene click presionado respectivamente; ninguno es lo mismo que `focus_widget`. El foco X11 real (qué ventana recibe teclado a nivel servidor) se pide con `set_input_focus` y se devuelve con `restore_input_focus`. Para ventanas top-level, el WM gestiona el foco: solo se llama a `set_input_focus` si el usuario lo pide explícitamente (por ejemplo, un popup). Para child windows, el WM no interviene y el toolkit debe llamar a `set_input_focus`.

Al cerrar (`_shutdown`), se destruyen `image_cr`, `image_surface`, `cr`, `surface`, se destruye la ventana X11, se libera el `xkb.State` con `destroy`, y se devuelve el foco: si es child, al `parent_window`; si se pidió foco con `set_input_focus`, a la ventana previa guardada en `_prev_focus`; si no, al root.

**API.**

**Construcción.**

- **`Window.new(opts)`** — Crea un `Server` propio.
- **`Window.new(server, opts)`** — Usa el `Server` dado.

Campos de `opts`:

| Campo | Default | Descripción |
|---|---|---|
| `width`, `height` | `400`, `300` | Especificadores de tamaño. |
| `x`, `y` | `0`, `0` | Especificadores de posición. |
| `kind` | `"normal"` | `normal`, `dock`, `dialog`, `menu`, `child`, `transient`. |
| `parent_window` | — | Requerido para `kind` `child` y `transient`. |
| `title` | — | Publica `_NET_WM_NAME` y `WM_NAME`. |
| `app_name`, `class_name` | `"lanetk"`, `"LaneTK"` | Para `WM_CLASS`. |
| `aspect` | — | Flotante ancho/alto. Publica `PAspect` en `WM_NORMAL_HINTS`. |
| `min_width`, `min_height` | `0` | Especificadores de bound. |
| `max_width`, `max_height` | `0` | Especificadores de bound. |
| `strut` | — | Tabla con `left`, `right`, `top`, `bottom` y `*_start_*`/`*_end_*` opcionales. Publica `_NET_WM_STRUT` y `_NET_WM_STRUT_PARTIAL`. |
| `event_mask` | máscara por defecto | Bits de `EVENT_MASK`. El default cubre exposición, teclado, ratón, estructura y propiedades. |
| `disable_q_close` | `false` | Si `true`, la tecla `q` no cierra la ventana. |
| `on_draw` | — | `function(cr, w, h)`. Se llama antes del árbol. |
| `on_key` | — | `function(key)`. Recibe la tabla de `xkb:make_event`. |
| `on_mouse` | — | `function(x, y, detail, state)`. Solo si el árbol no consumió el click. |
| `on_mouse_move` | — | `function(x, y)`. |
| `on_mouse_release` | — | `function(x, y, detail, state)`. |
| `on_resize` | — | `function(w, h)`. |
| `on_close` | — | `function()`. Se llama antes de destruir. |
| `on_focus_in`, `on_focus_out` | — | `function()`. |
| `on_measure` | — | `function()` que devuelve `w, h` cuando `width`/`height` son `"auto"`. |

**Campos públicos.**

- `id` — window id X11.
- `width`, `height`, `x`, `y` — geometría actual.
- `root` — `Area` raíz del árbol o `nil`.
- `xkb` — `State` de `lib.xkb`.
- `hover_element`, `active_element` — referencias al `Area` con hover o click activo.
- `focus_widget` — `Area` con foco de teclado.
- `damage_list` — lista de rectángulos `{x0, y0, x1, y1}`.
- `force_redraw` — booleano.
- `destroyed` — booleano.
- `surface`, `image_surface` — superficies Cairo (X11 y backing store).
- `cr`, `image_cr` — contextos Cairo correspondientes.
- `overlay` — tabla `{surface, x, y, alpha}` con el overlay activo, o `nil`.

**Métodos.**

| Método | Notas |
|---|---|
| `set_root(area)` | Establece el árbol, hace relayout y draw inmediato. |
| `move(x, y)` | Mueve la ventana. Para top-level es una petición al WM. |
| `move_by(dx, dy)` | Relativa a la posición actual. |
| `set_title(title)` | Actualiza `_NET_WM_NAME` y `WM_NAME`. |
| `add_damage(x0, y0, x1, y1)` | Añade un rect dañado. |
| `damage_all()` | Marca `force_redraw = true`. **No limpia `damage_list`** (se limpia al final de `draw`). |
| `draw()` | Ejecuta el ciclo de dibujo si hay damage o force_redraw. |
| `set_focus_widget(widget)` | Cambia el foco de teclado. Notifica al anterior y al nuevo con `set_focused`. |
| `clear_focus_widget()` | Equivale a `set_focus_widget(nil)`. |
| `set_input_focus()` | Pide el foco a X. Guarda `_prev_focus` la primera vez. |
| `restore_input_focus()` | Devuelve el foco guardado o a PointerRoot. |
| `restore_parent_focus()` | Devuelve el foco al `parent_window` si lo hay. |
| `set_overlay(surface, x, y, alpha)` | Coloca un surface encima del árbol. Uso típico: crossfade de tabs. |
| `clear_overlay()` | Quita el overlay y daña la ventana. |
| `close(reason)` | Llama a `on_close`, marca `running = false` y destruye. |
| `run()` | `server:run()`. |

**Patrón.**

Ventana simple con un árbol de widgets:

    local srv = Server.new()
    local win = Window.new(srv, {
        width = "60%", height = "60%",
        x = "center", y = "center",
        title = "Demo",
        disable_q_close = true,
        on_key = function(key)
            if key.pressed and key.name == "Escape" then
                win:close("escape")
            end
        end,
    })
    win:set_root(W.Group.new { children = { ... } })
    srv:run()

Panel flotante en el monitor del cursor (patrón launcher):

    local win = Window.new(srv, {
        kind = "dialog",
        width = 600, height = 400,
        x = "cursor-screen", y = "cursor-screen",
        on_focus_in = function()
            textinput:set_focused(true)
        end,
    })

Barra superior con `override_redirect` (ignora el WM):

    local win = Window.new(srv, {
        kind = "menu",
        width = screen.width_in_pixels,
        height = 24,
        x = mon.x, y = mon.y,
    })

Ver `examples/01-window.lua`, `examples/04-mouse.lua`, `examples/20-panel-toggle.lua`.

**Anti-patrón.**

- **Dibujar directamente sobre el `surface` X11 en lugar del `image_cr`.** El toolkit maneja el doble buffer automáticamente; los widgets siempre dibujan sobre `image_cr` (a través del `cr` que reciben en `draw`). Intentar escribir sobre el `surface` directamente rompe el damage tracking y provoca parpadeo.
- **Llamar `set_input_focus` en ventanas top-level sin motivo.** El WM gestiona el foco. Pedirlo manualmente interfiere con el WM y con el ciclo normal de FocusIn/FocusOut. Solo se justifica en child windows o popups donde el WM no interviene.
- **Disparar `damage_all()` por cualquier cambio.** El damage tracking existe para evitar repintados completos. Llamar a `damage_all` cuando basta con `add_damage` sobre el rect afectado fuerza un full redraw y multiplica el coste. `notes.md` documenta el bug concreto del panel que parpadeaba por esto.
- **Usar `kind = "dock"` sin `strut`.** El WM no reservará espacio y otras ventanas se solaparán con la barra. En este proyecto la barra usa `kind = "menu"` con `override_redirect` precisamente para no depender de struts. Ver `notes.md`, decisión de diseño de la barra.
- **Crear el árbol de widgets antes de `set_root` y esperar layout.** El relayout ocurre en `set_root`, que llama a `askMinMax` y `layout` con las dimensiones de la ventana. Hasta entonces los hijos tienen rect 0.
- **Mutar el árbol fuera de `set_root` sin llamar `invalidate_layout`.** Los hijos nuevos quedan con rect 0 y no se dibujan hasta el próximo resize. Es el mismo bug que en `Group`, `Card` y `Stack`. `notes.md` lo documenta bajo "mutar el árbol requiere relayout explícito".

**Notas.**

- El orden de dibujo es estricto: primero `opts.on_draw` (fondo), luego `root:draw` (widgets). Al revés, el fondo tapa los widgets. Documentado en `notes.md`.
- Los hooks globales de ratón (`on_mouse`, `on_mouse_move`, `on_mouse_release`) se llaman siempre tras el enrutado al árbol, no en lugar de él. Antes solo se llamaban si no había `root`. El cambio permite usar hooks globales en ventanas con árbol (context menus, atajos). `notes.md` lo documenta.
- El primer `draw` puede ser durante `Window.new` (si hay `on_draw` o `root`) y otro en `MapNotify`. El segundo es el que realmente pinta en la ventana mapeada. Documentado en `notes.md`.
- `ConfigureNotify` con `width < 1` o `height < 1` se descarta por guarda defensiva. X11 puede enviarlo durante el reparenting del WM con datos raros. `notes.md` lo documenta.
- Los eventos de input llevan el window id en offset 12; los eventos "notify" en offset 4. La distinción la hace `server.lua:extract_window_id` y el toolkit entero depende de ella.
- El `xkb.State` se destruye en `_shutdown`. Si el proceso se mata con SIGKILL, no se libera, pero el SO recupera la memoria.
- La tecla `q` cierra la ventana por defecto. Es un atajo de desarrollo; en producción, las aplicaciones lo desactivan con `disable_q_close = true` y gestionan el cierre ellas mismas.

- El overlay es un surface compuesto encima del árbol tras `root:draw`. Se usa para crossfades: el motor de animación (`anim.lua`) lo gestiona vía `set_overlay` y `clear_overlay`. Mientras hay overlay, el draw no aplica clip parcial: se repinta todo para que el overlay se componga sobre el contenido limpio. `set_overlay` NO limpia el `damage_list` existente: añade su propio rect al damage actual. `clear_overlay` sí limpia la lista y daña la ventana para que el rect del overlay se repinte en el próximo ciclo.

#### screens.lua

**Propósito.**
Lista de monitores activos del servidor X. Parsea la salida de `xrandr --query` para obtener el nombre y el rectángulo de cada monitor conectado, con cache del resultado.

**Alcance.**
Cubre listar monitores, consultar el monitor que contiene un punto, y obtener el centro de un monitor. No cubre cambios de configuración de monitores en caliente: el cache hay que invalidarlo manualmente. No cubre CRTCs, modos, tasas de refresco ni DPI. No cubre detección por Xinerama ni RandR vía FFI: usa `xrandr` como subproceso.

**Cómo funciona.**

`list` ejecuta `xrandr --query 2>/dev/null` con `helpers/util.shell_once` (un `io.popen` bloqueante) y parsea la salida línea a línea. Cada línea que empieza con `<nombre> connected` se considera un monitor. La palabra `primary` entre `connected` y la geometría es opcional y se ignora. La geometría se extrae buscando el primer patrón `WxH+X+Y` de la línea, que puede tener coordenadas negativas (los arreglos multimonitor pueden situar un monitor a la izquierda del principal).

El resultado se cachea en la variable local `cached`. Las llamadas siguientes devuelven la misma tabla sin volver a ejecutar `xrandr`. `invalidate` limpia la variable, forzando un re-parseo en la próxima llamada.

`at(cx, cy)` recorre los monitores y devuelve el primero cuyo rectángulo contiene el punto. Compara con `>= x` y `< x + w` (extremo izquierdo inclusivo, derecho exclusivo), de forma que un punto en el borde entre dos monitores pertenece al segundo. Si ningún monitor contiene el punto, devuelve el primero de la lista, que es el comportamiento esperado cuando la consulta llega con coordenadas fuera de rango.

`center(s)` calcula el centro geométrico del monitor: `s.x + floor(s.w/2)`, `s.y + floor(s.h/2)`.

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `list()` | tabla de `{ name, x, y, w, h }` | Cachea el resultado. |
| `invalidate()` | — | Limpia el cache. |
| `at(cx, cy)` | monitor | Primer monitor que contiene el punto. Si ninguno, el primero. |
| `center(s)` | `cx, cy` | Centro del monitor. |

Cada entrada de `list()` es una tabla con los campos `name` (string, como `"VGA-1"`), `x`, `y`, `w`, `h` (enteros en píxeles, coordenadas absolutas de la pantalla virtual).

**Patrón.**

Obtener el monitor bajo el cursor (patrón que usa `Window` con `x = "cursor-screen"`):

    local screens = require("lib.screens")
    local cx, cy = xcb.query_pointer(conn)
    local mon = screens.at(cx, cy)
    local mx, my = screens.center(mon)

Iterar todos los monitores:

    for _, mon in ipairs(screens.list()) do
        log.info("screens", "%s %dx%d+%d+%d",
            mon.name, mon.w, mon.h, mon.x, mon.y)
    end

Ver `examples/22-launcher.lua` para el uso con `cursor-screen`.

**Anti-patrón.**

- **Llamar `list()` en cada `on_draw` o en cada timer.** `list` ejecuta `xrandr` como subproceso, que es una llamada bloqueante. La primera vez paga el coste; las siguientes devuelven el cache. Pero si algo invalida el cache por error y se llama desde un timer corto, cada tick lanza un `xrandr`. Cachear la referencia fuera del draw.
- **Asumir que `at` devuelve `nil` si el punto no está en ningún monitor.** Devuelve el primero de la lista. Es una decisión de diseño: cubre el caso de coordenadas fuera de rango sin que el consumidor tenga que comprobarlo. Si un consumidor necesita distinguir "ninguno", tiene que comparar contra los rectángulos por su cuenta.
- **Modificar la tabla devuelta por `list`.** El cache devuelve la misma referencia en llamadas sucesivas. Mutarla afecta a futuros consumidores. Si hay que transformarla, copiar primero.

**Notas.**

- El parseo depende del formato de `xrandr --query`. Formatos alternativos (algunos drivers emiten líneas distintas) no se manejan. Si aparece un caso raro, hay que inspeccionar la salida cruda antes de tocar el parser. `notes.md` documenta el ajuste para ignorar `primary`.
- La detección es por línea: `^(%S+)%s+connected`. Líneas que empiezan por `Screen`, `HDMI-1 disconnected`, `eDP-1 unknown` o líneas de modos se ignoran.
- Coordenadas negativas se aceptan en el patrón (`%-?%d+`). Es necesario en arreglos donde un monitor está a la izquierda del principal.
- El módulo no distingue monitores "primary" de los demás. `xrandr` sí lo indica, pero el toolkit no lo usa: para elegir el monitor principal, se toma el primero de la lista, que en la práctica es el principal en configuraciones estándar.
- Si `xrandr` no está instalado, `shell_once` devuelve cadena vacía y `list()` devuelve tabla vacía. No es un error fatal: los consumidores que dependen de `at()` caerán al primer monitor (que no existe) y obtendrán `nil`. En la práctica `xrandr` siempre está disponible en un entorno X.

#### anim.lua

**Propósito.**
Motor de animaciones. Mantiene un pool de animaciones activas con un timer global que solo corre mientras hay animaciones en curso. En reposo, coste cero: no hay timer registrado. Ofrece tweens de propiedades numéricas y de color, springs de física, secuencias encadenadas, loops, stagger en cascada, y composición de dos superficies para crossfades.

**Alcance.**
Cubre animación de propiedades por interpolación (lineal y con easings), física de muelle, orquestación de varias animaciones (secuencia, loop, stagger, delay), y crossfade entre dos contenidos mediante overlay en `Window`. No cubre animación de layout completo (mover todo el árbol), ni animación de propiedades que no sean numéricas o `{r, g, b}`, ni animación de la ventana X11 en sí (posición o tamaño real de la ventana). No cubre audio ni efectos visuales que requieran compositor.

**Cómo funciona.**

El motor mantiene una tabla global `active` con las animaciones en curso. Cada animación es una tabla con `start_ms`, `duration_ms`, `easing`, `apply` y opcionalmente `on_done`. Cuando se añade una animación a través de `push`, se asegura de que el timer global esté corriendo. El timer se registra con `srv:add_timer(FRAME_MS, tick)`. Cuando la última animación termina, el timer se cancela: en reposo el proceso no tiene timers propios.

Cada tick (`tick`) hace un snapshot del pool, itera sobre las animaciones activas, y para cada una calcula `t = (now - start_ms) / duration_ms`, aplica la easing, y llama a `apply(eased, raw)`. Las animaciones con `is_spring` usan integración numérica (posición + velocidad + aceleración) en lugar del cálculo lineal por tiempo. Las que llegan a `t >= 1` se marcan `done`, se llama a `on_done` si lo tienen, y se descartan en el `reap` final.

El snapshot es importante: `on_done` puede añadir nuevas animaciones al pool (por ejemplo, un loop que se reprograma a sí mismo). Iterar sobre `active` directamente mientras los callbacks la mutan sería un bug. La copia del tick evita ese problema.

`M.EASE` es una tabla de funciones puras. Cada una recibe `t` en `[0, 1]` y devuelve el valor con la curva aplicada. `linear` es la identidad; `in_*` y `out_*` corresponden a diferentes aceleraciones; `out_elastic` y `out_bounce` sobrepasan `[0, 1]` y vuelven. `out_back` también sobrepasa al principio o al final.

`M.tween(area, prop, from, to, dur, easing, on_done)` es el caso base: anima `area[prop]` de `from` a `to`, aplicando `easing(t)` en cada tick, y llamando a `area:damage()` para que se repinte. `M.tween_rgb` es igual pero `prop` es una tabla `{r, g, b}` y se mutan sus tres elementos. `M.tween_custom` recibe una función `apply_fn(eased, raw)` y es la base para animar varias propiedades a la vez o propiedades que requieren lectura del widget.

`M.spring` no usa duración: integra física de muelle con `tension` (default 200) y `friction` (default 20). En cada tick calcula `accel = tension * (target - pos) - friction * vel`, actualiza `vel` y `pos`, y aplica. Termina cuando `|target - pos| < 0.001` y `|vel| < 0.001`. Es útil cuando quieres un efecto natural sin elegir una duración exacta.

`M.sequence(steps, on_done)` ejecuta una lista de pasos en orden, cada uno arrancando cuando el anterior llama a su `on_done`. Los pasos son tablas con campo `kind` (`"tween"`, `"tween_rgb"`, `"custom"`, `"spring"`, `"delay"`, `"fn"`). Es la forma limpia de encadenar animaciones sin anidar callbacks a mano.

`M.loop(area, prop, from, to, dur, easing, mode, on_cycle)` repite una animación al terminar. `mode` puede ser `"repeat"` (siempre `from → to`) o `"ping-pong"` (alterna `from → to`, `to → from`). Acepta valores numéricos o tablas `{r, g, b}`: detecta el tipo de `from` para elegir entre `tween` y `tween_rgb`. Devuelve un handle con `:cancel()`.

`M.stagger(list, opts)` anima una lista de áreas en cascada. Cada elemento de `list` es `{area, prop, from, to}`. Con `opts.delay` (default 40 ms) escalona los arranques. Útil para entradas tipo "lista que aparece".

`M.delay(ms, fn)` es un one-shot: ejecuta `fn` tras `ms`. Es el bloque básico para construir secuencias sin depender del `Server`.

`M.snapshot(area, opts)` renderiza un `Area` a un `cairo_image_surface` ARGB32 del tamaño del área (o de `opts.w` y `opts.h` si se pasan). Es la base del crossfade. Durante el snapshot, fuerza `window.force_redraw = true` temporalmente para que el árbol dibuje todo aunque no haya damage, y restaura el estado al terminar. El origen del surface corresponde a `(area.x0, area.y0)`. Devuelve `nil` si el área no tiene tamaño válido.

`M.crossfade(window, old_area, swap_fn, dur, opts)` hace un crossfade entre un contenido viejo y uno nuevo. El proceso es: si hay otro crossfade en curso, se cancela y se limpia; se hace snapshot del área vieja; se coloca el snapshot como overlay en la `Window` con alpha 1; se llama a `swap_fn` (típicamente `stack:set_active(id)`); se anima el alpha del overlay de 1 a 0; al terminar, se limpia el overlay y se destruye el surface.

El crossfade cancela el anterior si se pide otro durante uno activo. También se cancela si la ventana cambia de tamaño durante la animación: `initial_w` e `initial_h` se guardan al arrancar, y en cada tick se comparan con `window.width` y `window.height`. Si cambiaron, el overlay está en posición vieja y no encaja, así que se aborta.

`opts.extra_damage_area` permite declarar un área adicional que se debe repintar en cada tick, fuera del rect del overlay. El `TabbedPanel` lo usa para pasar el `tabsbar` como área extra: sin esto, en ventanas grandes el TabsBar queda fuera del damage del overlay y parpadea durante el crossfade. Cualquier widget que cambie durante la animación pero no esté dentro del rect del overlay debe declararse aquí.

`M.set_fps(n)` cambia la tasa del motor en caliente. Si hay un timer corriendo, lo reinicia con el nuevo intervalo. El contador `crossfade_depth` y el valor `crossfade_saved_fps` permiten que los crossfades anidados (o solapados) no dejen el motor con un FPS inesperado al terminar.

`M.is_ready()` devuelve `true` si `anim.init(srv)` fue llamado. Los consumidores (por ejemplo `TabbedPanel`) lo consultan antes de intentar animar.

**API.**

**Constantes.**

- `EASE` — tabla de easing functions. Incluye `linear`, `in_quad`, `out_quad`, `in_out_quad`, `in_cubic`, `out_cubic`, `in_out_cubic`, `in_quart`, `out_quart`, `in_out_quart`, `in_expo`, `out_expo`, `in_out_expo`, `out_back`, `in_back`, `out_elastic`, `out_bounce`.

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `init(srv, opts?)` | — | Inicializa el motor. `opts.fps` default 30. Lanza `error` si se llama a las funciones sin init. |
| `is_ready()` | `bool` | `true` si `init` fue llamado. |
| `count()` | `int` | Nº de animaciones activas. |
| `fps()` | `int` | FPS actual. |
| `set_fps(n)` | — | Cambia el FPS. Reinicia el timer si está corriendo. |
| `tween(area, prop, from, to, dur, easing, on_done)` | handle | Anima `area[prop]` de `from` a `to`. |
| `tween_rgb(area, prop, from, to, dur, easing, on_done)` | handle | Anima una tabla `{r, g, b}`. |
| `tween_custom(area, apply_fn, dur, easing, on_done)` | handle | `apply_fn(eased, raw)` por tick. |
| `spring(area, prop, target, opts, on_done)` | handle | Física de muelle. `opts.tension`, `opts.friction`, `opts.velocity`. |
| `delay(ms, fn)` | handle | Ejecuta `fn` tras `ms`. |
| `sequence(steps, on_done)` | — | Encadena pasos. Cada paso es `{kind = ..., ...}`. |
| `loop(area, prop, from, to, dur, easing, mode, on_cycle)` | handle | Repite. `mode` = `"repeat"` o `"ping-pong"`. |
| `stagger(list, opts)` | handle | Cascada. `list` = `{{area, prop, from, to}, ...}`. |
| `snapshot(area, opts?)` | surface o `nil` | Renderiza un área a un image_surface ARGB32. |
| `crossfade(window, old_area, swap_fn, dur, opts?)` | handle | Crossfade con overlay. `opts.fps`, `opts.easing`, `opts.extra_damage_area`, `opts.on_done`. |
| `stop_all()` | — | Cancela todas las animaciones y detiene el timer. |

**Handle devuelto.**

Todas las funciones que devuelven un `handle` dan una tabla con:

- `:cancel()` — marca la animación como terminada. La animación se descarta en el próximo `reap` sin llamar a `on_done`.
- `:get()` — devuelve la tabla interna de la animación. Uso interno, no recomendado.

**Patrón.**

Animar el valor de un anillo:

    local anim = require("lib.anim")
    anim.init(srv, { fps = 30 })

    anim.tween(ring, "value", 0, 1, 600, anim.EASE.out_cubic)

Encadenar con secuencia:

    anim.sequence({
        { kind = "tween", area = ring, prop = "thickness",
          from = 4, to = 24, duration = 500, easing = anim.EASE.out_cubic },
        { kind = "tween", area = ring, prop = "thickness",
          from = 24, to = 14, duration = 500, easing = anim.EASE.out_cubic },
    }, function()
        log.info("anim", "secuencia terminada")
    end)

Loop ping-pong de un color:

    anim.loop(ring, "color",
        { 0.55, 0.85, 0.60 }, { 0.95, 0.40, 0.40 },
        700, anim.EASE.in_out_cubic, "ping-pong")

Crossfade al cambiar de tab:

    anim.crossfade(
        window,
        stack,
        function() stack:set_active("page2") end,
        400,
        { fps = 30, extra_damage_area = tabsbar, on_done = function()
            log.info("anim", "crossfade terminado")
        end }
    )

Ver `examples/40-anim-test.lua` para un catálogo completo de efectos y `examples/41-anim-crossfade.lua` para el crossfade básico.

**Anti-patrón.**

- **Llamar `anim.tween` sin `anim.init(srv)` antes.** Las funciones de animación lanzan `error` si el motor no está inicializado. El error es explícito: "anim: llama a anim.init(srv) primero". Verificar con `anim.is_ready()` antes si el código puede correr en varios contextos.
- **Animar propiedades con `tween` cuando son tablas.** `tween` solo maneja números. Para `{r, g, b}` usar `tween_rgb`. Para tablas más complejas, `tween_custom` con una función que recorra los campos.
- **Animar `x0`/`x1` de un widget fuera de su rect asignado.** El modelo del toolkit asume que cada widget vive en la celda que le dio su padre. Moverlo fuera del rect rompe el clip del padre y deja rastros. Para mover un widget visualmente, envolverlo en un contenedor que le dé espacio y animar el widget dentro. Documentado en el apéndice E.
- **Cruzar crossfades sin cancelar el anterior.** `M.crossfade` cancela el anterior automáticamente y limpia su surface. No hay que gestionarlo desde fuera, pero si el consumidor guarda un handle y lo reutiliza tras un crossfade cancelado, el handle está muerto.
- **Animar durante un resize de la ventana.** El crossfade se cancela automáticamente al detectar cambio de tamaño. Un tween normal (no crossfade) no lo hace: si animas un `x0` mientras la ventana cambia de tamaño, los rects quedan desincronizados hasta el próximo relayout. En la práctica, los widgets se reconstruyen en el resize y las animaciones se reinician.
- **Llamar `snapshot` en un área sin rect válido.** `snapshot` devuelve `nil` si `area:getWidth()` o `area:getHeight()` son 0 o negativos. El consumidor debe comprobar el retorno antes de usar el surface.

**Notas.**

- El motor no tiene timer propio en reposo. Cuando `active` queda vacío, el timer se cancela. Esto significa que un proceso con el motor inicializado pero sin animaciones corriendo no consume CPU por el motor.
- Las animaciones se ejecutan con `pcall` en su `apply`. Un error en el callback se loguea y la animación sigue; no rompe el tick ni cancela las demás animaciones activas.
- El FPS default es 30. En hardware modesto (como un Celeron 847) es suficiente para transiciones fluidas. Un crossfade a 20 FPS se ve bien y reduce el coste ~33%.
- `M.crossfade` crea un `cairo_image_surface` en cada llamada. El surface se destruye al terminar el fade (o al cancelarlo). Si el consumidor necesita hacer muchos crossfades seguidos, el coste de crear y destruir el surface es apreciable pero aceptable.
- `snapshot` fuerza `window.force_redraw = true` durante la captura y lo restaura. Si el consumidor tiene su propio `force_redraw` puesto a `true` antes de la llamada, se respeta el valor original al restaurar.
- El overlay del crossfade se gestiona a través de `Window:set_overlay` y `Window:clear_overlay`. Ver `window.lua` para los detalles de cómo se compone sobre el árbol.
- El motor asume que `srv:add_timer` no repite automáticamente. Verifica esta suposición en `server.lua`: los timers se reprograman a sí mismos al ejecutarse. El motor lo usa sin añadir lógica adicional.
- El snapshot captura el estado actual del área. Si el área cambia entre el snapshot y el blit (por ejemplo, porque un timer la actualiza), el overlay muestra el estado viejo, que es lo que se espera en un crossfade.

#### greetd.lua

**Propósito.**
Cliente del protocolo de greetd. Habla JSON line-delimited sobre un socket Unix. Lo usan los greeters (como Lefty) para autenticar usuarios y lanzar sesiones.

**Alcance.**
Cubre los cuatro mensajes del protocolo (create_session, post_auth_message_response, start_session, cancel_session) y las tres respuestas (auth_message, success, error). No cubre PAM: eso lo maneja greetd del lado suyo. No cubre el ciclo de vida de la sesión: greetd mata al greeter y lanza la sesión del usuario por su cuenta.

**Cómo funciona.**

El socket lo provee greetd en la variable de entorno GREETD_SOCK. `M.connect(path?)` la consulta si no se le pasa path, y hace `connect(2)` vía FFI. Devuelve una instancia o `nil, err`.

El formato es line-delimited JSON: cada mensaje es una línea terminada en `\n`. Los mensajes van por `send()` y las respuestas se leen byte a byte hasta el `\n` con `recv()`. El socket es bloqueante. Cada método hace un round-trip sincrónico.

`_recv_dispatch(cb)` lee una línea, la decodifica con `lib.helpers.json`, y llama a `cb(kind, data)` donde `kind` es el campo `type` del mensaje recibido, o uno de los pseudo-tipos `"io_error"` y `"parse_error"`.

**IMPORTANTE: `start_session` no espera respuesta.** Greetd procesa el mensaje, mata al proceso del greeter, y lanza la sesión del usuario. No contesta. Esperar una respuesta acá es deadlock: el cliente queda bloqueado en `recv`, el proceso del greeter nunca sale, y greetd espera al greeter. El método cierra el socket inmediatamente después de mandar el mensaje. Después de llamarlo, el consumidor debe terminar el proceso.

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `connect(path?)` | Client o `nil, err` | Usa `$GREETD_SOCK` si no se le pasa path. |

**Métodos del Client.**

| Método | Notas |
|---|---|
| `create_session(username, cb)` | Manda `{type:"create_session", username:<name>}`. Espera `auth_message` o `success` o `error`. |
| `post_auth_response(response, cb)` | Manda `{type:"post_auth_message_response", response:<string o nil>}`. Espera la próxima respuesta. |
| `start_session(cmd)` | Manda `{type:"start_session", cmd:<array>}`. **No espera respuesta.** Cierra el socket. |
| `cancel_session()` | Manda `{type:"cancel_session"}`. No espera respuesta. |
| `close()` | Cierra el socket si sigue abierto. |

**Forma del mensaje `auth_message`.**

- `auth_message_type` — `"visible"`, `"secret"`, `"info"` o `"error"`.
- `auth_message` — texto a mostrar o solicitar.

`"visible"` espera una respuesta que se muestra en pantalla (por ejemplo, un usuario alternativo). `"secret"` espera una respuesta oculta (contraseña). `"info"` y `"error"` son informativos: hay que responder con `post_auth_response(nil, cb)` para continuar.

**Forma del mensaje `error`.**

- `error_type` — `"auth_error"` o `"error"`.
- `description` — texto legible.

**Patrón.**

Flujo típico:

    local greetd = require("lib.greetd")
    local cli = greetd.connect()

    local function on_msg(kind, data)
        if kind == "auth_message" then
            if data.auth_message_type == "secret" then
                cli:post_auth_response(leer_password(), on_msg)
            else
                cli:post_auth_response(nil, on_msg)
            end
        elseif kind == "success" then
            cli:start_session({ "startx", "/usr/bin/env", "bspwm" })
            os.exit(0)
        elseif kind == "error" then
            mostrar_error(data.description)
        end
    end

    cli:create_session("ansmoun", on_msg)

**Anti-patrón.**

- **Pasar un callback a `start_session`.** Greetd no responde. El cliente queda bloqueado en `recv` para siempre. Firma: `start_session(cmd)`, sin callback.
- **Esperar a que greetd cierre el socket antes de salir.** Greetd no cierra el socket: mata al proceso. El consumidor tiene que salir por su cuenta después de mandar `start_session`.
- **Llamar a los métodos sin `connect` previo.** El socket no existe. `connect` es lo primero.
- **Asumir que `GREETD_SOCK` está definido.** Solo lo está en procesos que greetd lanzó. Fuera de eso, hay que pasar la ruta explícita.
- **Cerrar el socket manualmente antes de `start_session`.** El método lo cierra solo. Cerrarlo antes puede truncar el último mensaje.

**Notas.**

- El cliente es síncrono. Bloquea el event loop mientras espera una respuesta. En el flujo de login es aceptable: son pocos mensajes, espaciados por input del usuario.
- La implementación vive en `src/lib/greetd.lua`. La prueba contra un servidor mock está en el historial de la sesión.
- Greetd usa el término "session" para "sesión de usuario" (una sesión de escritorio). No confundir con la sesión del greeter (el proceso que corre el greeter).

## README-widgets.md

### Widgets

Todos los widgets heredan de `Area`. La clase base está documentada en `README-lib.md` (sección Widgets → area.lua). Cada widget de esta sección documenta solo su API propia, sin repetir lo heredado. Los contenedores se agrupan al principio porque definen cómo se compone el resto.

#### group.lua

**Propósito.**
Contenedor con varios hijos en fila o columna, con pesos por hijo. Reparte el espacio disponible entre ellos respetando mínimos y repartiendo el sobrante proporcionalmente al peso.

**Alcance.**
Cubre disposición lineal (horizontal o vertical) con pesos, spacing entre hijos y padding uniforme. No cubre grids ni layouts no lineales. No cubre alineación del conjunto dentro de un área mayor: si se quiere centrar un grupo, hay que envolverlo en otro Group o en una Card. No cubre tamaño de hijos individuales: cada hijo decide su mínimo y su máximo en `askMinMax`.

**Cómo funciona.**

`Group.new` recibe `orientation` (`"horizontal"` o `"vertical"`), `spacing` (px entre hijos), `padding` (px en los cuatro lados) y `children` (lista inicial de hijos). La lista admite dos formas por entrada: un `Area` directamente, o una tabla `{ widget = <Area>, weight = <number> }`. En ambos casos se termina con un par `(hijo, peso)`.

`add` normaliza el argumento, propaga el `window` al hijo si ya está disponible, asigna `child.parent = self`, y añade a las tablas paralelas `children` y `weights`. Devuelve el hijo, para encadenar.

`remove` recorre `children` buscando identidad, quita la entrada correspondiente en `weights`, limpia `child.parent` y devuelve `true`. Si no encuentra el hijo, devuelve `false` sin tocar nada.

`clear` recorre todos los hijos, limpia sus `parent` y vacía ambas tablas.

`set_window` propaga el `window` a todos los hijos. Se llama cuando el `Window:set_root` recorre el árbol inicial, o cuando un `Group` padre ya tiene `window` y añade un hijo nuevo (en cuyo caso `add` ya lo propaga). El chequeo `if child.set_window then child:set_window(win) else child.window = win end` permite que los hijos que tienen lógica propia en `set_window` (por ejemplo, `Stack`, `Card`, `TabbedPanel`) la ejecuten, y los que no, reciban el campo directamente.

`askMinMax` recorre todos los hijos llamando `askMinMax(0, 0, 0, 0)` para obtener sus mínimos y máximos. Suma mínimos en el eje principal y toma máximos en el eje transversal. Al total le añade `spacing * (n-1)` y `padding * 2`. Devuelve los cuatro valores acumulados con los que vinieron como entrada.

`layout` es la parte más compleja. Recibe el rect asignado por el padre, aplica `padding` para obtener el rect útil. Calcula `gaps = spacing * (n-1)`. Para cada hijo llama `askMinMax(0,0,0,0)` y guarda el mínimo en el eje principal (`cminw` si horizontal, `cminh` si vertical) más el peso. Suma `total_min` y `total_weight` (solo contando pesos > 0).

Con `available = (ancho o alto útil) - gaps` y `extra = available - total_min`:

- Si `extra < 0` (no cabe): escala todos los mínimos por `available / total_min`. Los hijos quedan recortados. Cada uno decide qué hacer con un rect menor que su mínimo (clipear, reducir, etc).
- Si hay algún peso > 0: cada hijo con `weight > 0` recibe su mínimo más una fracción de `extra` proporcional a su peso. Los hijos con `weight = 0` reciben solo su mínimo.
- Si todos los pesos son 0: cada hijo recibe solo su mínimo, y el sobrante queda al final sin repartir.

Luego recorre los hijos asignando rects en secuencia, avanzando por `sizes[i] + spacing`.

`draw` recorre los hijos y llama `should_draw` antes de `draw`, filtrando los que no intersecan el damage actual.

`getByXY` recorre los hijos de atrás hacia delante (el último hijo tiene prioridad si hay solapamiento) y devuelve el primer hit. Si ningún hijo acierta y el punto está dentro del propio rect, devuelve `self`.

**API.**

**Construcción.**

- **`Group.new(opts)`** — `opts.orientation` (`"horizontal"` default, o `"vertical"`), `opts.spacing`, `opts.padding`, `opts.children` (lista).

**Métodos.**

| Método | Retorno | Notas |
|---|---|---|
| `add(child, weight?)` | el hijo | `child` puede ser `Area` o `{ widget = Area, weight = n }`. El peso se toma del argumento, de `child.weight` si es tabla, o de `child.opts.weight`. Default 1. |
| `remove(child)` | `bool` | `false` si no estaba. |
| `clear()` | — | Vacía el grupo y limpia `parent` de los hijos. |
| `set_window(win)` | — | Propaga `window` a todos los hijos. |

**Campos.**

- `orientation` — `"horizontal"` o `"vertical"`.
- `spacing` — px entre hijos.
- `padding` — px en los cuatro lados.
- `children` — array de hijos.
- `weights` — array paralelo de pesos.

**Patrón.**

Layout típico de sidebar fijo más contenido que crece:

    local root = W.Group.new {
        orientation = "horizontal",
        spacing = 8,
        padding = 10,
        children = {
            { widget = sidebar, weight = 0 },   -- fijo, solo su mínimo
            { widget = content, weight = 1 },   -- se lleva todo el sobrante
        },
    }

Ver `examples/06b-groups.lua` para el layout con rects de debug y `examples/07-layout.lua` para el reparto con pesos.

**Anti-patrón.**

- **Mutar hijos (`add`, `remove`, `clear`) sin llamar `invalidate_layout`.** Los hijos nuevos quedan con rect `0` (x0=y0=x1=y1=0) y no se dibujan hasta el próximo resize. Los viejos conservan rects obsoletos. Documentado en `notes.md`, entradas "particiones desaparecen tras reconstrucción" y "mutar el árbol requiere relayout explícito".
- **Poner `weight = 0` a todos los hijos y esperar que se reparta el espacio.** El sobrante queda al final sin repartir. Es un comportamiento intencional para dejar espacio vacío, pero suele ser un bug de configuración cuando se espera lo contrario.
- **Asignar `padding` y esperar que también separe a los hijos del borde exterior con un valor distinto al `spacing`.** `padding` es uniforme en los cuatro lados. Para separar más de un eje, usar `margin_spacer` (widget de ancho fijo) o envolver en otro Group.
- **Poner un hijo como `Area` cuando se quiere peso.** Si no se pasa la tabla `{ widget = ..., weight = ... }`, el peso default es 1. Un hijo que debía ser `weight = 0` (fijo) sin declararlo recibe espacio sobrante y crece más de lo previsto.

**Notas.**

- El algoritmo de reparto respeta los mínimos cuando hay espacio (`extra >= 0`) y escala proporcionalmente cuando no lo hay. Nunca recorta a un hijo por debajo de su mínimo si hay espacio; solo lo hace cuando no cabe.
- `weight` puede ser cualquier número real mayor o igual a 0. Los pesos no necesitan sumar 1: el reparto es proporcional al total.
- El orden de `children` importa. En horizontal, el primer hijo es el más a la izquierda. En vertical, el de arriba. No hay forma de invertir el orden sin reconstruir la lista.
- La llamada `askMinMax(0,0,0,0)` desde dentro de `layout` es redundante con la que hizo el padre en su propia `askMinMax`, pero no se cachea para permitir que los hijos cambien de mínimo en runtime (por ejemplo, al cambiar de página en un Stack).


**Rigidez de hijos (2026-09-25).**
`Group:layout` clasifica cada hijo en **rígido** o **flexible** según
el eje principal:

- Un hijo es **rígido** si su `min == max` en el eje principal. Típico:
  un `TabsBar`, un separador, un badge de ancho fijo. Los rígidos
  **nunca** se achican mientras haya espacio para ellos.
- Un hijo es **flexible** si `min < max`. Absorbe el sobrante (con
  `weight > 0`) o se recorta si no alcanza.

Algoritmo en tres casos:

1. `available >= total_min` → reparto normal: mínimos a todos,
   sobrante proporcional al peso entre los `weight > 0`.
2. `total_min_rigid <= available < total_min` → rígidos reciben su
   mínimo completo; flexibles se escalan proporcionalmente a lo que
   sobra.
3. `available < total_min_rigid` → fallback: escalar TODOS
   proporcionalmente al mínimo. No debería pasar con layouts
   razonables.

La regla es general: **cualquier widget puede declarar `min == max` y
se vuelve rígido automáticamente**. Sirve para barras de chrome,
separadores, badges, botones de icono. Sin cambios en el consumidor.

#### stack.lua

**Propósito.**
Contenedor con varios hijos, uno visible a la vez. Se usa para páginas: cada hijo es una página, se activa por nombre. Base de tabs, wizards y sub-paneles.

**Alcance.**
Cubre mantener múltiples páginas y mostrar una sola. No cubre la barra de tabs ni el lazy loading de las páginas: eso vive en `TabbedPanel`, que combina `Stack` con `TabsBar`. No cubre animación entre cambios de página. No cubre páginas anidadas más de lo que ya permite la composición (un Stack dentro de otro Stack).

**Cómo funciona.**

`Stack` mantiene dos estructuras paralelas: `pages` (tabla `nombre → Area`) para el acceso por nombre, y `order` (array de nombres en orden de inserción) para saber cuál es la primera página. `active` guarda el nombre de la página actual, o `nil` si ninguna está activa.

`add(name, widget)` registra una página sin activarla. El comentario del código explica la decisión: si `add` activara automáticamente la primera página, el `set_active(name)` posterior del consumidor encontraría `self.active == name` y haría early return sin `invalidate_layout`, dejando al árbol a medio layoutear. El consumidor **siempre** llama a `set_active` después de añadir, y es ahí donde se hace el relayout con el árbol completo. `notes.md` lo documenta como regla.

`remove(name)` quita la página de `pages` y de `order`. Si era la activa, activa la primera de `order` (la que quede) y llama `invalidate_layout`. Si `order` queda vacía, `active` pasa a `nil`.

`set_active(name)` cambia la página activa. Si ya estaba activa o el nombre no existe, es un no-op. Si cambia, guarda el nuevo `active` y llama `invalidate_layout`. El `invalidate_layout` es crítico: sin él, la página nueva queda con rect 0 y no se dibuja hasta el próximo resize.

`askMinMax` consulta solo la página activa. Las demás no cuentan para el mínimo ni el máximo del Stack, porque no se ven. Es coherente con `draw` y `layout`, que también solo actúan sobre la activa.

`layout` asigna el rect del Stack a la página activa. Las inactivas conservan su rect anterior (que puede estar desactualizado si el Stack cambió de tamaño mientras estaban inactivas). Al activarse, `invalidate_layout` fuerza un relayout completo que las corrige.

`draw` dibuja solo la activa, con `should_draw` antes.

`getByXY` consulta solo la activa. Si el punto cae dentro del Stack pero no en ningún hijo de la activa, devuelve `self`.

`set_window` propaga el `window` a **todas** las páginas, no solo a la activa. Necesario para que las páginas inactivas tengan `window` cuando se activen, y para que los timers que puedan tener registrados (aunque no deberían, porque no han hecho `start`) funcionen si los tienen.

**API.**

**Construcción.**

- **`Stack.new(opts)`** — `opts.min_width`, `opts.min_height` (mínimos propios). `max_w` y `max_h` internos se fuerzan a `10000` para permitir que el Stack crezca hasta su rect.

**Métodos.**

| Método | Retorno | Notas |
|---|---|---|
| `add(name, widget)` | el widget | Registra sin activar. |
| `remove(name)` | `bool` | `false` si no existía. |
| `set_active(name)` | `bool` | `false` si el nombre no existe. |
| `get_active()` | string o `nil` | Nombre de la página activa. |
| `get(name)` | `Area` o `nil` | Devuelve la página sin activarla. |
| `set_window(win)` | — | Propaga `window` a todas las páginas. |

**Campos.**

- `pages` — tabla `nombre → Area`.
- `order` — array de nombres en orden de inserción.
- `active` — nombre de la activa, o `nil`.

**Patrón.**

Sub-páginas sin barra de tabs (por ejemplo, un Stack controlado por un `Pills` externo):

    local stack = W.Stack.new {}
    stack:add("general", general_widget)
    stack:add("cpu",     cpu_widget)
    stack:add("ram",     ram_widget)
    stack:set_active("general")

    -- Al hacer click en un pill:
    stack:set_active(id)

El caso más común no usa `Stack` directamente: `TabbedPanel` lo envuelve junto con `TabsBar`. Ver `examples/14-tabbed.lua`.

**Anti-patrón.**

- **Activar una página sin haber llamado `set_window`.** La página no tiene `window` todavía. Los timers que arranque en su `start` fallarán. `TabbedPanel` resuelve esto activando la primera página dentro de `set_window`, después de que el árbol tenga `window`.
- **Llamar `set_active` antes de `add`.** Si el nombre no existe en `pages`, devuelve `false` sin hacer nada. Algunos consumidores asumen que el primer `set_active` funciona; hay que llamar `add` primero.
- **Mutar `pages` directamente sin pasar por `add`.** `order` quedaría desincronizada. `remove` recorre ambas y puede fallar en encontrar el nombre en `order`. Usar siempre los métodos.
- **Contar con que `askMinMax` devuelve el máximo de todas las páginas.** Solo devuelve el de la activa. Si el consumidor necesita reservar espacio para la página más grande (para evitar que el Stack salte de tamaño al cambiar), tiene que consultar cada página por su cuenta o fijar `min_width`/`min_height` explícitamente en la construcción.

**Notas.**

- `Stack` no dispara `start` ni `stop` en las páginas al cambiar. Eso lo hace `TabbedPanel`, que tiene la noción de `factory` y de página cargada. `Stack` solo muestra y oculta.
- El `invalidate_layout` en `set_active` provoca un `damage_all` más `_relayout` más `draw` en el `Window`. Es un coste real. Cambios de página muy frecuentes (por ejemplo, cada vez que el ratón se mueve sobre una lista) tienen que evitarlo con lógica propia.
- `set_window` propaga a todas las páginas pero no las activa. La activación la hace `TabbedPanel:set_window` después de llamar a `Stack:set_window`.
- `remove` de la página activa cambia `active` a `order[1]` sin reordenar. La nueva activa es la primera que se añadió de las que quedan.
- El `invalidate_layout` en `remove` solo se llama si la activa cambió. Si se quita una página inactiva, no hace relayout. Es correcto: la activa no cambió, el árbol visible tampoco.

#### card.lua

**Propósito.**
Contenedor visual: dibuja un fondo redondeado, un título opcional en la parte superior, y aloja un widget hijo (el contenido) dentro de un área con padding y clipping. Es el bloque que agrupa visualmente contenido relacionado.

**Alcance.**
Cubre fondo con esquinas redondeadas, borde opcional, título opcional (plano o markup), padding interno, separación entre título y contenido, y clipping del contenido al área interior. No cubre sombras, gradientes ni decoraciones más complejas. No cubre cabeceras con botones de acción: si se necesita, el título se compone como un `Group` externo y el Card se usa sin título. No cubre contenido con scroll propio: el Card no hace scroll, solo recorta.

**Cómo funciona.**

`Card.new` mide el título si lo hay con `pango.measure` al construir. Guarda `title_w`, `title_h` y `title_block_h` (la altura que ocupa el bloque título más el `spacing` que lo separa del contenido). Si no hay título, los tres son 0. La medición se hace una vez, no en cada `draw`.

`set_title` reemplaza el título y vuelve a medir. Quita las etiquetas de markup para medir el texto plano (`text:gsub("<[^>]+>", "")`), porque Pango mide el texto sin markup. Detecta si el nuevo texto tiene markup buscando `<` en el string y guarda `title_is_markup`.

`askMinMax` combina el mínimo del título con el del contenido. El ancho mínimo del Card es el máximo entre el ancho del título y el mínimo del contenido, más `padding * 2`. El alto mínimo es la suma del bloque título más el mínimo del contenido, más `padding * 2`. Si `opts.min_height` o `opts.min_width` son mayores que el resultado, se usan esos. `max_w` y `max_h` se calculan igual pero sumando los máximos en lugar de los mínimos, así que el Card puede crecer.

`layout` asigna el rect del Card al `Area` base y luego asigna el rect interior al contenido. El interior empieza en `x0 + padding`, `y0 + padding + title_block_h` y termina en `x1 - padding`, `y1 - padding`.

`draw` ejecuta cinco pasos. Primero dibuja el fondo con `rounded_rect` más `fill`. Segundo, si hay borde, dibuja un contorno redondeado con offset `+0.5` y dimensiones reducidas en 1 px por cada lado para que el trazo caiga dentro del rect. Tercero, si hay título, aplica clip a una región que cubre el ancho disponible menos el padding y la altura del título más un margen de 2 px, y dibuja el texto centrado horizontalmente. El clip evita que un título largo se salga de la Card. Cuarto, si hay contenido, aplica clip al rect interior y dibuja el contenido (con `should_draw` previo). El clip evita que el contenido se salga por un error de layout.

`getByXY` delega al contenido primero; si el contenido devuelve hit, se propaga; si no, cae al `Area:getByXY` base que comprueba el rect del Card.

`set_window` propaga el `window` al contenido si el contenido lo tiene. Si el contenido expone `set_window` propio (por ejemplo, un `Group` o un `TabbedPanel`), se llama; si no, se asigna el campo directamente.

**API.**

**Construcción.**

- **`Card.new(opts)`** — `opts.title` (string, plano o con markup), `opts.content` (widget hijo), `opts.padding` (default 10), `opts.spacing` (default 8, separación entre título y contenido), `opts.corner_radius` (default 8), `opts.bg` (tabla `{r,g,b}` de floats, default `{0.14, 0.14, 0.18}`), `opts.border` (tabla `{r,g,b}` o `nil`), `opts.title_font` (default `"DejaVu Sans Bold 10"`), `opts.title_color` (tabla `{r,g,b}` de floats, default `{0.65, 0.65, 0.65}`), `opts.min_width`, `opts.min_height`.

**Métodos.**

| Método | Notas |
|---|---|
| `set_title(text)` | Reemplaza el título y re-mide. `nil` limpia el título. |
| `set_window(win)` | Propaga `window` al contenido. |

**Campos.**

- `title`, `content` — referencia al título y al contenido.
- `title_w`, `title_h`, `title_block_h` — medidas del título.
- `title_is_markup` — booleano, detectado por presencia de `<`.
- `padding`, `spacing`, `corner_radius`, `bg`, `border`, `title_font`, `title_color`.

**Patrón.**

Card con título y contenido:

    local card = W.Card.new {
        title = "CPU",
        content = cpu_widget,
        bg = theme.bg_card_rgb,
        border = theme.separator_rgb,
    }

Card sin título, solo agrupador visual:

    W.Card.new {
        content = W.Group.new {
            orientation = "vertical",
            children = { ... },
        },
        padding = 12,
    }

Card con título en markup (por ejemplo, con un icono inline):

    W.Card.new {
        title = '<span foreground="#fabd2f">●</span> Uso',
        content = ...,
    }

Ver `examples/13-tab-cpu.lua`, `examples/15-tab-ram.lua`.

**Anti-patrón.**

- **Asumir que el Card va a reservar más espacio del que pide el contenido.** `askMinMax` combina el mínimo del contenido con el del título, pero no crece más allá. Si el contenido es pequeño y se quiere un Card alto, fijar `min_height`.
- **Poner un título largo sin esperar clip.** El título se recorta al ancho disponible (rect completo menos `padding * 2`). Los títulos que no caben se ven cortados por el borde derecho sin indicador. Para títulos que deben caber siempre, acortarlos o envolver el Card en un contenedor más ancho.
- **Confundir `spacing` con `padding`.** `padding` es la separación entre el borde del Card y el contenido (uniforme en los cuatro lados). `spacing` es la separación entre el título y el contenido. No son intercambiables.
- **Pasar un `content` que mute sus hijos sin llamar `invalidate_layout`.** El Card no lo hace por el contenido. El contenido es responsable de invalidar su propio layout tras mutar. Si no lo hace, los hijos nuevos quedan con rect 0 y no se dibujan.
- **Dibujar el borde con `set_line_width` mayor que 1.** El código asume `set_line_width(1)` y ajusta el rect del contorno con offset `+0.5` y dimensiones reducidas en 1 px. Un grosor distinto hace que el borde se salga del Card o quede descentrado.

**Notas.**

- El título se centra horizontalmente dentro del ancho disponible. No hay opción de alinearlo a la izquierda o a la derecha. Para eso, usar un `Header` como contenido del Card y dejar `title = nil`.
- El `title_is_markup` se detecta por presencia de `<` en el string. Un título plano que contenga `<` (por ejemplo, `"a < b"`) se interpretará como markup. Para evitarlo, escapar con `pango.escape`.
- El contenido se clipa al rect interior. Un contenido que dibuje fuera de su rect (por ejemplo, una sombra o un popup) se verá recortado. En ese caso, no usar Card.
- El bg y el border se pasan como tablas `{r, g, b}` de floats. Para construirlos desde strings hex, usar `theme.bg_card_rgb` o `helpers/graphics.hex_to_rgba`.
- El Card no propaga `parent` al contenido al construirse. Si el contenido es un `Group` que necesita saber su padre para algo, hay que asignarlo manualmente tras el constructor. En la práctica, ningún widget del toolkit consulta `parent` hacia arriba salvo el propio `Group` para mutaciones.

#### tabbedpanel.lua

**Propósito.**
Combina `TabsBar` y `Stack` en un solo widget. La barra arriba muestra los tabs disponibles y permite cambiarlos; el stack debajo muestra el contenido de la pestaña activa. Añade lazy loading: la función que construye cada tab solo se ejecuta la primera vez que el tab se activa.

**Alcance.**
Cubre la composición barra más stack, la coordinación entre ellos, el lazy loading de tabs, y las llamadas `start`/`stop` en las pestañas al cambiar. Cubre además el crossfade opcional entre tabs (ver `opts.anim`). No cubre padding exterior: el consumidor decide. No cubre close button por pestaña: se cierra la pestaña entera desde fuera (WM o Esc). No cubre estado global de las pestañas: cada tab gestiona su propio estado dentro de su `factory`.

**Cómo funciona.**

`TabbedPanel.new` recibe `opts.tabs`, una lista de entradas `{ id, label, icon, factory }`. Cada entrada describe una pestaña. `id` es el nombre único, `label` el texto del tab, `icon` el nombre del icono (opcional), `factory` una función sin argumentos que devuelve un objeto con la forma `{ widget = <Area>, start = fn?, stop = fn? }`. El `widget` es lo que se monta en el `Stack`. `start` y `stop` son opcionales.

El constructor arma tres cosas. Primero un `TabsBar` con los items derivados de la lista de tabs. Segundo un `Stack` vacío. Tercero un `Group` vertical que apila la barra (weight 0, solo su mínimo) sobre el stack (weight 1, se lleva el resto). El `spacing` del `Group` es configurable pero el default es 6, y el comentario del código aclara que es para minimizar el hueco cuando hay `TabbedPanel` anidados.

`set_tab(id)` es el método central. Si el id ya está activo, retorna. Si no existe en `tabs_by_id`, retorna. Llama `_stop_active` para detener la pestaña actual. Si la pestaña no está en `loaded`, llama a su `factory` con `pcall` y guarda el resultado (el objeto `{ widget, start, stop }`) en `loaded`, más el `widget` en el `Stack`. Luego llama `start` de la pestaña nueva si existe, también con `pcall`. Finalmente cambia la página activa del `Stack` y actualiza `active_id`.

`_stop_active` llama al `stop` de la pestaña actual si existe, con `pcall` y log de error si falla. El comentario del código indica que `stop` es donde las pestañas deben cancelar timers, detener samplers y liberar recursos.

`set_window` es donde ocurre la activación inicial. Propaga el `window` al `Group` (que lo propaga a sus hijos, incluidos el `TabsBar` y el `Stack`), y si `active_id` todavía es `nil` y hay al menos una pestaña en `tabs`, activa la primera. El orden importa: primero `set_window`, después `set_tab`. Si fuera al revés, la `factory` correría antes de que el árbol tenga `window`, y las pestañas que necesiten `srv` (pasado por el closure de la factory) o `window` fallarían.

`askMinMax` y `layout` delegan al `Group` interno. El `TabbedPanel` no tiene mínimos propios: todo lo hereda del grupo, que a su vez suma el `TabsBar` y el `Stack` (que solo cuenta la página activa).

`draw` dibuja el fondo si `self.bg` está definido, y luego delega al `Group`. El comentario del código aclara que el `TabbedPanel` en sí siempre se "dibuja" (el fondo), pero los hijos se filtran por `should_draw` dentro del `Group:draw`.

`getByXY` delega al `Group`; si el `Group` no acierta, cae al rect propio.

**API.**

**Construcción.**

- **`TabbedPanel.new(opts)`** — `opts.tabs` (lista de `{ id, label, icon, factory }`), `opts.spacing` (default 6), `opts.bg` (tabla `{r,g,b}` de floats, opcional), `opts.compact` (booleano, se pasa al `TabsBar`), `opts.theme` (se pasa al `TabsBar`), `opts.tabsbar_opts` (tabla de opciones extra para el `TabsBar`), `opts.anim` (booleano, default `false`; activa el crossfade al cambiar de tab), `opts.anim_duration` (duración del fade en ms, default 300), `opts.anim_fps` (Hz de la animación, default 30).

Forma de cada entrada de `opts.tabs`:

- `id` — identificador único de la pestaña.
- `label` — texto del tab.
- `icon` — nombre del icono (opcional).
- `factory` — función sin argumentos que devuelve `{ widget, start?, stop? }`.

**Métodos.**

| Método | Retorno | Notas |
|---|---|---|
| `set_tab(id)` | — | Activa la pestaña. Si no estaba cargada, llama a su factory. Si `opts.anim` está activo y el motor de anim está inicializado, hace crossfade con el tab anterior. |
| `get_tab(id)` | objeto o `nil` | Devuelve la pestaña cargada (`{ widget, start, stop }`), o `nil` si no se ha activado nunca. |
| `get_active()` | string o `nil` | Id de la pestaña activa. |
| `stop()` | — | Llama `stop` de la pestaña activa si lo tiene. |
| `set_window(win)` | — | Propaga `window` y activa la primera pestaña si no había ninguna. |

**Campos.**

- `tabs` — lista original de definiciones.
- `tabs_by_id` — tabla `id → definición`.
- `loaded` — tabla `id → objeto` de pestañas cargadas.
- `active_id` — id de la activa, o `nil`.
- `tabsbar` — el `TabsBar` interno.
- `stack` — el `Stack` interno.
- `group` — el `Group` que apila `tabsbar` y `stack`.

**Patrón.**

Panel con varias pestañas, cada una con su propio estado:

    local panel = W.TabbedPanel.new {
        tabs = {
            {
                id = "cpu", label = "CPU", icon = "cpu",
                factory = function()
                    return cpu_tab.new(srv, theme)  -- { widget, start, stop }
                end,
            },
            {
                id = "ram", label = "RAM", icon = "ram",
                factory = function()
                    return ram_tab.new(srv, theme)
                end,
            },
        },
    }

Con sub-pestañas anidadas (patrón del panel de sistema):

    local recursos = W.TabbedPanel.new {
        compact = true,
        theme = theme,
        tabs = { general, cpu, ram, gpu },
    }

Ver `examples/14-tabbed.lua` y `examples/16-panel.lua`.

**Anti-patrón.**

- **Construir todos los tabs por adelantado y pasarlos como widgets.** El `TabbedPanel` espera una `factory` por pestaña, no un widget. La `factory` es lo que permite el lazy loading: un tab con un sampler caro no se construye hasta que se activa.
- **Asumir que `get_tab(id)` devuelve algo para tabs no visitados.** Devuelve `nil` hasta que el tab se ha activado al menos una vez. Si un consumidor necesita el widget de un tab inactivo (por ejemplo, para comunicar datos), tiene que activarlo primero o gestionar el estado por fuera del panel.
- **Registrar timers en la `factory` y no cancelarlos en `stop`.** La `factory` corre al activar la pestaña; si registra un timer, hay que cancelarlo en `stop`. Sin `stop`, el timer sigue corriendo aunque la pestaña esté oculta, gastando CPU. `notes.md` documenta el patrón `start`/`stop`.
- **Cambiar el `active_id` directamente.** Siempre a través de `set_tab`. El cambio directo no llama a `_stop_active`, no carga la pestaña nueva, y deja `Stack.active` desincronizado con `TabbedPanel.active_id`.
- **Activar `opts.anim` sin haber llamado a `anim.init(srv)`.** El `TabbedPanel` consulta `anim.is_ready()` antes de intentar animar. Si el motor no está inicializado, cae al cambio directo sin crossfade, sin error. El consumidor debe asegurar que `anim.init` se haya llamado antes (típicamente en `Panel.new` o al construir la ventana).
- **Asumir que `set_tab` con el id actual es un no-op barato.** Sí lo es (early return), pero si la `factory` de la pestaña activa falló en su momento, el `TabbedPanel` se quedó sin la pestaña y `set_tab` sobre el mismo id vuelve a intentar la `factory`. Es intencional: permite reintentar tras un fallo.

**Notas.**

- El `Stack` interno recibe un `Stack.new {}` sin opciones. Los mínimos del `TabbedPanel` vienen del `Group` (que suma `TabsBar` + `Stack`).
- `_stop_active` envuelve la llamada en `pcall` para que un error en `stop` no rompa el cambio de pestaña. El error se loguea con `log.error`.
- La `factory` también va en `pcall`. Si falla, se loguea y `set_tab` retorna sin activar. El `active_id` queda apuntando a la pestaña previa.
- El `TabsBar` recibe `on_select = function(id) self:set_tab(id) end`, así que la coordinación entre la barra visual y el stack la maneja el propio panel.
- El `TabbedPanel` no cierra pestañas: no hay `close_tab` ni botón de X. La pestaña activa se detiene cuando el panel entero se cierra, gracias al `stop` que llama `Panel:on_close`. `notes.md` lo documenta.
- El `spacing` default de 6 es el hueco entre la `TabsBar` y el contenido. Para sub-paneles anidados, se suele pasar `spacing = 4` o `2` para que la acumulación no se note.



**Integración con Intro (2026-09-25).**
`TabbedPanel:set_tab` coordina tres llamadas al módulo `Intro`:

1. `Intro.cancel(active_old)` antes de cambiar. Cancela los tweens del
   tab viejo (guardados en `_intro_handles`) para que no sigan dañando
   rects que ya no están en pantalla. Sin esto, un cambio de tab
   durante el reveal deja el sistema de tabs/subtabs roto por ~1-2 s.
2. `Intro.reset(tab_new)` antes de `stack:set_active`. Pone los campos
   de animación (`reveal`, `alpha`, `_anim_pending`) a su estado
   inicial, para que la animación se vea de nuevo aunque el tab ya se
   haya activado antes.
3. `Intro.play(tab_new)` después del swap. Dispara las animaciones de
   entrada de cada widget animable del tab nuevo.

Si hay crossfade, `Intro.play` se llama en el `on_done` del fade, para
no mezclar los dos efectos.

Si `animate_widgets` es `false` o el motor no está listo, las tres
llamadas son no-op y los widgets quedan en estado final desde el
primer frame.

#### intro.lua

**Propósito.**
Motor de animaciones de entrada automáticas. Recorre el árbol de un tab
al activarlo y dispara las animaciones de los widgets que declaran
`_anim_kind`. Es el pegamento entre `TabbedPanel:set_tab` y los widgets
animables (`Ring`, `Spark`, `DualSpark`, `BarRow`, `KV`).

**Alcance.**
Cubre el recorrido del árbol, el reset del estado inicial de cada
widget animable, el disparo de los tweens correspondientes, y la
cancelación de tweens en curso al cambiar de tab. No cubre animaciones
de datos (esas las maneja cada widget en su `set_*`/`push_*`). No cubre
animaciones que no estén declaradas en `_anim_kind`.

**Cómo funciona.**

El módulo exporta cuatro funciones:

- **`Intro.reset(root)`** — Recorre el árbol y pone los campos de
  animación a su estado inicial (`reveal = 0`, `alpha = 0`,
  `_anim_pending = true`, etc.). Se llama antes de activar el tab,
  para que la animación se vea aunque el tab ya se haya activado antes.
- **`Intro.play(root)`** — Recorre el árbol y dispara las animaciones
  de entrada. Cada widget animable lanza su tween. Los handles se
  guardan en el widget (`_intro_handles`) para poder cancelarlos.
- **`Intro.cancel(root)`** — Cancela todos los tweens de intro en
  curso. Se llama al cambiar de tab para que los tweens del tab viejo
  no sigan dañando rects que ya no están en pantalla.
- **`Intro.each_child(w, fn)`** — Itera los hijos directos de un
  widget por campo conocido (`children`, `content`, `inner`,
  `feedback`, `buttons`, `group`, `pages` del activo). Es el
  recorrido que usan las tres funciones anteriores.

El contrato para un widget nuevo:

    Widget.new = function(opts)
        local self = ...
        self._anim_kind = "ring"  -- o "spark", "dualspark", "barrow", "kv"
        return self
    end

Si un widget no declara `_anim_kind`, `Intro` lo salta. Los
contenedores (`Group`, `Card`, `Stack`, `TabbedPanel`) no declaran
`_anim_kind`; solo se recorre su contenido.

**API.**

| Función | Notas |
|---|---|
| `reset(root)` | Pone los campos de animación a su estado inicial. |
| `play(root)` | Dispara las animaciones de entrada. |
| `cancel(root)` | Cancela los tweens de intro en curso. |
| `each_child(w, fn)` | Itera hijos directos por campo. |

**Valores de `_anim_kind`.**

| Valor | Widget | Efecto |
|---|---|---|
| `"ring"` | `Ring` | Tween `reveal` 0→1 (el arco se dibuja progresivamente). |
| `"spark"` | `Spark` | Fade in de `alpha`/`reveal` cuando llegue el 2º punto. |
| `"dualspark"` | `DualSpark` | Igual, cuando alguna serie llegue a 2 puntos. |
| `"barrow"` | `BarRow` (y `Motors`) | Stagger: cada fila entra con 35 ms de retraso. |
| `"kv"` | `KV` | Fade in de `alpha` (vía `set_alpha`). |

**Patrón.**

No se usa directamente. `TabbedPanel:set_tab` lo invoca:

    Intro.cancel(active_old)   -- antes del cambio
    Intro.reset(tab_new)       -- antes de set_active
    stack:set_active(id)
    Intro.play(tab_new)        -- después del swap

**Anti-patrón.**

- **Declarar `_anim_kind` sin implementar el campo/método que `Intro`
  espera.** Por ejemplo, declarar `"kv"` sin tener `set_alpha`. `Intro`
  llama `w:set_alpha(e)` y crashea. Cada tipo tiene su contrato (ver
  la tabla arriba).
- **Construir un árbol con hijos que no estén en `children`,
  `content`, `inner`, `feedback`, `buttons`, `group` o `pages`.** El
  recorrido no los verá. Si un contenedor nuevo expone sus hijos en
  otro campo, hay que añadirlo a `each_child`.
- **Llamar `Intro.play` sin haber llamado `Intro.reset` antes.** Sin
  reset, los widgets quedan en su estado del uso anterior (por ejemplo
  `reveal = 1`) y los tweens `0 → 1` no producen efecto visible.
- **Olvidar `Intro.cancel` al cambiar de tab.** Los tweens del tab
  viejo siguen corriendo, dañando rects que ya no están en pantalla.
  Efecto visual: tabs/subtabs parpadean durante ~1-2 s.

**Notas.**

- Los handles de los tweens se guardan en `w._intro_handles` (array).
  Cancelar recorre el array y cancela cada uno.
- `Intro` es no-op si `anim.is_ready()` devuelve `false` o
  `animate_widgets` es `false`. En ese caso los widgets quedan en su
  estado final desde el primer frame.
- El módulo vive en `src/lib/widgets/` aunque no sea un widget
  visible. Comparte carpeta porque es parte del flujo de
  `TabbedPanel:set_tab`.

#### text.lua

**Propósito.**
Texto plano o con markup Pango, con alineación horizontal y vertical configurables dentro de su rect. Mide su contenido al construir y al cambiar, para que el padre pueda reservar el espacio correcto.

**Alcance.**
Cubre texto simple con color uniforme, alineación, y wrapping opcional cuando el ancho de la celda es menor que el ancho natural. No cubre texto enriquecido con múltiples colores en la misma línea: para eso usar `markup` (Pango lo interpreta). No cubre edición ni cursor: vive en `textinput.lua`. No cubre justificación ni alineación a ambos lados. No cubre sombra ni contorno de texto.

**Cómo funciona.**

`Text.new` guarda el texto (`opts.text`), el markup opcional (`opts.markup`, tiene prioridad sobre `text`), la fuente (`"DejaVu Sans 12"` por defecto), el color (`r`, `g`, `b` por separado, default blanco), la alineación horizontal (`"left"`, `"center"`, `"right"`) y la vertical (`"top"`, `"center"`, `"bottom"`), y el flag `wrap`.

`_remeasure` calcula `text_w`, `text_h` con `pango.measure`. Si hay markup, mide el texto plano quitando las etiquetas con `gsub("<[^>]+>", "")`, porque Pango mide el texto final sin markup. Fija `min_w`/`min_h` a la medida del texto y `max_w`/`max_h` a `10000`, permitiendo que el widget crezca hasta su rect en ambos ejes. `notes.md` documenta esta decisión: sin liberar los máximos, los Text quedan con huecos vacíos a su alrededor porque el padre les da exactamente su tamaño natural.

`set_text` reemplaza el texto, limpia el markup y re-mide. `set_markup` reemplaza el markup y re-mide. `set_color` compara con los valores actuales y solo daña si cambiaron.

`draw` calcula la posición inicial `(x, y)` según las alineaciones. Para `align = "center"`, `x = x0 + (ancho - text_w)/2`; para `"right"`, `x = x1 - text_w`. Análogo para `valign`. Luego decide si aplica clip: si el texto cabe en el rect o el wrap está desactivado y el texto cabe, dibuja directo; si el texto es más ancho o más alto que el rect y no hay wrap, envuelve la llamada de dibujo en un `save`/`clip`/`restore` para recortarlo.

`_draw_text` es el paso final. Si `wrap` está activo y el ancho disponible es menor que el ancho natural del texto, añade `wrap_width = getWidth()` a las opciones de Pango. En ese caso, el `align` horizontal se ignora porque Pango maneja la alineación internamente sobre el ancho del layout. Llama a `pango.draw_markup` si hay markup, `pango.draw_text` si no.

**API.**

**Construcción.**

- **`Text.new(opts)`** — `opts.text` (plano), `opts.markup` (con markup, tiene prioridad), `opts.font` (default `"DejaVu Sans 12"`), `opts.r`, `opts.g`, `opts.b` (color, default `1.0`), `opts.align` (`"left"`, `"center"`, `"right"`), `opts.valign` (`"top"`, `"center"`, `"bottom"`), `opts.wrap` (booleano).

**Métodos.**

| Método | Notas |
|---|---|
| `set_text(text)` | Reemplaza el texto plano. Limpia el markup. Re-mide. `text` puede ser `nil`: se trata como `""`. |
| `set_markup(markup)` | Reemplaza con markup Pango. Re-mide. |
| `set_color(r, g, b)` | Cambia el color. Solo daña si cambió. |

**Campos.**

- `text`, `markup` — uno de los dos es el contenido activo.
- `font` — string de Pango.
- `r`, `g`, `b` — color.
- `align`, `valign`, `wrap`.
- `text_w`, `text_h` — medidas del contenido.

**Patrón.**

Texto centrado en una celda:

    W.Text.new {
        text = "Hello",
        align = "center",
        valign = "center",
        font = "DejaVu Sans 14",
    }

Texto con markup inline:

    W.Text.new {
        markup = '<span foreground="#fabd2f">CPU</span> 45%',
        font = "DejaVu Sans 11",
    }

Texto que se envuelve cuando el ancho se reduce:

    W.Text.new {
        text = "Descripción larga que puede ocupar varias líneas",
        wrap = true,
        font = "DejaVu Sans 10",
    }

Ver `examples/02-text.lua` para texto plano y `examples/12-markup.lua` para markup.

**Anti-patrón.**

- **Asumir que `align` funciona con wrap activo.** Cuando el texto es más ancho que la celda y `wrap` está activo, el `align` horizontal se ignora: Pango maneja la alineación internamente sobre el ancho del layout. Es intencional: el wrap necesita un ancho fijo para envolver, y el `align` de Cairo solo tiene sentido para texto ya medido.
- **Pasar markup por `opts.text`.** Si el texto tiene `<`, `&` o `>` y se pasa por `opts.text`, se dibuja tal cual. Si se quiere interpretar como markup, pasar por `opts.markup` o usar `set_markup`.
- **Pasar texto del usuario por `opts.markup` sin escapar.** Un `<` en el texto del usuario romperá el layout o lo interpretará como etiqueta. Escapar con `pango.escape` antes.
- **Esperar que `wrap` active el crecimiento vertical del texto.** `Text` mide siempre como si fuera una línea. Con `wrap`, el texto dibuja múltiples líneas pero `text_h` sigue reflejando el alto de una línea. El `max_h = 10000` permite que el rect crezca, pero el `askMinMax` sigue devolviendo el mínimo de una línea. Si se necesita reservar espacio para varias líneas, hay que darle el alto al widget por fuera.
- **Cambiar `text_w` o `text_h` a mano.** Son medidas derivadas. Cambiarlas sin llamar `_remeasure` deja el widget inconsistente.

**Notas.**

- El `align` horizontal solo aplica cuando el texto no se envuelve. Con wrap activo y texto desbordado, Pango alinea al inicio del layout (left) por defecto. El código no expone forma de cambiar ese comportamiento.
- El `valign` vertical sí aplica siempre, incluso con wrap: el bloque de texto se posiciona dentro de la celda según el valor.
- El clip solo se activa cuando el texto desborda **y** no hay wrap. Con wrap activo y texto desbordado, no hay clip; el texto se envuelve y Pango maneja el desbordamiento vertical.
- `set_text` limpia el markup. Si se estaba mostrando markup y se llama `set_text("foo")`, el widget pasa a mostrar `foo` como texto plano. Es intencional.
- El default `"DejaVu Sans 12"` es razonable para pantallas HiDPI pequeñas, pero cualquier aplicación del toolkit lo sobreescribe con el theme.

---

#### header.lua

**Propósito.**
Título de sección. Texto con fuente y color configurables, alineación, valign y wrap opcional. Similar a `Text` pero pensado para encabezados y con defaults distintos.

**Alcance.**
Cubre lo mismo que `Text` salvo el cambio de color en runtime. No cubre icono junto al título: si se necesita, componer con un `Group` horizontal. No cubre subtítulos: usar dos `Header` o un `Bignum` con caption. No cubre la funcionalidad de `Card`: `Header` es solo texto, no dibuja fondo.

**Cómo funciona.**

`Header` es casi idéntico a `Text` pero con defaults distintos (`"DejaVu Sans 11"` y color muted `{0.65, 0.65, 0.70}`), con `markup` como booleano (`opts.markup = true` para tratar `opts.text` como markup, en lugar de un campo separado) y con `max_w`/`max_h` fijados al tamaño natural.

La diferencia clave respecto a `Text` está en `_remeasure`: `Header` fija `max_w = text_w` y `max_h = text_h`, mientras `Text` los libera a `10000`. Un `Header` nunca crece más allá de su contenido: el padre le da exactamente su tamaño natural. Es lo correcto para encabezados, que no tienen por qué estirarse. `notes.md` documenta el caso general de `max_h`: si un widget devuelve su alto natural como máximo, nunca se estira y quedan huecos vacíos; si quiere crecer, devolver `10000`. `Header` elige no crecer.

`_plain` devuelve el texto sin markup si `is_markup` está activo. Se usa para medir. El markup se conserva para dibujar.

`set(text)` reemplaza el texto conservando el flag `is_markup` actual. `set_markup(markup)` reemplaza el texto y activa `is_markup`.

`draw` calcula posición según `align` y `valign`. Si hay wrap activo y el ancho disponible es menor que el ancho natural, pasa `wrap_width` a Pango y omite el `valign = "center"` (Pango maneja el bloque desde arriba). Si no hay wrap, centra según `valign`.

**API.**

**Construcción.**

- **`Header.new(opts)`** — `opts.text` (plano o markup), `opts.markup` (booleano, default `false`), `opts.font` (default `"DejaVu Sans 11"`), `opts.color` (tabla `{r, g, b}`, default `{0.65, 0.65, 0.70}`), `opts.align` (`"left"` default), `opts.valign` (`"center"` default), `opts.wrap` (booleano, default `false`).

**Métodos.**

| Método | Notas |
|---|---|
| `set(text)` | Reemplaza el texto. Conserva el flag `is_markup`. Re-mide. |
| `set_markup(markup)` | Reemplaza el texto y activa `is_markup`. Re-mide. |

**Campos.**

- `text` — contenido.
- `is_markup` — booleano.
- `font`, `color`, `align`, `valign`, `wrap`.
- `text_w`, `text_h` — medidas.

**Patrón.**

Encabezado de sección:

    W.Header.new {
        text = "Sistema",
        font = "DejaVu Sans Bold 11",
        color = { 0.75, 0.75, 0.85 },
    }

Encabezado con markup:

    W.Header.new {
        text = '<b>CPU</b> — <i>Intel i7</i>',
        markup = true,
    }

**Anti-patrón.**

- **Esperar que `set_markup` con texto plano funcione.** `set_markup` activa `is_markup`, así que cualquier `<`, `&` o `>` en el texto se interpretará como markup. Para texto plano, usar `set`.
- **Esperar que `Header` crezca verticalmente.** No lo hace: `max_h = text_h`. Es intencional. Si se necesita un header que ocupe más espacio, envolverlo en un `Card` con `min_height` o ponerlo en un `Group` con `weight = 1`.
- **Usar `Header` para texto general.** Los defaults están pensados para encabezados, no para cuerpo. Para texto arbitrario, `Text` es más flexible (permite cambiar el color en runtime, libera los máximos).

**Notas.**

- El `wrap` con `align = "center"` desactiva el centrado horizontal. Misma razón que en `Text`: Pango maneja la alineación del bloque envuelto sobre el ancho del layout, y el `align` de Cairo no aplica.
- El `valign = "center"` se ignora cuando hay wrap activo y el texto desborda. El bloque se ancla al tope. Es una limitación heredada de `Text`.
- `Header` no tiene `set_color`: el color se fija al construir. Para cambios de color en runtime, usar `Text`.

#### bignum.lua

**Propósito.**
Número grande con unidad opcional y caption opcional, los tres centrados. Pensado para paneles de telemetría: el valor destaca visualmente, la unidad y el caption dan contexto.

**Alcance.**
Cubre un valor principal, una unidad (opcional) y un caption (opcional). No cubre el número formateado con separadores de miles: el valor se pasa como string ya formateado. No cubre icono junto al número. No cubre actualización con color dinámico por umbral: el color se fija al construir, aunque se puede reconstruir. No cubre más de tres líneas: si se necesita más, componer con `Group`.

**Cómo funciona.**

`Bignum.new` recibe `value` (string, no número), `unit` (string, opcional), `caption` (string, opcional), y tres colores distintos para cada parte. Los tamaños de fuente se derivan de `size` (default 28 para el número) y `caption_size` (default 10 para unidad y caption). Las fuentes se construyen como strings Pango: `"DejaVu Sans Bold 28"`, `"DejaVu Sans 10"`.

`_remeasure` mide las tres partes con `pango.measure` (las que existen) y calcula `w_min` como el máximo de los tres anchos, y `h_min` como la suma de las alturas más pequeños espaciados. Fija `min_w`/`min_h` y `max_w`/`max_h` a esos valores: el widget no crece más allá de su contenido natural. El padre le da exactamente su tamaño.

`set(value, caption, unit)` permite actualizar cualquier combinación de los tres campos. Los argumentos `nil` no modifican el campo correspondiente, así que `set(45)` solo cambia el valor, y `set(nil, "Uso")` solo cambia el caption. Re-mide y daña.

`draw` centra las tres líneas horizontalmente respecto al centro del rect (`cx = x0 + width/2`). Empieza en `y0` y va acumulando alturas. El valor primero, luego la unidad (con 1 px de separación), luego el caption (con 2 px de separación). Cada línea se dibuja re-midiendo con `pango.measure` para obtener el ancho y calcular el offset `cx - ancho/2`. La medición dentro de `draw` es redundante con la de `_remeasure`, pero el número de líneas es pequeño (1-3) y el coste es aceptable.

**API.**

**Construcción.**

- **`Bignum.new(opts)`** — `opts.value` (string, default `"0"`), `opts.unit` (string, opcional), `opts.caption` (string, default `""`), `opts.size` (default 28), `opts.caption_size` (default 10), `opts.color` (tabla `{r, g, b}` del número, default `{0.95, 0.95, 0.95}`), `opts.unit_color` (default `{0.65, 0.65, 0.70}`), `opts.caption_color` (default `{0.55, 0.55, 0.60}`).

**Métodos.**

| Método | Notas |
|---|---|
| `set(value?, caption?, unit?)` | Actualiza los campos no-`nil`. Re-mide. |

**Campos.**

- `value`, `unit`, `caption` — el contenido.
- `size`, `caption_size` — tamaños de fuente.
- `color`, `unit_color`, `caption_color`.
- `w_min`, `h_min` — medidas calculadas.

**Patrón.**

Tarjeta con porcentaje de uso:

    W.Bignum.new {
        value = "45",
        unit = "%",
        caption = "Uso de CPU",
        color = { 0.9, 0.9, 0.9 },
    }

Actualización en un timer:

    bignum:set(string.format("%d", math.floor(pct * 100)))

Ver `examples/13-tab-cpu.lua` y `examples/15-tab-ram.lua`.

**Anti-patrón.**

- **Pasar un número en vez de un string.** El constructor hace `opts.value or "0"` sin `tostring`, así que un número queda como número y `pango.measure` puede fallar o comportarse raro según la versión. Usar `tostring(n)` o `string.format("%d", n)`.
- **Esperar que `Bignum` crezca para llenar la celda.** `max_w` y `max_h` son iguales a `min_w` y `min_h`. El padre le da exactamente su tamaño natural. Para que ocupe más, envolver en un `Group` con `weight = 1` o fijarle un `min_height` externo.
- **Cambiar `size` o `caption_size` después de construir.** Las fuentes se calculan en el constructor (`num_font`, `unit_font`, `cap_font`). Cambiar `size` directamente no actualiza las fuentes. Reconstruir el widget o exponer un setter si hace falta.
- **Pasar `caption = nil` cuando se quiere limpiar el caption.** El constructor lo convierte a `""`, pero el check de `draw` es `self.caption ~= ""`. Un `nil` asignado después por error no limpia el caption y `pango.measure` fallaría. Usar siempre strings, `""` para vacío.

**Notas.**

- El valor se pasa ya formateado. No hay opción de formatear números con decimales o separadores: el consumidor usa `string.format` o `helpers/format`.
- El `unit` se dibuja más pequeño que el número, mismo tamaño que el caption. No hay opción de dibujarlo en superíndice o al lado del número; siempre va debajo.
- Las tres partes se centran horizontalmente respecto al rect. No hay opción de alinear a la izquierda o derecha.
- `Bignum` no tiene `_hover_visual` ni `_pressed_visual`: no responde a interacción. Es un widget de solo lectura.

---

#### button.lua

**Propósito.**
Botón rectangular con texto centrado, fondo redondeado, estados de hover y pressed, y callback al click. Uso típico: acciones discretas.

**Alcance.**
Cubre botón con texto, colores por estado, borde opcional, padding y callback. No cubre iconos: si se necesita icono más texto, componer con `Group`. No cubre botones con estados toggle (encendido/apagado): usar dos `Button` y alternar el texto, o un widget propio. No cubre atajos de teclado: solo responde a click.

**Cómo funciona.**

`Button.new` declara `_hover_visual = true` y `_pressed_visual = true` para que `Area:set_hover` y `Area:set_pressed` generen damage al cambiar de estado. Sin estas marcas, el hover y el pressed no repintarían.

El constructor tiene dos conjuntos de colores predefinidos según `opts.flat`. Con `flat = true`, el fondo normal es transparente (color `{0, 0, 0}` con la convención de que no dibuja si `flat`), el borde no se dibuja, y solo aparecen colores en hover y pressed. Con `flat = false`, hay fondo normal, borde y colores de hover y pressed.

Cualquier color pasado por `opts.color_*` tiene prioridad sobre los defaults. El consumidor puede por ejemplo definir solo `color_normal` y dejar los demás con los defaults.

`askMinMax` (implícito, fijado en el constructor) devuelve el tamaño del texto más `padding_x * 2` y `padding_y * 2`. `max_w` y `max_h` son iguales a los mínimos: el botón no crece más allá de su contenido. Es lo correcto: un botón que crece más de lo que necesita se ve mal.

`set_text` re-mide y actualiza los mínimos. El llamador debe considerar que el botón puede cambiar de tamaño tras esta llamada; si estaba en un layout, hay que forzar relayout.

`draw` elige el color de fondo según el estado: pressed > hover > normal (con la excepción de `flat`, que no dibuja normal). Dibuja el `rounded_rect` y lo rellena. Si hay borde, dibuja el contorno con offset `+0.5` y dimensiones reducidas para que el trazo caiga dentro del rect. Finalmente dibuja el texto centrado.

El `on_click` se dispara desde `Window:_dispatch`, no desde `Button` mismo. Cuando el usuario hace click y el release cae sobre el mismo widget que recibió el press, `Window` llama a `active.opts.on_click(active, bev.detail)`. El botón no necesita manejar el evento.

**API.**

**Construcción.**

- **`Button.new(opts)`** — `opts.text` (default `"Button"`), `opts.font` (default `"DejaVu Sans Bold 12"`), `opts.padding_x` (default 16), `opts.padding_y` (default 8), `opts.corner_radius` (default 6), `opts.flat` (booleano, default `false`), `opts.color_normal`, `opts.color_hover`, `opts.color_pressed`, `opts.color_border`, `opts.color_text`, `opts.on_click`, `opts.on_hover`, `opts.on_press`.

**Métodos.**

| Método | Notas |
|---|---|
| `set_text(text)` | Reemplaza el texto. Re-mide y actualiza los mínimos. |

**Callbacks.**

- `on_click(self, button)` — disparado por `Window` tras un click completo (press + release sobre el mismo widget). `button` es el botón del ratón (1 para izquierdo).
- `on_hover(self, hover_bool)` — disparado por `Area:set_hover`.
- `on_press(self, pressed_bool)` — disparado por `Area:set_pressed`.

**Campos.**

- `text`, `font`.
- `padding_x`, `padding_y`, `corner_radius`, `flat`.
- `color_normal`, `color_hover`, `color_pressed`, `color_border`, `color_text`.

**Patrón.**

Botón estándar con callback:

    W.Button.new {
        text = "Aplicar",
        on_click = function(self, button)
            apply_config()
        end,
    }

Botón plano (sin fondo normal, solo hover y pressed):

    W.Button.new {
        text = "Cancelar",
        flat = true,
        color_hover = { 0.3, 0.3, 0.4 },
    }

Ver `examples/09-button.lua`.

**Anti-patrón.**

- **Esperar que el botón crezca con el layout.** `max_w = min_w` y `max_h = min_h`. El botón ocupa exactamente su tamaño natural. Para botones que se expanden, envolver en un `Group` con `weight = 1` y dejar que el `Group` le dé el rect; el `Button` seguirá dibujando su `rounded_rect` al tamaño del rect, pero el texto quedará centrado con huecos. Si se quiere un botón que ocupe todo, hay que escribir uno propio o modificar los máximos.
- **Llamar `on_click` desde el propio widget con `on_mouse_press`.** El toolkit dispara `on_click` al completar un click (press + release sobre el mismo widget). Dispararlo desde `on_mouse_press` haría que el botón se active aunque el usuario arrastre fuera antes de soltar. Si se necesita comportamiento diferente, no usar `Button`.
- **Pasar `on_click` que mute el árbol sin `invalidate_layout`.** El botón no lo hace por el consumidor. Si el callback añade o quita widgets, hay que invalidar el layout correspondiente. `notes.md` lo documenta como regla general.
- **Asumir que `flat = true` no dibuja nada en estado normal.** El color normal es `{0, 0, 0}` pero el dibujo se omite porque el código comprueba `not self.flat`. El efecto es el mismo (no se dibuja fondo), pero la diferencia está en que con `flat` tampoco se dibuja borde aunque se pase `color_border`. El constructor fuerza `color_border = nil` cuando `flat`.

**Notas.**

- El texto se centra horizontal y verticalmente dentro del rect. No hay opción de alinearlo de otra forma.
- El `set_text` no genera relayout del padre. Si el texto cambia de ancho, el botón cambia de tamaño mínimo, pero el padre no se entera hasta el próximo `askMinMax`. Si hace falta, llamar `invalidate_layout` en el contenedor.
- El `on_click` recibe `self` como primer argumento y el `button` como segundo. Algunos consumidores prefieren escribir `function(self, _) ... end` para ignorar el botón.
- El `Button` no tiene `disabled`: si se necesita un botón deshabilitado, usar otro widget o gestionar el estado desde el callback (no hacer nada si la condición no se cumple).

#### icon.lua

**Propósito.**
Dibuja una imagen PNG en un `Area`, con tamaño de destino independiente del tamaño nativo, alineación dentro del rect, y tintado opcional preservando el alpha del PNG original.

**Alcance.**
Cubre PNG cargado desde disco, escalado al tamaño de dibujo, alineación horizontal y vertical, y tintado con un color sólido. No cubre SVG: si la ruta es un SVG, la carga fallará; para SVG en runtime usar `lib.svg` y un widget propio. No cubre iconos con múltiples capas ni composición de varios PNG. No cubre iconos vectoriales escalables sin pérdida: el escalado es rasterizado.

**Cómo funciona.**

`Icon.new` declara `_hover_visual = true` y `_pressed_visual = true` para que los cambios de hover y pressed generen damage. Aunque un icono no dibuje un fondo de hover por defecto, la marca permite que consumidores que reaccionen al hover (por ejemplo, cambiando el color del icono) repinten correctamente.

La carga del PNG se hace en el constructor con `cairo.load_png_cached`. Esto usa el cache global de PNG: dos iconos con la misma ruta comparten el mismo surface. La superficie se guarda en `self.surface`. Si la carga falla, `self.surface` queda `nil` y `self.err` contiene el mensaje. El icono se construye igual: los mínimos y máximos son el tamaño nativo (o `16, 16` si no hay superficie), y `draw` retorna sin dibujar nada si no hay superficie.

El tamaño de dibujo se fija con `opts.width` y `opts.height`. Si no se pasan, se usan `native_w` y `native_h` del PNG. Los mínimos y máximos se fijan al tamaño de dibujo, así que el icono no crece ni se estira: ocupa exactamente su tamaño.

El color de tintado se puede pasar como `opts.color` (tabla `{r, g, b}`) o `opts.color_hex` (string `#rrggbb`). Si ambos se pasan, `opts.color` tiene prioridad. `set_color` y `set_color_hex` cambian el tintado en runtime; pasar `nil` quita el tintado.

`draw` calcula la posición según `halign` (`"left"`, `"center"`, `"right"`) y `valign` (`"top"`, `"center"`, `"bottom"`) dentro del rect asignado. Si hay color, llama `cairo.draw_surface_tinted`; si no, `cairo.draw_surface`. El escalado ocurre dentro de `draw_surface` (interpolación GOOD), no en el constructor, así que el mismo surface cacheado se puede dibujar a distintos tamaños por distintos iconos sin recargar.

`on_mouse_press` dispara `opts.on_click` con el propio icono como argumento, si el botón es el izquierdo. No hay `on_mouse_release`: el click se dispara al presionar, no al completar el ciclo.

**API.**

**Construcción.**

- **`Icon.new(opts)`** — `opts.path` (ruta al PNG), `opts.width` (ancho de dibujo, default el nativo), `opts.height` (alto de dibujo, default el nativo), `opts.color` (tabla `{r, g, b}`), `opts.color_hex` (string `#rrggbb`, alternativa a `color`), `opts.halign` (`"left"` default, `"center"`, `"right"`), `opts.valign` (`"center"` default, `"top"`, `"bottom"`), `opts.on_click`.

**Métodos.**

| Método | Notas |
|---|---|
| `set_path(path)` | Cambia el PNG. Recarga del cache. |
| `set_color(r, g, b)` | Cambia el tintado. `nil` en `r` quita el tintado. |
| `set_color_hex(hex)` | Cambia el tintado desde string hex. `nil` quita el tintado. |

**Callbacks.**

- `on_click(self)` — disparado en `on_mouse_press` con botón 1.

**Campos.**

- `path` — ruta actual.
- `surface` — superficie Cairo cargada, o `nil` si falló.
- `err` — mensaje de error si la carga falló.
- `native_w`, `native_h` — tamaño nativo del PNG.
- `width`, `height` — tamaño de dibujo.
- `color` — tabla `{r, g, b}` o `nil`.
- `halign`, `valign`.

**Patrón.**

Icono de barra tintado con el color del theme:

    W.Icon.new {
        path = "icons-png/32/cpu.png",
        width = 16, height = 16,
        color_hex = theme.telemetry.cpu or theme.accent,
        valign = "center",
    }

Icono de tab (color por estado):

    local icon = W.Icon.new {
        path = "icons-png/32/tab-cpu.png",
        width = 22, height = 22,
    }
    icon:set_color_hex(active and theme.fg_normal or theme.muted)

Icono clickeable:

    W.Icon.new {
        path = "icons-png/32/power.png",
        width = 24, height = 24,
        on_click = function() shutdown() end,
    }

Ver `examples/10-icon.lua`.

**Anti-patrón.**

- **Pasar una ruta a SVG.** `cairo.load_png_cached` falla con SVG (no es PNG). `self.surface` queda `nil` y el icono no dibuja nada. Para SVG en runtime, usar `lib.svg.load` y un widget propio.
- **Asumir que `set_path` a una ruta inválida limpia el icono.** Cambia `self.path`, intenta cargar, y si falla, deja `self.surface` con el PNG anterior. El icono sigue dibujando el PNG viejo. Si se quiere limpiar, llamar `set_path(nil)`.
- **Esperar que el icono crezca con el rect.** `max_w = width` y `max_h = height`. El icono ocupa exactamente el tamaño configurado. Para que se estire, modificar los máximos o envolver en un `Group` con `weight = 1`; el icono seguirá dibujando a su tamaño, centrado o alineado según `halign`/`valign`, con huecos.
- **Cambiar `width` o `height` después de construir.** Los mínimos y máximos no se recalculan. El `draw` usa el nuevo `width`/`height`, pero el layout sigue reservando el tamaño viejo. Reconstruir o modificar los mínimos/máximos a mano.
- **Confundir `on_click` con el patrón `Button`.** `Icon` dispara `on_click` al presionar (en `on_mouse_press`), no al completar el ciclo press + release como `Button`. Si se necesita el ciclo completo, usar otro widget o componer con `Button` de fondo transparente.

**Notas.**

- El cache global de PNG (`cairo.load_png_cached`) se libera con `cairo.clear_surface_cache()`. Llamar esto invalida todos los iconos cargados: los que tengan `self.surface` apuntando a un surface destruido dibujarán basura o fallarán. Solo llamar al desmontar todo el árbol.
- El tintado usa `cairo.draw_surface_tinted`, que colapsa el icono a un solo color preservando el alpha. Iconos multicolor tintados quedan monocromo.
- `set_color` con `nil` como primer argumento quita el tintado. `set_color(0, 0, 0)` pinta el icono en negro. No es lo mismo.
- Si `opts.color` y `opts.color_hex` se pasan juntos, `opts.color` gana. El `color_hex` solo se consulta si `color` es `nil`.
- `halign` y `valign` solo tienen efecto cuando el rect asignado es mayor que `width`/`height`. Si coinciden (el caso habitual), el icono se dibuja ocupando el rect completo.

---

#### closebutton.lua

**Propósito.**
Botón pequeño con una X dibujada con dos trazos cruzados. Uso típico: cerrar panel, cerrar popup, cerrar tab. Reacciona a hover y pressed con fondo de color y cambio de color del trazo.

**Alcance.**
Cubre un botón cuadrado con una X y estados visuales. No cubre botón con texto: para eso usar `Button` con `text = "X"`. No cubre botón con icono SVG/PNG: para eso usar `Icon` con `on_click`. No cubre otras formas (guiones, chevrons): la X está hardcodeada.

**Cómo funciona.**

`CloseButton.new` declara `_hover_visual = true` y `_pressed_visual = true` para repintar al cambiar de estado. Configura tres colores para el trazo: `color` (normal, gris muted por defecto), `color_hover` (blanco casi puro) y `color_pressed` (blanco puro). Y dos colores de fondo: `color_hover_bg` (`"#7a3030"`, rojo oscuro) y `color_pressed_bg` (`"#a04040"`, rojo más claro). Los colores de fondo son strings hex, no tablas `{r,g,b}`, porque se pasan a `G.hex_to_rgba`.

El widget es cuadrado: `min_w = min_h = max_w = max_h = size` (default 24). No crece ni se estira.

`draw` primero decide el fondo: si `pressed`, `color_pressed_bg`; si `hover`, `color_hover_bg`; si no, ninguno. Cuando hay fondo, dibuja un `rounded_rect` con `corner_radius` (default 4) y lo rellena. Luego decide el color del trazo según el mismo patrón (pressed > hover > normal). Dibuja la X con dos llamadas a `cairo.move_to` + `cairo.line_to` + `cairo.stroke`. Entre cada trazo hace `new_sub_path` para que Cairo no conecte el final del primero con el inicio del segundo. Al final `new_path` para limpiar el path pendiente y no contaminar el próximo dibujo del contenedor.

La X ocupa un cuadrado inscrito con margen `pad = size * 0.30`, dejando el 40% del tamaño como zona de dibujo. El grosor del trazo es 1.6, constante.

`on_mouse_press` dispara `opts.on_click` con el widget como argumento, solo si el botón es el izquierdo. Como `Icon`, dispara al presionar, no al completar el ciclo.

**API.**

**Construcción.**

- **`CloseButton.new(opts)`** — `opts.size` (default 24), `opts.color` (tabla `{r, g, b}`, default `{0.65, 0.65, 0.70}`), `opts.color_hover` (default `{0.95, 0.95, 0.95}`), `opts.color_pressed` (default `{1.0, 1.0, 1.0}`), `opts.color_hover_bg` (hex, default `"#7a3030"`), `opts.color_pressed_bg` (hex, default `"#a04040"`), `opts.corner_radius` (default 4), `opts.on_click`.

**Callbacks.**

- `on_click(self)` — disparado en `on_mouse_press` con botón 1.

**Campos.**

- `size` — tamaño del cuadrado.
- `color`, `color_hover`, `color_pressed` — tablas `{r, g, b}` del trazo.
- `color_hover_bg`, `color_pressed_bg` — strings hex del fondo.
- `corner_radius` — radio del fondo.

**Patrón.**

Botón de cierre en la cabecera de un panel:

    W.CloseButton.new {
        size = 24,
        on_click = function() self.window:close("close button") end,
    }

Botón de cierre con colores adaptados al theme:

    local bg_hover, _, _ = G.hex_to_rgba(theme.urgent)
    W.CloseButton.new {
        color       = theme.muted,
        color_hover = theme.fg_normal,
        color_hover_bg = theme.urgent,
    }

**Anti-patrón.**

- **Pasar `color_hover_bg` como tabla `{r, g, b}`.** El constructor espera un string hex para `color_hover_bg` y `color_pressed_bg`, y lo pasa a `G.hex_to_rgba`. Una tabla haría fallar `hex_to_rgba` (espera string). Los colores del trazo (`color`, `color_hover`, `color_pressed`) sí son tablas. La asimetría viene del uso interno de `set_rgb` vs `hex_to_rgba`.
- **Esperar que el botón crezca con el layout.** Igual que `Button`: tamaño fijo. Si el contenedor le da un rect mayor, la X se dibuja arriba a la izquierda y el resto queda vacío.
- **Cambiar `size` después de construir.** Los mínimos y máximos no se recalculan. Reconstruir.
- **Confundir el disparo al presionar con el ciclo completo.** `CloseButton` llama `on_click` en `on_mouse_press`. Es intencional para que el cierre sea inmediato al presionar, sin esperar al release. Si el usuario arrastra fuera antes de soltar, el cierre ya ocurrió.

**Notas.**

- La X se dibuja con dos trazos independientes con `new_sub_path` entre ellos. Sin el `new_sub_path`, Cairo conectaría el final del primero con el inicio del segundo, dibujando una línea extra. `notes.md` documenta el patrón general de `cairo_arc` y arcos consecutivos; el mismo cuidado aplica a líneas.
- El `new_path` al final limpia el path pendiente. Sin él, el próximo widget que haga `cairo.stroke` sin `new_path` previo podría dibujar el path anterior. Es defensivo.
- El `color_hover_bg` default (`#7a3030`) es un rojo oscuro que armoniza con temas oscuros. Los temas claros van a querer cambiarlo.
- Como `Icon`, `CloseButton` no participa en el ciclo de click completo del `Window`. Esto significa que el usuario no puede "arrepentirse" arrastrando el cursor fuera antes de soltar.

---

#### cardbutton.lua

**Propósito.**
Tarjeta de opción: icono PNG grande arriba, título y subtítulo debajo. Hover animado por interpolación de color de fondo y de texto. Pensado para grids de modos, opciones y menús visuales.

**Alcance.**
Cubre un icono, un título, un subtítulo opcional, hover animado, y un estado `selected` con borde accent. No cubre layouts horizontales (icono al lado del texto): el icono va siempre arriba. No cubre múltiples iconos. No cubre estados `disabled`. No cubre click secundario (solo botón 1).

**Cómo funciona.**

`CardButton.new` guarda los colores como strings `#rrggbb` y los convierte internamente a tablas `{r, g, b}` de floats `[0, 1]` con `G.hex_to_rgba`. Al construir carga el icono con `cairo.load_png_cached` (cache global de PNGs del módulo `cairo`).

El estado de hover se anima con `anim.tween_custom`. En `set_hover(true)` se lanza un tween de `hover_t` de `0` a `1` en 180 ms con easing `out_cubic`. En `set_hover(false)` se anima de vuelta. Si el motor de animación no está inicializado (`anim.is_ready() == false`), el `hover_t` se setea directo sin animación.

`draw` interpola tres cosas con `hover_t`:

- **Fondo**: `mix(bg_color, hover_color, t)`.
- **Texto (título)**: `mix(fg_color, fg_dark_color, t)`. El título pasa de claro a negro a medida que avanza el hover.
- **Subtítulo**: `mix(fg_sub_color, fg_dark_color, t)`. También oscurece.
- **Icono**: se dibuja con `cairo.draw_surface_tinted` con el color `fg` interpolado, así que también oscurece con el hover. El tintado preserva el alpha del PNG.

El borde se dibuja con `rounded_rect` offset `+0.5` y dimensiones reducidas en 1 px (borde normal) o con `+1` y dimensiones reducidas en 2 px (borde `selected`, 2 px de grosor).

El layout interno centra el bloque (icono + gap + título + gap + subtítulo) verticalmente y cada elemento horizontalmente. Los gaps son 6 px entre icono y título, 3 px entre título y subtítulo.

`selected` es un flag booleano. Cuando es `true`, el borde usa `accent_color` con 2 px de grosor en lugar del borde normal. No hay cambio de fondo ni de texto por `selected`: solo el borde.

**API.**

**Construcción.**

- **`CardButton.new(opts)`** — campos:
  - `opts.icon` — nombre del PNG sin extensión.
  - `opts.icon_dir` — directorio donde están los PNGs (con `/` final).
  - `opts.icon_size` — tamaño del icono en px (default 48).
  - `opts.title` — texto del título.
  - `opts.subtitle` — texto del subtítulo (opcional).
  - `opts.bg_color` — fondo normal (hex, default `"#13171f"`).
  - `opts.hover_color` — fondo en hover (hex, default `"#1a1f28"`).
  - `opts.fg_color` — color del título normal (hex, default `"#bfbdb6"`).
  - `opts.fg_dark_color` — color del título en hover (hex, default `"#000000"`).
  - `opts.fg_sub_color` — color del subtítulo normal (hex, default `"#565b66"`).
  - `opts.border_color` — borde normal (hex, default `"#242a35"`).
  - `opts.accent_color` — borde cuando `selected` (hex, default `"#e6b450"`).
  - `opts.corner_radius` — radio (default 8).
  - `opts.font_title` — fuente Pango del título (default `"DejaVu Sans Bold 11"`).
  - `opts.font_sub` — fuente del subtítulo (default `"DejaVu Sans 9"`).
  - `opts.width`, `opts.height` — tamaño del card (defaults 200, 110).
  - `opts.on_click` — callback.

**Métodos.**

| Método | Notas |
|---|---|
| `set_hover(v)` | Override de `Area:set_hover`. Dispara el tween de `hover_t`. |

**Campos.**

- `selected` — booleano. Se puede cambiar en runtime y llamar `:damage()` para reflejar el cambio.
- `hover_t` — valor interpolado `[0, 1]`. Lectura, no escritura directa.

**Patrón.**

Grid de opciones con colores por hover:

    local CardButton = require("lib.widgets.cardbutton")
    local cb = CardButton.new {
        icon       = "tab-foto",
        icon_dir   = "/path/to/icons/",
        title      = "Foto",
        subtitle   = "captura instantánea",
        bg_color   = "#13171f",
        hover_color= "#5aa8ff",
        fg_color   = "#bfbdb6",
        fg_dark_color = "#000000",
        on_click   = function() do_photo() end,
    }

Marcar uno como seleccionado y actualizar el resto:

    for _, btn in ipairs(buttons) do
        btn.selected = (btn._key == current_key)
        btn:damage()
    end

Ver `lib/tabs/screenshot.lua` para el uso real en la grid de modos y la fila de calidad.

**Anti-patrón.**

- **Pasar `bg_color` como tabla `{r,g,b}`.** `CardButton` espera strings hex y los convierte internamente. Una tabla haría fallar `G.hex_to_rgba`. El tema del toolkit tiene ambos formatos: usar `_rgb` del theme solo si el widget lo pide, o convertir con `string.format("#%02x%02x%02x", ...)` antes de pasarlo.
- **Esperar que `selected` cambie el fondo.** Solo cambia el borde. Para un cambio de fondo hay que mutar `bg_color` a mano y llamar `:damage()`.
- **Llamar `set_hover` sin motor de animación.** Sin `anim.init(srv)` previo, el hover no se anima: pasa de golpe. No es un error, pero se pierde el efecto.
- **Tintar el icono con colores que no contrasten.** Como el `fg_dark_color` es negro por default y el `hover_color` suele ser un color vivo (azul, verde, turquesa), el resultado es un icono negro sobre fondo vivo. Si el hover_color es oscuro, el icono queda invisible. Elegir `fg_dark_color` acorde al hover_color.
- **Ignorar el tamaño al construir.** `CardButton` no crece: `min == max` en ambos ejes. Si el grid necesita 3 columnas de 132 px, hay que pasar `width = 132` a cada uno. El `Group` que los contiene les da exactamente ese tamaño.

**Notas.**

- `icon_dir` se concatena directo al `icon` más `.png`. Si el `icon_dir` no termina en `/`, el path queda mal.
- El icono se carga con `cairo.load_png_cached`, así que dos CardButton con el mismo icono comparten el mismo surface en memoria.
- El borde `selected` de 2 px se dibuja con offset `+1` y dimensiones reducidas en 2. Los bordes de 1 px usan `+0.5` y reducen 1. Es el patrón general del toolkit para que el trazo caiga dentro del rect.

#### rowparse.lua

**Propósito.**
Helper compartido por los widgets que aceptan filas en dos formatos: tabla con claves (`{ id = ..., label = ... }`) o array posicional (`{ "id", "label" }`). Normaliza la entrada y devuelve los valores en el orden pedido.

**Alcance.**
Cubre dos formatos de fila y la extracción de N campos por posición. No cubre valores por defecto: si un campo falta, el consumidor recibe `nil`. No cubre validación de tipos: los valores se devuelven tal cual. No cubre ordenamiento ni filtrado: es puro parseo.

**Cómo funciona.**

`M.parse(row, keys)` recibe la fila y una lista de claves. La lógica es:

1. Si `row[keys[1]]` no es `nil`, se trata como tabla con claves. Recorre `keys` en orden, extrae cada valor y los devuelve como valores sueltos con `unpack`.
2. Si no, se trata como array posicional. Recorre del `1` a `#keys` extrayendo `row[i]` y devuelve también como valores sueltos.

El criterio de detección es la presencia de la primera clave. Si la fila tiene `id` como campo (o la primera clave de `keys` si es distinta), se toma como tabla con claves. Si no, se toma como array. Es una decisión pragmática: los dos formatos son mutuamente excluyentes en la práctica, y la primera clave sirve como discriminante.

`unpack(out, 1, #keys)` es importante porque `unpack` sin límites devuelve hasta el primer `nil` según el `#` del array. Forzar `1, #keys` garantiza que se devuelven exactamente N valores, con `nil` en las posiciones que falten. Sin este límite, un campo ausente en medio cortaría el retorno.

**API.**

**Funciones.**

- **`M.parse(row, keys?)`** — Normaliza una fila. `keys` default `{ "id", "label" }`. Devuelve tantos valores como `#keys`.

**Patrón.**

Widget que acepta filas en los dos formatos:

    local RowParse = require("lib.widgets.rowparse")

    function Rows:add_row(row)
        local id, label, extra = RowParse.parse(row, { "id", "label", "extra" })
        -- id y label están garantizados
        -- extra puede ser nil
        ...
    end

Llamadas del consumidor:

    -- Formato con claves
    rows:add_row { id = "cpu", label = "CPU", extra = "40%" }

    -- Formato posicional
    rows:add_row { "cpu", "CPU", "40%" }

Ver `rows.lua`, `kv.lua`, `barrow.lua`, `actions.lua` para el uso.

**Anti-patrón.**

- **Asumir que `keys` puede cambiar entre llamadas con el mismo widget.** El `parse` es puro y stateless, pero el consumidor debe usar las mismas claves en cada llamada para que las filas se interpreten igual. Mezclar formatos con claves distintas en el mismo widget lleva a filas interpretadas de forma inconsistente.
- **Pasar una fila vacía (`{}`).** `row[keys[1]]` es `nil`, así que cae al formato posicional. Extrae `row[1]` (también `nil`). Devuelve una lista de `nil`. El widget que lo consume debe estar preparado para valores `nil`, o validar antes de llamar.
- **Pasar `keys` con claves repetidas.** No hay validación: la primera ocurrencia en el bucle gana y las demás se ignoran silenciosamente. No es un error frecuente, pero si se detecta comportamiento raro, revisar `keys`.
- **Confiar en el formato posicional para tablas que mezclan campos.** Una fila como `{ id = "x", "algo" }` no es válida: Lua la trata como tabla con `id` más un valor en la posición `1` del array implícito, pero la construcción es sintácticamente rara y no está soportada por `parse`. Elegir uno de los dos formatos por fila.

**Notas.**

- El `unpack` con límite explícito (`1, #keys`) garantiza el número de valores devueltos aunque haya `nil` en medio. Sin él, `#` sobre un array con `nil` en medio es indefinido.
- `parse` no modifica la fila. El consumidor puede conservar la referencia y usarla en otro sitio.
- El módulo es puro: no tiene estado, no depende de `Area` ni de otras clases. Se puede importar desde cualquier widget.
- Los widgets del toolkit que lo usan declaran en su comentario de cabecera que aceptan ambos formatos, y el `parse` hace la traducción. Es un punto de extensión si en el futuro se quiere añadir otro formato (por ejemplo, `{ id, label, { color = ... } }`).

---

#### ring.lua

**Propósito.**
Anillo de progreso con texto centrado. Muestra un valor `0..1` como arco sobre un anillo base, con un texto principal y un texto secundario dentro del círculo. Pensado para telemetría: CPU, RAM, batería.

**Alcance.**
Cubre anillo con progreso, colores configurables, grosor, dos fuentes de texto centradas. Cubre opcionalmente un `raw_range` para mapear valores crudos a `0..1` sin que el consumidor tenga que normalizar antes. No cubre múltiples anillos concéntricos. No cubre anillos parciales con ángulos personalizados: siempre recorre desde arriba (`-π/2`) en sentido horario. No cubre ticks ni marcas en la circunferencia.

**Cómo funciona.**

`Ring.new` guarda el valor inicial (`0..1`), el `text` principal, el `sub` secundario, el grosor del anillo (`thickness`), dos colores (del arco y del fondo del anillo), las fuentes y colores del texto. El tamaño mínimo es `size` (default 140) en ambos ejes; los máximos se liberan a `10000` para que el anillo pueda crecer hasta el rect asignado por el padre. `notes.md` documenta el caso: sin liberar `max_w`/`max_h`, los anillos quedan con huecos a su alrededor en `Card` y `Group`.

`raw_range` es opcional. Si se pasa `{ min, max }`, el `set_value` interpreta el primer argumento como un valor en ese rango y lo normaliza a `0..1` antes de guardarlo en `self.value`. Guarda además el valor crudo en `self.raw_value` para que el consumidor pueda consultarlo. `notes.md` documenta esta decisión: permite pasar `set_value(3500, "3.5 GHz")` y que el anillo se llene proporcionalmente a un rango `{0, 5000}` sin que el consumidor haga la división.

`set_value(v, text, sub)` actualiza los tres campos. Cada argumento `nil` deja el campo correspondiente sin tocar, así que `set_value(0.5)` solo cambia el valor. Si algo cambió, daña. Si nada cambió, no daña: es una optimización contra llamadas repetidas desde un timer con el mismo valor.

`draw` calcula el centro del rect, el radio útil (`min(ancho, alto)/2 - thickness/2 - 2`) y retorna sin dibujar si el radio es menor que 5 px (el anillo no cabría). Dibuja el anillo base como un arco completo de `0` a `2π` con `color_bg`, con `new_sub_path` previo para no contaminar el path anterior. Luego, si `value > 0`, dibuja el arco de progreso desde `-π/2` (arriba del círculo) recorriendo `value * 2π` en sentido horario. El color del arco es `color`. Finalmente dibuja el texto centrado: primero el `text` principal con `value_font`, luego el `sub` si no está vacío con `sub_font`. La posición vertical se calcula sumando las alturas para que el bloque completo quede centrado en el círculo.

**API.**

**Construcción.**

- **`Ring.new(opts)`** — `opts.value` (0..1, default 0), `opts.raw_range` (tabla `{min, max}` opcional), `opts.text` (default `"0"`), `opts.sub` (default `""`), `opts.thickness` (default 10), `opts.color` (tabla `{r, g, b}` del arco, default verde), `opts.color_bg` (tabla `{r, g, b}` del anillo base, default gris oscuro), `opts.value_font` (default `"DejaVu Sans Bold 22"`), `opts.sub_font` (default `"DejaVu Sans 10"`), `opts.value_color` (default blanco), `opts.sub_color` (default gris), `opts.size` (default 140).

**Métodos.**

| Método | Notas |
|---|---|
| `set_value(v, text, sub)` | Actualiza los campos no-`nil`. Solo daña si algo cambió. |
| `animate_to(v, text, sub, duration?)` | Actualiza `text`/`sub` inmediatamente y anima `self.value` desde su valor actual al nuevo en `duration` ms (default 700). Cancela una animación previa si la hay. Sin motor listo, cae a `set_value`. |

**Campos.**

- `value` — valor normalizado (`0..1`).
- `reveal` — factor de reveal (0..1). Multiplica el ángulo del arco del
  valor sin tocar el texto. Default `1.0`. Animado por `Intro.play`.
- `_anim_handle` — handle del tween de `animate_to` en curso. Cancelable.
- `raw_value` — último valor crudo pasado a `set_value`, si hay `raw_range`.
- `raw_range` — tabla `{min, max}` o `nil`.
- `text`, `sub` — textos.
- `thickness`, `color`, `color_bg`, `value_font`, `sub_font`, `value_color`, `sub_color`.

**Patrón.**

Anillo con rango crudo (por ejemplo, temperatura de 0 a 100°C):

    local ring = W.Ring.new {
        raw_range = { 0, 100 },
        thickness = 8,
        color = { 0.4, 0.75, 0.55 },
        size = 120,
    }
    ring:set_value(45, "45°C")

Anillo con color cambiando por umbral (recrear el color del arco en cada tick):

    local color = pct > 0.9 and { 0.9, 0.3, 0.3 }
               or pct > 0.7 and { 0.95, 0.75, 0.3 }
               or { 0.4, 0.75, 0.55 }
    ring.color = color
    ring:set_value(pct, string.format("%d%%", math.floor(pct * 100)))

Ver `examples/13-tab-cpu.lua` y `examples/15-tab-ram.lua`.

**Anti-patrón.**

- **Pasar un valor fuera de `[0, 1]` sin `raw_range`.** El valor se clampea silenciosamente en `set_value`, pero si el consumidor no normaliza puede estar pasando porcentajes (0..100) esperando que el anillo lo interprete. Sin `raw_range`, el anillo asume `0..1`.
- **Asumir que `set_value` con el mismo valor repinta.** Si los tres argumentos coinciden con los actuales, no daña. Es intencional: llamadas repetidas desde un timer con el mismo valor no gastan CPU. Si se necesita forzar un repintado, llamar `self:damage()` directamente.
- **Cambiar `thickness` o `size` después de construir.** Los mínimos y máximos se fijan en el constructor. El `draw` sí usa el nuevo `thickness` para calcular el radio, pero el layout sigue reservando `size`. Reconstruir o ajustar los mínimos a mano.
- **Esperar que `raw_range` actualice el texto.** El `raw_range` solo afecta al `self.value` normalizado. El `text` se pasa como string en la llamada a `set_value` y no se recalcula desde `self.raw_value`. El consumidor formatea el texto por su cuenta.
- **Poner `thickness` mayor que el radio.** El `draw` retorna sin dibujar si el radio resultante es menor que 5. Un anillo con `thickness` cercano al `size` no dibuja nada visible.

**Notas.**

- El arco de progreso con `value = 1` recorre `2π` completo, superponiéndose al arco base. El efecto visual es el mismo que un círculo lleno.
- El ángulo de inicio es fijo (`-π/2`, 12 en punto). No hay forma de cambiarlo sin modificar el widget.
- El sentido del arco es horario. No hay opción de antihorario.
- El texto centrado se compone de dos líneas como máximo: `text` arriba, `sub` abajo. No hay opción de más líneas: para eso, componer con un `Group` sobre el anillo.
- El `draw` hace `pango.measure` de los textos en cada llamada. Para widgets con timer de refresco corto, la medición se repite sin cambios. Aceptable dado que solo son dos textos cortos.
- El comentario de código tiene una línea duplicada (`if r < 5 then return end` dos veces). No es un bug funcional, es ruido. `notes.md` no lo menciona.

---

#### spark.lua

**Propósito.**
Sparkline con un solo canal de datos. Muestra un historial de muestras como línea (con relleno opcional), con soporte para grid, etiquetas del eje Y, y rango fijo o autocalculado.

**Alcance.**
Cubre un historial circular de muestras, dibujo de línea con relleno opcional, grid horizontal, etiquetas del eje Y con formato configurable, ancho reservado para las etiquetas. No cubre dos series: eso es `dualspark.lua`. No cubre ejes X con etiquetas de tiempo. No cubre puntos marcados en la línea. No cubre zoom ni interacción.

**Cómo funciona.**

`Spark.new` guarda el número de muestras (`samples`, default 60), el rango (`min`, `max`, ambos opcionales), el color (`color`, string hex), el flag `fill` (default `true`), el formato de las etiquetas (`axis_format`, opcional), el ancho reservado al eje (`axis_width`), y el flag `grid`. Crea un objeto `G.history(samples)` para el buffer circular. Los mínimos son `opts.min_width`/`opts.min_height` (defaults 100×80); los máximos, `opts.max_width`/`opts.max_height` (defaults 10000).

`push(v)` añade una muestra al historial y daña. `set_range(vmin, vmax)` cambia el rango y daña. `clear()` vacía el historial y daña.

`draw` calcula el área útil restando `axis_width` a la izquierda. Si `grid` está activo, dibuja tres líneas horizontales a `1/4`, `2/4` y `3/4` del alto con color `"#3c3836"` y alpha `0.5`. Si `axis_format` está definido y `min_v`/`max_v` no son `nil`, dibuja dos etiquetas: `max_v` arriba y `min_v` abajo, formateadas con `string.format(axis_format, valor)` y dibujadas con `"DejaVu Sans 8"` en gris. Finalmente dibuja la sparkline con `G.sparkline`, pasando `min` y `max` (que pueden ser `nil` para autocalcular del historial). Si el historial tiene menos de dos muestras, dibuja `"Recolectando..."` centrado verticalmente.

**API.**

**Construcción.**

- **`Spark.new(opts)`** — `opts.samples` (default 60), `opts.min`, `opts.max` (opcionales, autocalcula si no), `opts.color` (hex, default `"#8ec07c"`), `opts.fill` (default `true`), `opts.axis_format` (formato `string.format`, por ejemplo `"%d%%"`), `opts.axis_width` (px reservados al eje, default 0), `opts.grid` (default `false`), `opts.min_width` (default 100), `opts.min_height` (default 80), `opts.max_width`, `opts.max_height`.

**Métodos.**

| Método | Notas |
|---|---|
| `push(v)` | Añade una muestra. Daña. |
| `set_range(vmin, vmax)` | Fija el rango. Daña. |
| `clear()` | Vacía el historial. Daña. |

**Campos.**

- `samples` — tamaño del buffer.
- `min_v`, `max_v` — rango actual (`nil` si autocalcula).
- `color`, `fill`, `axis_format`, `axis_width`, `grid`.
- `history` — objeto `G.history`.

**Patrón.**

Sparkline de uso de CPU con rango 0..100:

    local spark = W.Spark.new {
        samples = 60,
        min = 0,
        max = 100,
        color = "#8ec07c",
        axis_format = "%d%%",
        axis_width = 30,
        grid = true,
    }

    -- En cada tick del timer:
    spark:push(cpu_pct * 100)

Sparkline sin rango fijo (autocalcula al máximo del historial):

    W.Spark.new {
        samples = 30,
        color = "#83a598",
        fill = false,
    }

Ver `examples/13-tab-cpu.lua`.

**Anti-patrón.**

- **Pasar un color en formato `{r, g, b}` en vez de hex.** El `color` se pasa tal cual a `G.sparkline`, que lo interpreta como hex. Una tabla haría fallar `hex_to_rgba` dentro de `sparkline`. Solo `color_bg` de Ring usa tabla; los widgets que delegan en `graphics.sparkline` usan hex.
- **Asumir que el widget sin `min`/`max` tiene un rango estable.** Con autocalculado, el rango se recalcula del historial en cada `draw`. Un pico aislado hace que la línea se comprima en los frames siguientes. Para telemetría estable (CPU, RAM con rango 0..100), fijar `min` y `max`.
- **Pasar `axis_format` sin `axis_width`.** Las etiquetas se dibujan sobre la línea. El `axis_format` no reserva espacio por sí solo: hay que dar `axis_width` para que la sparkline empiece más a la derecha.
- **Pasar `axis_format` sin `min`/`max`.** Las etiquetas del eje usan `self.min_v` y `self.max_v`, que pueden ser `nil` si no se fijaron. La guarda `if self.axis_format and self.min_v and self.max_v` protege, pero el consumidor no verá etiquetas.
- **Llamar `push` desde varios timers.** El historial es compartido, no hay sincronización. Si dos timers pulsan al mismo Spark, el orden de las muestras en el buffer depende del orden de ejecución de los callbacks.

**Notas.**

- El buffer circular no se llena completamente hasta que se han hecho `samples` llamadas a `push`. Hasta entonces, `#data` es menor que `samples` y la línea se dibuja solo con los datos disponibles.
- `G.sparkline` requiere al menos 2 puntos. Spark dibuja `"Recolectando..."` hasta tener 2. El primer push no dibuja nada visible.
- El relleno (con `fill = true`) usa un alpha fijo de `0.18` del color de la línea. No es configurable desde `Spark`.
- Las etiquetas del eje Y van siempre a la izquierda, alineadas al borde izquierdo del rect. No hay opción de ponerlas a la derecha.
- El grid solo tiene líneas horizontales (a `1/4`, `2/4`, `3/4` del alto). No hay grid vertical.
- La fuente de las etiquetas del eje (`"DejaVu Sans 8"`) está hardcodeada. Para otro tamaño, modificar el widget.

---


**Animaciones (2026-09-25).**

Campos nuevos:

- `alpha` (0..1) — opacidad global. Se pasa a `G.sparkline`.
- `reveal` (0..1) — recorte horizontal, para el efecto "dibujarse de
  izquierda a derecha".
- `tail` (0..1) — trazo progresivo del último segmento.
- `scroll` (0..1) — desplazamiento global del sparkline.
- `_anim_pending` — flag interno. El `Intro` lo setea a `true`;
  `Spark:push` / `Spark:push_animated` disparan el fade in cuando
  llega el primer dato (>= 2 puntos).
- `_push_handle` — handle del tween de `push_animated`.
- `_anim_kind = "spark"` — tipo para `Intro`.

**Métodos nuevos.**

- **`push_animated(v, duration?)`** — Empuja un valor y, si el buffer
  ya tiene >= 1 punto antes del push:
  - **Buffer en llenado** (`count < samples`): anima solo `tail`
    (0 → 1). La línea nueva se dibuja de izquierda a derecha sin mover
    los puntos previos.
  - **Buffer lleno** (`count == samples`): anima `tail` (0 → 1) y
    `scroll` (1 → 0) juntos en el mismo tween. El contenido se desliza
    `dx` a la izquierda mientras el nuevo segmento se traza, sin salto.

  Si el motor no está listo, cae a `Spark:push` normal.

- **`push(v)`** — Empuje sin animación. Resetea `tail`/`scroll` por si
  venía un `push_animated` cancelado a mitad.

#### dualspark.lua

**Propósito.**
Sparkline con dos canales de datos superpuestos. La serie A se dibuja con relleno por defecto, la serie B como línea encima. Pensado para comparaciones del estilo "descarga vs subida", "lectura vs escritura", "uso vs límite".

**Alcance.**
Cubre dos historiales independientes, rango común (fijo o autocalculado), relleno independiente por serie, grid, etiquetas del eje Y. No cubre más de dos series: para tres o más, escribir un widget propio. No cubre eje X compartido con etiquetas de tiempo. No cubre leyenda: el consumidor dibuja la leyenda aparte si la necesita.

**Cómo funciona.**

`DualSpark.new` mantiene dos objetos `G.history` (`history_a`, `history_b`) del mismo tamaño `samples` (default 60). Los colores son independientes (`color_a` con relleno por defecto, `color_b` sin relleno por defecto). El flag `auto_max` (default `true`) hace que el máximo del eje se calcule del máximo entre ambas series en cada `draw`, con un margen del 10% hacia arriba para que la línea no quede pegada al borde. `floor_max` (default 0) es el valor mínimo que puede tomar el máximo calculado: evita que dos series planas con valores bajos se vean como líneas gruesas pegadas arriba.

`_effective_range` calcula el rango efectivo. Si `auto_max` está activo, recorre ambas series buscando el máximo, lo compara con `floor_max`, aplica el margen del 10%, y devuelve `(min, max)`. Si `auto_max` está desactivado, usa `min_v` y `max_v` tal cual (con defaults `0` y `1` si no se pasan). Guarda contra el caso `vmax <= vmin` forzando `vmax = vmin + 1`.

`push_a(v)` y `push_b(v)` añaden muestras a los historiales correspondientes y dañan. `set_range(vmin, vmax)` cambia el rango fijo. `clear()` vacía ambos historiales.

`draw` calcula el rango efectivo, dibuja grid y etiquetas del eje Y si están configurados (igual que `Spark`), luego la serie A con `G.sparkline`, luego la serie B. El orden importa: la serie A se dibuja primero, con su relleno, y la serie B encima como línea. Si ambas series tienen menos de 2 muestras, dibuja `"Recolectando..."`.

**API.**

**Construcción.**

- **`DualSpark.new(opts)`** — `opts.samples` (default 60), `opts.color_a` (hex, default `"#8ec07c"`), `opts.color_b` (hex, default `"#e06060"`), `opts.fill_a` (default `true`), `opts.fill_b` (default `false`), `opts.auto_max` (default `true`), `opts.min`, `opts.max` (ignorado si `auto_max`), `opts.floor_max` (default 0), `opts.axis_width`, `opts.axis_format`, `opts.grid`, `opts.min_width` (default 100), `opts.min_height` (default 80), `opts.max_width`, `opts.max_height`.

**Métodos.**

| Método | Notas |
|---|---|
| `push_a(v)` | Añade muestra a la serie A. Daña. |
| `push_b(v)` | Añade muestra a la serie B. Daña. |
| `set_range(vmin, vmax)` | Fija el rango. Daña. Ignorado si `auto_max` activo. |
| `clear()` | Vacía ambos historiales. Daña. |

**Campos.**

- `samples`, `color_a`, `color_b`, `fill_a`, `fill_b`.
- `auto_max`, `min_v`, `max_v`, `floor_max`.
- `axis_width`, `axis_format`, `grid`.
- `history_a`, `history_b`.

**Patrón.**

Red con descarga (rellena) y subida (línea):

    local net = W.DualSpark.new {
        samples = 60,
        color_a = "#8ec07c",
        color_b = "#d3869b",
        fill_a = true,
        fill_b = false,
        auto_max = true,
        axis_format = "%.1f",
        axis_width = 40,
    }

    -- En el timer:
    net:push_a(download_kb)
    net:push_b(upload_kb)

Comparación lectura/escritura con rango fijo:

    W.DualSpark.new {
        min = 0,
        max = 1000,
        auto_max = false,
        color_a = "#83a598",
        color_b = "#fabd2f",
    }

**Anti-patrón.**

- **Pasar `color_a` o `color_b` como `{r, g, b}`.** Igual que `Spark`, van como strings hex a `G.sparkline`, que los interpreta con `hex_to_rgba`.
- **Esperar que `set_range` funcione con `auto_max` activo.** `set_range` cambia `min_v` y `max_v`, pero `_effective_range` los ignora cuando `auto_max` está activo. Para que `set_range` tenga efecto, construir con `auto_max = false`.
- **Pasar `floor_max` mayor que el máximo real esperado.** El margen del 10% se aplica sobre `floor_max` si el máximo real es menor. Un `floor_max` alto comprime la serie cerca de cero. Es el comportamiento buscado cuando el rango real es bajo: sin él, cualquier variación se ve como un pico enorme.
- **Asumir que `push_a` y `push_b` se llaman siempre juntas.** No hay sincronización: los dos historiales pueden tener longitudes distintas si una serie se actualiza menos. El `draw` dibuja cada uno con la longitud que tenga. Para series que deben ir sincronizadas, llamar a los dos en el mismo tick.
- **Poner `fill_a` y `fill_b` en `true` al mismo tiempo.** La serie A tapa parcialmente a la B porque se dibuja primero. Con ambos rellenos, el efecto visual suele ser confuso. Elegir una de las dos con relleno.

**Notas.**

- El margen del 10% hacia arriba solo se aplica cuando `auto_max` está activo. Con rango fijo, la serie llega exactamente a `max_v` si el valor lo alcanza.
- `auto_max` recorre ambas series en cada `draw` para encontrar el máximo. Con `samples` grande (cientos) y timers cortos, el coste se nota. Para historiales largos, fijar `min`/`max`.
- El `floor_max` por defecto es 0. Con dos series que siempre están a 0, el rango efectivo queda en `0..1` tras el guard `vmax <= vmin`. Es correcto pero poco informativo: las dos series se ven planas abajo.
- El orden de dibujo es A primero, B encima. La serie B siempre es la que "gana" visualmente si se superponen. En el patrón descarga/subida, la descarga (A) es la que se ve como área, la subida (B) como línea encima.
- El widget no dibuja leyenda. Si el consumidor necesita mostrar qué color es qué serie, lo hace con dos `Text` pequeños al lado o envuelve el `DualSpark` en un `Group` con cabecera.

---


**Animaciones (2026-09-25).**
Mismo esquema que `Spark`:

- Campos `alpha`, `reveal`, `tail`, `scroll`, `_anim_pending`,
  `_push_handle`, `_anim_kind = "dualspark"`.
- **`push_a_animated(v, duration?)`** — anima la serie A con
  `tail`+`scroll` igual que `Spark:push_animated`. La serie B se
  empuja con `push_b` normal.
- **Importante**: `push_b` **no** toca `tail`/`scroll`. Si los
  reseteara, pisaría el tween de `push_a_animated` cuando
  `conexion.lua` llama los dos en el mismo tick.

#### kv.lua

**Propósito.**
Lista de pares clave-valor con las columnas alineadas. Pensado para mostrar tablas de datos estáticos como "Fabricante: Intel", "Modelo: i7-9750H", "Núcleos: 6". El label va a la izquierda, el valor alineado a la derecha.

**Alcance.**
Cubre filas de dos columnas (label y valor) con formato consistente, medición de ancho de columna para que todas las filas se alineen, y actualización de valores en runtime. No cubre más de dos columnas: para eso, usar `Rows` (tres columnas: grupo, nombre, valor). No cubre ordenamiento, filtrado ni selección. No cubre paginación: la lista se dibuja entera.

**Cómo funciona.**

`KV.new` guarda las fuentes y colores de label y valor, la altura de fila (`row_height`), el padding, y una tabla `rows` vacía. `add_row(id, label, format)` añade una fila con su id, label, y formateador opcional. El formato puede ser una función que recibe el valor crudo y devuelve el string a mostrar.

`_rebuild` mide los labels con `pango.measure` para calcular el ancho de la columna del label. Este ancho determina dónde empieza la columna del valor, para que todos los valores queden alineados verticalmente. El cálculo se hace una vez por `_rebuild`, que se llama tras `add_row` o tras un cambio de contenido.

`set(id, value)` busca la fila por id y actualiza su valor, aplicando el formateador si lo hay. `set_markup(id, markup)` hace lo mismo pero con markup Pango directo. `askMinMax` devuelve la suma de las alturas de todas las filas más padding, y el ancho combinado de las columnas.

`layout` reparte el rect entre las filas: cada una ocupa una franja horizontal de `row_height` px, con el label a la izquierda y el valor alineado a la derecha.

`draw` recorre las filas y dibuja el label y el valor. Mide el valor con `pango.measure` para calcular la posición de alineación a la derecha (`x1 - valor_w`). El label se dibuja alineado a la izquierda desde `x0 + padding`.

`set_title(markup)` es un no-op: existe por compatibilidad con otros widgets pero no dibuja título. El consumidor que necesite título usa un `Header` o un `Card` con título.

**API.**

**Construcción.**

- **`KV.new(opts)`** — `opts.font_key` (default `"DejaVu Sans 10"`), `opts.font_value` (default `"DejaVu Sans 10"`), `opts.color_key` (tabla `{r, g, b}`, default gris muted), `opts.color_value` (tabla `{r, g, b}`, default blanco casi puro), `opts.row_height` (default 20), `opts.padding` (default 4).

**Métodos.**

| Método | Notas |
|---|---|
| `add_row(id, label, format?)` | Añade una fila. `format` es una función `function(value) -> string` o `nil`. |
| `set_alpha(a)` | Aplica un multiplicador de alpha (0..1) a los colores base del texto. Recalcula desde `key_color`/`value_color` para no acumular atenuación. Animado por `Intro.play`. |
| `set(id, value)` | Actualiza el valor. Aplica el formateador. |
| `set_markup(id, markup)` | Actualiza con markup Pango. |
| `set_title(markup)` | No-op. |
| `set_window(win)` | Propaga `window` (por compatibilidad, `KV` no tiene hijos reales). |

**Patrón.**

KV con formateador por fila:

    local kv = W.KV.new {
        row_height = 22,
    }
    kv:add_row("cpu", "CPU", function(v) return v .. "%" end)
    kv:add_row("ram", "RAM", F.mb)
    kv:add_row("disk", "Disco", function(v) return F.bytes(v) end)

    -- En el timer:
    kv:set("cpu", cpu_pct * 100)
    kv:set("ram", ram_kb)
    kv:set("disk", disk_bytes)

KV sin formateador, valores directos:

    kv:add_row("kernel", "Kernel")
    kv:set("kernel", "6.6.30")

Ver `examples/13-tab-cpu.lua`.

**Anti-patrón.**

- **Asumir que `set` aplica el formateador automáticamente sin haberlo pasado en `add_row`.** El formateador se guarda con la fila. Sin él, el valor se pasa a `pango.draw_text` sin conversión. Un número entero pasado como valor se dibujará como número si Pango lo acepta (Lua lo convierte a string en la mayoría de los casos), pero es mejor formatear siempre.
- **Llamar `set_title` esperando que dibuje un título.** Es un no-op. El título, si se necesita, va en un `Card` que envuelva al `KV` o en un `Header` hermano.
- **Añadir filas después de que el KV esté en el layout sin `invalidate_layout`.** El `_rebuild` de `add_row` recalcula el tamaño, pero el padre no se entera hasta el próximo `askMinMax`. Llamar `invalidate_layout` en el contenedor tras añadir filas en runtime.
- **Asumir que el label se envuelve.** Un label demasiado largo no cabe: el ancho de la columna lo determina el más largo de todos. Si un label es ancho y los demás cortos, la columna del valor empieza muy a la derecha. Acortar el label o usar `Rows` con columnas.

**Notas.**

- El `color_key` y el `color_value` son tablas `{r, g, b}`, no strings hex. Se pasan directamente a `pango.draw_text` como `opts.r`, `opts.g`, `opts.b`.
- `row_height` es fijo. Todas las filas tienen el mismo alto. Para filas de alturas variables, usar `Group` con hijos heterogéneos.
- El `format` es una función que se llama en cada `set`. Si el formateo es caro (por ejemplo, acceso a disco), no hacerlo aquí. El formateo esperado es conversión de número a string.
- `set_markup` permite pasar markup Pango directamente (por ejemplo, con `<b>` o `<span color=...>`). Es útil para resaltar valores en color.
- El `KV` no tiene un método para quitar filas. Para vaciar, reconstruir el widget.

---

#### barrow.lua

**Propósito.**
Filas con label, barra de progreso horizontal, porcentaje y detalle. Cada fila es una franja con `[label] [====bar====] [42%] [detalle]`. Los colores de la barra y del porcentaje pueden cambiar por umbrales (`warn_at`, `crit_at`).

**Alcance.**
Cubre filas con barra de progreso, colores por umbral, columna de detalle opcional, columna de porcentaje opcional. No cubre ordenamiento, filtrado, selección ni interacción por fila. No cubre barras verticales. No cubre múltiples barras por fila.

**Cómo funciona.**

`BarRow.new` guarda la configuración global: fuentes, colores, altura de fila, padding, y umbrales (`warn_at`, `crit_at`) que definen cuándo la barra y el porcentaje cambian de color. `warn_at` y `crit_at` son valores de `0..1`. Si `pct >= crit_at`, se usa color crítico; si `pct >= warn_at`, color de advertencia; si no, color normal.

`add_row(id, label, color)` añade una fila con su id, label, y color de barra opcional (el color explícito tiene prioridad sobre los umbrales). `remove_all_rows` vacía la lista. `_total_height` calcula el alto total sumando `row_height` más separación por cada fila.

`_bar_color_for(row)` y `_text_color_for(row)` eligen el color de la barra y del texto del porcentaje según los umbrales. El flag `text_warn` (default `true`) controla si el texto cambia de color con el umbral; si es `false`, el texto siempre usa `color_value` y solo la barra cambia.

`set(id, data)` actualiza una fila con una tabla `data = { pct, value, color }`. El `pct` es el porcentaje a dibujar (`0..1`); el `value` es el string del detalle (opcional); el `color` es un override del color de barra (opcional). `set_empty(id, text)` marca la fila sin datos, con un texto en lugar de barra.

`askMinMax` suma los altos de todas las filas más padding. El ancho mínimo lo determina el label más ancho más un mínimo de barra más el porcentaje y el detalle. `layout` reparte el rect entre las filas y dentro de cada fila reparte el espacio entre label, barra, porcentaje y detalle según anchos configurables (`pct_width`, `detail_width`).

`draw` recorre las filas, dibuja el label a la izquierda, la barra con `G.bar`, el porcentaje como texto, y el detalle a la derecha.

**API.**

**Construcción.**

- **`BarRow.new(opts)`** — `opts.font_label`, `opts.font_value`, `opts.row_height` (default 22), `opts.padding`, `opts.bar_height` (default 8), `opts.bar_radius`, `opts.color_bar` (color normal de la barra), `opts.color_warn` (color de la barra cuando `pct >= warn_at`), `opts.color_crit` (color cuando `pct >= crit_at`), `opts.warn_at` (umbral, default 0.7), `opts.crit_at` (umbral, default 0.9), `opts.text_warn` (default `true`), `opts.pct_width`, `opts.detail_width`.

**Métodos.**

| Método | Notas |
|---|---|
| `add_row(id, label, color?)` | Añade una fila. `color` es un override del color de barra. |
| `set_animated(id, data, duration?)` | Igual que `set` pero anima `row.pct_value` desde su valor actual al nuevo. Default 500 ms. Sin motor listo, cae a `set`. |
| `remove_all_rows()` | Vacía todas las filas. |
| `set(id, data)` | Actualiza. `data = { pct, value, color }`. |
| `set_empty(id, text)` | Marca la fila sin datos, con `text` en lugar de barra. |
| `set_window(win)` | Propaga `window`. |

**Campos.**

- `rows` — lista de filas.
- `row_height`, `padding`, `bar_height`, `bar_radius`.
- `warn_at`, `crit_at`, `text_warn`.
- `pct_width`, `detail_width`.

**Patrón.**

Filas con umbrales de color:

    local bar = W.BarRow.new {
        row_height = 24,
        warn_at = 0.7,
        crit_at = 0.9,
        color_bar = theme.telemetry.cpu,
        color_warn = "#fabd2f",
        color_crit = "#fb4934",
    }
    bar:add_row("core1", "Núcleo 1")
    bar:add_row("core2", "Núcleo 2")

    -- En el timer:
    bar:set("core1", { pct = 0.45, value = "45%" })
    bar:set("core2", { pct = 0.92, value = "92%" })  -- color crítico

Ver `examples/13-tab-cpu.lua`.

**Anti-patrón.**

- **Asumir que `set` con `pct` fuera de `[0,1]` se clampea.** El color se elige comparando con los umbrales, que funcionan sobre `[0,1]`. Un `pct = 1.5` haría que `_bar_color_for` comparara con `crit_at` (0.9) y eligiera crítico, pero la barra se dibujaría al 100% por el clamp interno de `G.bar`. Resultado: color coherente, ancho saturado. Mejor clampear en el consumidor antes de llamar.
- **Llamar `set` antes de `add_row` con el mismo id.** La fila no existe y `set` no hace nada. `add_row` primero, `set` después.
- **Esperar que `remove_all_rows` reinicie los colores.** Solo vacía la lista. La configuración de la instancia (`warn_at`, `crit_at`, colores) sigue. Reconstruir el widget si se quiere resetear todo.
- **Poner `pct_width = 0` y `detail_width = 0` a la vez esperando que la barra ocupe todo.** El widget reparte el espacio restante entre label y barra, pero el label tiene un mínimo natural. La barra ocupa lo que sobra. Si el label es muy ancho, la barra queda pequeña. Ajustar `pct_width`/`detail_width` es la forma de dar más espacio a la barra, no quitarlos.
- **Confundir `Motors` (subclase) con `BarRow`.** `Motors` es una configuración concreta de `BarRow` para filas sin porcentaje ni detalle. Ver más abajo.

**Notas.**

- `text_warn` es útil cuando el texto del porcentaje forma parte de una cabecera común y no debe cambiar de color según la fila. Con `text_warn = false`, solo la barra cambia.
- El color explícito pasado en `add_row(id, label, color)` tiene prioridad sobre los umbrales. Sirve para filas que no siguen el patrón warn/crit (por ejemplo, una barra de color fijo).
- El `value` de `data` en `set` es el detalle (segundo texto a la derecha). El porcentaje se dibuja automáticamente como `math.floor(pct * 100) .. "%"`. Si se quiere otro formato, no usar `BarRow`.
- `set_empty` marca la fila sin datos. Es útil cuando un sampler no está disponible (por ejemplo, sensor de temperatura ausente). El texto suele ser algo como `"—"` o `"n/a"`.

---

#### motors.lua

**Propósito.**
Subclase concreta de `BarRow` para el caso "solo label y barra, sin porcentaje ni detalle". El nombre viene del proyecto original de Awesome, donde se usaba para mostrar "motores" (núcleos de CPU) como barras.

**Alcance.**
Cubre exactamente lo mismo que `BarRow` pero con `pct_width = 0` y `detail_width = 0` fijados en el constructor. No añade funcionalidad nueva.

**Cómo funciona.**

`Motors.new` llama al constructor de `BarRow` con `pct_width = 0` y `detail_width = 0`, lo que hace que el layout reparta todo el espacio entre label y barra. La API pública es la de `BarRow` más un método `set(id, pct)` de conveniencia que evita tener que construir la tabla `{ pct = ... }` en el consumidor.

La razón de tener `Motors` como clase propia en lugar de solo usar `BarRow.new { pct_width = 0, detail_width = 0 }` es la ergonomía: el constructor queda más corto y `set(id, pct)` es más natural que `set(id, { pct = pct })` cuando solo hay un dato por fila.

**API.**

**Construcción.**

- **`Motors.new(opts)`** — mismos campos que `BarRow.new`. `pct_width` y `detail_width` son forzados a 0 y no se pueden sobrescribir.

**Métodos.**

| Método | Notas |
|---|---|
| `set(id, pct)` | Atajo sobre `BarRow:set` que solo pasa `pct`. |
| `set_animated(id, pct, duration?)` | Atajo sobre `BarRow:set_animated`. |

Hereda todos los demás métodos de `BarRow` (`add_row`, `remove_all_rows`, `set_empty`, `set_window`).

**Patrón.**

Motores de CPU (un núcleo por fila):

    local motors = W.Motors.new {
        row_height = 18,
        warn_at = 0.7,
        crit_at = 0.9,
    }
    for i = 1, 8 do
        motors:add_row("core" .. i, "c" .. i)
    end

    -- En el timer:
    for i, pct in ipairs(per_core) do
        motors:set("core" .. i, pct)
    end

**Anti-patrón.**

- **Pasar `pct_width` o `detail_width` en `opts`.** El constructor de `Motors` los sobreescribe a 0 después de pasarlos a `BarRow`. Si se necesita personalizar esos valores, usar `BarRow` directamente.
- **Asumir que `set(id, { pct = ... })` funciona.** El método `set` de `Motors` recibe un número, no una tabla. Internamente construye la tabla. Pasar una tabla haría que `pct` fuera una tabla y `math.floor(pct * 100)` fallaría.

**Notas.**

- `Motors` no tiene código propio más allá del constructor y el `set`. Toda la lógica es de `BarRow`. Cualquier cambio en `BarRow` afecta a `Motors`.
- La herencia es `setmetatable({}, { __index = BarRow })`, así que los métodos de `BarRow` están disponibles sin copia.
- El nombre `Motors` no es descriptivo para usos fuera de "motores de CPU". Para filas con barra sin porcentaje en otros contextos, usar `BarRow` con `pct_width = 0, detail_width = 0`.

---

#### rows.lua

**Propósito.**
Lista de filas con tres columnas: grupo, nombre y valor. El grupo es una etiqueta corta (por ejemplo, una letra o un icono de categoría) a la izquierda; el nombre al medio; el valor a la derecha. Pensado para sensores donde varias filas comparten grupo (por ejemplo, "núcleo 0, 1, 2..." bajo "CPU").

**Alcance.**
Cubre tres columnas con alineación, agrupación visual mediante el nombre repetido o vacío, y actualización de valores en runtime. No cubre colapsar/expandir grupos. No cubre ordenamiento ni filtrado. No cubre interacción por fila.

**Cómo funciona.**

`Rows.new` guarda las fuentes y colores de las tres columnas, la altura de fila, y el padding. `add_row(id, group, name)` añade una fila con un id único, un group (puede ser `""` para filas que no lo llevan), y un nombre. El group es una columna puramente visual: no agrupa funcionalmente, solo se dibuja en su columna.

`set_window` propaga `window` (aunque `Rows` no tiene hijos reales, se llama por convención).

`_total_height` calcula el alto total sumando `row_height` por fila. `askMinMax` devuelve el ancho combinado de las tres columnas más padding, y el alto total.

`layout` reparte el rect entre las filas horizontalmente. Cada fila ocupa una franja de `row_height` px. La columna de grupo empieza en `x0 + padding` y ocupa un ancho fijo; la columna de nombre empieza después de la de grupo; el valor se alinea a la derecha.

`set(id, value, format)` actualiza el valor de una fila, aplicando el formateador si lo hay. `set_markup(id, markup)` permite pasar markup Pango.

`draw` recorre las filas y dibuja las tres columnas. La columna del valor se mide con `pango.measure` para alinear a la derecha. El grupo y el nombre se dibujan con las fuentes y colores configurados.

**API.**

**Construcción.**

- **`Rows.new(opts)`** — `opts.font_group`, `opts.font_name`, `opts.font_value`, `opts.color_group`, `opts.color_name`, `opts.color_value`, `opts.row_height` (default 20), `opts.padding`, `opts.group_width`.

**Métodos.**

| Método | Notas |
|---|---|
| `add_row(id, group, name)` | Añade una fila. `group` puede ser `""`. |
| `set(id, value, format?)` | Actualiza el valor con formateador opcional. |
| `set_markup(id, markup)` | Actualiza con markup Pango. |
| `set_window(win)` | Propaga `window` (por convención). |

**Patrón.**

Sensores de temperatura agrupados por chip:

    local rows = W.Rows.new { row_height = 20 }
    rows:add_row("core0", "CPU", "Núcleo 0", function(v) return v .. "°C" end)
    rows:add_row("core1", "",    "Núcleo 1", function(v) return v .. "°C" end)
    rows:add_row("nvme0", "SSD", "NVMe 0")
    rows:add_row("nvme1", "",    "NVMe 1")

    -- En el timer:
    rows:set("core0", 45)
    rows:set("core1", 48)

Ver `examples/21-tab-temps.lua`.

**Anti-patrón.**

- **Asumir que `add_row` agrupa visualmente.** El grupo es solo una columna más. No hay indentación, ni fondo distinto, ni separador entre grupos. El consumidor que quiera eso tiene que dibujarlo o construir sub-`Rows` por grupo.
- **Pasar `group` como `nil`.** El constructor espera un string. `nil` puede causar problemas en la medición de ancho de la columna. Usar `""` para filas sin grupo.
- **Añadir filas en runtime sin `invalidate_layout` en el contenedor.** Igual que `KV` y `BarRow`: el `askMinMax` del padre no se recalcula automáticamente.
- **Confundir `Rows` con `KV`.** `Rows` tiene tres columnas (grupo, nombre, valor) y el nombre no es clave de un par. `KV` tiene dos columnas (label, valor) con alineación izquierda-derecha.

**Notas.**

- El `format` es una función `function(value) -> string`. Se llama en cada `set`. Mismo consejo que en `KV`: formateo ligero.
- `Rows` no tiene un método `remove_all_rows`. Para vaciar, reconstruir.
- El `group_width` es fijo, no se ajusta al contenido. Un grupo más ancho que `group_width` se saldrá de su columna y se solapará con el nombre. Elegir un valor lo bastante grande o acortar los grupos.
- El valor se alinea a la derecha del rect. El nombre y el grupo, a la izquierda de sus columnas respectivas.

---

#### barmulti.lua

**Propósito.**
Barra horizontal con varios segmentos apilados y una leyenda dinámica debajo. Cada segmento tiene su color, su label, y un porcentaje. La leyenda reorganiza sus columnas en función del ancho disponible para que todos los textos quepan sin pisarse.

**Alcance.**
Cubre barra apilada horizontal, leyenda con color por segmento, y reflow dinámico de la leyenda (reducir columnas cuando no cabe, repartir el sobrante). No cubre barras verticales. No cubre ordenamiento ni interacción por segmento. No cubre más de una barra por widget: todos los segmentos van en la misma barra.

**Cómo funciona.**

`BarMulti.new` guarda la configuración global (alto de la barra, colores de fondo, radio, configuración de la leyenda) y una lista vacía de segmentos. `add_segment(id, color, label)` añade un segmento con `pct = 0` inicial y lo registra en `by_id` para acceso rápido por id.

`set(values)` recibe una lista de `{ id, pct, color?, value_str? }`. Para cada entrada, busca el segmento por id y actualiza `pct` (si cambió), `color` (si se pasa) y `value_str` (si se pasa y cambió). Solo daña si algo cambió.

`_text_for(seg)` construye el texto que se muestra en la leyenda para un segmento. Si el segmento tiene `value_str`, lo usa tal cual más el label. Si no, aplica el `value_format` (por defecto `"%.1f"`) al `pct * 100`. Esto permite mostrar `"CPU 45.2"` en lugar de `"CPU 45.2%"` o cualquier otra combinación.

`_compute_legend(w, avail_h)` es el corazón del reflow. Calcula el ancho natural de cada entrada de leyenda con `pango.measure`. Luego prueba de `legend_cols` hacia abajo hasta `legend_cols_min`, calculando para cada número de columnas: cuántas filas salen, el ancho de cada columna (el máximo de los anchos de sus entradas), el ancho total con gaps, y la altura necesaria. Elige la primera configuración que quepa en `w` y `avail_h`. Si ni con `legend_cols_min` cabe, usa esa y deja que el clip corte lo que se salga. La primera configuración que cabe se devuelve con los sobrantes (ancho y alto) repartidos entre los gaps para que la leyenda ocupe todo el espacio disponible de forma equilibrada. `notes.md` documenta esta lógica bajo "reflow dinámico en leyendas".

`askMinMax` devuelve un ancho mínimo de 120 px (suficiente para la barra) y un alto mínimo de alto de barra más una línea de leyenda. Los máximos se liberan.

`draw` dibuja primero la barra apilada con `G.stacked_bar`, pasando los segmentos en orden. Luego dibuja la leyenda: para cada segmento, calcula su columna y fila según el layout devuelto por `_compute_legend`, aplica clip por celda, dibuja el cuadro de color (un `rounded_rect` pequeño) y el texto al lado.

**API.**

**Construcción.**

- **`BarMulti.new(opts)`** — `opts.segments` (lista inicial de `{ id, color, label }`), `opts.bar_height` (default 18), `opts.bar_bg` (hex, default `"#3c3836"`), `opts.bar_radius` (default `bar_height/2`), `opts.legend_cols` (máximo, default 2), `opts.legend_cols_min` (mínimo, default 1), `opts.legend_gap_y` (default 4), `opts.legend_gap_x` (default 12), `opts.legend_dot` (default 10), `opts.legend_font` (default `"DejaVu Sans 10"`), `opts.legend_color` (tabla `{r, g, b}`, default gris claro), `opts.value_format` (string de `string.format`, default `"%.1f"`).

**Métodos.**

| Método | Notas |
|---|---|
| `add_segment(id, color, label)` | Añade un segmento. Devuelve el segmento. |
| `set(values)` | Actualiza. `values = { { id, pct, color?, value_str? }, ... }`. |

**Campos.**

- `segments` — lista de segmentos.
- `by_id` — tabla `id → segmento`.
- `bar_height`, `bar_bg`, `bar_radius`.
- `legend_cols`, `legend_cols_min`, `legend_gap_x`, `legend_gap_y`, `legend_dot`, `legend_font`, `legend_color`, `value_format`.

**Patrón.**

Uso de RAM desglosada por proceso:

    local bm = W.BarMulti.new {
        segments = {
            { id = "firefox", color = "#8ec07c", label = "Firefox" },
            { id = "luajit",  color = "#fabd2f", label = "LuaJIT"  },
            { id = "otros",   color = "#83a598", label = "Otros"   },
        },
        legend_cols = 2,
        value_format = "%.0f",
    }

    -- En el timer:
    bm:set({
        { id = "firefox", pct = 0.45 },
        { id = "luajit",  pct = 0.20 },
        { id = "otros",   pct = 0.35 },
    })

Con `value_str` para controlar el texto exacto:

    bm:set({
        { id = "temp", pct = 0.5, value_str = "45°C" },
    })

**Anti-patrón.**

- **Asumir que la leyenda tiene siempre `legend_cols` columnas.** El número de columnas baja dinámicamente si no caben todos los textos. El `legend_cols` es el máximo, no el fijo.
- **Pasar `value_format` que espera un `%d` cuando el valor es `pct * 100`.** El `pct * 100` es un float, así que el formato debe ser `%.0f`, `%.1f` o `%d` (con conversión implícita). Usar `%s` daría un resultado inesperado con floats muy largos.
- **Pasar segmentos que no suman 1.** `G.stacked_bar` no valida la suma. Si la suma es mayor que 1, los segmentos se salen del ancho (clipados); si es menor, queda espacio sin pintar.
- **Asumir que añadir un segmento tras construir el widget dispara un `invalidate_layout`.** No lo hace. Llamar al `invalidate_layout` del contenedor si se mutan segmentos en runtime.

**Notas.**

- El `bar_height` determina el radio de la barra por defecto (`bar_height / 2`). Una barra de 18 px con radio 9 se ve como una pastilla.
- `_compute_legend` llama a `pango.measure` dos veces por segmento en cada `draw` (una vez para el ancho natural, otra dentro del bucle). Para leyendas con muchas entradas y timers cortos, el coste se nota. Aceptable para los usos del toolkit (3-8 entradas).
- El `_text_for` prefiere `value_str` sobre `value_format`. Es intencional: permite formatear por segmento cuando el `value_format` global no aplica (por ejemplo, mezclar porcentajes con temperaturas).
- La leyenda se clipa por celda con `cairo.clip`. Un texto demasiado largo para su columna se corta por la derecha sin elipsis. Acortar los labels o reducir el número máximo de columnas.

---

#### pills.lua

**Propósito.**
Columna de pills horizontales. Cada pill es un texto sobre un fondo redondeado con un color. Pensado para etiquetas y categorías.

**Alcance.**
Cubre una lista horizontal de pills con color propio. No cubre orientación vertical: los pills siempre se apilan en horizontal. No cubre interacción por pill. No cubre más de una línea de texto por pill. No cubre iconos dentro de la pill.

**Cómo funciona.**

`Pills.new` guarda la configuración (gap entre pills, padding interno, fuente, color de texto) y una lista de items. Cada item se compone al añadirse: mide el texto con `pango.measure`, calcula el ancho (`tw + pad_x * 2`) y el alto (`th + pad_y * 2`), y lo guarda. Esta medición única permite que `_total_width` y `_total_height` sean sumas simples sin volver a medir.

`add(id, text, color)` construye un item y lo añade. El color por defecto es `"#8ec07c"` (verde del theme).

`_total_height` devuelve el máximo alto de todos los items. `_total_width` suma los anchos más `gap` entre cada par consecutivo.

`askMinMax` devuelve esos dos valores como mínimos. Los máximos se liberan en ancho (`10000`) pero no en alto (`max_h = _total_height()`): los pills no crecen verticalmente.

`layout` reparte horizontalmente. Cada item tiene su `x0`, `y0`, `x1`, `y1` calculados en el layout. El `y0` se centra verticalmente dentro del rect: `y0 + (alto - total_h)/2`.

`draw` recorre los items y dibuja cada uno como un `rounded_rect` con `radius` (o la mitad del alto si no se especifica) más el texto centrado verticalmente.

`set(id, text)` mide el nuevo texto y recalcula el ancho del item. Daña. No dispara `invalidate_layout`, así que si el texto crece mucho el layout del padre no se entera hasta el próximo `askMinMax`.

`set_color(id, color)` cambia el color del fondo. Daña.

**API.**

**Construcción.**

- **`Pills.new(opts)`** — `opts.items` (lista inicial de `{ id, text, color }`), `opts.gap` (default 6), `opts.pad_x` (default 8), `opts.pad_y` (default 3), `opts.font` (default `"DejaVu Sans 10"`), `opts.text_color` (tabla `{r, g, b}`, default casi negro), `opts.radius` (default la mitad del alto del pill).

**Métodos.**

| Método | Notas |
|---|---|
| `add(id, text, color?)` | Añade un pill. |
| `set(id, text)` | Cambia el texto. Re-mide. |
| `set_color(id, color)` | Cambia el color de fondo. |

**Campos.**

- `items` — lista de items con sus medidas y posiciones.
- `gap`, `pad_x`, `pad_y`, `font`, `text_color`, `radius`.

**Patrón.**

Etiquetas de categoría:

    local pills = W.Pills.new {
        gap = 6,
        items = {
            { id = "hot", text = "Caliente", color = "#fb4934" },
            { id = "ok",  text = "OK",       color = "#8ec07c" },
        },
    }
    pills:set_color("ok", "#b8bb26")

**Anti-patrón.**

- **Esperar que los pills se envuelvan a varias líneas.** No lo hacen. Si no caben en el ancho del rect, se salen por la derecha y se recortan (clip del padre). Para varias líneas, componer con `Group` vertical de `Pills` horizontales.
- **Pasar un color en formato `{r, g, b}` a `add` o `set_color`.** Los colores de los pills van como strings hex (`"#rrggbb"`), que `G.set_color` interpreta. Una tabla haría fallar `hex_to_rgba`.
- **Cambiar el texto a uno mucho más largo en `set` sin invalidar el layout del padre.** El pill crece, pero los hermanos no se reposicionan. Llamar `invalidate_layout` en el contenedor tras el `set` si el tamaño cambia significativamente.

**Notas.**

- El radio por defecto es la mitad del alto del pill, lo que da la forma "pastilla" clásica. Pasar `radius = 0` para esquinas rectangulares, o un valor intermedio para esquinas suaves.
- El `text_color` es único para todos los pills. No hay opción de color de texto por pill. Para pills con fondos muy claros y muy oscuros mezclados, el contraste uniforme puede quedar mal. En ese caso, usar `PillRow` (que sí personaliza label y value) o hacer un widget propio.
- `Pills` no tiene `remove`. Para quitar un pill, reconstruir.

---

#### pillrow.lua

**Propósito.**
Fila horizontal de pills con formato `[LABEL VALOR]`. Cada pill tiene un label pequeño en color muted y un valor a la derecha en un color propio. Pensado para mostrar telemetría compacta: "CPU 45%", "RAM 62%", "NET 1.2 MB/s".

**Alcance.**
Cubre una fila horizontal de pills con label y valor, color dinámico del valor por pill, y reserva de ancho inicial para evitar que el layout quede demasiado ajustado. No cubre orientación vertical. No cubre iconos. No cubre más de una línea por pill. No cubre interacción.

**Cómo funciona.**

`PillRow.new` guarda la configuración, un theme opcional, y una lista de items. `T` guarda el theme (o `{}` si no se pasa) para leer `T.separator` (color de fondo de la pill) y `T.muted_rgb` (color del label). `bg_color` y `label_color` se resuelven de esas fuentes si no se pasan explícitamente.

`add(id, label, value, color)` construye un item. Mide el label y el valor con `pango.measure`. Además, reserva el ancho de `"100%"` como ancho mínimo del valor: si el valor actual es más corto que `"100%"`, se usa el reservado para el ancho del pill. Esto evita que el layout inicial quede demasiado ajustado y luego "salte" cuando el valor crezca. `notes.md` documenta esta decisión.

`_recalc` recalcula `min_h` (alto máximo de todos los items) y `min_w` (suma de anchos más gaps). Se llama tras `add` y tras `set` cuando el ancho cambia.

`set(id, value, color)` actualiza el valor y/o el color. Re-mide el valor si cambió. Si el ancho del item cambia en más de 4 px, llama a `self:layout(self.x0, self.y0, self.x1, self.y1)` para reacomodar las posiciones internas. El comentario del código aclara: esto NO invalida el layout global del árbol, solo la fila, porque el relayout global es caro y la fila de pills puede recolocarse sola. `notes.md` lo documenta como optimización.

`askMinMax` devuelve `min_w` y `min_h` como mínimos, y libera `max_w` a `10000` pero fija `max_h` a `min_h` (no crece verticalmente).

`layout` centra verticalmente la fila en el rect asignado, y distribuye los items horizontalmente desde `x0`.

`draw` recorre los items: dibuja el fondo redondeado (color `bg_color`, interpretado como hex o tabla), el label a la izquierda, y el valor a la derecha alineado a `x1 - pad_x - value_w`.

**API.**

**Construcción.**

- **`PillRow.new(opts)`** — `opts.theme` (tabla del theme), `opts.items` (lista de `{ id, label, value?, color? }`), `opts.gap` (default 6), `opts.pad_x` (default 8), `opts.pad_y` (default 3), `opts.label_font` (default `"DejaVu Sans 8"`), `opts.value_font` (default `"DejaVu Sans Bold 10"`), `opts.radius` (default 3), `opts.bg` (color de fondo, default `theme.separator` o `"#3c3836"`), `opts.label_color` (default `theme.muted_rgb` o gris).

**Métodos.**

| Método | Notas |
|---|---|
| `add(id, label, value?, color?)` | Añade una pill. |
| `set(id, value?, color?)` | Actualiza valor y/o color. Re-layout interno si el ancho cambia > 4px. |
| `set_color(id, color)` | Atajo para cambiar solo el color. |

**Campos.**

- `items`, `by_id`.
- `gap`, `pad_x`, `pad_y`, `radius`, `label_font`, `value_font`.
- `bg_color`, `label_color`.
- `T` — tabla del theme (o `{}`).

**Patrón.**

Fila de telemetría en la cabecera de una lista:

    local pills = W.PillRow.new {
        theme = theme,
        items = {
            { id = "cpu", label = "CPU", value = "--", color = theme.telemetry.cpu },
            { id = "ram", label = "RAM", value = "--", color = theme.telemetry.ram },
            { id = "net", label = "NET", value = "--", color = theme.telemetry.net },
        },
    }

    -- En el timer:
    pills:set("cpu", string.format("%d%%", cpu_pct))
    pills:set("ram", string.format("%d%%", ram_pct))
    pills:set("net", F.speed(net_bps))

Ver `examples/17-tab-proc.lua` para el uso real.

**Anti-patrón.**

- **Asumir que `add` con el mismo id dos veces crea dos pills.** Crea dos items en `items` pero `by_id` solo guarda el último. `set` afectaría solo al segundo. Usar ids únicos.
- **Pasar un `bg` en formato `{r, g, b}` cuando el widget espera también strings hex.** El código acepta ambos: chequea `type(self.bg_color) == "string"` y usa `hex_to_rgba` si lo es, o usa la tabla directamente. Mismo tratamiento para `label_color` y para los colores de cada item.
- **Esperar que `set` con el mismo valor no dañe.** El código compara `value ~= item.value` antes de actualizar. Un `set` con el mismo valor es un no-op y no daña. Es una optimización para timers que refrescan sin cambios.
- **Asumir que el layout global se recalcula automáticamente al crecer una pill.** El `set` con cambio de ancho > 4px re-layouta la fila internamente, pero el padre no se entera. Si el ancho total excede el rect asignado, los pills se salen por la derecha.

**Notas.**

- La reserva del ancho `"100%"` hace que todos los pills tengan al menos ese ancho de valor. Si todos los valores reales son más cortos, la fila queda con espacio de sobra. El propósito es evitar saltos visuales cuando un valor pasa de `"--"` a `"100%"`.
- El `bg_color` de fondo por defecto viene de `theme.separator` si hay theme, o `"#3c3836"` si no. Los pills se ven como pequeñas cajas discretas.
- El `value` se alinea a la derecha dentro del pill. El `label` a la izquierda. Entre ambos queda el espacio que sobra.
- `set` con cambio de ancho llama `self:layout(...)`, que recalcula las posiciones internas. No dispara `invalidate_layout` ni relayout del padre.

---

#### actions.lua

**Propósito.**
Lista vertical de botones que ejecutan comandos shell. Cada acción muestra un botón; al hacer click, corre el comando y muestra feedback (éxito o error) debajo durante unos segundos. Pensado para paneles de configuración: "Recargar Awesome", "Reiniciar red", "Suspender".

**Alcance.**
Cubre lista de acciones con comando, feedback temporal, y posibilidad de sobreescribir el ejecutor (`on_run`) para usar ejecución asíncrona. No cubre confirmación previa ("¿seguro?") antes de ejecutar. No cubre acciones con parámetros dinámicos. No cubre agrupación de acciones.

**Cómo funciona.**

`Actions.new` guarda la configuración (tiempo de feedback, ancho de botón, espaciado entre filas, colores del feedback) y crea un widget `Text` interno para el feedback, inicialmente vacío. Si se pasa `on_run`, se guarda como ejecutor alternativo.

`add_action(label, cmd, ok_msg)` crea un `Button` con el label, en modo `flat` (sin fondo normal, solo hover), con `min_width` igual al `button_width` configurado. El `on_click` del botón llama a `self:_run(action)`, donde `action = { label, cmd, ok_msg }`.

`_run` es donde ocurre la magia. Si hay `on_run`, lo llama con `(label, cmd)` y espera que devuelva `(ok, msg)`. Si no, ejecuta el comando con `os.execute`. En LuaJIT, `os.execute` devuelve tres valores `(ok, "exit", status)`; el código reduce a booleano con `ok = (a == true or a == 0)`. El mensaje es el `ok_msg` de la acción si `ok`, o `"Fallo"` si no. Setea el texto del feedback y el color según éxito o error. Cancela un timer previo de feedback si existe, y registra uno nuevo que limpia el texto tras `feedback_time` ms.

El timer se registra vía `self.window.server:add_timer`. La condición `self.window and self.window.server` protege contra el caso de llamar a `_run` antes de que el widget esté montado en una `Window`. Si no hay `window`, el feedback queda como texto visible y no se limpia automáticamente.

`_total_height` calcula el alto total asumiendo un alto de botón de 28 px (aproximado, no consulta el botón). Suma `n * 28 + (n-1) * row_spacing + 8 + 14` (8 para separación con feedback, 14 para el propio feedback).

`askMinMax` devuelve `button_width` como ancho mínimo y `_total_height` como alto mínimo. Los máximos se liberan en ancho.

`layout` distribuye los botones verticalmente centrados horizontalmente dentro del rect. Cada botón recibe `(bx, y)` a `(bx + bw, y + h)` donde `bw = min(button_width, avail_w)` y `bx` está centrado. Tras los botones, si queda espacio, posiciona el feedback debajo.

`draw` dibuja todos los botones y el feedback.

`getByXY` recorre los botones; si alguno acierta, lo devuelve. Si no, cae al rect propio.

**API.**

**Construcción.**

- **`Actions.new(opts)`** — `opts.actions` (lista inicial de `{ label, cmd, ok_msg }`), `opts.feedback_time` (ms, default 3000), `opts.button_width` (default 140), `opts.row_spacing` (default 6), `opts.feedback_color` (tabla `{r, g, b}`, default verde), `opts.feedback_error_color` (default rojo), `opts.on_run` (`function(label, cmd) -> ok, msg` opcional).

**Métodos.**

| Método | Notas |
|---|---|
| `add_action(label, cmd, ok_msg?)` | Añade una acción. Devuelve la tabla `action`. |
| `set_window(win)` | Propaga `window` a los botones internos y al feedback. |

**Callbacks.**

- `on_run(label, cmd)` — override del ejecutor. Debe devolver `(ok, msg)`. Si no se pasa, se usa `os.execute`.

**Campos.**

- `buttons` — lista de `Button`.
- `rows` — alias de `buttons` (compatibilidad).
- `feedback` — `Text` interno.
- `feedback_timer` — handle del timer actual.
- `feedback_time`, `button_width`, `row_spacing`, `feedback_color`, `feedback_error_color`, `on_run`.

**Patrón.**

Acciones de configuración:

    W.Actions.new {
        feedback_time = 4000,
        button_width = 180,
        actions = {
            { label = "Recargar",  cmd = "pkill -USR1 awesome", ok_msg = "Recargado" },
            { label = "Reiniciar red", cmd = "systemctl restart NetworkManager" },
            { label = "Bloquear",  cmd = "loginctl lock-session" },
        },
    }

Con `on_run` para ejecución asíncrona:

    W.Actions.new {
        on_run = function(label, cmd)
            local A = require("lib.helpers.async")
            return true, "Lanzado"  -- el async devuelve por callback
        end,
        actions = { ... },
    }

**Anti-patrón.**

- **Pasar comandos que bloquean el event loop.** Por defecto se usa `os.execute`, que bloquea. Para comandos que tardan (por ejemplo, `systemctl restart`), usar el `on_run` con `helpers/async.lua`. El comentario del código lo documenta.
- **Asumir que `on_run` recibe un resultado ya resuelto.** Si `on_run` lanza un comando asíncrono, el `ok` y `msg` que devuelve son inmediatos, no el resultado real. La firma `(ok, msg)` espera síncrono. Para casos asíncronos, `on_run` devuelve `true, "Lanzado"` y el feedback real se actualiza en el callback del comando.
- **Llamar `_run` antes de que el widget esté montado.** El feedback no tiene `window` y no se limpia. Si se necesita el feedback garantizado, esperar a `set_window` antes de permitir clicks.
- **Esperar que `add_action` recalcule el layout del padre.** Igual que otros widgets mutables, hay que invalidar el layout del contenedor.
- **Usar `Actions` para comandos que necesitan confirmación.** No hay paso intermedio de confirmación. Para eso, usar un `ContextMenu` con "Sí / No" o un diálogo propio.

**Notas.**

- El `button_width` es el ancho mínimo de cada botón, no el ancho real. El `layout` centra los botones horizontalmente y los dibuja a `min(button_width, avail_w)`. Con rects estrechos, los botones se encogen.
- El `_total_height` asume `btn_h = 28`, que es el alto típico del `Button` por defecto. Si los botones se configuran con padding distinto, el alto real puede diferir y `_total_height` queda desalineado con el layout.
- El timer del feedback se guarda en `self.feedback_timer`. Si se llama `_run` dos veces seguidas, el timer anterior se cancela y se reemplaza. No se acumulan timers.
- El color del feedback verde/rojo por defecto se adapta a temas oscuros. En temas claros, ajustar `feedback_color` y `feedback_error_color`.
- Los comandos se ejecutan con `os.execute`, que usa `/bin/sh`. Comandos con redirecciones y pipes funcionan, pero comandos con características específicas de bash (`[[ ]]`, arrays) fallan. Invocar bash explícitamente: `bash -c '...'`.

---

#### scrollview.lua

**Propósito.**
Lista vertical con scroll pixel-perfect. El contenido de cada fila se dibuja mediante un callback `draw_row` que el consumidor provee. El `ScrollView` se encarga del clip, del translate por el offset, del filtro de filas visibles y del hover por fila.

**Alcance.**
Cubre scroll vertical pixel-perfect, dibujo por callback, hover por fila, wheel scroll, click y click derecho por fila, y daño granular por fila cuando hay comparador de items. No cubre scroll horizontal. No cubre filas de alto variable: `row_height` es fijo. No cubre selección múltiple. No cubre scrollbar: se combina con `ScrollBar` vía `scrolllink.lua`. No cubre cache de Pango layouts por fila.

**Cómo funciona.**

`ScrollView.new` guarda la altura de fila (`row_height`, default 18), el callback de dibujo (`draw_row`), los callbacks de click (`on_click`, `on_right_click`), un color de fondo opcional, y la lista inicial de items. Crea un array vacío `change_cbs` para los suscriptores del cambio de offset. Los mínimos son `min_width`/`min_height` (defaults 100×100); los máximos se liberan.

`_recalc_max` calcula `offset_max` como `max(0, #items * row_height - view_h)` y clampea `offset` si se pasó del máximo. Se llama tras `set_items`, tras `layout` y desde el propio `set_offset`.

`set_items(items)` es donde vive la optimización de daño granular. Sin `opts.compare`, cualquier cambio de la lista daña todo el `ScrollView` y resetea el hover. Con `opts.compare(a, b)` (función que devuelve `true` si dos items son iguales), el `ScrollView` recorre los items viejos y nuevos y daña solo las filas visibles que cambiaron. El comentario del código aclara: si el widget aún no tiene rect válido (`x1 <= x0` o `y1 <= y0`) o si la lista cambió de tamaño, se cae al daño completo porque el diff granular solo tiene sentido cuando el widget ya tiene posición en pantalla. `notes.md` documenta la motivación: `ScrollView:set_items` que dañaba todo el rect del scrollview en cada refresh provocaba full redraws cada 2 s en el tab de procesos.

`set_offset(px, silent)` clampea y actualiza el offset. Daña todo el `ScrollView` (la vista cambia entera). El `silent` controla si se llaman o no los `change_cbs`. Es la clave del bucle cerrado con el `ScrollBar`: cuando el `ScrollBar` mueve el offset del `ScrollView`, se hace con `silent = true` para que el `ScrollView` no re-notifique al `ScrollBar`. Ver `scrolllink.lua`.

`on_change(fn)` registra un callback `fn(offset, offset_max)` que se llama cada vez que el offset o el máximo cambian (sin `silent`).

`draw` aplica clip al rect, opcionalmente pinta el fondo, y luego itera solo las filas visibles. El rango visible va de `first = floor(offset / row_height)` a `last = min(first + ceil(h / row_height), #items - 1)`. La `y` inicial de la primera fila es `y0 - (offset - first * row_height)`, que desplaza el bloque para que la primera fila quede parcialmente fuera cuando el offset no es múltiplo de la altura. Para cada fila, se hace `save`, `translate(x, 0)` (para que el callback reciba coordenadas en su espacio local), el callback, `restore`. El callback recibe `(cr, item, idx, ry, row_h, w, hover, self)`.

`on_mouse_move` calcula el índice de la fila bajo el cursor a partir de `my + offset`. Si cambia, daña la fila vieja y la nueva. `_damage_row(idx)` traduce el índice a coordenadas absolutas y añade el rect al damage list del `Window`.

`on_wheel` mueve el offset por `row_height * 3` por tick. `on_mouse_press` calcula el índice y despacha a `on_click` (botón 1) o `on_right_click` (botón 3).

`set_hover(v)` es un override: cuando el ratón sale del widget, resetea el `hover_idx` y daña toda la vista.

**API.**

**Construcción.**

- **`ScrollView.new(opts)`** — `opts.row_height` (default 18), `opts.draw_row` (obligatorio, `function(cr, item, idx, y, row_h, width, hover, view)`), `opts.on_click` (`function(item, idx)`), `opts.on_right_click` (`function(item, idx)`), `opts.bg_color` (hex), `opts.items` (lista inicial), `opts.compare` (`function(a, b) -> bool`), `opts.min_width` (default 100), `opts.min_height` (default 100).

**Métodos.**

| Método | Notas |
|---|---|
| `set_items(items)` | Reemplaza la lista. Con `compare` daña solo filas visibles cambiadas. |
| `set_offset(px, silent?)` | Fija el offset. `silent` no notifica a los `change_cbs`. |
| `get_offset()` | Offset actual. |
| `get_offset_max()` | Offset máximo. |
| `get_row_height()` | Alto de fila. |
| `get_count()` | Nº de items. |
| `on_change(fn)` | Registra callback `fn(offset, offset_max)`. |
| `set_window(win)` | Propaga `window`. |
| `set_hover(v)` | Override. Resetea `hover_idx` al salir. |

**Callbacks.**

- `draw_row(cr, item, idx, y, row_h, width, hover, view)` — dibuja una fila. Recibe coordenadas locales.
- `on_click(item, idx)` — click izquierdo sobre una fila.
- `on_right_click(item, idx)` — click derecho.
- `compare(a, b)` — devuelve `true` si dos items son iguales (para el diff de daño).

**Patrón.**

Lista de procesos con comparador para diff de daño:

    local sv = W.ScrollView.new {
        row_height = 20,
        compare = function(a, b)
            return a.pid == b.pid and a.cpu == b.cpu
               and a.mem == b.mem and a.comm == b.comm
        end,
        draw_row = function(cr, item, idx, y, h, w, hover, view)
            if hover then
                G.set_color(cr, "#2a2a34")
                cairo.rectangle(cr, 0, y, w, h)
                cairo.fill(cr)
            end
            pango.draw_text(cr, 4, y + 2, item.comm, "DejaVu Sans 10")
            pango.draw_text(cr, w - 60, y + 2, item.pid, "DejaVu Sans 10")
        end,
        on_click = function(item, idx)
            open_context_menu(item)
        end,
    }

Ver `examples/17-tab-proc.lua` para el uso completo con `ScrollBar` y `scrolllink`.

**Anti-patrón.**

- **No pintar el fondo de la fila en el callback `draw_row` cuando no hay hover.** El `ScrollView` hace blit parcial por filas. Si `draw_row` pinta el fondo solo cuando `hover == true`, la fila que deja de estar bajo el cursor conserva el tinte del frame anterior en el `image_surface` de la ventana. El resultado es un "rastro" del mouse por varias filas. El callback debe pintar SIEMPRE el fondo de la fila, con o sin hover. Ver Apéndice E, entrada 7.5.
- **Dibujar fuera del rect de la fila.** El callback `draw_row` recibe `(y, row_h)` y debe dibujar exactamente en esa franja. Cairo no clipea por fila: el clip es a nivel de `ScrollView`. Una fila que dibuja fuera pisa la adyacente.
- **Asumir que `set_items` sin `compare` daña solo lo que cambió.** Sin `compare`, cualquier llamada daña todo el `ScrollView`. Con timers de refresco cortos y listas largas, esto dispara repintados grandes. Pasar `compare` cuando la lista se refresca periódicamente.
- **Pasar `compare` que no es una función.** El código hace `if not self.opts.compare then return false end` y luego `self.opts.compare(a, b)`. Un `compare` que no sea función lanzará error en el segundo caso.
- **Esperar que `set_items` notifique cambio de offset.** No lo hace. El offset puede haber cambiado si el `offset_max` bajó y el clamp lo movió, pero no se notifica. Si el `ScrollBar` depende del cambio, llamar `notify` a mano o usar un timer que lea `get_offset`.
- **Dibujar con paths de Cairo que no se cierran.** El `draw` del `ScrollView` hace `cairo.new_path` antes y después de cada fila, pero dentro de la fila el callback es responsable de cerrar sus propios paths. Un path abierto al terminar el callback se arrastra a la fila siguiente y produce solapamientos visuales.
- **Olvidar `self._hover_visual`.** `ScrollView` no declara `_hover_visual` ni `_pressed_visual`: el hover se gestiona con `_damage_row` por índice de fila, no con el mecanismo general de `Area`. No confundir el hover del `ScrollView` con el hover de un botón.

**Notas.**

- El `ScrollView` no tiene scrollbar propio. Se combina con `ScrollBar` mediante `scrolllink.lua`, que cablea el flujo bidireccional.
- El `compare` debe ser una función pura y barata. Se llama una vez por item por cada `set_items`. Comparaciones campo a campo son ideales.
- `hover_idx` es `-1` cuando no hay hover. El `draw_row` recibe `hover = (hover_idx == idx)`.
- El `ScrollView` no tiene un método `scroll_to(idx)`. Para saltar a una fila, calcular `idx * row_height` y llamar `set_offset`.
- El `on_wheel` mueve por `row_height * 3` por tick. La mayoría de las apps usan este factor para que un tick de wheel recorra aproximadamente tres líneas.
- El fondo (`bg_color`) se dibuja antes de las filas, dentro del clip. Si no se pasa, se ve el fondo del contenedor.

---

#### scrollbar.lua

**Propósito.**
Scrollbar vertical u horizontal con handle arrastrable. Se ata a un `ScrollView` (o cualquier fuente con `offset`/`offset_max`) mediante callbacks. Se auto-oculta cuando el contenido cabe entero.

**Alcance.**
Cubre scrollbar vertical y horizontal, arrastre del handle, wheel scroll, y auto-oculto. No cubre botones de flecha en los extremos. No cubre doble click ni click en el track para saltar. No cubre temas de colores múltiples: solo hay color de track y color de handle.

**Cómo funciona.**

`ScrollBar.new` guarda la orientación (`"vertical"` o `"horizontal"`), el grosor del área, el grosor del track, el radio del handle, el paso del wheel, los colores, y el flag `auto_hide`. La orientación fija los mínimos y máximos: en vertical son `width × length`, en horizontal `length × width`.

`on_change(fn)` registra un callback `fn(new_offset)` que se llama cuando el handle mueve el offset.

`is_visible()` devuelve `true` si `auto_hide` está desactivado, o si `offset_max > 0` cuando está activado. Es el criterio de auto-oculto: sin contenido que scrollear, el scrollbar no se dibuja.

`set_offset(px, silent)` clampea y actualiza el offset. Daña todo el scrollbar. El `silent` controla la notificación a los `change_cbs`. Es simétrico al `ScrollView`: cuando el `ScrollView` mueve el offset, llama a `ScrollBar:set_offset(off, true)` para no re-notificar.

`set_offset_max(px)` actualiza el máximo. Si el offset actual queda fuera de rango, lo clampea. Daña, y si el cambio de visibilidad (`is_visible` cambia) afecta al área ocupada, daña el rect completo del scrollbar.

`layout` actualiza `length` al rect asignado. Es lo que permite que el scrollbar se adapte al alto del contenedor en vez de usar el `length` fijo del constructor.

`draw` retorna sin dibujar si `not is_visible()`. Calcula el rango útil del track restando el espacio de los dos extremos (`2 * handle_r + 4`). El track se dibuja como un `rounded_rect` fino (grosor `thickness`) centrado en el ancho del área. El handle se dibuja como un `cairo_arc` completo de radio `handle_r` posicionado a `range * pct` desde el inicio del track. El código hace `cairo.new_path` antes y después del track, y `cairo.new_sub_path` + `cairo.new_path` alrededor del handle. El comentario del código es explícito: sin el `new_path` previo, el primer arc del handle se une con el path pendiente del `on_draw` de la ventana y se rellena un triángulo deformado. `notes.md` documenta el patrón general de `new_path` con arcos.

Interacción: `on_mouse_press` con botón 1 inicia el arrastre guardando `drag_base` (offset actual) y `drag_mouse` (posición del cursor). `on_mouse_move` calcula el delta desde el inicio del arrastre, lo escala al rango del track, y llama `set_offset`. `on_mouse_release` con botón 1 termina el arrastre. `on_wheel` mueve el offset por `step` por tick.

**API.**

**Construcción.**

- **`ScrollBar.new(opts)`** — `opts.orientation` (`"vertical"` default, o `"horizontal"`), `opts.length` (longitud inicial del track, default 200), `opts.width` (grosor del área, default 20), `opts.thickness` (grosor del track, default 4), `opts.handle_r` (radio del handle, default 5), `opts.step` (paso del wheel, default 60), `opts.color_track` (hex, default `"#504945"`), `opts.color_handle` (hex, default `"#8ec07c"`), `opts.auto_hide` (default `true`), `opts.on_change` (`function(new_offset)`).

**Métodos.**

| Método | Notas |
|---|---|
| `on_change(fn)` | Registra callback `fn(new_offset)`. |
| `is_visible()` | `true` si `offset_max > 0` o `auto_hide = false`. |
| `set_offset(px, silent?)` | Fija el offset. `silent` no notifica. |
| `set_offset_max(px)` | Fija el máximo. Clampea el offset si hace falta. |
| `set_step(px)` | Cambia el paso del wheel. |
| `get_offset()` | Offset actual. |
| `get_offset_max()` | Offset máximo. |

**Campos.**

- `orientation`, `vertical` (booleano, derivado).
- `length`, `width`, `thickness`, `handle_r`, `step`.
- `color_track`, `color_handle`.
- `auto_hide`.
- `offset`, `offset_max`.
- `dragging`, `drag_base`, `drag_mouse`.

**Patrón.**

Scrollbar vertical cableado a un `ScrollView` con `scrolllink`:

    local sb = W.ScrollBar.new {
        orientation = "vertical",
        width = 12,
        thickness = 3,
        handle_r = 5,
        step = 60,
        color_track  = theme.separator,
        color_handle = theme.accent,
    }
    require("lib.widgets.scrolllink").link(list, sb)

Scrollbar horizontal para una lista de iconos:

    W.ScrollBar.new {
        orientation = "horizontal",
        length = 200,
        width = 12,
    }

**Anti-patrón.**

- **Cablear el `ScrollBar` a mano sin `silent`.** Sin `silent`, el flujo `list:on_change -> sb:set_offset -> sb:on_change -> list:set_offset` entra en bucle infinito. Usar `scrolllink.lua`, que maneja el `silent` automáticamente. `notes.md` lo documenta como patrón del cableado.
- **Dibujar el scrollbar sin haber hecho `new_path` antes.** El primer `arc` del handle se une con el path pendiente de un dibujo anterior. El síntoma es un triángulo deformado cerca del handle. `ScrollBar:draw` ya lo hace, pero si se compone un widget propio basado en el mismo patrón, recordar el `new_path`.
- **Asumir que `set_offset_max` no daña.** Daña siempre, y además puede dañar el rect completo si la visibilidad cambia. Para actualizar el máximo sin dañar (por ejemplo, durante el layout), habría que añadir una ruta específica; hoy no existe.
- **Poner `handle_r` mayor que `width / 2`.** El rango del track es `length - 2 * handle_r - 4`. Con un `handle_r` grande respecto al área, el rango útil se reduce o incluso se vuelve negativo. El `draw` retorna sin dibujar si `range <= 0`.
- **Confundir el `width` del área con el grosor del track.** `width` es el grosor total del área clickeable. `thickness` es el grosor visible del track. El handle tiene radio `handle_r`, que también determina el espacio reservado a los extremos.

**Notas.**

- El `length` del constructor es solo un valor inicial. `layout` lo sobreescribe con el rect asignado. Para scrollbars en `Group` horizontal con `weight = 0`, el ancho es fijo pero el alto lo da el `Group`.
- El `auto_hide` está activo por defecto. Para scrollbars que se muestran siempre (aunque no haya contenido que scrollear), pasar `auto_hide = false`.
- El handle se dibuja con `arc` + `fill`, no con `rounded_rect`. Es un círculo, no una pastilla. El comentario del código no lo menciona, pero el efecto visual es de un pomo redondo sobre un track fino.
- El drag usa `on_mouse_move` continuo. La `Window` enruta los `MotionNotify` al `active_element` durante el drag, no al widget bajo el cursor. Es lo que permite arrastrar el handle aunque el cursor salga de su rect.
- El `set_offset_max` no notifica a los `change_cbs`. La notificación solo ocurre desde `set_offset`. Si el consumidor necesita reaccionar a cambios de `offset_max`, tiene que comparar por su cuenta o registrar un timer.

---

#### scrolllink.lua

**Propósito.**
Cablea un `ScrollView` con un `ScrollBar` en el flujo bidireccional, manejando el `silent` para evitar bucles de feedback. Es la forma recomendada de combinar los dos widgets.

**Alcance.**
Cubre exactamente la coordinación entre `ScrollView` y `ScrollBar`. No cubre otros tipos de lista: aunque un consumidor puede escribir su propio cableado, el helper solo asume que la lista expone `on_change`, `set_offset` y la barra expone `on_change`, `set_offset` con `silent`, `set_offset_max`.

**Cómo funciona.**

`M.link(list, sb)` registra dos callbacks:

1. En el `ScrollView`: cuando cambia el offset o el máximo, llama a `sb:set_offset(off, true)` (con `silent = true`) y a `sb:set_offset_max(max)`. El `silent` evita que el `ScrollBar` re-notifique al `ScrollView`.
2. En el `ScrollBar`: cuando el usuario mueve el handle, llama a `list:set_offset(new_off)` sin `silent` (por defecto). Esto hace que el `ScrollView` se actualice y, al hacerlo, notifique al `ScrollBar` vía el callback anterior — pero con `silent = true`, así que no hay re-notificación hacia atrás.

El resultado es un flujo unidireccional en cada dirección, sin bucles. `notes.md` documenta el patrón.

**API.**

**Funciones.**

- **`M.link(list, sb)`** — Cablea los callbacks. No devuelve nada.

**Patrón.**

    local list = W.ScrollView.new { ... }
    local sb   = W.ScrollBar.new { orientation = "vertical" }
    require("lib.widgets.scrolllink").link(list, sb)

    -- Ahora el ScrollBar refleja el estado del ScrollView y viceversa.
    list:set_items(procesos)
    list:set_offset(0)  -- también actualiza el ScrollBar vía el cableado

**Anti-patrón.**

- **Cablear a mano sin `silent`.** El `ScrollView` notifica al `ScrollBar`, que notifica al `ScrollView`, que notifica al `ScrollBar`... Cada iteración es un `set_offset` con cambio real, así que el bucle no se estabiliza hasta que ambos se quedan sin cambiar. Si el clampeo corta, se detiene; si no, entra en CPU alta. `scrolllink.lua` está para evitarlo.
- **Llamar `link` dos veces sobre los mismos widgets.** Registra los callbacks dos veces. Cada cambio notifica dos veces por callback. Idempotencia no está garantizada. Llamar `link` una sola vez, al construir.
- **Asumir que `link` construye los widgets.** Solo cablea callbacks. Los widgets deben existir ya y estar configurados.
- **Cablear un `ScrollView` a varios `ScrollBar`.** No está prohibido pero es raro. El segundo `ScrollBar` recibiría los mismos eventos y, al moverse, movería el `ScrollView`, que notificaría al primero. Puede tener sentido (barra arriba y abajo), pero hay que ser consciente del flujo.

**Notas.**

- `scrolllink` no guarda referencias a los widgets. Los callbacks registrados en `list` y `sb` mantienen las referencias hasta que los widgets se destruyan. No hay `unlink`.
- El orden de los callbacks importa: el `ScrollView` se suscribe primero, así que al cambiar el offset del `ScrollView`, primero se llama su `on_change` propio (que notifica al `ScrollBar`) y luego el `ScrollBar` actualiza su estado. Si el consumidor registra sus propios `on_change` después de `link`, se llaman en orden de registro.
- El helper no valida que los widgets tengan los métodos esperados. Pasar un `ScrollBar` a un `ScrollView` (en el orden invertido) lanzaría error al primer cambio. Es responsabilidad del consumidor.

---

#### tabsbar.lua

**Propósito.**
Barra horizontal de tabs. Cada tab tiene un icono (opcional) y un label, y hay un tab activo. Soporta dos modos: uno con icono arriba y texto abajo para tabs principales, y otro con icono y texto lado a lado para sub-tabs compactos.

**Alcance.**
Cubre una barra horizontal de tabs con icono y texto, un tab activo único, hover por tab, y callback al seleccionar. No cubre tabs verticales. No cubre scroll horizontal cuando los tabs no caben. No cubre close buttons por tab. No cubre sub-tabs anidados directamente: los sub-tabs se componen con otro `TabsBar` en modo `compact = true`. No cubre selección múltiple.

**Cómo funciona.**

`TabsBar.new` guarda el modo (`compact`), los parámetros de layout (padding, gap, tamaño de icono, fuente, radio), los colores por estado (activo, inactivo, con hover intermedio) y la lista de items. La mayoría de colores tienen fallback al `theme`: `color_active_bg` cae a `theme.accent`, `color_active_fg` a `theme.bg_rgb`, etc. Si no hay theme, usa defaults.

Los dos modos cambian los parámetros de layout por defecto. En modo normal (`compact = false`): `pad_x = 10`, `pad_y = 6`, `icon_size = 22`, icono arriba y texto abajo. En modo compacto (`compact = true`): `pad_x = 8`, `pad_y = 2`, `icon_size = 16`, icono y texto lado a lado. Cualquiera de los valores se puede sobreescribir con las opciones.

`icon_path(name)` resuelve el path al PNG del icono. Acepta `"home"` o `"tab-home"`: si ya empieza por `tab-`, lo usa tal cual; si no, añade el prefijo. La ruta base es `$HOME/proyectos/lanetk/icons-png/32/`. Es hardcodeada porque el toolkit vive en esa ruta hoy; en una instalación real habría que derivarla del directorio del módulo como hace `theme.lua`.

`get_surface(path)` es un cache local (no el global de `cairo.load_png_cached`) que guarda el surface por path o `false` si la carga falló. La doble representación (`surface | false | nil`) permite distinguir entre "no intentado" (`nil`), "intentado y falló" (`false`) e "intentado y OK" (surface). Sin este truco, un PNG que falla se re-intentaría en cada draw.

`add(id, label, icon_name)` mide el label, calcula el ancho y alto del tab según el modo, y guarda el item. En modo normal: `w = pad_x * 2 + max(text_w, icon_size)`, `h = pad_y * 2 + icon_size + icon_text_gap + text_h`. En modo compacto: `w = pad_x * 2 + icon_size + icon_text_gap + text_w`, `h = pad_y * 2 + max(text_h, icon_size)`. Los gaps entre icono y texto son distintos: 2 px en modo normal (apilado), 6 px en modo compacto (lado a lado).

`set_active(id)` cambia el tab activo y llama a `on_select`. `askMinMax` devuelve el ancho total (suma de anchos más gaps) y el alto máximo de los items. `layout` posiciona los items en fila desde `x0`.

`_draw_item(cr, item, bg_rgb, fg_rgb)` dibuja un tab completo: fondo con `rounded_rect`, icono centrado (arriba o a la izquierda según el modo), texto centrado. El icono se tinta con el color `fg_rgb` vía `draw_surface_tinted`.

`draw` recorre los items y elige los colores según el estado: activo (colores de activo), hover (fondo inactivo con fg aclarado en 0.2), inactivo (colores de inactivo).

`_hit_item(mx, my)` convierte las coordenadas locales a globales sumando `self.x0` y `self.y0`, y busca el item que contiene el punto. El comentario del código no lo menciona, pero `notes.md` documenta este patrón: si un widget guarda posiciones de sub-items en coordenadas globales (como hace `layout`), el hit-test debe convertir de vuelta. `notes.md` lo registra como bug encontrado originalmente en `TabsBar`.

`on_mouse_move` actualiza `hover_id` y daña si cambió. `set_hover(v)` resetea `hover_id` al salir del widget. `on_mouse_press` con botón 1 selecciona el tab bajo el cursor.

**API.**

**Construcción.**

- **`TabsBar.new(opts)`** — `opts.theme` (tabla del theme), `opts.compact` (default `false`), `opts.items` (lista de `{ id, label, icon }`), `opts.active` (id del tab activo inicial), `opts.pad_x`, `opts.pad_y`, `opts.icon_size`, `opts.gap`, `opts.font`, `opts.radius`, `opts.color_active_bg`, `opts.color_active_fg`, `opts.color_inactive_bg`, `opts.color_inactive_fg`, `opts.on_select` (`function(id)`).

**Métodos.**

| Método | Notas |
|---|---|
| `add(id, label, icon_name?)` | Añade un tab. Devuelve el item. |
| `set_active(id)` | Cambia el tab activo. Llama a `on_select`. |
| `get_active()` | Id del tab activo. |
| `set_hover(v)` | Override. Resetea `hover_id` al salir. |

**Callbacks.**

- `on_select(id)` — se llama al cambiar de tab (desde `set_active`).

**Campos.**

- `items`, `by_id` — tabs registrados.
- `active`, `hover_id`.
- `compact`, `pad_x`, `pad_y`, `icon_size`, `gap`, `font`, `radius`.
- `color_active_bg`, `color_active_fg`, `color_inactive_bg`, `color_inactive_fg`, `T`.

**Patrón.**

Tabs principales del panel (icono arriba, texto abajo):

    local tb = W.TabsBar.new {
        theme = theme,
        items = {
            { id = "home",  label = "Inicio",   icon = "home" },
            { id = "cpu",   label = "CPU",      icon = "cpu" },
            { id = "ram",   label = "RAM",      icon = "ram" },
        },
        on_select = function(id)
            panel:set_tab(id)
        end,
    }

Sub-tabs compactos:

    W.TabsBar.new {
        theme = theme,
        compact = true,
        items = { ... },
    }

Ver `examples/14-tabbed.lua`.

**Anti-patrón.**

- **Asumir que el icono se carga desde cualquier ruta.** La ruta base está hardcodeada a `$HOME/proyectos/lanetk/icons-png/32/`. Iconos fuera de esa carpeta no se cargan. Si se mueve el proyecto, hay que ajustar el módulo.
- **Pasar `icon` con extensión (`.png`).** El prefijo `tab-` se añade pero la extensión `.png` también. Un icono pasado como `"home.png"` produce `"tab-home.png.png"`, que no existe. Pasar el nombre base.
- **Confundir el hover con el activo.** `hover_id` es un campo separado de `active`. Hover con ratón no cambia el activo. El activo solo cambia con `set_active` (que se llama desde `on_mouse_press`).
- **Asumir que `_hit_item` recibe coordenadas globales.** Recibe locales y las convierte. El `on_mouse_press` y `on_mouse_move` ya las pasan locales (vienen del dispatch del `Window`). `notes.md` documenta el bug original por saltarse esta conversión.
- **Cambiar `icon_size` o `pad_x` después de construir.** El tamaño de los items se calcula en `add` con los valores actuales. Cambiar los parámetros no re-mide. Reconstruir.
- **Añadir tabs en runtime sin `invalidate_layout`.** Los tabs nuevos se añaden a `items` pero el padre no recalcula su `askMinMax`. Llamar `invalidate_layout` en el contenedor tras añadir.

**Notas.**

- El cache de surfaces por path (`surface_cache`) es local al módulo, no usa el cache global de `cairo`. Los PNGs de iconos también están en el cache global, así que se cargan una vez y se comparten.
- La distinción `surface | false | nil` en el cache permite no reintentar cargas fallidas. Si un icono no existe en disco, el primer intento lo marca como `false` y los siguientes no vuelven a `io.open`.
- El `color_active_fg` por defecto es `theme.bg_rgb`, que es el color de fondo general del theme. El efecto es texto oscuro sobre el fondo `accent` (que suele ser un color saturado). Es el patrón "pastilla de color" típico de las barras de tabs.
- `on_select` se llama desde `set_active`. Si el widget se activa programáticamente (por ejemplo, al montar el panel con un tab por defecto), `on_select` se dispara. Es útil para sincronizar con el `Stack` hermano, pero puede causar un bucle si el `on_select` llama a `set_active` con el mismo id (early return).
- El widget no envuelve los items en `padding` alrededor del grupo. El padding es interno de cada tab. Para separar la barra entera de su contenedor, usar `padding` del `Group` o del `Card` que la contiene.

---

#### textinput.lua

**Propósito.**
Campo de texto editable minimalista. Acepta teclado cuando tiene foco, muestra un cursor parpadeante, soporta navegación básica por flechas, home/end, delete/backspace, y callbacks de submit, cancel y change. Soporta modo máscara (`mask = true`) para passwords.

**Alcance.**
Cubre edición básica de una sola línea, cursor parpadeante, mask, navegación por caracteres. No cubre scroll horizontal: el texto largo se sale por la derecha. No cubre selección de texto ni portapapeles. No cubre edición multilínea. No cubre historial de undo/redo. No cubre IME (entrada de caracteres complejos con composición). No cubre copy/paste.

**Cómo funciona.**

`TextInput.new` guarda el texto, la posición del cursor (en bytes, no en caracteres), el estado de foco, la fase del cursor parpadeante, y un timer opcional para ese parpadeo. Los mínimos son `min_height` (default 26) y `min_width` (default 100); los máximos se liberan.

`set_focused(v)` es el método que gestiona la entrada de teclado. Al activarse, si hay `window`, se autorregistra como `window.focus_widget` (si no lo era ya) y arranca un timer de 500 ms que alterna `_cursor_phase` entre 0 y 1 para el parpadeo. Al desactivarse, cancela el timer, resetea la fase y se desregistra del `window`. El comentario del código es explícito: la autorregistración se hacía solo en `on_mouse_press` antes, lo que obligaba a hacer click para empezar a escribir. Ahora basta con `set_focused(true)` programático. `notes.md` lo documenta como mejora del launcher.

El soporte UTF-8 es manual. `_display_text` cuenta codepoints para el modo mask. `_cursor_display_index` y `_byte_index_of_char_index` traducen entre índices de byte y de codepoint. Los patrones `[%z\1-\127\194-\244][\128-\191]*` matchean un codepoint UTF-8 completo: el primer byte indica la longitud (1-4 bytes según el rango), los siguientes son bytes de continuación `[%128-\191]`. Esto permite que `backspace` y `move_left` operen sobre caracteres completos, no sobre bytes sueltos.

`insert_char(ch)` inserta un string (posiblemente multi-byte) en la posición del cursor y avanza el cursor por el número de bytes del string. `backspace` borra el carácter completo antes del cursor usando el mismo patrón de codepoint. `delete` borra el carácter después del cursor.

`move_left` y `move_right` desplazan el cursor un codepoint, no un byte. `move_home` va a la posición 0, `move_end` a `#self.text`.

`on_key(key)` procesa las teclas cuando el widget tiene foco. Retorna `true` si consumió la tecla (no propagar), `false` si no. Teclas manejadas: `Return` (dispara `on_submit`), `Escape` (dispara `on_cancel`), `BackSpace`, `Delete`, `Left`, `Right`, `Home`, `End`. Cualquier otro caracter imprimible (byte >= 32) se inserta. Retorna `false` para el resto.

`draw` pinta el fondo y el borde si se configuraron, dibuja el texto (o la máscara) centrado verticalmente, y si `focused` y `_cursor_phase == 0`, dibuja el cursor como una barra vertical de 1.5 px de ancho a la altura del texto, posicionado en el ancho del texto antes del cursor.

`on_mouse_press` con botón 1 pide el foco al `window` (que desregistra el foco del widget anterior y lo pone en este). Llama también a `on_focus_request` si está definido.

**API.**

**Construcción.**

- **`TextInput.new(opts)`** — `opts.text` (inicial), `opts.font` (default `"DejaVu Sans 12"`), `opts.padding_x` (default 8), `opts.padding_y` (default 4), `opts.color_text` (tabla `{r, g, b}`), `opts.color_cursor` (default amarillo claro), `opts.color_bg` (hex, opcional), `opts.color_border` (hex, opcional), `opts.corner_radius` (default 4), `opts.mask` (booleano, default `false`), `opts.min_height` (default 26), `opts.min_width` (default 100), `opts.on_submit`, `opts.on_cancel`, `opts.on_change`, `opts.on_focus_request`, `opts.on_up`, `opts.on_down`, `opts.placeholder`, `opts.color_placeholder`.

  - `opts.on_up` / `opts.on_down` — funciones sin argumentos. Si están definidas, `TextInput:on_key` las llama al recibir `Up` / `Down` y consume la tecla. Sin ellas, `Up`/`Down` retornan `false` y se propagan al handler global de la `Window`. Uso típico: navegación de listas adyacentes (el launcher lo usa para mover la selección).
  - `opts.placeholder` — string que se dibuja cuando `text == ""`. Se pinta con `opts.color_placeholder` (default `{0.34, 0.36, 0.40}`). El cursor sigue funcionando: si el input está enfocado y vacío, se ve el placeholder con el cursor encima.

**Métodos.**

| Método | Notas |
|---|---|
| `set_text(t)` | Reemplaza el texto. Cursor va al final. Llama a `on_change`. |
| `get_text()` | Devuelve el texto actual. |
| `set_focused(v)` | Activa o desactiva el foco. Autorregistra el `focus_widget`. |
| `insert_char(ch)` | Inserta un string en la posición del cursor. |
| `backspace()` | Borra el carácter anterior. |
| `delete()` | Borra el carácter siguiente. |
| `move_left()`, `move_right()` | Mueve el cursor un codepoint. |
| `move_home()`, `move_end()` | Mueve el cursor a extremos. |
| `on_key(key)` | Procesa una tecla. Retorna `true` si la consumió. |

**Callbacks.**

- `on_submit(text)` — al pulsar `Return`.
- `on_cancel()` — al pulsar `Escape`.
- `on_change(text)` — al cambiar el contenido (insert, delete, backspace, set_text).
- `on_focus_request(self)` — al recibir click, antes de pedir foco al `window`.

**Campos.**

- `text`, `cursor_pos` (en bytes).
- `focused`, `_cursor_phase`, `_cursor_timer`.
- `mask`, `font`, `padding_x`, `padding_y`, `corner_radius`.
- `color_text`, `color_cursor`, `color_bg`, `color_border`.

**Patrón.**

Campo de búsqueda con filtrado al cambiar:

    local input = W.TextInput.new {
        font = "DejaVu Sans 12",
        color_bg = theme.bg_card,
        color_border = theme.separator,
        on_change = function(text)
            list:set_items(filter_items(all_items, text))
        end,
        on_submit = function(text)
            run_first_match(text)
        end,
        on_cancel = function()
            window:close()
        end,
    }

Campo de password con mask:

    W.TextInput.new {
        mask = true,
        font = "DejaVu Sans 12",
        on_submit = function(text)
            attempt_login(text)
        end,
    }

Ver `examples/19-launcher.lua` y `examples/17-tab-proc.lua`.

**Anti-patrón.**

- **Olvidar llamar `set_focused(true)` tras montar el widget en una ventana con `kind = "dialog"` y `on_focus_in`.** El WM da el foco a la ventana, pero el `TextInput` no lo recibe hasta que el consumidor llama a `set_focused(true)` desde `on_focus_in`. `notes.md` documenta el flujo del launcher.
- **Llamar `set_focused(true)` desde un `on_mouse_press` en lugar de dejar que el widget lo haga.** El widget ya lo hace en su propio `on_mouse_press`. Una llamada externa puede pisar el `focus_widget` del `window` con el orden incorrecto.
- **Asumir que `on_key` se llama para KeyRelease.** El código chequea `if not key.pressed then return false end`. Las teclas soltadas no hacen nada. La `Window` sí llama a `on_key` en KeyRelease, pero el `TextInput` lo ignora.
- **Asumir que `cursor_pos` es un índice de carácter.** Es un índice de byte. Las funciones de navegación usan los helpers `_cursor_display_index` y `_byte_index_of_char_index` para traducir. El consumidor que necesite leer `cursor_pos` para otros fines debe ser consciente.
- **Pasar texto con `\n` a `set_text`.** El widget es de una línea. El `\n` se dibuja como un carácter más (o invisible según Pango). Si se necesita multilínea, usar otro widget.
- **Asumir que el texto largo hace scroll horizontal.** No lo hace. El texto que excede el ancho del rect se sale por la derecha y se corta (clip implícito del padre, si lo hay). Para inputs con textos muy largos, no usar este widget sin modificarlo.

**Notas.**

- El timer del cursor se crea con `window.server:add_timer`. Si el `TextInput` se construye antes de montarse en una `Window`, no hay timer y el cursor no parpadea hasta `set_focused(true)` con `window` disponible.
- El `mask` cuenta codepoints, no bytes: una cadena UTF-8 de N caracteres se muestra como N `●`, no como la longitud en bytes. Es lo correcto para passwords con acentos o símbolos.
- El borde del `TextInput` usa `+0.5` y dimensiones reducidas para que el trazo caiga dentro del rect. Mismo patrón que `Card`, `Button` y `CloseButton`.
- `insert_char` con un string multi-byte actualiza `cursor_pos` por la longitud del string (`#ch`). Si `ch` viene de `key.text` (que ya es UTF-8), la posición queda consistente.
- El `on_focus_request` es útil para que un contenedor (por ejemplo, un `Group` con un borde de foco) actualice su estado visual cuando el `TextInput` toma foco.
- El widget no captura Tab. Tab normalmente se propaga a la `Window`, que lo pasa al próximo widget con foco si existe esa lógica (no existe en el toolkit hoy).

---

#### contextmenu.lua

**Propósito.**
Menú contextual flotante anclado a un punto de la ventana padre. Muestra una lista de items con label y acción. Se cierra al hacer click fuera o al pulsar Escape. Usa una ventana child del padre más un `grab_pointer` para capturar todos los clicks mientras está abierto.

**Alcance.**
Cubre un menú con items y separadores, selección por click, cierre por click fuera o Escape, clamping a los bordes del parent. No cubre submenús anidados. No cubre items con iconos. No cubre items con checkbox o radio. No cubre atajos de teclado en los items (solo Escape). No cubre animación de apertura/cierre.

**Cómo funciona.**

`ContextMenu` no es un `Area`. Es un objeto que envuelve una `Window` child del parent. Se usa como singleton: `M.new(srv, parent_win, theme)` crea la instancia, y `:show(x, y, items, opts)` la abre.

`show(x, y, items, opts)` cierra un menú previo si estaba abierto, guarda los items y el callback `on_close`, calcula el ancho (máximo ancho de los labels más padding más espacio para un chevron que no se usa hoy) y el alto (suma de alturas de items más separadores). Reposiciona si el menú se sale del parent: si `px + w > parent_w - 4`, mueve `px` a `parent_w - w - 4`; análogo para `py`. Clampea a `>= 4` para no pegar el menú contra los bordes.

Crea una `Window` child con:
- `kind = "child"` y `parent_window` al parent.
- Tamaño exacto del menú.
- Posición clampeada.
- `disable_q_close = true`.
- `on_draw`, `on_mouse`, `on_mouse_move`, `on_key` cableados a los métodos internos.

Tras crear la ventana, llama `xcb.grab_pointer(conn, win.id)` para capturar todos los clicks del servidor. Mientras el grab está activo, **todos** los clicks llegan al child, incluso los que ocurren fuera de su rect. Los eventos llevan `event_x`/`event_y` relativos al child (que pueden ser negativos o mayores que su tamaño). Esto es lo que permite cerrar el menú con el primer click fuera.

`close()` libera el grab, destruye la ventana, y llama al `on_close` guardado. Es idempotente: si no hay ventana, retorna.

`is_open()` devuelve `true` si hay ventana y no está destruida.

`_draw` pinta el fondo (`theme.bg_card_rgb`), el borde (`theme.separator_rgb`), y los items. Los separadores se dibujan como una línea horizontal de 1 px. Los items con hover y habilitados reciben un fondo con `accent` a alpha 0.25. Los items deshabilitados (`enabled = false`) se dibujan en `muted_rgb`. Los items con `color` propio usan ese color para el texto.

`_index_at(my)` recorre los items contando las posiciones de las franjas (con `ITEM_H = 26` para items, `1` para separadores) y devuelve el índice del item bajo la coordenada `my`, o `nil`.

`_on_mouse(mx, my, button)` es el callback del clic. Primero chequea si el click está dentro del rect del child (`inside(x, y, w, h)`). Si está fuera, cierra y **consume** el click: no pasa al padre. Si está dentro y es botón 1, busca el item bajo el cursor y, si está habilitado y tiene `on_click`, cierra el menú **antes** de ejecutar la acción. El comentario del código aclara: se cierra primero para que el menú desaparezca antes de que la acción corra (importante si la acción abre otra ventana o bloquea).

`_on_mouse_move` actualiza `hover_idx` si el cursor está sobre un item habilitado y no es separador. Si cambió, daña la ventana del menú y llama `draw` inmediatamente.

`_on_key` maneja solo Escape: cierra el menú.

**API.**

**Construcción.**

- **`M.new(srv, parent_win, theme)`** — Crea una instancia. `srv` es el `Server`, `parent_win` la ventana padre, `theme` la tabla del theme.

**Métodos.**

| Método | Notas |
|---|---|
| `show(x, y, items, opts?)` | Abre el menú en `(x, y)` con los items dados. Cierra un menú previo si había. |
| `close()` | Cierra el menú y libera el grab. Llama a `on_close`. |
| `is_open()` | `true` si hay ventana activa. |

Forma de cada item:

- `{ label = "Terminar", on_click = function() ... end }` — item normal.
- `{ label = "Forzar", color = {0.9, 0.4, 0.4}, on_click = ... }` — con color de texto propio.
- `{ label = "Deshabilitado", enabled = false }` — sin acción, se ve en muted.
- `{ sep = true }` — separador.

`opts` de `show`: `opts.on_close` — callback al cerrar.

**Campos.**

- `srv`, `parent_win`, `theme`.
- `win` — la `Window` child actual, o `nil`.
- `items`, `hover_idx`, `on_close_cb`.
- `win_w`, `win_h` — tamaño del menú (copiado por si `win` se destruye).

**Patrón.**

Menú contextual sobre una fila de lista:

    local CM = require("lib.widgets.contextmenu")
    local cm = CM.new(srv, window, theme)

    list:on_right_click(function(item, idx)
        cm:show(mx, my, {
            { label = "Terminar", on_click = function() kill(item.pid) end },
            { label = "Forzar", color = { 0.9, 0.4, 0.4 },
              on_click = function() kill9(item.pid) end },
            { sep = true },
            { label = "Prioridad: alta", on_click = function() renice(item.pid, -5) end },
            { label = "Prioridad: baja", on_click = function() renice(item.pid, 5) end },
        })
    end)

Ver `examples/17-tab-proc.lua`.

**Anti-patrón.**

- **Crear un `ContextMenu` nuevo cada vez que se abre.** La instancia es un singleton reutilizable: `M.new` una vez, `:show` muchas veces. Crear uno por apertura acumula ventanas y grabs.
- **Llamar `show` con un `parent_win` destruido.** La nueva `Window` child se crearía contra un padre inválido y fallaría con `BadValue`. Cerrar el menú antes de destruir el padre, o re-crear el menú al reconstruir el padre.
- **Asumir que el click fuera del menú pasa al padre.** El grab consume el click: cierra el menú y no lo propaga. Es intencional, es el comportamiento estándar de los menús contextuales.
- **Ejecutar la acción antes de cerrar.** El código cierra el menú primero y luego llama `on_click`. Si se invierte el orden, el menú queda visible durante la acción, lo que puede tapar el resultado o interferir con él.
- **Pasar items con `on_click` que abren otro `ContextMenu`.** El segundo `show` cierra el primero (la primera línea de `show` lo hace). Efecto visual: el primero desaparece antes de abrir el segundo. Para submenús reales, hay que modificar el widget para soportar anidamiento.
- **Usar `ContextMenu` sin un `Server` válido.** La creación de la `Window` child necesita un `Server` con conexión XCB. Pasar `nil` lanza error en la creación.

**Notas.**

- `ContextMenu` no es un `Area`: no participa del árbol de widgets, no recibe eventos del `Window` padre. Vive en su propia `Window` child.
- El `grab_pointer` se hace al abrir y se libera al cerrar. Mientras está activo, otros widgets no reciben clicks, aunque sean de la misma aplicación. Es correcto: el menú tiene prioridad absoluta.
- El `set_input_focus` al abrir hace que el `Window` child reciba teclado. Sin él, Escape no llegaría al menú. Al cerrar, el `Window` padre debería recuperar el foco (dependiendo del WM). `notes.md` documenta el flujo de foco en `Window`.
- Los tamaños `ITEM_H`, `PAD_X`, `PAD_Y`, `MIN_W`, `FONT` están hardcodeados en el módulo. No hay opciones para cambiarlos desde `show`. Para menús con estilos distintos, modificar el módulo o escribir uno propio.
- El `chevron` que menciona el cálculo de ancho (`+ 16`) no se dibuja. Es un resto de un diseño que preveía submenús indicados con una flecha a la derecha. Hoy ese espacio queda vacío.
- El menú no cierra si el usuario cambia de ventana por otros medios (Alt+Tab, click en otra app). El grab se mantiene hasta un click o Escape. Es una limitación del `grab_pointer` frente a otros métodos de captura.

---

## README-bar.md

### Barra superior

Motor de barra data-driven. La barra se monta a partir de una spec puro dato (`layout.lua`), y cada widget de la barra se resuelve por nombre contra un registry de constructores. La estructura del motor (engine, geometry, separators) está completa; los constructores de widgets reales son placeholders en esta fase, ver `notes.md` Fase E.

#### engine.lua

**Propósito.**
Motor de barra. Lee la spec (`layout.lua`), resuelve los nombres de widgets contra un registry, monta el árbol de `Group`s que representa la barra, y aplica el modo de separador declarado (`arrow`, `glyph`, `glyph_thick`, `gap`, `none`, `underline`, `island`).

**Alcance.**
Cubre el parseo de la spec, la normalización de entradas (widgets sueltos y grupos toggle), la construcción del árbol, la aplicación de separadores según el modo, y la exposición de las instancias para que el consumidor pueda interactuar con los widgets (por ejemplo, un timer que actualice el reloj). No cubre el montaje de la `Window` que aloja la barra: eso vive en el ejemplo o en la aplicación. No cubre el cambio de layout en caliente más allá de lo que el consumidor haga con `M.build` (reconstruir y cerrar la ventana anterior). No cubre la lógica de "toggle" del grupo: expone el estado inicial pero no tiene API para cambiarlo en runtime.

**Cómo funciona.**

`normalize_entry` acepta dos formas de entrada en las listas `left`, `center` y `right` de la spec. Un string es un widget suelto. Una tabla con campo `toggle_group` es un grupo toggle que contiene una lista de nombres de widgets. Cualquier otra cosa devuelve `nil` y se ignora silenciosamente.

`flatten_list(list)` recorre una lista de la spec y la convierte en una lista plana de `{ name, group }`. Los grupos toggle se expanden en sus widgets componentes, cada uno marcado con el nombre del grupo al que pertenece. La tabla `groups` paralela guarda el estado inicial de cada grupo (`default = "visible"` o `"hidden"`).

`build_side(theme, list, registry, groups, opts)` es la pieza central. Para cada entrada de la lista plana:

1. Busca el constructor en el registry. Si no está, loguea un `warn` y salta el widget.
2. Llama al constructor con `theme` dentro de `pcall`. Si falla, loguea un `error` y salta el widget.
3. Verifica la visibilidad según el grupo (`groups[group].visible`). Los widgets de grupos ocultos no se añaden al árbol.
4. Normaliza el resultado del constructor a un "wrapper" con campos `widget`, `color`, `set_fg`. Un constructor puede devolver directamente un `Area` (envuelto internamente) o una tabla con esos campos.
5. Calcula el color de fondo (`color`) y el color del texto (`set_fg`) según el modo. En `underline` el fg es siempre `theme.fg_normal`; en otros modos, si hay `color`, el fg se calcula con `Sep.pick_fg(color)` (contraste automático por luminancia); si no hay color, cae a `theme.fg_normal`.
6. Añade el widget al árbol según el modo. En `underline` y `island`, envuelve el widget en `UnderlineBox` / `IslandBox` sin insertar separadores. En modos con fondo por widget (`arrow`, `glyph`, `glyph_thick`, `gap`, `none`), inserta un separador entre el color anterior y el nuevo cuando cambian, y envuelve el widget en un `ColorBox` si tiene color. En `none` además inserta un `GapSep` entre widgets adyacentes sin colores.

`insert_separator(prev_color, next_color)` elige el separador según `sep_style`. `arrow` construye un `ArrowSep` con los dos colores. `glyph` y `glyph_thick` insertan un `GlyphSep` con el carácter `"│"` o `"┃"` y el color del separador del theme. `gap` inserta un `GapSep` del ancho configurado. `none`, `underline` e `island` no insertan nada.

El color "actual" se lleva en `current_color`, inicializado al color de fondo del theme (`T.bg_rgb` convertido a hex). Cuando un widget con color aparece y su color es distinto del actual, se inserta un separador de transición antes. Cuando un widget sin color aparece después de uno con color, se inserta un separador hacia "alpha" (un color especial que el `ArrowSep` interpreta como el fondo del theme).

Cada lado (`left`, `center`, `right`) se construye independientemente con `build_side`, y luego se combinan en un `Group` horizontal raíz. El reparto de pesos es: `left` weight 0 (natural), `center` weight 1 (absorbe el resto), `right` weight 0 (natural). Esto alinea `left` a la izquierda, `right` a la derecha, y `center` en el espacio entre ambos. `notes.md` lo documenta como el reparto esperado.

`M.adjust_height(base_h, sep_style)` ajusta el alto de la barra según el modo: `underline` suma 6 px (para el subrayado), `island` suma 8 px (para el margen del fondo redondeado). Los demás modos no ajustan.

`M.build(theme, spec, registry)` orquesta todo: parsea la spec, aplana las listas, construye cada lado, los combina en el `Group` raíz, y devuelve una tabla con `widget` (el `Group` raíz), `height` (alto ajustado), `sep_style` (el modo), `groups` (estado inicial de los grupos toggle) e `instances` (mapa nombre de widget → objeto devuelto por su constructor).

**API.**

**Funciones.**

- **`M.build(theme, spec, registry)`** — Monta la barra. Devuelve `{ widget, height, sep_style, groups, instances }`.
- **`M.adjust_height(base_h, sep_style)`** — Devuelve el alto ajustado según el modo de separador.

**Forma de la spec.**

- `spec.height` — alto base de la barra en px (default 22).
- `spec.separator` — modo: `"arrow"` (default), `"glyph"`, `"glyph_thick"`, `"gap"`, `"none"`, `"underline"`, `"island"`.
- `spec.gap` — separación entre widgets adyacentes en px (default 12). Aplica en modos `gap` y `none`, y en el caso sin color.
- `spec.left`, `spec.center`, `spec.right` — listas de entradas.

Forma de cada entrada de lista:

- `"nombre"` — widget suelto. El nombre se resuelve contra el registry.
- `{ toggle_group = "nombre", default = "visible" | "hidden", widgets = { "a", "b", ... } }` — grupo toggle.

**Forma del resultado de un constructor del registry.**

- `Area` — widget directo. Se envuelve internamente en `{ widget = Area }`.
- `{ widget = Area, color = "#hex"?, set_fg = function(hex)? }` — wrapper con color de fondo y opcional callback de cambio de color de texto.

**Forma del retorno de `M.build`.**

- `widget` — el `Group` raíz.
- `height` — alto ajustado por `M.adjust_height`.
- `sep_style` — el modo usado.
- `groups` — tabla `nombre → { default, visible }`.
- `instances` — tabla `nombre → objeto` (el retorno del constructor).

**Patrón.**

Montaje desde un ejemplo con `layout.lua` como spec:

    local Bar = require("lib.bar.engine")
    local registry = require("lib.bar.constructors")
    local spec = dofile("layout.lua")

    local built = Bar.build(theme, spec, registry)

    local win = Window.new(srv, {
        kind = "menu",
        width = mon.w,
        height = built.height,
        x = mon.x, y = mon.y,
    })
    win:set_root(built.widget)

    -- Actualizar el reloj periódicamente desde las instancias:
    local clock = built.instances.clock
    if clock and clock.widget then
        srv:add_timer(1000, function()
            clock.widget:set_text(os.date("%H:%M"))
        end)
    end

Ver `examples/23-bar.lua`.

**Anti-patrón.**

- **Asumir que todos los nombres de la spec tienen constructor.** Un nombre sin constructor se salta con `log.warn` y no aparece en la barra. La barra se monta igual, pero con huecos. Revisar los `warn` en el arranque tras cambios en `layout.lua`.
- **Pasar un `theme` sin `bg_rgb`.** El código hace `T.bg_rgb and Sep.rgb_to_hex(T.bg_rgb) or "#000000"`. Sin `bg_rgb`, el color de fondo "actual" inicial es negro, lo que produce separadores con fondo negro. El theme cargado por `lib.theme.load` siempre tiene `bg_rgb`.
- **Cambiar la spec en runtime y esperar que la barra se actualice.** No lo hace. La spec se lee una sola vez en `build`. Para cambiar el layout, hay que destruir la `Window` anterior, volver a llamar a `M.build` y montar la nueva. `notes.md` documenta este patrón como "cambio de layout en caliente" del ejemplo.
- **Asumir que los grupos toggle tienen API de cambio en runtime.** `M.build` expone `groups` con el estado inicial, pero no hay método para togglear un grupo. Si se necesita, el consumidor tiene que reconstruir la barra o mutar el árbol directamente y llamar `invalidate_layout`.
- **Llamar `M.build` sin un registry completo.** Los constructores que faltan se saltan silenciosamente. En desarrollo, los `warn` ayudan; en producción, la barra queda con menos widgets de los esperados sin indicación visual.

**Notas.**

- El `Group` raíz usa `spacing = 0` y `padding = 0`. Toda la separación viene de los `GapSep` y `ArrowSep` insertados por el motor. Los widgets de la barra no llevan padding propio salvo el que su constructor decida.
- El reparto de pesos `left = 0`, `center = 1`, `right = 0` hace que el centro absorba todo el espacio sobrante. El `center` queda alineado al espacio entre `left` y `right`, no al centro geométrico de la barra. Es lo estándar y lo que espera el usuario.
- `pick_fg` usa la fórmula estándar de luminancia perceptual (`0.299*R + 0.587*G + 0.114*B`). El umbral `0.55` divide entre "fondo claro, texto negro" y "fondo oscuro, texto blanco". Los colores saturados con luminancia cercana al umbral pueden quedar con fg poco contrastado.
- El modo `underline` no inserta separadores aunque los widgets tengan color: la transición entre colores se ve como un cambio brusco de subrayado, sin flecha ni glyph. Es intencional.
- El modo `island` envuelve cada widget en una caja redondeada con `vgap = 4` por defecto. El alto total se ajusta en `adjust_height` para acomodar el margen.
- Los separadores `arrow` usan el color `"alpha"` como marcador especial para "el fondo del theme". `ArrowSep` interpreta `"alpha"` como `theme.bg_rgb`. Es el único valor reservado además de los colores hex.

#### geometry.lua

**Propósito.**
Traduce una spec de posición a coordenadas absolutas sobre un monitor. Devuelve el rectángulo `{x, y, w, h}` y la `position` resuelta, listo para pasárselo a `Window.new`.

**Alcance.**
Cubre cinco posiciones (`top`, `bottom`, `left`, `right`, `free`), resolución de dimensiones y posiciones en píxeles, `"screen"`, porcentajes y palabras reservadas (`"center"`, `"start"`, `"end"`), y márgenes por lado. No cubre múltiples monitores: recibe un monitor ya resuelto (vía `lib.screens.at` o similar). No cubre validación de que el rect resultante esté dentro del monitor: un margen mayor que el tamaño del monitor produce un rect con ancho o alto negativos, que el llamador debe evitar.

**Cómo funciona.**

`dim(val, avail)` resuelve una dimensión (ancho o alto). Acepta un número (píxeles), `"screen"` (el tamaño completo del monitor), un string `"N%"` (porcentaje), o `nil`. Cualquier otra cosa lanza `error`. Los porcentajes se calculan sobre `avail` (el ancho o alto del monitor).

`pos(val, avail, size)` resuelve una posición (x o y). Acepta un número, `"center"` (centrado, `(avail - size) / 2`), `"start"` (0), `"end"` (`avail - size`), un string `"N%"`, o `nil` (que se interpreta como 0). Cualquier otra cosa lanza `error`.

`M.compute(spec, mon)` es la función pública. Resuelve los márgenes de `spec.margin` como un array `[top, right, bottom, left]`. Luego ramifica según `position`:

- `"top"`: ancho `spec.width or "screen"`, alto `spec.height or 24`. Posición `(mon.x + ml, mon.y + mt)`.
- `"bottom"`: ancho `spec.width or "screen"`, alto `spec.height or 24`. Posición `(mon.x + ml, mon.y + mon.h - h - mb)`.
- `"left"`: ancho `spec.width or 24`, alto `spec.height or "screen"`. Posición `(mon.x + ml, mon.y + mt)`.
- `"right"`: ancho `spec.width or 24`, alto `spec.height or "screen"`. Posición `(mon.x + mon.w - w - mr, mon.y + mt)`.
- `"free"`: ancho `spec.width or 200`, alto `spec.height or 24`. Posición `(mon.x + pos(spec.x, mon.w, w), mon.y + pos(spec.y, mon.h, h))`.

Los defaults dependen de la posición: top y bottom asumen `"screen"` de ancho y 24 px de alto; left y right asumen 24 px de ancho y `"screen"` de alto. `free` no tiene defaults "naturales" y usa 200×24 como fallback.

Los márgenes se aplican sumando a las coordenadas del monitor. En top y left suman al inicio (`+ml`, `+mt`); en bottom y right restan del final (`- mb`, `- mr`).

**API.**

**Funciones.**

- **`M.compute(spec, mon)`** — Resuelve la spec contra el monitor. Devuelve `{ x, y, w, h, position }`.

**Forma de `spec`.**

- `spec.position` — `"top"` (default), `"bottom"`, `"left"`, `"right"`, `"free"`.
- `spec.width` — dimensión. Número, `"screen"` o `"N%"`. Default según posición.
- `spec.height` — dimensión. Número, `"screen"` o `"N%"`. Default según posición.
- `spec.margin` — array `[top, right, bottom, left]` en px. Default `[0, 0, 0, 0]`.
- `spec.x`, `spec.y` — solo para `position = "free"`. Número, `"center"`, `"start"`, `"end"` o `"N%"`.

**Forma de `mon`.**

- `mon.x`, `mon.y` — esquina superior izquierda del monitor en coordenadas absolutas.
- `mon.w`, `mon.h` — tamaño del monitor.

**Patrón.**

Barra superior ocupando todo el ancho del monitor principal:

    local screens = require("lib.screens")
    local geom = require("lib.bar.geometry")

    local mon = screens.list()[1]
    local r = geom.compute({
        position = "top",
        height = 24,
        margin = { 0, 0, 0, 0 },
    }, mon)
    -- r = { x = mon.x, y = mon.y, w = mon.w, h = 24, position = "top" }

Barra flotante centrada arriba (dock tipo macOS):

    local r = geom.compute({
        position = "free",
        width = 600,
        height = 30,
        x = "center",
        y = 8,
    }, mon)

Ver `examples/23-bar.lua`.

**Anti-patrón.**

- **Pasar un `mon` que no tenga `x`, `y`, `w`, `h`.** El código accede directamente a esos campos. Un monitor mal formado produce `nil` en las sumas y `error` en `math.floor`. Usar `screens.at(cx, cy)` o `screens.list()[1]` para obtener monitores válidos.
- **Pasar `spec.margin` como tabla con claves (`{top = 8}`).** El código espera un array posicional `[top, right, bottom, left]`. Con claves, `m[1]` es `nil` y los márgenes quedan en 0.
- **Asumir que un margen mayor que el tamaño del monitor se clampa.** No lo hace. Un margen de 2000 en un monitor de 1080 produce un rect con alto negativo. `Window.new` fallaría al crear la ventana con dimensiones inválidas.
- **Confundir `"screen"` con el monitor actual.** `"screen"` se resuelve contra el `mon` recibido, no contra la pantalla virtual completa. Para una barra en un monitor concreto, pasar ese monitor.
- **Usar `"free"` sin `x` ni `y`.** Los defaults son 0, lo que pone la barra en la esquina superior izquierda del monitor. Si se quiere centrada, pasar `x = "center"` explícitamente.

**Notas.**

- El default de 24 px de alto para top/bottom es coherente con el alto base de la barra en `engine.lua` (`spec.height or 22`). Los dos defaults son independientes: la barra puede tener un alto de 22 en el motor y el rect calculado por geometría 24, si el consumidor no pasa `height` a la geometría. En la práctica, el consumidor pasa el mismo valor a ambos.
- Los porcentajes en dimensiones se calculan como `floor(avail * N / 100)`, que puede redondear hacia abajo. Un `50%` en un monitor de 1081 da 540, no 541. El píxel sobrante queda sin cubrir.
- Los márgenes no se ajustan por porcentaje: son siempre píxeles.
- `position` se devuelve en el resultado para que el consumidor pueda consultarlo sin volver a leer la spec.
- `dim` y `pos` son funciones locales. No se exportan. Si se necesita resolver una dimensión suelta, usar `M.compute` con una spec mínima.

#### separators.lua

**Propósito.**
Primitivas de separadores y envoltorios que el motor de barra usa para componer los widgets según el modo declarado. Incluye utilidades de color para contraste automático (luminancia, elección de color de texto).

**Alcance.**
Cubre cuatro tipos de separador (`ArrowSep`, `GlyphSep`, `GapSep`, y el envoltorio `Wrapper` con tres modos: `bg`, `underline`, `island`) y tres utilidades de color (`luminance`, `pick_fg`, `rgb_to_hex`). No cubre modos de separador que no estén en el motor. No cubre interacción: los separadores y envoltorios no tienen handlers de ratón, son puramente visuales. No cubre rotación para barras verticales.

**Cómo funciona.**

`M.luminance(hex)` calcula la luminancia perceptual de un color hex con la fórmula estándar `(0.299*R + 0.587*G + 0.114*B) / 255`. Devuelve un valor en `[0, 1]` donde 0 es negro y 1 es blanco. Un color con menos de 7 caracteres devuelve `0.5` (gris neutro). Esto protege contra hex malformados sin lanzar error.

`M.pick_fg(hex)` usa la luminancia para elegir entre `"#000000"` y `"#FEFEFE"`. El umbral es `0.55`: por encima, negro; por debajo, blanco casi puro. El umbral no es 0.5 porque la percepción humana del contraste no es lineal respecto a la luminancia; el ligero desvío favorece el texto negro en colores un poco más oscuros de lo que sugeriría el cálculo puro. `notes.md` documenta la decisión de contraste automático.

`M.rgb_to_hex(rgb)` convierte una tabla `{r, g, b}` de floats `[0, 1]` a string `"#rrggbb"`. Cada componente se multiplica por 255, se redondea con `+0.5` y `floor`, y se formatea en hexadecimal de 2 dígitos. Se usa en el motor para convertir `theme.bg_rgb` (tabla) a hex (string), que es lo que esperan los separadores.

`ArrowSep` dibuja un rectángulo de fondo con `color_from` y un triángulo del color `color_to` encima. El triángulo tiene base a la derecha (todo el ancho del separador) y pico en el centro del lado izquierdo, formando una flecha que apunta hacia la izquierda. El efecto visual es una transición diagonal entre dos colores contiguos: el fondo pertenece al widget anterior, el triángulo al siguiente. El color especial `"alpha"` en `color_to` se interpreta como `theme.bg_rgb`. Si `color_from` es `"alpha"` o `nil`, no se dibuja el fondo (queda transparente).

`GlyphSep(char, color, font)` devuelve un `Text` con el carácter dado (`"│"` o `"┃"`), centrado, con el color y la fuente. El ancho mínimo y máximo se fijan a 12 px para que el glifo no crezca aunque el `Text` tenga `max_w = 10000`. La elección del ancho fijo es lo que da consistencia visual entre separadores en la barra.

`GapSep(width)` devuelve un `Text` con texto vacío y fuente `"DejaVu Sans 1"`. El ancho mínimo y máximo se fijan al `width` configurado. El texto vacío no se dibuja; el widget es puramente espacial. La fuente mínima es un truco para que `pango.measure("")` no falle y para reducir el alto natural del `Text` al mínimo.

`Wrapper` es un `Area` que envuelve otro `Area` con uno de tres modos visuales. En modo `bg`, pinta un rectángulo lleno con `color` de fondo y dibuja el hijo encima. En modo `underline`, pinta una franja horizontal de 2 px en la parte inferior del rect con `color` y dibuja el hijo encima. En modo `island`, pinta un `rounded_rect` con `radius` (default 3) y `vgap` (default 4) de margen vertical, con `color` de fondo.

`Wrapper:askMinMax` suma los mínimos del hijo más `pad_x * 2` en ancho y `vgap * 2` en alto. `pad_x` es 0 en los tres constructores públicos (`ColorBox`, `UnderlineBox`, `IslandBox`), así que el padding viene dado por los propios widgets.

`Wrapper:layout` asigna el rect al hijo. En modo `island`, el hijo se posiciona con margen vertical `vgap`; en los otros modos, ocupa todo el rect horizontalmente (menos `pad_x`).

`Wrapper:draw` pinta el fondo (o el subrayado, o la isla) con `color` y luego dibuja el hijo. `Wrapper:getByXY` delega al hijo y cae al `Area:getByXY` base si el hijo no acierta.

`M.ColorBox(inner, color)`, `M.UnderlineBox(inner, color)` y `M.IslandBox(inner, color, vgap)` son constructores de conveniencia. Fijan `pad_x = 0` y ajustan el `vgap` del modo `island`. Son los que usa el motor desde `build_side`.

**API.**

**Utilidades de color.**

| Función | Retorno | Notas |
|---|---|---|
| `luminance(hex)` | float `[0, 1]` | Luminancia perceptual. Hex malformado devuelve 0.5. |
| `pick_fg(hex)` | string | `"#000000"` o `"#FEFEFE"` según umbral 0.55. |
| `rgb_to_hex(rgb)` | string `"#rrggbb"` | Convierte tabla de floats a hex. |

**Separadores.**

- **`M.ArrowSep.new(color_from, color_to, theme, width?)`** — Triángulo de transición. `width` default 16. `color_to` puede ser `"alpha"` para usar `theme.bg_rgb`.
- **`M.GlyphSep(char, color, font?)`** — `Text` con el glifo dado, ancho fijo 12 px. `font` default `"DejaVu Sans 10"`.
- **`M.GapSep(width)`** — `Text` vacío con ancho fijo `width`. Sin fondo.

**Envoltorios.**

- **`M.ColorBox(inner, color)`** — Fondo lleno con `color`.
- **`M.UnderlineBox(inner, color)`** — Subrayado inferior con `color`.
- **`M.IslandBox(inner, color, vgap?)`** — Fondo redondeado con `color` y margen vertical `vgap` (default 4).

**Wrapper (clase).**

- **`Wrapper.new(inner, mode, color, opts)`** — Constructor directo. `mode` es `"bg"`, `"underline"` o `"island"`. `opts.radius`, `opts.vgap`, `opts.pad_x`.

**Patrón.**

Uso directo desde el motor (lo que ocurre dentro de `build_side`):

    local Sep = require("lib.bar.separators")

    -- Separador de transición entre dos colores
    local arrow = Sep.ArrowSep.new("#d79921", "#83a598", theme)

    -- Envolver un widget con fondo
    local boxed = Sep.ColorBox(cpu_widget, "#d79921")

    -- Isla con margen vertical
    local island = Sep.IslandBox(clock_widget, "#458588", 3)

Contraste automático desde el color de fondo:

    local fg = Sep.pick_fg("#d79921")  -- -> "#000000" (fondo claro)
    local fg2 = Sep.pick_fg("#1d2021") -- -> "#FEFEFE" (fondo oscuro)

Ver `examples/23-bar.lua`.

**Anti-patrón.**

- **Pasar un color `"alpha"` como `color_from` a `ArrowSep`.** El código comprueba `color_from and color_from ~= "alpha"` antes de dibujar el fondo, así que el resultado es un fondo transparente. Es válido pero inusual: el triángulo se dibuja sobre un fondo sin pintar, lo que puede dejar restos de píxeles previos si no se limpia antes. El motor nunca pasa `"alpha"` como `color_from`, solo como `color_to`.
- **Pasar un hex malformado a `luminance` o `pick_fg`.** `luminance` devuelve `0.5` si el hex tiene menos de 7 caracteres. `pick_fg` devuelve `"#FEFEFE"` porque `0.5 <= 0.55`. Un color malformado no lanza error, pero el fg resultante puede ser inesperado.
- **Asumir que `GlyphSep` y `GapSep` aceptan clics.** Son `Text`, sin handlers. Un click sobre ellos se propaga al padre (`Group`) y este lo descarta. No hay forma de hacerlos interactivos sin cambiar el tipo de widget.
- **Pasar un `inner` nulo a `ColorBox` o `IslandBox`.** El `Wrapper` acepta `inner = nil` y dibuja solo el fondo. Es válido pero el resultado es un rectángulo de color sin contenido. Si el motor llama a `emit` con un wrapper sin widget, el resultado es un bloque de color. `build_side` no lo hace porque salta los constructores que fallan.
- **Usar `Wrapper.new` directamente en lugar de los constructores.** Los constructores fijan `pad_x = 0`; `Wrapper.new` permite `pad_x` arbitrario, lo que puede desalinear el contenido respecto a otros widgets. La única razón para usarlo directo es un `pad_x` distinto de 0.

**Notas.**

- El `ArrowSep` no lleva `new_sub_path` antes del `move_to` del triángulo. En el motor se llama después de otros separadores que sí limpian sus paths, así que en la práctica funciona. Si en el futuro se usa de forma aislada, conviene añadir `cairo.new_path` antes del `move_to` por consistencia con el patrón general de Cairo documentado en `notes.md`.
- El umbral `0.55` de `pick_fg` es un valor empírico. Colores con luminancia exactamente en el umbral (por ejemplo, algunos amarillos saturados) pueden quedar con texto poco contrastado. Ajustar el umbral no está expuesto como opción.
- `GlyphSep` y `GapSep` devuelven `Text`, no `Wrapper`. El motor los añade directamente al `Group` sin envolverlos. Esto significa que no llevan fondo ni color propio más allá del que el propio `Text` dibuje.
- El modo `island` se ajusta en alto con `+8` desde `M.adjust_height` en `engine.lua`. El `Wrapper:askMinMax` del modo island suma `vgap * 2 = 8` al alto mínimo del hijo, lo que concuerda con el ajuste del motor. Si el `vgap` cambia, el ajuste del motor sigue siendo `+8`, lo que puede desalinearlos. Es una limitación conocida: el `vgap` no es configurable desde la spec hoy.
- `M.rgb_to_hex` redondea con `+0.5` antes de `floor`. Un componente de `0.5` exacto se convierte en `128`, que es el punto medio entre `127` y `128`. La convención estándar para redondeo a entero sería `floor(x + 0.5)`, que es lo que hace. Correcto.

#### constructors.lua

**Propósito.**
Registry de constructores de widgets de barra. Mapea nombres (`"cpu"`, `"clock"`, `"mem"`, etc.) a funciones que construyen el widget correspondiente a partir del theme. Es el punto de extensión que el motor consulta para resolver los nombres de la spec.

**Alcance.**
En esta fase los constructores son **placeholders**: devuelven `Text` con una etiqueta corta (`"cpu"`, `"mem"`, etc.) en lugar de widgets reales con telemetría. La estructura (firma, convención de retorno, color por telemetría) está completa y es la que usarán los constructores reales. No cubre la implementación real de los widgets de telemetría (icono, valor numérico, timer propio): eso es la Fase E documentada en `notes.md`. No cubre widgets que necesiten el `Server` para timers: la firma actual `fn(theme)` no lo recibe, y añadirlo requeriría cambiar el motor.

**Cómo funciona.**

`text_widget(opts)` es un helper local. Construye un `W.Text` con las opciones dadas y lo devuelve envuelto en `{ widget = t, set_fg = function(hex) ... end }`. El `set_fg` cierra sobre el `Text` y llama a `t:set_color(...)` con el color convertido de hex a `r, g, b`. Esto es lo que el motor usa para recolorear el texto de los widgets según el color de fondo calculado por contraste.

`with_color(res, hex)` añade el campo `color = hex` al resultado de `text_widget`. Ese campo es el que el motor lee para decidir el fondo del widget (modos `bg`, `island`, `underline`) y para calcular el `fg` por contraste con `Sep.pick_fg`.

Los constructores de **widgets sin color de telemetría** (`clock`, `taglist`, `prompt`) devuelven directamente `text_widget` sin `with_color`. El motor los trata como widgets de fondo transparente: no llevan color propio, el fg se toma del theme (`T.fg_normal`).

`clock` construye un `Text` con la hora actual (`os.date("%H:%M")`) en fuente bold y color `theme.accent_rgb` con fallback a `fg_rgb`. El color se fija en construcción, no se actualiza: para que el reloj avance hay que actualizar el texto desde fuera (ver el patrón).

`taglist` y `prompt` construyen `Text` con contenido placeholder (`"tags"` y `""` respectivamente) en color `fg_rgb`. Son stubs: el `taglist` real necesita hablar con EWMH y el `prompt` necesita coordinación con el WM, ninguno de los cuales existe todavía.

Los constructores de **widgets con color de telemetría** se generan con `telemetry(label, key)`. Es una factoría que devuelve la función del constructor. Cada constructor resultante:

1. Lee `theme.telemetry.<key>` con fallback a `theme.accent` y después a `"#808080"`.
2. Construye un `Text` con el `label` pasado y color `fg_rgb` (o blanco casi puro).
3. Envuelve el resultado con `with_color(res, hex)` para que el motor sepa el color de fondo.

La tabla de mapeo nombre → clave de telemetría:

- `cpu` → `telemetry.cpu`
- `mem` → `telemetry.ram`
- `gpu` → `telemetry.gpu`
- `net` → `telemetry.internet`
- `temp` → `telemetry.temp`
- `bright` → `telemetry.bright`
- `vol` → `telemetry.volume`
- `bat` → `telemetry.battery`

Los labels son cortos (`"cpu"`, `"mem"`, `"gri"`, `"bri"`, `"vol"`, `"bat"`) para que el widget placeholder ocupe poco y no distorsione el layout de la barra mientras se reemplaza por el widget real.

`M.register(name, fn)` permite añadir constructores externos en runtime. Es el punto de extensión documentado: un consumidor puede registrar sus propios widgets (`M.register("mi_widget", function(theme) ... end)`) sin tocar el módulo.

**API.**

**Constructores.**

| Nombre | Devuelve | Notas |
|---|---|---|
| `clock` | `{ widget, set_fg }` | Hora actual, color `accent_rgb` o `fg_rgb`. |
| `taglist` | `{ widget, set_fg }` | Placeholder `"tags"`. |
| `prompt` | `{ widget, set_fg }` | Placeholder vacío. |
| `cpu` | `{ widget, color, set_fg }` | Placeholder `"cpu"`, color de `telemetry.cpu`. |
| `mem` | `{ widget, color, set_fg }` | Placeholder `"mem"`, color de `telemetry.ram`. |
| `gpu` | `{ widget, color, set_fg }` | Placeholder `"gpu"`, color de `telemetry.gpu`. |
| `net` | `{ widget, color, set_fg }` | Placeholder `"net"`, color de `telemetry.internet`. |
| `temp` | `{ widget, color, set_fg }` | Placeholder `"temp"`, color de `telemetry.temp`. |
| `bright` | `{ widget, color, set_fg }` | Placeholder `"bri"`, color de `telemetry.bright`. |
| `vol` | `{ widget, color, set_fg }` | Placeholder `"vol"`, color de `telemetry.volume`. |
| `bat` | `{ widget, color, set_fg }` | Placeholder `"bat"`, color de `telemetry.battery`. |

**Funciones.**

- **`M.register(name, fn)`** — Registra un constructor nuevo. `fn` es `function(theme) -> Area | { widget, color?, set_fg? }`. Sobrescribe si el nombre ya existe.

**Forma del retorno de un constructor.**

- `Area` — widget directo, sin color. El motor lo envuelve internamente.
- `{ widget = Area, color = "#hex"?, set_fg = function(hex)? }` — wrapper con color de fondo y callback de color de texto.

**Patrón.**

Actualizar el reloj desde fuera, porque el constructor no registra timers:

    local built = Bar.build(theme, spec, registry)

    local clock = built.instances.clock
    if clock and clock.widget then
        srv:add_timer(1000, function()
            clock.widget:set_text(os.date("%H:%M"))
        end)
    end

Registrar un widget propio:

    local constructors = require("lib.bar.constructors")
    local W = require("lib.widgets")

    constructors.register("battery_icon", function(theme)
        local icon = W.Icon.new {
            path = "icons-png/32/battery.png",
            width = 16, height = 16,
        }
        return {
            widget = icon,
            color = theme.telemetry.battery or theme.accent,
            set_fg = function(hex)
                local G = require("lib.helpers.graphics")
                local r, g, b = G.hex_to_rgba(hex)
                icon:set_color(r, g, b)
            end,
        }
    end)

Ver `examples/23-bar.lua` para el flujo completo.

**Anti-patrón.**

- **Asumir que los placeholders son funcionales.** El `cpu` placeholder muestra la palabra `"cpu"`, no el uso de CPU. El motor y la spec funcionan, pero la barra no tiene telemetría real hasta que se porte la Fase E. `notes.md` lo documenta como el próximo hito de la barra.
- **Registrar un constructor con la misma firma errónea.** `M.register` acepta cualquier función. Un constructor que no devuelva `Area` ni `{ widget }` hará que el motor lo ignore con un log de error. No hay validación en el momento de registrar.
- **Esperar que el constructor reciba el `Server`.** La firma es `function(theme)`. Los constructores que necesiten timers tienen que obtenerlos por otra vía (por ejemplo, clausurar el `Server` desde fuera). Es una limitación del diseño actual.
- **Asumir que `theme.telemetry` tiene todas las claves.** El código hace `(T.telemetry and T.telemetry[key]) or T.accent or "#808080"`. Una paleta sin `telemetry.internet` cae a `theme.accent`. Es intencional: las paletas pueden definir solo las claves que quieran.
- **Reemplazar un constructor built-in sin saber que pierdes el placeholder.** `M.register("cpu", fn)` sobrescribe el `cpu` actual. Si `fn` falla, el motor loguea el error y el widget no aparece en la barra. El placeholder anterior no se recupera sin reiniciar el proceso.
- **Devolver `nil` desde un constructor.** El motor hace `if not ok or not res then log.error(...)`. Un `nil` explícito se trata como fallo y el widget se salta. Es correcto pero puede pasar inadvertido si el consumidor esperaba un widget con contenido vacío.

**Notas.**

- La firma de los constructores no recibe el `Server`. En la Fase E del port, es previsible que se añada el `srv` como segundo argumento. `notes.md` lo menciona como posible cambio de firma.
- Los placeholders usan `Text` como base. Reemplazarlos por widgets reales (por ejemplo, `Icon` + `Text` en un `Group`) no requiere cambios en el motor: mientras la firma de retorno se respete, el motor los monta igual.
- El `set_fg` es lo que permite que el texto del widget tenga contraste con su fondo en modos como `arrow` o `island`. Un constructor que devuelva un widget sin `set_fg` deja el color del texto a cargo del widget, que puede quedar ilegible sobre fondos saturados.
- El color `"#808080"` de fallback es un gris neutro que no armoniza con ninguna paleta. Es solo un último recurso para que la barra no falle si no hay theme. En la práctica, `theme.accent` está siempre disponible.
- Los placeholders usan `font = "DejaVu Sans 10"` y `align = "center"`, `valign = "center"`. Es lo que hace que los textos de la barra queden centrados verticalmente en el alto ajustado. El widget real heredará esos valores o los sobreescribirá según su diseño.
- `M.register` muta el módulo. El cambio afecta a todas las llamadas posteriores a `Bar.build`. No hay forma de deshacer un `register` salvo reemplazar la función por la original.

---

### Pendiente: Fase E de la barra

El motor y la composición están completos. Los constructores son placeholders. La Fase E consiste en reemplazarlos por widgets reales con:

- Icono (`W.Icon` con PNG en `icons-png/32/`).
- Valor numérico de los samplers de `lib/data/` (`cpu`, `ram`, `gpu`, `temps`, `bat`, `net`, `wifi`).
- Colores dinámicos desde `theme.telemetry.<key>`.
- Timers propios registrados contra el `Server`.

La firma de los constructores probablemente cambie a `fn(theme, srv)` para permitir los timers. Los archivos del proyecto Awesome original (`~/.config/awesome/widgets/*.lua`) sirven de spec visual. `notes.md` tiene la lista de samplers disponibles y los pendientes.

## README-data.md

### Samplers

Módulos que leen datos del sistema: `/proc`, `/sys`, comandos shell, archivos cacheados por servicios externos. Devuelven tablas Lua sin conocer el toolkit, los widgets ni el theme. Los tabs los consumen y los formatean. La convención de nombres es `M.sample()` para lecturas periódicas, `M.info()` para datos estáticos del sistema, y `M.status()` para casos particulares.

#### init.lua

**Propósito.**
Registry de samplers. Reexporta los módulos más usados como campos de una tabla para que un consumidor pueda hacer `D.cpu.sample()` sin requerir cada uno por separado.

**Alcance.**
Reexporta `cpu`, `ram`, `gpu`, `temps`, `disk`, `dispositivos`, `notes`, `config`, `inicio`, `search`, `bat`. No reexporta `net`, `wifi`, `ping`, `launcher`: se importan por ruta completa cuando se necesitan.

**Cómo funciona.**

Es un módulo de tres líneas efectivas: crea `M`, asigna campos con `require("lib.data.<nombre>")` y lo devuelve. Importar `lib.data` carga los once módulos reexportados, lo que a su vez carga sus dependencias (`helpers.util`, `helpers.async`, `helpers.graphics` indirectamente). Es una carga completa, sin lazy loading.

**API.**

**Campos.**

- `cpu`, `ram`, `gpu`, `temps`, `disk`, `dispositivos`, `notes`, `config`, `inicio`, `search`, `bat` — cada uno es la tabla del módulo correspondiente.

**Patrón.**

    local D = require("lib.data")
    local s = D.cpu.sample()

O importar solo lo necesario:

    local cpu = require("lib.data.cpu")

**Anti-patrón.**

- **Asumir que todos los samplers están en el registry.** Los ausentes (`net`, `wifi`, `ping`, `launcher`) hay que importarlos por ruta completa.
- **Requerir `lib.data` por comodidad cuando solo se necesita un sampler.** Carga once módulos en memoria. Para un script suelto, importar el específico.

**Notas.**

- No hay orden de carga particular: cada módulo se carga independientemente al hacer `require`.

---

#### cpu.lua

**Propósito.**
Lectura de uso de CPU, frecuencias, temperaturas y datos estáticos del procesador. Fuentes: `/proc/stat`, `/proc/cpuinfo`, `/proc/uptime`, `/proc/loadavg`, `/sys/devices/system/cpu/cpu0/cpufreq/*` y `/sys/class/hwmon/*/temp*_input` (coretemp).

**Alcance.**
Cubre uso total y por núcleo, frecuencia actual, rango de frecuencias (min/max), temperatura del paquete y núcleos 0/1, modelo del CPU, uptime y load average. No cubre frecuencia por núcleo individual. No cubre temperaturas de otros chips que no sean coretemp. No cubre cambios de governor ni ajustes.

**Cómo funciona.**

`read_stat()` lee `/proc/stat` línea a línea y extrae, para cada línea `cpuN`, los campos `user`, `nice`, `system`, `idle`, `iowait`, `irq`, `softirq`, `steal`. El campo `active` es la suma de `user + nice + system + irq + softirq + steal`. El campo `idle` es `idle + iowait`. Devuelve una tabla `nombre_cpu → { active, idle }`.

`M.sample()` compara el estado actual con el anterior (guardado en `prev_stat` en el módulo). El delta de `active` dividido por el delta total da el porcentaje de uso en el intervalo entre llamadas. La primera llamada devuelve `usage = 0` porque no hay estado previo. `notes.md` documenta el patrón: la primera lectura después del arranque no es un uso real, es ruido.

`ensure_coretemp()` es una inicialización con cache. Recorre `/sys/class/hwmon/hwmon0..9`, busca el que tenga `name = "coretemp"`, y guarda la ruta. Después recorre `temp1_input` a `temp20_input` buscando los que existan, más sus `_label` correspondientes. El resultado se guarda en `coretemp_path` y `coretemp_files`. Si no encuentra ningún coretemp, guarda `false` como marcador para no reintentar en cada llamada. `read_temp()` busca `Package id 0` o `Core 0` en los labels y devuelve la temperatura en grados. Si no encuentra ninguno, devuelve 0.

`M.sample()` devuelve `{ usage, per_core, n_cores, freq, temp }`. `per_core` es una tabla indexada por número de núcleo (1-based según el índice extraído del nombre `cpuN`). `freq` es la frecuencia actual en MHz, leída de `scaling_cur_freq` de `cpu0` (kHz) dividida por 1000. `n_cores` cuenta cuántas entradas `cpuN` hay en `/proc/stat`.

`M.info()` devuelve `{ model, uptime, loadavg }`. El modelo se extrae de `/proc/cpuinfo` con `model name`, y se limpia de paréntesis `(R)`, `(TM)`, y espacios múltiples. `uptime` es el primer valor de `/proc/uptime` en segundos. `loadavg` es el primer valor de `/proc/loadavg` como string (se mantiene string porque solo se muestra).

`M.freq_range()` lee `cpuinfo_min_freq` y `cpuinfo_max_freq` de `cpu0`. Si no existen o son 0, usa defaults `800` y `1100`. Los valores están en kHz y se convierten a MHz.

`M.reset()` limpia `prev_stat`. Útil si se quiere forzar que la próxima llamada a `sample()` no tenga en cuenta el intervalo previo (por ejemplo, tras un suspend/resume).

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `sample()` | tabla | `{ usage, per_core, n_cores, freq, temp }`. |
| `info()` | tabla | `{ model, uptime, loadavg }`. |
| `freq_range()` | tabla | `{ min, max }` en MHz. |
| `reset()` | — | Limpia el estado previo. |

**Campos del retorno de `sample`.**

- `usage` — float `[0, 1]`. 0 en la primera llamada.
- `per_core` — tabla `índice → float [0, 1]`.
- `n_cores` — número de núcleos detectados.
- `freq` — MHz actuales (de `cpu0`).
- `temp` — grados del paquete o del núcleo 0, o 0 si no se puede leer.

**Patrón.**

Timer de CPU en un tab:

    local D = require("lib.data.cpu")
    srv:add_timer(2000, function()
        local s = D.cpu.sample()
        ring:set_value(s.usage, string.format("%d%%", math.floor(s.usage * 100)))
        for i, pct in ipairs(s.per_core) do
            motors:set("core" .. i, pct)
        end
    end)

Ver `examples/13-tab-cpu.lua`.

**Anti-patrón.**

- **Llamar `sample()` con intervalos muy cortos (< 500 ms).** El delta entre lecturas es pequeño y el porcentaje resultante es ruidoso. El toolkit usa 2 s para el tab de CPU. Intervalos menores son aceptables para sparklines (donde la variación es visual), pero no para el valor numérico mostrado.
- **Asumir que `temp` siempre está disponible.** En CPUs sin coretemp (AMD con otros drivers, o máquinas virtuales), el campo es 0. Comprobar `s.temp > 0` antes de mostrarlo.
- **Ignorar que `per_core` es 1-based.** Los índices de `per_core` vienen del número de núcleo extraído de `cpuN` (0-based en el kernel) más uno. `per_core[1]` es el núcleo 0 del kernel. La convención del toolkit es 1-based para iteración con `ipairs`.
- **Llamar `M.info()` en cada tick del timer.** El modelo de CPU y el uptime son datos que cambian muy lentamente (el modelo nunca, el uptime cada segundo). Leer `/proc/cpuinfo` en cada tick es un desperdicio. Una sola vez al construir el tab.

**Notas.**

- El campo `active` de la fórmula incluye `steal`, que en máquinas virtuales indica tiempo robado por el hipervisor. Es correcto contarlo como uso. `guest` y `guest_nice` no se incluyen porque están contabilizados implícitamente en `user` y `nice` en el kernel de Linux.
- `idle` incluye `iowait`. El kernel lo cuenta como no-idle en el detalle, pero para el uso agregado es correcto sumarlo a idle.
- `read_temp()` busca `Package id 0` primero y `Core 0` después. En CPUs sin paquete (por ejemplo, algunos AMD) puede no haber `Package`, y cae a `Core 0`. En CPUs sin `Core 0` (nomenclatura distinta) devuelve 0.
- El cache de `coretemp_files` es a nivel de módulo, no por instancia. Si hay varios samplers de CPU en el mismo proceso, comparten el cache. Correcto.
- `freq_range` solo lee `cpu0`. En CPUs con frecuencias asimétricas (big.LITTLE), el rango puede no representar todos los núcleos. Es una limitación aceptada hoy.

---

#### ram.lua

**Propósito.**
Lectura de uso de memoria RAM y swap, swappiness del kernel, y módulos físicos de memoria vía `dmidecode`. Fuentes: `/proc/meminfo`, `/proc/swaps`, `/proc/sys/vm/swappiness`, `dmidecode -t memory`.

**Alcance.**
Cubre total, libre, disponible, usada, buffers, cached, SReclaimable, Shmem, swap total y usado, swappiness (lectura y escritura), y lista de módulos instalados. No cubre memoria de procesos individuales (eso es `/proc/PID/status`). No cubre zram ni zswap. No cubre memoria de GPU. No cubre cambios de swappiness sin sudo.

**Cómo funciona.**

`M.sample()` lee `/proc/meminfo` completo y extrae cada campo con `string.match`. Los campos en KB. El cálculo de "usado" no es `total - free`, porque Linux usa el `free` para cache y la cifra sería inútilmente alta. Se usa `avail` (`MemAvailable`), que es la cantidad que el kernel estima que se puede asignar sin swap. Si `MemAvailable` no existe (kernels viejos), se cae a `free + buffers + cached`. `used = total - avail`. `pct = used / total`.

El swap se lee de `/proc/swaps`, línea 2 (la primera es cabecera). Los campos son `Filename Type Size Used Priority`. Se extrae Size y Used en KB. `swap_pct = swap_used / swap_total`.

`M.swappiness()` lee `/proc/sys/vm/swappiness`. Devuelve 60 si no se puede leer (default del kernel).

`M.set_swappiness(v)` clampea `v` a `[0, 100]` y ejecuta `sudo -n sysctl -w vm.swappiness=<v>`. El `-n` significa no interactivo: si sudo pide contraseña, falla silenciosamente. Corre en background con `&`. Devuelve el valor clampeado. El efecto real no se verifica: el llamador debe comprobar el nuevo valor con `swappiness()` en el próximo tick si quiere confirmar.

`M.modules()` ejecuta `sudo -n dmidecode -t memory`. Si no hay salida suficiente (comando falló o sudo pidió contraseña), prueba con la ruta `/usr/sbin/dmidecode`. Si tampoco hay salida, devuelve `nil` más la longitud de la salida (útil para diagnosticar). Si hay salida, parsea los bloques `Memory Device` y extrae `Size`, `Type`, `Speed`, `Manufacturer`, `Part Number`. Los módulos con `Size` igual a `"No Module Installed"` o con `Size` que empieza por `0` o contiene `Unknown` se filtran.

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `sample()` | tabla | Ver campos abajo. |
| `swappiness()` | int | 0-100, default 60 si falla. |
| `set_swappiness(v)` | int | Clampea a `[0, 100]`. Lanza `sudo -n` en background. |
| `modules()` | `modules, len` | `nil, len` si `dmidecode` no devuelve datos. |

**Campos del retorno de `sample`.**

- `total`, `free`, `avail`, `used`, `cached`, `buffers`, `srecl`, `shmem` — KB.
- `pct` — float `[0, 1]` de uso.
- `swap_total`, `swap_used` — KB.
- `swap_pct` — float `[0, 1]`.

**Campos de cada módulo de `modules()`.**

- `size`, `type`, `speed`, `manuf`, `part` — strings tal cual vienen de `dmidecode`.

**Patrón.**

    local D = require("lib.data.ram")
    srv:add_timer(2000, function()
        local s = D.ram.sample()
        ring:set_value(s.pct, string.format("%d%%", math.floor(s.pct * 100)))
        kv:set("total", F.mb(s.total))
        kv:set("used", F.mb(s.used))
    end)

Ver `examples/15-tab-ram.lua`.

**Anti-patrón.**

- **Asumir que `modules()` devuelve datos.** Necesita sudo sin password para `dmidecode`. Si el usuario no está en `sudoers` con `NOPASSWD`, devuelve `nil`. El consumidor debe manejar el caso: no mostrar la sección de módulos si no hay datos.
- **Calcular "usado" como `total - free`.** El `free` de Linux es engañoso: el sistema usa toda la RAM libre para cache. `MemAvailable` es la cifra correcta. Usar el helper del módulo.
- **Llamar `modules()` en cada tick.** Ejecuta `sudo` y `dmidecode`, que tarda cientos de milisegundos y bloquea el loop. Leer una sola vez al construir el tab. `notes.md` documenta el problema general de `shell_once` con comandos lentos.
- **Asumir que `set_swappiness` tiene efecto inmediato.** Corre en background. El cambio es asíncrono. Si se quiere confirmar, leer `swappiness()` en el próximo tick.

**Notas.**

- `MemAvailable` no está en kernels muy antiguos (pre-3.14). El fallback `free + buffers + cached` es razonable pero ligeramente pesimista (no cuenta `SReclaimable`). En kernels modernos siempre está.
- `swap_total` es 0 si no hay swap configurado. El cálculo de `swap_pct` protege contra división por cero con el `swap_total > 0 and ... or 0`.
- `dmidecode` necesita root. La variante `sudo -n` no pide contraseña. Si el usuario no tiene regla `NOPASSWD` para `dmidecode`, la ejecución falla y el módulo devuelve `nil`. Es el comportamiento esperado: el toolkit no fuerza sudo interactivo.
- `M.modules` ejecuta `sudo` dos veces si la primera falla (una para la ruta `/usr/bin/dmidecode`, otra para `/usr/sbin/dmidecode`). En distribuciones donde la ruta es distinta, falla. No hay búsqueda en `$PATH`.

#### gpu.lua

**Propósito.**
Lectura de telemetría de GPU Intel integrada. Fuentes: `/tmp/gpu-status.txt` (escrito por un servicio externo) y `/sys/class/drm/card0/gt_*_freq_mhz` (frecuencias mín/máx/boost).

**Alcance.**
Cubre frecuencia actual, tiempo en RC6, potencia, IRQs, y uso de los motores render, blitter y video. Cubre el rango de frecuencias del `card0`. No cubre GPUs NVIDIA ni AMD: los archivos `/sys/class/drm/card0/gt_*` son específicos del driver `i915`. No cubre temperatura de GPU. No cubre memoria de video.

**Cómo funciona.**

El módulo **no** consulta la GPU directamente. Lee `/tmp/gpu-status.txt`, un archivo que un servicio externo (runit, systemd, cron) escribe periódicamente con una línea con formato:

    freq|rc6|power|irqs|render|blitter|video

Cada campo es numérico. `freq` es la frecuencia en MHz, `rc6` es el porcentaje de tiempo en RC6 (estado de bajo consumo), `power` es la potencia estimada en watts, `irqs` el número de interrupciones, y los tres últimos son porcentajes de uso de los motores render, blitter y video.

`M.status()` lee ese archivo con `helpers/util.read_file`, extrae la primera línea, y la parsea con un `string.match` de siete campos separados por `|`. Si el archivo no existe, está vacío, o el formato no encaja, devuelve `nil`. Todos los valores se convierten a número con `tonumber` y se protegen con `or 0`.

`M.specs()` lee tres archivos del `i915`: `gt_min_freq_mhz`, `gt_max_freq_mhz` y `gt_boost_freq_mhz`. Devuelve un `{ min, max, boost }` con defaults `350`, `1000`, `1000` si los archivos no existen o no contienen números. Los defaults corresponden a una GPU Intel típica.

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `status()` | tabla o `nil` | `nil` si el archivo no existe o no parsea. |
| `specs()` | tabla | `{ min, max, boost }` en MHz. |

**Campos del retorno de `status`.**

- `freq` — MHz actuales.
- `rc6` — porcentaje (0-100) de tiempo en RC6.
- `power` — watts estimados.
- `irqs` — número de IRQs.
- `render`, `blitter`, `video` — porcentaje (0-100) de uso de cada motor.

**Patrón.**

    local D = require("lib.data.gpu")
    srv:add_timer(2000, function()
        local s = D.gpu.status()
        if not s then return end
        ring:set_value(s.render / 100,
            string.format("%d%%", s.render))
        kv:set("freq", s.freq .. " MHz")
        kv:set("power", string.format("%.1f W", s.power))
    end)

Ver `examples/16-tab-gpu.lua`.

**Anti-patrón.**

- **Asumir que `status()` devuelve algo en máquinas sin GPU Intel.** En máquinas sin el servicio que escribe `/tmp/gpu-status.txt`, devuelve `nil` siempre. El tab debe manejar el caso: mostrar un mensaje o no renderizar el widget.
- **Llamar `status()` en un bucle muy corto.** No es caro (una lectura de archivo), pero el archivo no cambia más rápido que el servicio que lo escribe. Cada 1-2 segundos es suficiente.
- **Asumir que `specs()` devuelve el rango real de la GPU.** Los defaults `350/1000/1000` son genéricos. Una GPU Intel con rango distinto (por ejemplo, Iris Xe con boost a 1300 MHz) mostrará valores incorrectos si el `card0` no expone los archivos. La información está en `/sys/class/drm/card0/` solo si el driver `i915` la publica.

**Notas.**

- El servicio externo que escribe `/tmp/gpu-status.txt` no forma parte del toolkit. Es un script que el usuario instala en su init system. `notes.md` no documenta cómo se generó; es un formato heredado del proyecto original.
- El formato `freq|rc6|power|irqs|render|blitter|video` es fijo. Un cambio en el productor del archivo rompe el parser. Si algún campo empieza a fallar, inspeccionar el archivo crudo.
- `M.status` no tiene cache. Cada llamada lee del disco. La lectura es barata (archivo pequeño) pero podría cachearse con TTL si se necesita.

---

#### bat.lua

**Propósito.**
Lectura de batería desde `/sys/class/power_supply/BAT*`. Detecta la primera batería disponible y devuelve su estado, capacidad, voltajes, corrientes, potencia, tiempo estimado y ciclos.

**Alcance.**
Cubre una sola batería. No cubre sistemas con múltiples baterías (por ejemplo, laptops con batería extraíble más la interna). No cubre `UPS` ni `AC` directamente (aunque `status` incluye los valores). No cubre el cálculo de salud a largo plazo: solo lo que el kernel expone.

**Cómo funciona.**

`find_base()` localiza la primera ruta que case con `/sys/class/power_supply/BAT*` con `ls -d` y `head -n1`. Guarda el resultado en `BAT_BASE` como cache a nivel de módulo. El cache se inicializa a `""` (string vacío) si no encuentra nada, para no reintentar el `ls` en cada llamada. La distinción entre `nil` (sin buscar todavía) y `""` (buscado, no hay) evita la repetición.

`read_str(path)` lee un archivo de sysfs y quita whitespace (saltos de línea incluidos). `read_num(path)` es el mismo pero convierte a número, con `nil` si el archivo no existe o está vacío.

`M.available()` devuelve `true` si `find_base` encontró algo. No cachea el booleano, pero `find_base` sí está cacheado.

`M.sample()` lee todos los archivos de la batería. Los campos disponibles dependen del driver: `charge_now`, `charge_full`, `current_now`, `voltage_now` están presentes en la mayoría, pero algunos drivers exponen `energy_now` en lugar de `charge_now`. El módulo lee los de `charge` y si faltan, los deja a 0. `power_w` se calcula como `power / 1e6` si el archivo `power` existe, o como `current * voltage / 1e12` si no. Las unidades de `current_now` y `voltage_now` en sysfs son microamperios y microvoltios, respectivamente, así que el producto es picovatios (1e-12 W).

`charge_full_pct` es la salud de la batería: `charge_full / charge_full_design * 100`. Es el porcentaje que la batería puede retener respecto a cuando era nueva.

`time_hours` estima el tiempo restante. Si está descargando, es `charge_now / current_now`. Si está cargando, es `(charge_full - charge_now) / current_now`. Si está llena o el estado es `Unknown`, queda en 0.

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `available()` | `bool` | `true` si existe una batería. |
| `sample()` | tabla o `nil` | `nil` si no hay batería. |

**Campos del retorno de `sample`.**

- `base` — ruta a la batería.
- `status` — `"Charging"`, `"Discharging"`, `"Full"`, `"Unknown"`, o `"N/A"`.
- `capacity` — porcentaje entero (0-100).
- `capacity_level` — `"High"`, `"Normal"`, `"Low"`, `"Critical"`, `"Unknown"`, o `"-"`.
- `technology` — `"Li-ion"`, `"Li-poly"`, etc.
- `model`, `vendor`, `serial` — strings.
- `cycle_count` — número de ciclos, o `nil`.
- `charge_now`, `charge_full`, `charge_full_design` — en la unidad del driver (mAh típicamente).
- `current_now`, `voltage_now`, `voltage_min_design` — en µA y µV.
- `power_w` — float en watts.
- `charge_full_pct` — salud (0-100). 100 significa "batería nueva".
- `time_hours` — horas estimadas restantes (o hasta llenar).

**Patrón.**

    local D = require("lib.data.bat")
    if D.bat.available() then
        srv:add_timer(10000, function()
            local s = D.bat.sample()
            if not s then return end
            ring:set_value(s.capacity / 100,
                string.format("%d%%", s.capacity),
                string.format("%.1f h", s.time_hours))
            kv:set("estado", s.status)
            kv:set("salud", s.charge_full_pct .. "%")
        end)
    end

Ver `examples/18-tab-bat.lua`.

**Anti-patrón.**

- **Asumir que todos los archivos existen.** Algunos drivers no exponen `charge_now` o `power`. El módulo protege con `or 0` y `nil`, pero un consumidor que use `charge_now` directamente sin comprobar puede dibujar 0 cuando en realidad no hay dato. Comprobar si el campo es 0 antes de formatearlo.
- **Llamar `sample()` a intervalos muy cortos.** La batería no cambia rápido. 10 s es lo que usa el tab del toolkit. Intervalos de 1 s no aportan información nueva.
- **Interpretar `time_hours` como exacto.** Es una estimación basada en `current_now`, que fluctúa con la carga del sistema. Bajo carga alta, el `current_now` instantáneo da tiempos muy optimistas o muy pesimistas. Es una guía, no una promesa.
- **Usar `charge_full_pct` para decidir si reemplazar la batería.** El valor "sano" típico es 80-100% para baterías en uso. Por debajo de 80% se considera degradada, por debajo de 60% candidata a reemplazo. Son heurísticas, no reglas.
- **Asumir que `status` es siempre uno de los valores esperados.** Algunos drivers exponen `"Not charging"` (con espacio) o cadenas localizadas. El módulo no las normaliza. Si el consumidor depende del valor, hay que manejar más casos.

**Notas.**

- `find_base` usa `ls -d /sys/class/power_supply/BAT* | head -n1`. Un sistema sin baterías (desktop) devuelve `""`. El cache se queda en `""` y no se reintenta. Correcto.
- `charge_full_design` es la capacidad de fábrica. `charge_full` es la capacidad actual medida. La relación entre ambos es la salud. Si `charge_full_design` es 0 (no expuesto), la salud queda en 0.
- `current_now` en algunos drivers se reporta con signo (negativo cuando descarga). El módulo usa el valor absoluto implícitamente en el producto `current * voltage`, que siempre da positivo. Para el cálculo de `time_hours` usa `current_now` tal cual; si fuera negativo, el cálculo daría tiempo negativo, y el check `st.status == "Discharging"` protege contra eso.
- El campo `power` de sysfs está en microwatts. Dividido por `1e6` da watts. Correcto.
- `technology`, `model`, `vendor`, `serial` son strings opcionales. Algunos drivers no los exponen y el módulo usa `"?"` como fallback.

---

#### temps.lua

**Propósito.**
Lectura de sensores de temperatura de la CPU y la placa. Fuentes: `/sys/class/hwmon/*` (coretemp para CPU) y `/sys/class/thermal/thermal_zone*` (para placa y x86_pkg_temp).

**Alcance.**
Cubre núcleos 0 y 1 y paquete de CPU vía coretemp, zonas térmicas 0 y 1 (board y x86), y lectura de un archivo `/tmp/disk-temp.txt` para la temperatura de disco. No cubre otros hwmon (por ejemplo, NVMe, GPU). No cubre sensores de ventiladores. No cubre temperaturas de más núcleos: solo 0 y 1 más el paquete.

**Cómo funciona.**

`M.find_coretemp()` recorre `/sys/class/hwmon/hwmon*` buscando el que tenga `name = "coretemp"`. Devuelve la ruta o `nil`. Es el equivalente al `ensure_coretemp` de `cpu.lua`, pero sin cache: cada llamada ejecuta el `ls` y lee los nombres. Para no repetir la búsqueda, el consumidor suele llamarlo una vez al construir el tab y pasar la ruta a `read_coretemp`.

`M.read_coretemp(path)` recibe la ruta del coretemp. Mantiene dos caches a nivel de módulo (`coretemp_labels` y `coretemp_files`) que se llenan la primera vez que se llama con una ruta. El cache guarda la ruta para invalidarse si cambia. Recorre `temp1_input` a `temp20_input` buscando los que existan, y lee sus `_label` correspondientes. Devuelve `{ core0, core1, pkg }` con las temperaturas en grados. Las temperaturas están en milésimas de grado en sysfs; se dividen por 1000.

`M.read_zones()` lee `thermal_zone0/temp` y `thermal_zone1/temp`. Devuelve `{ board, x86 }` con las temperaturas en grados. La asignación es por convención: en la mayoría de sistemas, la zona 0 es la placa y la zona 1 es `x86_pkg_temp`. En otros, el orden varía. El módulo no lee los `type` de las zonas para verificar.

`M.read_smart(cb)` lee `/tmp/disk-temp.txt` y llama a `cb(n)` con el valor numérico o `cb(nil)` si no existe. Es una función síncrona envuelta en un callback por compatibilidad con la API del proyecto original. El archivo lo escribe un servicio externo (por ejemplo, un timer que corre `smartctl`). El toolkit no lo genera.

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `find_coretemp()` | string o `nil` | Ruta al hwmon de coretemp. |
| `read_coretemp(path)` | tabla | `{ core0, core1, pkg }`, cada uno `nil` o grados. |
| `read_zones()` | tabla | `{ board, x86 }`, cada uno `nil` o grados. |
| `read_smart(cb)` | — | Llama a `cb(n)` con la temp de disco o `nil`. |

**Patrón.**

    local D = require("lib.data.temps")

    local coretemp = D.temps.find_coretemp()
    srv:add_timer(2000, function()
        local t = D.temps.read_coretemp(coretemp)
        kv:set("core0", t.core0 and (t.core0 .. "°C") or "—")
        kv:set("core1", t.core1 and (t.core1 .. "°C") or "—")
        kv:set("pkg",   t.pkg   and (t.pkg   .. "°C") or "—")

        local z = D.temps.read_zones()
        kv:set("board", z.board and (z.board .. "°C") or "—")
    end)

Ver `examples/21-tab-temps.lua`.

**Anti-patrón.**

- **Llamar `find_coretemp()` en cada tick.** Ejecuta `ls` y lee los `name` de cada hwmon. Cachear la ruta al construir el tab.
- **Asumir que `thermal_zone0` es la placa y `thermal_zone1` es x86_pkg_temp.** La asignación varía por sistema. El módulo no lo verifica. Si el consumidor necesita precisión, leer los archivos `type` de cada zona y decidir.
- **Asumir que `read_coretemp` siempre devuelve los tres valores.** Los nombres exactos de los labels varían: `"Core 0"`, `"Core 1"`, `"Package id 0"` son los más comunes en Intel. Un sistema AMD con `k10temp` u otro driver no expone estos labels. El consumidor debe manejar `nil`.
- **Bloquear el event loop con `read_smart`.** Es una lectura de archivo local, rápida. El productor del archivo sí puede bloquear (si corre `smartctl`), pero el sampler no. La decisión de cuándo actualizar `/tmp/disk-temp.txt` es del servicio externo.
- **Pasar un `path` nulo a `read_coretemp`.** Devuelve `{ core0 = nil, core1 = nil, pkg = nil }`. Es correcto pero el consumidor que no compruebe dibujará tres "—" sin entender por qué. Comprobar `find_coretemp()` antes.

**Notas.**

- El cache de `coretemp_files` se invalida cuando cambia la ruta. Es una comprobación trivial por comparación de string. Si dos llamadas con la misma ruta se hacen en secuencia, la segunda reutiliza el cache.
- La lista de archivos se construye con `io.open` en cada slot, no con `popen` y `ls`. Es más rápido y no depende del shell. El comentario del código es explícito.
- `read_zones` no verifica los `type` de las zonas. En algunos sistemas, `thermal_zone0` puede ser otra cosa (por ejemplo, `acpitz`). El consumidor que necesite precisión, lee los `type` por su cuenta.
- `M.read_smart` acepta un callback aunque no es asíncrono. Es por compatibilidad con el original de Awesome, que sí era asíncrono. En la práctica, el callback se ejecuta inmediatamente.
- El archivo `/tmp/disk-temp.txt` no se limpia. Si el servicio externo deja de escribirlo, el valor queda obsoleto indefinidamente. No hay verificación de timestamp. Es una limitación heredada.

#### disk.lua

**Propósito.**
Lectura de particiones montadas (vía `df` y `lsblk`) y de datos SMART de disco (vía `smartctl` con salida JSON, mediada por un archivo intermedio). Fuentes: `df -hP`, `lsblk -P`, `/tmp/lanetk-smart.tsv`.

**Alcance.**
Cubre particiones montadas con uso, tamaño y filesystem, excluyendo pseudo-filesystems y puntos de montaje del sistema. Cubre 22 campos SMART de un solo disco (`/dev/sda` por defecto). No cubre múltiples discos: el TSV es de uno, y los campos son de ese. No cubre NVMe con atributos SMART distintos: los IDs de los atributos ATA (5, 197, 198, 199, 193, 241, 242) no aplican. No cubre el detalle de salud por atributo más allá de los once valores predefinidos.

**Cómo funciona.**

`M.partitions()` ejecuta `df -hP` y parsea línea a línea. El patrón captura `fs`, `size`, `used`, `avail`, `pct` y `mount`. Se filtran los puntos de montaje que no empiezan por `/` (excluye cabeceras y entradas raras). Se filtran los pseudo-filesystems por nombre (contienen `tmpfs`, `devtmpfs`, `udev`, `squashfs`, `efivarfs`) y por punto de montaje (exacto o prefijo de `/run`, `/sys`, `/proc`, `/dev`, `/media`). Las particiones restantes se ordenan alfabéticamente por mount.

Después, `lsblk -P -o NAME,LABEL,FSTYPE,MOUNTPOINT` enriquece cada partición con el `label` y el `fs_type` real. `lsblk -P` emite pares `KEY="value"`, que el parser lee con `string.match`. Se hace un match por mountpoint entre las dos fuentes. Si el device existe en `lsblk` pero no en `df` (por ejemplo, disco montado con `-o` distintas), se ignora. Si existe en ambos, se actualiza `dev`, `label` y `fs_type`.

`M.smart_read()` lee `/tmp/lanetk-smart.tsv`. Formato: una sola línea con 22 campos separados por tab. Los campos son, en orden:

1. `passed` — `true` / `false`
2. `temp` — temperatura en °C
3. `hours` — horas de encendido
4. `cycles` — ciclos de encendido
5. `realloc` — sectores reasignados (attr 5)
6. `pending` — sectores pendientes (attr 197)
7. `offline` — sectores offline uncorrectable (attr 198)
8. `crc` — errores CRC (attr 199)
9. `load_cycles` — ciclos de carga (attr 193)
10. `lba_written` — LBAs escritos (attr 241)
11. `lba_read` — LBAs leídos (attr 242)
12. `model_family`
13. `model_name`
14. `serial`
15. `firmware`
16. `cap_bytes` — capacidad en bytes
17. `rotation` — RPM (0 = SSD)
18. `form_factor`
19. `sec_logical` — tamaño de sector lógico
20. `sec_physical` — tamaño de sector físico
21. `sata_version`
22. `sata_link` — velocidad del enlace actual

El parser corta por tabuladores con un `gmatch` que añade un `\t` extra al final para que el último campo también se capture.

`M.smart_trigger(device)` construye un comando `sudo -n smartctl -j -a <device> | jq -r '<filtro>' > <tmp> && mv <tmp> <tsv>` y lo lanza en background con `&`. El filtro `jq` extrae los 22 campos del JSON que devuelve `smartctl -j`. El resultado se escribe atómicamente con `mv` (primero a `.tmp`, luego renombrado). El `os.execute` retorna inmediatamente sin esperar.

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `partitions()` | tabla | Lista de `{ dev, size, used, avail, pct, mount, label?, fs_type? }`. |
| `smart_read()` | tabla o `nil` | Lee el TSV. `nil` si no existe o está vacío. |
| `smart_trigger(device)` | — | Lanza `smartctl` en background. `device` default `"/dev/sda"`. |

**Campos del retorno de `smart_read`.**

Ver la lista de 22 campos arriba. Todos numéricos salvo `passed` (booleano), `model_family`, `model_name`, `serial`, `firmware`, `form_factor`, `sata_version`, `sata_link` (strings).

**Patrón.**

    local D = require("lib.data.disk")

    -- Lanzar el smart en background al arrancar el tab.
    D.disk.smart_trigger("/dev/sda")

    srv:add_timer(10000, function()
        local parts = D.disk.partitions()
        rebuild_parts(parts)
    end)

    srv:add_timer(60000, function()
        local s = D.disk.smart_read()
        if s then
            kv:set("smart", s.passed and "OK" or "FALLO")
            kv:set("temp", s.temp .. "°C")
        end
    end)

Ver `examples/18-tab-disks.lua`.

**Anti-patrón.**

- **Llamar `smart_trigger` en cada tick.** Corre `smartctl`, que tarda. Se lanza en background para no bloquear, pero lanzarlo cada 10 s acumula procesos. El toolkit lo lanza una vez al construir el tab y refresca el TSV cada 60 s leyendo el archivo.
- **Asumir que `smart_read` devuelve datos tras `smart_trigger`.** El trigger es asíncrono. El archivo tarda en aparecer. El consumidor debe tolerar `nil` en las primeras lecturas.
- **Interpretar `pct` como un entero sin clampear.** El `df` puede devolver `100%` en un filesystem lleno. El valor es correcto, pero un widget que dibuja la barra sin clampear pintará fuera del rect. El clamp lo hace el widget.
- **Asumir que `partitions()` incluye todos los discos.** El filtro excluye `/media` (montajes de USB típicamente). Es intencional: el tab de Discos muestra particiones del sistema, no dispositivos externos. Para listar todo, modificar el filtro.
- **Asumir que `smart_read` funciona en NVMe.** Los IDs de atributos son ATA. En NVMe, `smartctl` devuelve un JSON con estructura distinta y el filtro `jq` falla silenciosamente. El archivo `.tmp` queda vacío y el `mv` no se ejecuta. El TSV previo (si existe) se queda obsoleto.

**Notas.**

- El nombre `/tmp/lanetk-smart.tsv` está fijado en el módulo. Es compartido entre todas las instancias del toolkit en el mismo sistema. Si dos paneles corren a la vez, compiten por el mismo archivo. Aceptado.
- El `jq` está hardcodeado en el comando. Si no está instalado, `smartctl` corre, pero el `jq` falla y el archivo no se genera. `notes.md` no menciona la dependencia, pero es un requisito del módulo.
- `M.partitions` filtra por nombre de filesystem con `fs:find(v, 1, true)`. El `true` es "plain find", sin pattern magic. Correcto para nombres de FS que podrían contener `%`, `[`, etc.
- Los `pct` en `df` vienen como entero 0-100. El módulo lo convierte a número. Los widgets lo usan como `pct / 100` para las barras.
- `M.smart_read` corta la primera línea del TSV. Si por algún motivo hay más líneas (por ejemplo, por un `mv` parcial), solo la primera se procesa. El `mv` atómico garantiza que no haya lecturas parciales en la práctica.

---

#### net.lua

**Propósito.**
Resumen de tráfico de red por periodo (hoy, semana, mes) y datos de la interfaz activa (tipo, IP, gateway, SSID). Fuentes: archivos TSV en `~/.local/share/awesome/traffic/`, `ip`, `iwgetid`.

**Alcance.**
Cubre suma de tráfico por día/semana/mes de archivos TSV escritos por un servicio externo. Cubre tipo de interfaz, IP, gateway y SSID de la interfaz activa. Cubre lectura de bytes acumulados de una interfaz desde sysfs. No cubre escritura del registro de tráfico: el servicio que escribe los TSV es externo. No cubre `nftables`/`iptables` ni estadísticas de paquetes. No cubre IPv6 más allá de lo que el `ip route` devuelva por defecto.

**Cómo funciona.**

El registro de tráfico vive en `~/.local/share/awesome/traffic/`. Cada día tiene un archivo `<YYYY-MM-DD>.tsv` con líneas con formato:

    <timestamp>|<iface>|<ssid>|<rx>|<tx>

`parse_tsv_line` divide por `|` y extrae los cinco campos. Los vacíos o malformados se ignoran silenciosamente.

`sum_file(path)` suma los `rx` y `tx` de todas las líneas de un archivo, y también acumula por interfaz en `by_net` (tabla `iface → { rx, tx }`). Devuelve `nil` si el archivo no existe.

`last_n_dates(n)` genera los últimos `n` días como strings `YYYY-MM-DD`, empezando hoy. `sum_dates(dates)` suma los archivos correspondientes a esos días, consolidando `rx`, `tx` y `by_net`.

`M.traffic_summary()` calcula hoy (1 día), semana (7 días) y mes (30 días). El resultado se cachea con TTL de 30 s en `cache` (nivel de módulo). Repetidas llamadas dentro de 30 s devuelven la misma tabla. `notes.md` documenta el cache como la optimización clave contra `io.popen` repetidos.

`M.iface_info(iface)` devuelve un resumen de la interfaz. Determina el tipo por prefijo (`wl`/`wlan` → WiFi, `en`/`eth` → Ethernet, otro → Otro). Lee la IP con `ip -4 addr show <iface>`. Lee el gateway con `ip route show default`. Lee el SSID con `iwgetid -r`. Devuelve `{ iface, tipo, ip, gw, ssid }` con `"-"` como valor por defecto en los campos no disponibles.

`M.iface_bytes(iface)` lee `rx_bytes` y `tx_bytes` de `/sys/class/net/<iface>/statistics/`. Devuelve `{ rx, tx }` en bytes, o `nil` si la interfaz no existe.

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `traffic_summary()` | tabla | `{ hoy, semana, mes }`, cada uno `{ rx, tx, by_net }`. Cacheado 30 s. |
| `iface_info(iface)` | tabla | `{ iface, tipo, ip, gw, ssid }`. |
| `iface_bytes(iface)` | tabla o `nil` | `{ rx, tx }` en bytes. `nil` si no existe la interfaz. |

**Campos de cada entrada del `traffic_summary`.**

- `rx`, `tx` — total del periodo en bytes.
- `by_net` — tabla `iface → { rx, tx }`.

**Patrón.**

    local D = require("lib.data.net")

    srv:add_timer(5000, function()
        local t = D.net.traffic_summary()
        kv:set("hoy", F.bytes(t.hoy.rx) .. " ↓ / " .. F.bytes(t.hoy.tx) .. " ↑")
        kv:set("mes", F.bytes(t.mes.rx) .. " ↓")
    end)

    srv:add_timer(3000, function()
        local iface = require("lib.data.wifi").wifi.iface()
        local info = D.net.iface_info(iface)
        kv:set("ip", info.ip)
        kv:set("gw", info.gw)
        if info.tipo == "WiFi" then
            kv:set("ssid", info.ssid)
        end
    end)

Ver `examples/17-tab-net.lua`.

**Anti-patrón.**

- **Asumir que los archivos TSV existen.** Un sistema recién instalado no tiene el directorio ni los archivos. `sum_file` devuelve `nil` y `sum_dates` lo ignora. El total queda en 0. No es un error, pero el consumidor debe saber que "0" significa "sin datos" hasta que el servicio externo empiece a escribir.
- **Llamar `traffic_summary()` sin depender del cache.** El TTL es 30 s. Llamar desde un timer de 1 s da 30 llamadas al cache por cada cálculo real. Está bien, pero el consumidor podría llamar cada 30 s directamente y obtener el mismo resultado sin sobrecarga de llamadas.
- **Pasar un nombre de interfaz con espacios o caracteres raros a `iface_info`.** El nombre se interpola en un `io.popen` sin escape. Aunque los nombres de interfaz en Linux raramente tienen caracteres problemáticos, un `iface` construido desde input del usuario sería una inyección de shell.
- **Asumir que `iwgetid` está instalado.** El comando es parte de `wireless-tools`, no de `iw`. En sistemas con solo `iw` (más moderno), `iwgetid` puede faltar. El SSID quedaría en `"-"` sin error.
- **Interpretar `by_net` como "por SSID".** La clave es la interfaz (`"wlan0"`, `"eth0"`), no la red. La SSID está en cada línea pero no se agrega.

**Notas.**

- El cache de `traffic_summary` es a nivel de módulo. Dos llamadas desde timers distintos comparten el cache. Es intencional: evita leer los mismos archivos dos veces.
- El formato de los archivos TSV es externo al toolkit. Si el servicio que los escribe cambia el formato, `parse_tsv_line` devuelve `nil` y las líneas se ignoran. El síntoma es un total de 0 sin error visible.
- `iface_info` ejecuta tres comandos shell (`ip addr`, `ip route`, `iwgetid`). Para un timer de pocos segundos, es aceptable, pero podría combinarse en un solo `ip` con varios `-o` para reducir el número de procesos.
- El tipo de interfaz se determina por prefijo del nombre. En algunos sistemas, las interfaces WiFi pueden llamarse `wlp3s0` (empieza por `wl`, correcto) pero también `ath0` (no empieza por `wl` ni `wlan`, cae a "Otro"). La detección es heurística, no infalible.
- `iface_bytes` lee `/sys/class/net/<iface>/statistics/*_bytes`. Los valores son acumulados desde el arranque del sistema, no por periodo. El consumidor que quiera velocidad (bytes/s) tiene que llevar la diferencia entre dos lecturas.

---

#### wifi.lua

**Propósito.**
Información básica de WiFi: interfaz activa, SSID conectado, formato de barras de señal, y búsqueda de conexiones guardadas en NetworkManager. Fuentes: `ip route`, `iw dev`, `iwgetid`, `nmcli`.

**Alcance.**
Cubre detección de interfaz WiFi, lectura de SSID conectado, formato de barras visuales de señal, y búsqueda de conexiones guardadas por SSID. No cubre escaneo de redes cercanas ni conexión/desconexión: eso lo haría `nmcli dev wifi list` y `nmcli dev wifi connect`, que no están en el módulo. No cubre gestión de contraseñas. No cubre detección de bandas (2.4/5 GHz) ni canales.

**Cómo funciona.**

`M.iface()` devuelve la interfaz asociada a la ruta por defecto. Consulta `ip route show default` y extrae el quinto campo (el nombre de la interfaz). Es la interfaz que el kernel usa para llegar a internet, sin importar si es WiFi o Ethernet.

`M.wifi_iface()` específicamente busca una interfaz WiFi. Primero con `iw dev`, que lista las interfaces inalámbricas del sistema. Si no hay o `iw` no está instalado, cae a `ls /sys/class/net` filtrando por prefijo `wl` o `wlan`.

`M.ssid()` lee el SSID de la interfaz WiFi conectada con `iwgetid -r`. Devuelve `""` si no está conectado a ninguna.

`M.signal_bars(sig)` recibe un porcentaje (0-100) y devuelve un string con cinco posiciones, de las cuales `floor(sig / 20 + 0.5)` están rellenas (`▮`) y el resto vacías (`▯`), seguidas del porcentaje numérico. Por ejemplo, `sig = 75` devuelve `"▮▮▮▮▯  75%"`. Los valores fuera de `[0, 100]` se clampean: negativo se trata como 0, mayor que 100 como 5 barras llenas.

`M.find_saved(ssid)` busca una conexión guardada en NetworkManager cuyo nombre coincida con el SSID dado y sea de tipo `802-11-wireless`. Consulta `nmcli -t -f NAME,TYPE connection show`. `-t` (terse) usa `:` como separador. Si encuentra coincidencia, devuelve el nombre de la conexión. Si no, devuelve `nil`.

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `iface()` | string | Interfaz de la ruta por defecto. Puede ser Ethernet. |
| `wifi_iface()` | string | Interfaz WiFi. Vacío si no hay. |
| `ssid()` | string | SSID conectado. Vacío si no aplica. |
| `signal_bars(sig)` | string | Barras + porcentaje. |
| `find_saved(ssid)` | string o `nil` | Nombre de la conexión guardada. |

**Patrón.**

    local D = require("lib.data.wifi")

    srv:add_timer(5000, function()
        local iface = D.wifi.iface()
        if iface == "" then
            kv:set("wifi", "sin conexión")
            return
        end
        local ssid = D.wifi.ssid()
        kv:set("wifi", ssid)
        local saved = D.wifi.find_saved(ssid)
        kv:set("guardada", saved and "sí" or "no")
    end)

Ver `examples/17-tab-net.lua`.

**Anti-patrón.**

- **Confundir `iface()` con la WiFi.** `iface()` devuelve la interfaz de la ruta por defecto, que puede ser Ethernet. Para WiFi específicamente, usar `wifi_iface()`.
- **Asumir que `ssid()` devuelve algo cuando `iface()` es Ethernet.** El SSID se lee con `iwgetid -r` sin especificar interfaz. Si hay una WiFi conectada además de Ethernet, `iwgetid` puede devolver el SSID aunque la ruta por defecto sea por Ethernet. La lógica del consumidor debe decidir cuál usar.
- **Asumir que `signal_bars` recibe un valor de 0-100.** El rango de `nmcli` para señal es 0-100, pero `iwconfig` reporta 0-70 en algunos casos. Si el productor del valor usa una escala distinta, el formato de barras queda mal. El módulo no normaliza.
- **Llamar `find_saved` en cada tick.** Ejecuta `nmcli`, que tarda cientos de milisegundos. Leer una vez al construir el tab o tras un cambio de conexión.
- **Asumir que `nmcli` está instalado.** En sistemas sin NetworkManager (por ejemplo, con `wpa_supplicant` puro), `nmcli` no existe y la función devuelve `nil` siempre.

**Notas.**

- `wifi_iface` prefiere `iw` sobre `ls /sys/class/net`, porque `iw` da información más precisa de la interfaz inalámbrica. El fallback por prefijo es heurístico.
- `signal_bars` usa caracteres Unicode de bloque (`▮` y `▯`). Deben ser visibles con la fuente que use el consumidor. Fuentes sin cobertura de estos caracteres los dibujan como cajas.
- El formato de barras incluye el porcentaje con `%3d%%`, que rellena con espacios a la izquierda hasta 3 dígitos. Es para que el string tenga ancho consistente entre valores de 0 y 100.
- `find_saved` usa `:` como separador porque `nmcli -t` cambia el separador por defecto a `:`. Los nombres de conexión con `:` (raros) romperían el parser. No es un caso real hoy.
- El módulo no expone `wifi.list()`. El escaneo de redes cercanas no está implementado. `notes.md` documenta la conexión WiFi desde el panel como pendiente.

---

#### ping.lua

**Propósito.**
Gestión de la lista de hosts a monitorear, host activo, y ejecución asíncrona de `ping` con lectura del último resultado. Fuentes: `~/.config/awesome/ping-hosts.conf`, `/tmp/lanetk-ping.txt`.

**Alcance.**
Cubre lista de hosts editables, host activo persistido en archivo, añadir host, cambiar activo, y lanzar un ping en background. Cubre lectura del último resultado con timestamp. No cubre el envío de múltiples pings ni medición continua: cada llamada a `ping_async` lanza un ping único. No cubre ICMP vía FFI: usa el binario `ping` del sistema.

**Cómo funciona.**

`M.hosts()` lee `~/.config/awesome/ping-hosts.conf`. El archivo tiene un host por línea. La línea que empieza por `*` marca el host activo (y se incluye en la lista sin el asterisco). Si el archivo no existe o no tiene hosts, devuelve la lista por defecto `{"1.1.1.1", "8.8.8.8", "google.com"}` con el primero como activo. Devuelve `{ list, active }`.

`M.save(list, active)` escribe el archivo. Marca el activo con `*`. Es la operación inversa de `hosts()`.

`M.add(state, host)` añade un host a la lista (si no está ya) y lo marca como activo. Persiste. Devuelve `true` si se añadió, `false` si ya existía o el host es vacío.

`M.set_active(state, host)` cambia el activo solo si el host está en la lista. Persiste. Devuelve `true` si se cambió, `false` si no.

`M.ping_async(host)` lanza `ping -c1 -W1 <host>`, extrae el `time=<ms>` de la salida, y lo escribe a `/tmp/lanetk-ping.txt` junto con un timestamp Unix en la línea siguiente. El comando corre en background con `&`. El archivo se escribe atómicamente con `mv` (primero a `.tmp`, luego renombrado). Usa `LC_ALL=C` para que el formato de `time=` sea consistente independientemente del locale.

`M.ping_read(max_age)` lee `/tmp/lanetk-ping.txt`. Extrae la primera línea (el tiempo en ms, o vacío si el ping falló) y la última línea (el timestamp). Calcula la edad del resultado en segundos. Si la edad excede `max_age` (default 5), devuelve `nil`. Si el resultado es válido, devuelve `{ ms, age }`. `ms` puede ser `nil` si el ping no obtuvo respuesta (la primera línea del archivo estaría vacía).

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `hosts()` | tabla | `{ list, active }`. Lee el archivo o devuelve defaults. |
| `save(list, active)` | — | Escribe el archivo. |
| `add(state, host)` | `bool` | Añade y marca activo. `false` si ya existía. |
| `set_active(state, host)` | `bool` | Cambia activo. `false` si no está. |
| `ping_async(host)` | — | Lanza ping en background. |
| `ping_read(max_age)` | tabla o `nil` | `{ ms, age }` o `nil` si viejo o no existe. |

**Patrón.**

    local D = require("lib.data.ping")

    local state = D.ping.hosts()

    srv:add_timer(5000, function()
        D.ping.ping_async(state.active)
    end)

    srv:add_timer(1000, function()
        local r = D.ping.ping_read(8)
        if r and r.ms then
            kv:set("ping", string.format("%.0f ms", r.ms))
        else
            kv:set("ping", "sin respuesta")
        end
    end)

Ver `examples/17-tab-net.lua`.

**Anti-patrón.**

- **Llamar `ping_async` con más frecuencia que la duración del ping.** Cada llamada lanza un proceso `ping` con timeout de 1 s. Un timer de 0.5 s acumula procesos. El toolkit lo llama cada 5 s y lee el resultado con `ping_read` con `max_age = 8`.
- **Asumir que `ping_read` devuelve un resultado fresco.** Si `ping_async` nunca se llamó o el archivo tiene más de `max_age` segundos, devuelve `nil`. El consumidor debe manejar el caso.
- **Interpretar `ms = nil` como error del módulo.** Significa que el ping corrió pero no obtuvo respuesta. El archivo tiene una línea vacía seguida del timestamp. Es un resultado válido (host no responde).
- **Pasar un host con caracteres de shell a `ping_async`.** El host se interpola en el comando sin escape. Un host malicioso podría inyectar comandos. Validar antes o usar un ejecutable wrapper.
- **Llamar `M.save` con una lista que no sea la de `M.hosts()`.** El formato de escritura espera la estructura `list, active`. Si el consumidor construye una lista ad-hoc con otro formato, `save` puede fallar o escribir algo inconsistente.

**Notas.**

- `ping -c1 -W1` envía un solo paquete con timeout de 1 s. En redes con DNS lento, la resolución del hostname puede tardar más que el propio ping. El `LC_ALL=C` es para asegurar que el formato `time=` no cambia con el locale.
- El archivo `/tmp/lanetk-ping.txt` es compartido por todas las instancias del toolkit. Si dos paneles lanzan pings a la vez, el último gana. Aceptado.
- El timestamp en la última línea del archivo es Unix (`date +%s`). El formato `%%s` en el `os.execute` es necesario porque el `%` debe escaparse una vez para el `string.format` y otra para el shell.
- `M.hosts` devuelve `list` y `active` como campos separados en lugar de mantener el estado en el módulo. El consumidor pasa `state` a `add` y `set_active`, que mutan `state` y persisten. Es un patrón funcional sin estado global. `notes.md` no lo menciona explícitamente pero es coherente con el resto del toolkit.
- El módulo no tiene un `M.remove(host)` para quitar hosts de la lista. Si se necesita, reconstruir la lista y llamar a `save`.

#### config.lua

**Propósito.**
Lectura y escritura de claves en `conf.lua` del proyecto Awesome original, y listado de recursos disponibles (temas, paletas). Puente entre el toolkit y la configuración heredada del entorno original.

**Alcance.**
Cubre lectura/escritura de claves de `~/.config/awesome/conf.lua`, listado de directorios de temas y archivos de paletas, comprobación de existencia de scripts externos (locker, greeter, wallpaper), y lectura de las opciones de animación del panel. Escribe strings entre comillas dobles (incluidas las booleanas como `"true"`/`"false"` y las numéricas como `"30"`), y añade la clave si no existe. No cubre la aplicación de la configuración ni el cambio de tema: solo lee y escribe el archivo. No cubre claves con otros formatos (tablas, funciones, comentarios inline).

**Cómo funciona.**

`M.CONF`, `M.THEMES`, `M.PALETTES` son rutas constantes calculadas al cargar. Apuntan al proyecto Awesome original (`~/.config/awesome/...`) y a la carpeta de paletas del proyecto LaneTK (`~/.config/lanetk/palettes`).

`palettes_dir()` decide cuál usar para el listado de paletas: prefiere `~/.config/lanetk/palettes` si contiene al menos `ayu.lua`, y cae a `~/.config/awesome/ui/palettes` si no. La comprobación se hace con `io.open` sobre `ayu.lua`, no con `io.popen` ni `ls`.

`M.get(key)` lee una clave de `conf.lua` con `helpers/util.read_conf_key`, que hace match de texto sobre `key = "valor"`. `M.set(key, value)` sobrescribe si la clave existe y la añade si no (antes del `return` final, o al final si no hay). El helper `helpers/util.write_conf_key` solo cubre el caso de sobrescritura; `data/config.M.set` es el que añade la lógica de inserción.

`M.list_themes()` ejecuta `ls -1d <THEMES>/*/` y extrae el nombre de cada directorio. Un "tema" es un directorio con un `theme.lua` dentro; el módulo no verifica el contenido, solo lista los directorios.

`M.list_palettes()` lista los `.lua` de `palettes_dir()` y extrae los nombres sin extensión. Ordena alfabéticamente.

`M.has_locker()`, `M.has_greeter()` y `M.has_wallpaper_conf()` comprueban con `io.open` si existen tres archivos concretos (`~/.config/locker/locker.sh`, `~/.config/lanetk/sh/greeter-wallpaper.sh`, `~/.config/awesome/wallpaper.conf`). Devuelven booleano. Se usan para decidir qué acciones mostrar en el tab de configuración.

**API.**

**Constantes.**

- `M.CONF` — ruta a `~/.config/awesome/conf.lua`.
- `M.THEMES` — ruta a `~/.config/awesome/ui/themes`.
- `M.PALETTES` — ruta a `~/.config/lanetk/palettes`.

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `get(key)` | string o `nil` | Lee de `conf.lua`. Solo claves string. |
| `set(key, value)` | `bool` | Sobrescribe si existe; **añade la clave** si no existe (antes del `return` final o al final del archivo). |
| `list_themes()` | tabla de strings | Nombres de directorios. |
| `list_palettes()` | tabla de strings | Nombres sin `.lua`. |
| `has_locker()` | `bool` | |
| `has_greeter()` | `bool` | |
| `has_wallpaper_conf()` | `bool` | |
| `get_bool(key, default)` | `bool` | Lee "true"/"false". Devuelve `default` si no está o no parsea. |
| `set_bool(key, value)` | `bool` | Escribe "true" o "false". |
| `get_int(key, default)` | `int` | Lee un entero. Devuelve `default` si no está o no parsea. |
| `set_int(key, value)` | `bool` | Escribe un entero como string. |

**Patrón.**

    local D = require("lib.data.config")

    local current_theme = D.config.get("theme")
    local themes = D.config.list_themes()
    local palettes = D.config.list_palettes()

    if D.config.has_locker() then
        actions:add_action("Cambiar wallpaper", "...")
    end

Ver `examples/11-tab-config.lua`.

**Anti-patrón.**

- **Asumir que `conf.lua` existe.** Si no, `get` devuelve `nil` y `set` devuelve `false`. El consumidor debe manejar el caso: mostrar valores por defecto o avisar que no hay configuración.
- **Pasar valores numéricos a `set`.** `write_conf_key` espera un string y lo interpola directamente. Un número se convierte a string por Lua, pero un valor con comillas dobles dentro rompería el patrón. Los valores válidos son strings sin `"`.
- **Asumir que `list_themes` devuelve solo temas válidos.** Lista todos los directorios de `THEMES`, sin comprobar si contienen `theme.lua`. Un directorio vacío o incompleto se lista igual.
- **Modificar las rutas constantes.** `M.CONF`, `M.THEMES`, `M.PALETTES` se calculan una vez al cargar. Reasignarlos no afecta a las funciones ya definidas que los leen por referencia directa.
- **Confundir las paletas del proyecto LaneTK con las del Awesome original.** `palettes_dir` prefiere las de LaneTK. Si el usuario no tiene `~/.config/lanetk/palettes`, cae al directorio de Awesome, que puede tener paletas distintas.

**Notas.**

- El módulo vive en `lib/data/` aunque no es un sampler en el sentido estricto: no lee datos del sistema, sino de configuración. Su presencia en `data/` es por convención del proyecto original.
- `has_locker`, `has_greeter` y `has_wallpaper_conf` comprueban rutas hardcodeadas. En una máquina sin esas instalaciones, devuelven `false` siempre.
- `list_themes` y `list_palettes` usan `io.popen` con `ls`. Para directorios con muchos archivos, la salida es larga pero el parseo es por línea. Aceptable para los tamaños típicos (decenas de temas, decenas de paletas).
- `M.set` sobrescribe si la clave existe y **añade la clave si no existe**, insertándola antes del `return` final del archivo (o al final si no hay `return`). El comportamiento anterior (solo sobrescribir) impedía que las claves nuevas de animación (`animate_tabs`, `animate_widgets`, `animate_values`) se persistieran al pulsar Aplicar en Configuración: `set` devolvía `false` sin escribir, y al reconstruir el panel `get_bool(..., true)` volvía al default.
- Los helpers tipados (`get_bool`, `set_bool`, `get_int`, `set_int`) son envoltorios sobre `get`/`set`. Convierten entre el string que vive en `conf.lua` y el tipo real. Si el archivo tiene `animate_panel = "true"`, `get_bool("animate_panel", false)` devuelve `true` (booleano, no string). Si la clave no existe o el valor no parsea, devuelven el `default`.

---

##### Niveles de animación (2026-09-25)

`get_anim_opts()` devuelve las cuatro claves de animación y los dos
parámetros de tiempo. La estructura es:

    {
        animate  = master,       -- animate_panel
        tabs     = master and get_bool("animate_tabs",    true),
        widgets  = master and get_bool("animate_widgets", true),
        values   = master and get_bool("animate_values",  true),
        hz       = get_int("anim_hz", 30),
        duration = get_int("anim_duration", 300),
    }

- `animate` es el **master**. Si está en `false`, los tres sub-toggles
  quedan en `false` sin importar lo que digan sus claves.
- `tabs`, `widgets` y `values` son independientes entre sí. Los tres
  default a `true` cuando `animate_panel = "true"` y no existen las
  claves nuevas (compatibilidad con configuraciones viejas).
- `hz` y `duration` los consume el motor de animación
  (`lib/anim.set_fps`, crossfade y tweens).

---

#### inicio.lua

**Propósito.**
Samplers estáticos y semi-estáticos del tab Inicio: nombre de usuario, hostname, distro, kernel, uptime, IP local, número de pantallas, shell, y búsqueda del avatar del usuario con conversión a PNG si es necesario.

**Alcance.**
Cubre datos del sistema que cambian lento o nunca (usuario, host, distro, kernel, shell) y datos que cambian en cada sesión (uptime, IP local, número de pantallas). Cubre la conversión de JPEG/BMP a PNG para el avatar. No cubre identidad visual del usuario (nombre completo, email): eso viene de AccountsService o similar, que el módulo no consulta. No cubre iconos de distro. No cubre wallpaper.

**Cómo funciona.**

`M.user()`, `M.host()`, `M.distro()`, `M.kernel()`, `M.shell_name()` son funciones que devuelven datos puntuales. `user` lee `$USER`. `host` ejecuta `hostname`. `distro` lee `PRETTY_NAME` de `/etc/os-release`. `kernel` ejecuta `uname -r`. `shell_name` extrae el nombre del `$SHELL` sin el path. Todos devuelven `"?"`, `"user"` o vacío si no pueden obtener el dato.

`M.uptime_secs()` lee el primer campo de `/proc/uptime` en segundos. `M.ip_local()` ejecuta `ip route get 1.1.1.1` y extrae el séptimo campo (la IP local de la ruta hacia 1.1.1.1). Si no hay ruta, devuelve `"sin red"`. `M.screens()` ejecuta `xrandr --query` y cuenta las ocurrencias de `" connected"`.

`is_png(path)` comprueba si un archivo empieza con la cabecera PNG (`\x89PNG`). Es un chequeo de 4 bytes, suficiente para descartar cualquier otro formato.

`convert_to_png(src, username?)` convierte un archivo (JPEG, BMP, lo que sea) a PNG en `~/.cache/lanetk/avatar-<username>.png`. El `username` es el del avatar, no el del proceso: un greeter corriendo como `greeter` pero mostrando el avatar de `ansmoun` tiene que pasar `"ansmoun"` para que cada usuario tenga su propio cache. Si se omite, se usa `"default"` como sufijo. Primero comprueba si el cache existe y es más reciente que el original con `test -f ... -a ... -nt ...`. Si el cache es válido, lo devuelve. Si no, prueba tres comandos en orden: `ffmpeg`, `magick` (ImageMagick 7), `convert` (ImageMagick 6). Tras cada uno, verifica que el archivo cacheado sea PNG con `is_png`. Si ninguno funciona, devuelve `nil`. El directorio de cache se crea con `mkdir -p` antes de intentar.

`M.find_avatar(username?)` busca el avatar en `~/.face`, `~/.face.icon` y `/var/lib/AccountsService/icons/<user>`. Si no se pasa `username`, usa `$USER` del proceso. **Es obligatorio pasar el username explícito** cuando el proceso corre como un usuario distinto al que se muestra (por ejemplo, un greeter). Si encuentra uno que ya es PNG, lo devuelve tal cual. Si no, intenta convertirlo con `convert_to_png(src, username)`. Si todas las opciones fallan, devuelve `nil`.

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `user()` | string | `$USER` o `"user"`. |
| `host()` | string | Salida de `hostname` sin whitespace. |
| `distro()` | string | `PRETTY_NAME` de `/etc/os-release`. |
| `kernel()` | string | `uname -r`. |
| `uptime_secs()` | number | Segundos desde el arranque. |
| `ip_local()` | string | IP local o `"sin red"`. |
| `screens()` | number | Cuenta de monitores conectados. |
| `shell_name()` | string | Nombre del shell sin path. |
| `find_avatar(username?)` | string o `nil` | Ruta a un PNG. `username` default `$USER`. Convierte si hace falta. |

**Patrón.**

    local D = require("lib.data.inicio")
    local F = require("lib.helpers.format")

    header:set("Hola, " .. D.inicio.user())
    kv:set("host", D.inicio.host())
    kv:set("distro", D.inicio.distro())
    kv:set("kernel", D.inicio.kernel())
    kv:set("uptime", F.uptime(D.inicio.uptime_secs()))

    local av = D.inicio.find_avatar()
    if av then avatar:set_path(av) end

Ver `examples/12-tab-inicio.lua`.

**Anti-patrón.**

- **Llamar `find_avatar()` sin username desde un proceso que corre como otro usuario.** Un greeter corre como `greeter` pero muestra el avatar de `ansmoun`. Sin pasar `"ansmoun"` explícito, busca `/var/lib/AccountsService/icons/greeter` que no existe. Pasar siempre el username del usuario a mostrar.
- **Asumir que `find_avatar` devuelve algo.** En sistemas sin foto de usuario, devuelve `nil` siempre. El widget que lo consume debe dibujar un placeholder (inicial del usuario, icono genérico) cuando no hay avatar.
- **Llamar `find_avatar` en cada tick.** Ejecuta `test -nt` (rápido) y, si el cache no es válido, hasta tres conversiones (lentas). Llamar una vez al construir el tab.
- **Asumir que `ffmpeg`, `magick` o `convert` están instalados.** En un sistema mínimo, ninguno puede estar. La conversión falla, `find_avatar` devuelve `nil`, y el consumidor debe manejar el caso. El módulo no reporta cuál de las tres herramientas falta.
- **Usar `M.screens()` para el layout.** Devuelve una cuenta, no la geometría de cada pantalla. Para saber dónde está cada monitor, usar `lib/screens`.
- **Llamar `ip_local()` en un sistema sin `ip`.** El binario `ip` es parte de `iproute2`. En sistemas muy minimalistas puede faltar. La función devuelve `"sin red"` en ese caso, que puede ser confuso si en realidad hay red.

**Notas.**

- El chequeo de antigüedad del cache del avatar usa `test -f ... -a ... -nt ...`. Si el original fue modificado después del cache, se regenera. Si no, se reutiliza. Es la forma estándar en shell sin depender de `stat`.
- La conversión con `ffmpeg` es la preferida porque es la más rápida y no depende de ImageMagick. En sistemas sin `ffmpeg` pero con ImageMagick, el segundo comando funciona. El orden importa.
- `is_png` lee solo 4 bytes. Es suficiente para verificar la firma PNG (`\x89PNG\r\n\x1a\n` completa sería 8 bytes, pero los primeros 4 ya descartan la mayoría de otros formatos).
- `find_avatar` prefiere `~/.face` sobre `~/.face.icon` sobre `/var/lib/AccountsService/icons/<user>`. El orden es por convención: `.face` es lo más común en X11, `.face.icon` en algunos gestores, y AccountsService en GNOME/KDE.
- El archivo cacheado (`~/.cache/lanetk/avatar.png`) es compartido por todas las ejecuciones del toolkit en el mismo usuario. El primer tab que se abra lo genera; los siguientes lo reutilizan.

---

#### notes.lua

**Propósito.**
Gestión de notas en archivos Markdown individuales en `~/.config/awesome/notes/`. Cada nota es un archivo `.md` con la primera línea como título (`[ ] Título` o `[x] Título`) y el resto como cuerpo. Cubre listar, crear, borrar, alternar estado done, leer, y migrar un archivo legacy de formato plano.

**Alcance.**
Cubre notas de una línea de título más cuerpo. No cubre edición dentro del tab: el módulo lee y escribe archivos, pero el editor real es externo (por ejemplo, `$EDITOR` en una terminal). No cubre etiquetas, categorías, ni búsqueda full-text. No cubre sincronización con otros formatos (todo es Markdown plano). No cubre adjuntos.

**Cómo funciona.**

`M.DIR` es `~/.config/awesome/notes`. `M.LEGACY` es `~/.config/awesome/notes.txt`, el archivo plano del proyecto original. `ensure_dir` crea el directorio con `mkdir -p` si no existe.

`slugify(title)` convierte un título en un nombre de archivo válido. Reemplaza caracteres acentuados del español (`á`, `é`, `í`, `ó`, `ú`, `ñ`) por sus equivalentes ASCII, elimina caracteres no alfanuméricos (excepto `-` y `_`), colapsa espacios y guiones múltiples, y trunca a 60 caracteres. Si el resultado queda vacío, usa `"nota"`.

`unique_path(title)` genera una ruta única. Si ya existe un archivo con el slug del título, añade `-2`, `-3`, etc. hasta encontrar uno libre. Es el patrón típico para no sobrescribir.

`parse_content(content)` analiza el contenido de una nota. Si la primera línea empieza por `[ ]` o `[x]`, extrae el estado (`done`) y el título. El resto es el cuerpo. Si no tiene ese formato, la primera línea es el título y `done = false`. Siempre devuelve `{ done, title, body }`.

`format_content(done, title, body)` hace lo inverso: construye el contenido con el marcador `[x]` o `[ ]` seguido del título, más el cuerpo. Asegura que el archivo termine en `\n`.

`read_note(path)` lee un archivo y le aplica `parse_content`. Añade el campo `path` al resultado. `write_note(path, done, title, body)` escribe el archivo formateado.

`M.list()` lista todos los `.md` del directorio ordenados por mtime descendente (`ls -t -1`). Para cada uno, lee y parsea. Añade un campo `preview` con la primera línea del cuerpo, truncada a 90 caracteres con elipsis. Separa las notas en pendientes y hechas, y devuelve primero todas las pendientes y luego las hechas. Cada nota en el retorno tiene `{ path, title, done, body, preview }`.

`M.create(title)` genera una nota nueva vacía con el título dado. Usa `slugify` para el nombre del archivo. Devuelve la ruta. Si el título está vacío, usa `"Nueva nota"`.

`M.delete(path)` llama a `os.remove`.

`M.toggle_done(path)` lee la nota, invierte el estado `done`, y la reescribe.

`M.read(path)` es un alias público de `read_note`.

`M.migrate_legacy()` convierte el archivo legacy `notes.txt` (formato plano con entradas `[ ] Título`, `[x] Título`, y cuerpo en las líneas siguientes separadas por líneas vacías) en archivos individuales bajo `M.DIR`. Tras la migración, renombra el original a `.migrated` para no volver a migrarlo. Devuelve `true` si había algo que migrar, `false` si el archivo legacy no existe.

**API.**

**Constantes.**

- `M.DIR` — ruta al directorio de notas.
- `M.LEGACY` — ruta al archivo legacy.

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `list()` | tabla | Pendientes primero, luego hechas. |
| `create(title)` | string | Ruta del archivo nuevo. |
| `delete(path)` | — | `os.remove`. |
| `toggle_done(path)` | — | Invierte el estado. |
| `read(path)` | tabla o `nil` | `{ done, title, body, path }`. |
| `migrate_legacy()` | `bool` | `true` si migró algo. |

**Campos de cada nota de `list()`.**

- `path` — ruta al `.md`.
- `title` — título.
- `done` — booleano.
- `body` — cuerpo completo.
- `preview` — primera línea del cuerpo, truncada a 88 caracteres más `…`.

**Patrón.**

    local D = require("lib.data.notes")

    -- Migrar una sola vez al arrancar el tab.
    D.notes.migrate_legacy()

    local notes = D.notes.list()
    for _, n in ipairs(notes) do
        list:add_row({
            title = n.title,
            done = n.done,
            preview = n.preview,
            on_toggle = function() D.notes.toggle_done(n.path) end,
            on_edit = function() open_external_editor(n.path) end,
        })
    end

Ver `examples/19-tab-notes.lua`.

**Anti-patrón.**

- **Llamar `list()` en cada tick.** Lista el directorio con `ls` y lee cada archivo para el preview. Con muchas notas, es costoso. Llamar tras cambios explícitos (crear, borrar, toggle) o con un timer de varios segundos.
- **Asumir que `migrate_legacy` es idempotente sin protección.** Sí lo es: tras la migración, renombra el original a `.migrated`. Pero si el consumidor llama `migrate_legacy` sin comprobar el retorno, el rename se ejecuta cada vez que se llame (aunque el archivo ya no exista, el chequeo inicial lo detecta). Es correcto pero redundante.
- **Editar el archivo mientras el módulo lo lee.** No hay locking. Un editor externo que escriba mientras `read_note` corre puede dar un contenido parcial. Es un problema de concurrencia inherente al modelo de archivos.
- **Asumir que el título no se pierde al cambiar el archivo a mano.** El título está en la primera línea. Si el usuario edita el archivo y borra la primera línea, `parse_content` toma la primera línea del cuerpo como título. Es el comportamiento esperado pero puede sorprender.
- **Usar `M.create` con un título que ya existe.** `unique_path` resuelve el conflicto añadiendo `-2`, `-3`. Nunca sobrescribe. Correcto, pero el usuario puede terminar con tres notas tituladas igual y sufijos distintos.

**Notas.**

- El slugify cubre los caracteres acentuados del español pero no los de otros idiomas (alemán `ß`, francés `ç`, etc.). Un título en otro idioma produce un slug con caracteres eliminados o con el título original si todos los caracteres son válidos.
- `M.DIR` está en `~/.config/awesome/notes` (heredado del proyecto original), no en `~/.config/lanetk/notes`. Es intencional: las notas son del usuario y se mantienen entre proyectos.
- El preview corta en la primera línea del cuerpo. Si la nota no tiene cuerpo, el preview es `""`.
- `M.list` ordena por mtime descendente (`ls -t`), y luego separa por estado. Dentro de cada grupo, el orden es por mtime descendente (más recientes primero). Es el orden natural de un gestor de notas.
- El archivo legacy `.migrated` se mantiene por seguridad. El usuario puede borrarlo tras verificar que la migración fue correcta.

#### dispositivos.lua

**Propósito.**
Descubre dispositivos en la red local a partir de la tabla de vecinos ARP del kernel (`ip neigh`) y los enriquece con fabricante (por OUI) y hostname (por mDNS/DNS). Mantiene un registro de cuándo se vio cada MAC por primera vez.

**Alcance.**
Cubre el escaneo de la tabla ARP, lookup de fabricante por OUI con fallback local, lookup de hostname por `avahi-resolve` o `getent`, y registro persistente de "seen" en `~/.cache/awesome-net-seen`. No cubre escaneo activo con `arp-scan` (el parámetro `use_arpscan` existe pero no está implementado). No cubre puertos abiertos, fingerprinting ni detección de tipo de dispositivo. No cubre la carga y descarga del archivo de OUI completo: solo tiene una tabla de fabricantes comunes.

**Cómo funciona.**

`M.local_macs()` recorre `/sys/class/net/*/address` para obtener las MAC locales del propio host, indexadas por interfaz. Se usa para marcar dispositivos como `is_local`.

`lookup_vendor(mac)` extrae los primeros 3 bytes de la MAC (`XX:XX:XX`) y consulta la tabla `OUI_FALLBACK` con más de 15 fabricantes comunes (VMware, Intel, Raspberry Pi, TP-Link, Xiaomi, Huawei, Samsung, Apple). Si no encuentra el prefijo, comprueba si la MAC está localmente administrada mirando el bit `0x02` del primer octeto: si está activo, devuelve `"(local)"`, si no, `"(desconocido)"`. Los resultados se cachean en `vendor_cache` a nivel de módulo.

`lookup_hostname(mac, ip)` intenta resolver el hostname por dos vías: primero con `avahi-resolve -4 -a <ip>` con timeout de 1 s (mDNS), luego con `getent hosts <ip>` (DNS/hosts). Si ambos fallan, devuelve `"—"`. Los resultados se cachean en `hostname_cache`.

`load_seen()` lee el archivo de registro `~/.cache/awesome-net-seen` con líneas `MAC timestamp`. Cada entrada se guarda en `seen_cache`. Se llama una sola vez por sesión (marcado con `seen_loaded`).

`fmt_seen(mac)` formatea la antigüedad del último avistamiento: `"ahora"` si fue hace menos de 60 s, `"Nm"` para minutos, `"Nh"` para horas, `"Nd"` para días, o `"—"` si nunca se vio.

`save_seen()` escribe el `seen_cache` de vuelta al archivo. Se llama al final del escaneo.

`ipkey(ip)` convierte una IP en un entero para ordenar numéricamente (no lexicográficamente). Sin esta conversión, `192.168.1.100` se ordenaría antes que `192.168.1.2`.

`M.scan(use_arpscan, cb)` es la función principal. Ejecuta `ip neigh show`, parsea cada línea con el patrón `ip dev iface lladdr mac state`, y construye una lista de entradas. Para cada entrada: marca `is_local` si la MAC es del host, actualiza `seen_cache` con el timestamp actual, calcula `prio` (1 si es local, 2 si REACHABLE, 3 si STALE, 4 si otro estado), resuelve el fabricante y el hostname, y calcula el `seen_str`. Ordena por `prio` ascendente y luego por `ipkey` ascendente. Guarda el `seen_cache` y llama a `cb(list)`. El parámetro `use_arpscan` se ignora en esta versión.

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `local_macs()` | tabla | `mac → iface` de las MAC locales. |
| `scan(use_arpscan, cb)` | — | Llama a `cb(entries)`. `use_arpscan` ignorado. |

**Campos de cada entrada de `scan`.**

- `ip`, `mac`, `iface`, `state` — datos crudos de `ip neigh`.
- `is_local` — booleano. `true` si la MAC es del host.
- `prio` — 1 (local), 2 (REACHABLE), 3 (STALE), 4 (otro).
- `vendor_display` — fabricante o `"(local)"`/`"(desconocido)"`.
- `hostname` — hostname resuelto o `"—"`.
- `seen_str` — `"ahora"`, `"Nm"`, `"Nh"`, `"Nd"` o `"—"`.

**Patrón.**

    local D = require("lib.data.dispositivos")

    srv:add_timer(30000, function()
        D.dispositivos.scan(false, function(list)
            rows:clear()
            for _, e in ipairs(list) do
                rows:add_row {
                    id = e.mac,
                    label = e.ip,
                    extra = e.vendor_display .. " " .. e.hostname,
                }
            end
        end)
    end)

Ver `examples/17-tab-net.lua`.

**Anti-patrón.**

- **Asumir que `scan` es asíncrono.** Es completamente síncrono: `ip neigh`, `avahi-resolve` (timeout 1 s por host), y `getent` bloquean. Con muchos hosts desconocidos, el tab puede quedar congelado varios segundos. El comentario del código sugiere que en el futuro se use `arp-scan` como opción, pero hoy no está.
- **Confundir `vendor_display` con el fabricante real.** Es una aproximación por prefijo OUI de una tabla corta. Muchos fabricantes no están en la tabla y caen a `"(desconocido)"`. Para fabricantes precisos, se necesitaría la base completa de IEEE OUI.
- **Asumir que `hostname` es siempre legible.** Depende de que el otro extremo responda a mDNS o tenga entrada en DNS. En redes domésticas típicas, la mayoría de dispositivos no responden, y el campo queda `"—"`.
- **Llamar `scan` en intervalos cortos.** El avahi-resolve con timeout 1 s por host hace que un escaneo con 20 hosts desconocidos tarde hasta 20 s. Cada llamada adicional acumula. El toolkit usa 30 s entre escaneos.
- **Ignorar el parámetro `use_arpscan`.** No hace nada hoy. Si en el futuro se implementa, cambiará el comportamiento de la función. Los consumidores no deben depender de su valor actual.

**Notas.**

- El archivo de "seen" persiste entre sesiones. Un dispositivo que se vio hace 3 días aparece con `"3d"` hasta que se vuelva a ver.
- `save_seen` reescribe el archivo completo en cada escaneo. Es un archivo de decenas de líneas, no hay problema de rendimiento.
- El `prio` se ordena ascendentemente: los locales primero, luego los reachable, luego stale, luego el resto. Dentro de cada grupo, por IP numérica ascendente. Es el orden esperado en un listado de red.
- La detección de "localmente administrada" usa el bit `0x02` del primer octeto. Es la convención IEEE para MACs configuradas a mano (por ejemplo, en máquinas virtuales).
- El hostname se intenta resolver siempre, incluso para MACs locales. En la práctica, el lookup falla rápido para MACs locales porque no están en ninguna tabla. No hay optimización al respecto.

---

#### launcher.lua

**Propósito.**
Escaneo, parseo y búsqueda de archivos `.desktop`. Indexa las aplicaciones instaladas en `/usr/share/applications`, `/usr/local/share/applications` y `~/.local/share/applications`, mantiene un historial de uso, y busca con puntuación por relevancia. También indexa iconos asociados a las aplicaciones.

**Alcance.**
Cubre el parseo de `.desktop` de tipo `Application`, búsqueda por relevancia (prefijo, substring, subsequence), historial de uso persistente, comandos directos con prefijo `>`, y resolución de iconos con cache en disco. No cubre aplicaciones que requieren argumentos adicionales complejos. No cubre `.desktop` con `OnlyShowIn`/`NotShowIn` específicos de escritorio: los muestra todos. No cubre categorías ni filtros por tipo. No cubre la ejecución real: delega a `os.execute`.

**Cómo funciona.**

`parse_desktop(path)` abre el archivo y busca la sección `[Desktop Entry]`. Lee pares `key = value` hasta la siguiente sección (`[...]`). Filtra entradas con `NoDisplay=true` o `Hidden=true`, y descarta las que no tienen `Name` o `Exec`. Limpia el `Exec` quitando los campos `%u`, `%U`, `%f`, `%F`, `%d`, `%D`, `%n`, `%N`, `%i`, `%c`, `%k`, `%v`, `%m`. Devuelve `{ name, exec, icon, comment, path, kind = "app" }`.

`M.scan()` recorre los tres directorios y parsea cada `.desktop`. Deduplica por nombre en lowercase, quedándose con la primera aparición. Ordena por nombre. Guarda el resultado en `cache = { entries, by_name }`. Devuelve el número de entradas.

`load_history()` lee `~/.cache/lanetk-launcher-history` con líneas `nombre\tn`. `save_history(h)` lo escribe. `M.record_usage(entry)` incrementa el contador del nombre.

`M.history_top(n)` devuelve las `n` entradas más usadas del historial, en orden descendente.

`score_match(name, query, hist)` calcula un score:

- Prefijo: 100.
- Substring: 60.
- Subsequence (caracteres en orden, no contiguos): 20.
- Sin match: `nil`.

Si hay historial, suma `min(hist, 20)` al score. Cuanto más se ha usado una app, más sube.

`M.search(query)` maneja tres casos. Si la query empieza por `>`, trata el resto como un comando directo y devuelve una entrada virtual `{ name, exec, kind = "command" }`. Si la query es vacía, devuelve el top 20 del historial seguido de todas las apps ordenadas por nombre. Si hay query, puntúa cada app y devuelve las 100 mejores.

`M.execute(entry)` registra el uso y ejecuta `(exec &)` en background.

La indexación de iconos es más compleja. `collect_needed_icons()` recorre el cache de apps y extrae el nombre base del icono (sin directorio ni extensión de imagen) en un conjunto. `build_icon_index(needed)` ejecuta `find` sobre `/usr/share/icons`, `/usr/share/pixmaps` y `~/.local/share/icons` buscando archivos de imagen, y para cada uno que matchee un nombre del conjunto, lo guarda. Si hay varias coincidencias para un mismo nombre, prefiere la extensión `.svg` sobre las demás. Los nombres sin coincidencia se guardan como `""` (indicando "buscado, no encontrado"). El resultado se guarda en `~/.cache/lanetk-icon-index.tsv`. `load_cache()` lee el cache y `save_cache` lo escribe.

`get_icon_index()` es la función de cache inteligente: si hay cache en disco y cubre todos los iconos necesarios, la usa. Si no, reconstruye con `build_icon_index` y guarda. El cache solo se invalida cuando aparece un icono nuevo que no está en el índice.

`M.find_icon(name)` resuelve un nombre de icono a una ruta. Si el nombre es una ruta absoluta, comprueba que exista y la devuelve. Si no, usa el índice cacheado. Devuelve `nil` si no encuentra.

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `scan()` | int | Fuerza un re-escaneo. Devuelve el número de apps. |
| `search(query)` | tabla | Lista de entradas según la query. |
| `execute(entry)` | — | Ejecuta y registra uso. |
| `history_top(n)` | tabla | Las `n` entradas más usadas. |
| `record_usage(entry)` | — | Incrementa el contador. |
| `find_icon(name)` | string o `nil` | Ruta al icono resuelto. |

**Campos de una entrada de app.**

- `name`, `exec`, `icon`, `comment`, `path`, `kind` (`"app"`).

**Campos de una entrada de comando.**

- `name`, `exec`, `icon` (vacío), `comment`, `kind` (`"command"`).

**Patrón.**

    local D = require("lib.data.launcher")

    D.launcher.scan()

    -- En cada cambio del TextInput:
    local items = D.launcher.search(query)
    for _, e in ipairs(items) do
        local icon_path = D.launcher.find_icon(e.icon)
        -- construir fila con icono + nombre
    end

    -- Al hacer Enter sobre una fila:
    D.launcher.execute(items[idx])

Ver `examples/19-launcher.lua`.

**Anti-patrón.**

- **Llamar `scan` en cada búsqueda.** El escaneo recorre los `.desktop` de tres directorios y los parsea. Es rápido (decenas de ms) pero no trivial. `search` llama a `ensure_cache` que escanea si no hay cache. Llamar `scan` una vez al arrancar el launcher y dejar que `search` use el cache.
- **Asumir que `search("")` devuelve lo mismo que `search` con query.** El caso vacío devuelve el historial seguido de todo ordenado por nombre. La query no vacía devuelve solo las mejores coincidencias. Son flujos distintos.
- **Asumir que `find_icon` encuentra todos los iconos.** Muchos `.desktop` declaran iconos con nombres que no existen en el sistema. La primera vez que se busca un nombre nuevo, se reconstruye el índice completo (con `find` sobre todos los directorios de iconos, que es lento). Los nombres no encontrados se cachean como `""`, así que la segunda vez es rápida.
- **Ignorar el coste del primer `find_icon`.** La primera llamada con un nombre nuevo reconstruye el índice, que puede tardar segundos en un sistema con muchos iconos. Ocurre una sola vez por sesión (el índice queda en `icon_index` y en el archivo de cache). Llamar una vez al arrancar el launcher con un icono de prueba para forzar la construcción.
- **Confundir `execute` con `os.execute` bloqueante.** `M.execute` lanza `(exec &)` en background. No bloquea. Pero el `os.execute` de Lua en sí espera a que el shell retorne, lo que con `&` es inmediato. La diferencia con `os.execute` directo es el paréntesis, que crea un subshell.

**Notas.**

- El historial se guarda como `nombre\tn`. La clave es el nombre en lowercase para que sea robusto frente a cambios de mayúsculas en el `.desktop`.
- `score_match` con subsequence devuelve 20, bastante bajo, para que coincidencias más fuertes ganen. Una app que empieza por la query siempre gana a una que la tiene en medio, que gana a una con caracteres dispersos.
- El bonus por historial es `min(hist, 20)`. Una app usada 100 veces no tiene más bonus que una usada 20. Es un techo deliberado para evitar que el historial domine completamente el ranking.
- La deduplicación por nombre en lowercase resuelve el caso de apps instaladas en `/usr/share` y `~/.local/share` con el mismo nombre. Gana la primera que se encuentra, que es la de `/usr/share` porque se escanea primero.
- `find` en `build_icon_index` busca en todos los subdirectorios de temas de iconos. El conjunto `needed` filtra para no procesar miles de archivos de temas que no se usan. Sin este filtro, el índice tendría decenas de miles de entradas.
- Preferir `.svg` sobre `.png` en el índice es por la calidad en distintos tamaños. Un icono SVG se puede escalar; un PNG a 16x16 se ve mal a 64x64.

---

#### search.lua

**Propósito.**
Búsqueda de archivos por nombre en el sistema de archivos, con filtros por tipo y dos fases (búsqueda de paths con `fd`, enriquecido con `stat`). Ambas fases corren de forma asíncrona mediante `helpers/async`.

**Alcance.**
Cubre búsqueda por nombre con `fd` (o `find` como fallback), filtros por tipo (archivo, directorio, imagen, audio, video, documento), case sensitivity configurable, búsqueda en múltiples roots, límite de profundidad, y enriquecido con `stat` (tamaño, mtime, tipo). No cubre búsqueda por contenido (grep). No cubre búsqueda en archivos ocultos fuera de los roots permitidos. No cubre paginación: el límite está fijo en 500 resultados.

**Cómo funciona.**

`M.has_fd()` comprueba si el binario `fd` está instalado con `command -v fd`. El resultado se cachea en `FD_AVAILABLE` a nivel de módulo.

`build_fd_cmd(query, root, type, case_sensitive, multi_root, max_depth)` construye el comando. Si `fd` está disponible:

- Prefijo con `nice -n 19 ionice -c 3 timeout 15` para bajar la prioridad de CPU e IO y limitar la duración.
- Flags: `--max-results 500`, `--absolute-path`, `--threads 1`, `--hidden`, y varios `--exclude` (`.git`, `.cache`, `node_modules`, `.local/share/Trash`, `/proc`, `/sys`, `/dev`).
- Case sensitive o ignore-case según el parámetro.
- Filtros de tipo: `--type f` (archivo), `--type d` (directorio), o extensiones específicas para imagen/audio/video/documento.
- La query entre comillas dobles con `%q`.
- El root (o `multi_root`) entre comillas dobles.
- Opcionalmente `--max-depth N`.

Si `fd` no está disponible, usa `find <root> -type f -iname "*query*"` con `timeout 15` y `head -n 500`.

`M.search(srv, query, root, type, case_sensitive, multi_root, max_depth, cb)` es la función pública. Si la query está vacía, llama a `cb({})` inmediatamente. Si no:

1. Construye el comando `fd` con `build_fd_cmd`.
2. Lo lanza con `A.async_shell`. En el callback, escribe cada línea de resultado a `/tmp/lanetk-search-paths.txt` (uno por línea) para no desbordar `argv` con paths largos.
3. Lanza `xargs -d '\n' -r stat -c '%n|%s|%Y|%F' < <archivo>` con `A.async_shell`. El separador `\n` (en lugar del default, espacio) preserva paths con espacios.
4. En el callback de `stat`, parsea cada línea `path|size|mtime|ftype` y construye el item `{ path, name, size, mtime, is_dir }`.
5. Llama a `cb(items)`.

El uso de `async_shell` en ambas fases hace que el event loop no se bloquee. La búsqueda de un filesystem grande puede tardar varios segundos sin afectar al repintado.

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `has_fd()` | `bool` | Cacheado. |
| `search(srv, query, root, type, case_sensitive, multi_root, max_depth, cb)` | — | Llama a `cb(items)`. |

**Parámetros de `search`.**

- `srv` — instancia de `Server`.
- `query` — string a buscar.
- `root` — directorio raíz por defecto.
- `type` — `"file"`, `"dir"`, `"image"`, `"audio"`, `"video"`, `"doc"`, o `nil` (todos).
- `case_sensitive` — booleano.
- `multi_root` — string con múltiples paths separados por espacio (opcional).
- `max_depth` — profundidad máxima (opcional).
- `cb` — `function(items)`.

**Campos de cada item.**

- `path` — ruta absoluta.
- `name` — nombre del archivo (último segmento).
- `size` — bytes.
- `mtime` — timestamp Unix.
- `is_dir` — booleano.

**Patrón.**

    local D = require("lib.data.search")

    D.search.search(srv, "informe",
        os.getenv("HOME"), "doc", false, nil, nil,
        function(items)
            list:set_items(items)
        end)

    D.search.search(srv, "vacaciones",
        os.getenv("HOME"), "image", false, nil, 5,
        function(items)
            list:set_items(items)
        end)

Ver `examples/20-search.lua`.

**Anti-patrón.**

- **Llamar `search` sin `srv`.** El parámetro es obligatorio: `async_shell` lo necesita para el timer de polling. Un `srv` nil hace que el timer falle al registrarse.
- **Asumir que `fd` está instalado.** El fallback con `find` funciona pero es más lento y no soporta todos los filtros de tipo (imagen/audio/video/doc usan `--extension` de `fd`, que `find` no tiene). Con `find`, los filtros de tipo caen a `-type f -iname "*query*"`, sin filtro por extensión.
- **Llamar `search` sin cancelar la anterior.** Cada búsqueda lanza dos `async_shell`. Si el usuario escribe rápido en el `TextInput`, se acumulan búsquedas. `notes.md` documenta el patrón general: guardar el handle de `async_shell` y cancelarlo en la siguiente búsqueda. El módulo no lo hace por sí solo: el consumidor debe hacerlo.
- **Asumir que `cb` se llama solo una vez.** La cadena de callbacks es lineal y cada `search` llama a `cb` exactamente una vez. Pero si el consumidor lanza dos `search` seguidos sin cancelar el primero, ambos callbacks se ejecutarán.
- **Pasar paths con `"` o `'` en `multi_root`.** El comando se construye con `string.format("%q", ...)`, que escapa comillas dobles. Los paths con comillas simples también se manejan porque `%q` usa comillas dobles. Pero paths con newlines o caracteres de control rompen el parser.

**Notas.**

- El timeout de 15 s evita que una búsqueda en un filesystem enorme cuelgue el sistema. Si la búsqueda no termina en 15 s, `fd` se mata y el resultado es parcial.
- `nice -n 19` y `ionice -c 3` bajan la prioridad al mínimo. En un sistema interactivo, la búsqueda no compite con otras tareas.
- El `--threads 1` de `fd` es conservador. La búsqueda es más lenta pero menos agresiva con el sistema.
- La lista de `--exclude` está hardcodeada. `.git`, `.cache`, `node_modules`, `.local/share/Trash`, `/proc`, `/sys`, `/dev`. Es un filtro razonable para búsquedas de usuario, pero puede dejar fuera archivos legítimos (un `.gitignore` que el usuario quiera encontrar, por ejemplo).
- El archivo `/tmp/lanetk-search-paths.txt` es compartido entre todas las instancias del toolkit. Dos búsquedas simultáneas en el mismo usuario compiten por el archivo. El `os.remove` al final del segundo callback lo borra. Aceptado.
- El parser de `stat` divide por `|`. Los paths con `|` en el nombre rompen el parser. Es un caso raro en la práctica. El `xargs -d '\n'` evita el problema para espacios, pero no para pipes.

---

### Pendiente: samplers no portados

El toolkit tiene los samplers del proyecto original portados, pero hay dos categorías que hoy no existen o están incompletos:

- **Samplers de hardware**: nada para sensores de ventiladores, brillo de pantalla, ni volumen de audio. El tab de Configuración hoy cicla paletas y poco más.
- **Samplers específicos de WM**: `taglist`, `layoutbox`, `systray`. Hablan con EWMH, que el toolkit no implementa todavía.

`notes.md` documenta el estado del port y los pendientes de la Fase E y posteriores.

#### users.lua

**Propósito.**
Descubre los usuarios "reales" del sistema desde `/etc/passwd`. Filtra cuentas de servicio, shells no interactivas, y una lista negra configurable.

**Alcance.**
Cubre el descubrimiento y filtrado. No cubre autenticación (eso es PAM / greetd). No cubre la gestión de usuarios (crear, borrar, modificar). No cubre grupos ni permisos.

**Cómo funciona.**

`M.list(opts)` abre `/etc/passwd` y parsea cada línea con el formato estándar:

    name:x:uid:gid:gecos:home:shell

Un usuario se incluye si:

- `uid >= 1000` y `uid < 60000` (usuarios reales, no sistema).
- El shell está en la lista blanca: `/bin/bash`, `/bin/sh`, `/bin/zsh`, `/bin/dash`, `/bin/fish`, y sus variantes en `/usr/bin/`.
- El nombre no está en la blacklist.

La blacklist por defecto incluye `greeter` y `nobody`. Se puede extender con `opts.blacklist` (array de strings).

El campo `gecos` puede contener el nombre completo del usuario separado por comas. Se extrae la primera parte (antes de la primera coma) y se guarda como `display`. Si está vacío, se usa el nombre de usuario.

El resultado se ordena alfabéticamente por `username`.

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `list(opts?)` | tabla | Cada entrada es `{ username, uid, gid, home, shell, display }`. |

**Patrón.**

Listar usuarios reales excluyendo algunos:

    local users = require("lib.data.users")
    for _, u in ipairs(users.list({ blacklist = { "root" } })) do
        print(u.username, u.uid, u.display)
    end

**Anti-patrón.**

- **Asumir que `/etc/passwd` siempre es legible.** En sistemas con LDAP/NIS/SSSD, los usuarios pueden no estar en `/etc/passwd`. El módulo devuelve tabla vacía sin error.
- **Asumir que `uid >= 1000` cubre todos los usuarios reales.** Algunas distros usan rangos distintos (por ejemplo, `1000-60000` en Debian, `1000-65533` en otras). El módulo usa `1000 <= uid < 60000`, que cubre los casos comunes.
- **Usar el campo `display` como identificador.** Es el nombre completo del usuario, puede repetirse. El identificador es `username`.
- **Ignorar el campo `shell` para decidir si un usuario puede autenticarse.** Un usuario con `/sbin/nologin` no puede loguearse, pero puede aparecer en el listado si se quita el filtro. No lo hagas.

**Notas.**

- La lista blanca de shells cubre las variantes comunes. Si un usuario tiene un shell raro (`/bin/ksh`, por ejemplo) no aparece. Agregarlo a la lista si hace falta.
- `gecos` puede tener encoding raro. El módulo no lo valida.
- El módulo no consulta PAM ni logind. Solo `/etc/passwd`.

#### last_user.lua

**Propósito.**
Persiste el último usuario autenticado con éxito, para preseleccionarlo en el próximo login.

**Alcance.**
Cubre lectura y escritura del archivo. No cubre el flujo de autenticación (lo hace el consumidor). No cubre múltiples usuarios por sesión (solo guarda el último).

**Cómo funciona.**

El archivo de estado vive en `/var/lib/lefty/last-user`. Es un archivo de texto con una línea: el username. `install.sh` (de lefty) lo crea con modo `0666` y el directorio `/var/lib/lefty/` con `0777`, para que tanto el usuario `greeter` (que corre el greeter) como el usuario final (que se autentica) puedan escribirlo.

`M.get()` abre el archivo, lee la primera línea, limpia espacios y saltos. Devuelve `nil` si el archivo no existe, está vacío, o el nombre es vacío.

`M.set(name)` escribe el nombre con un `\n` final. Devuelve `false` si el archivo no se puede abrir (por ejemplo, sin permisos).

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `get()` | string o `nil` | Username del último login, o `nil`. |
| `set(name)` | `bool` | Escribe el archivo. `false` si falla. |

**Campos.**

- `M.FILE` — ruta absoluta al archivo. `/var/lib/lefty/last-user`.

**Patrón.**

Lectura al arrancar el greeter:

    local last_user = require("lib.data.last_user")
    local previous = last_user.get()   -- "ansmoun" o nil

Escritura tras autenticación exitosa:

    last_user.set("ansmoun")

**Anti-patrón.**

- **Llamar `set` antes de confirmar la autenticación.** Si el login falla pero ya escribiste el archivo, en el próximo intento se preselecciona el usuario equivocado. Escribir solo después del `success` del protocolo.
- **Asumir que el archivo es escribible.** En sistemas donde `/var/lib/lefty/` no se creó (porque `install.sh` no se corrió), el archivo no existe y `set` falla silenciosamente. La primera vez, el consumidor debe manejar el caso sin errores.
- **Leer el archivo en cada tick.** Es una operación de disco. Se lee una vez al arrancar.
- **Ignorar el retorno de `set`.** Devuelve `false` en fallo. Loguear el fallo si importa.

**Notas.**

- El path está hardcodeado a `/var/lib/lefty/last-user`. Es parte del contrato con `install.sh` de lefty. Si se cambia, hay que cambiar los dos.
- El archivo lo crea `install.sh`, no el módulo. Si el archivo no existe, `get` devuelve `nil` sin crearlo.
- La escritura no es atómica. Dos escrituras concurrentes pueden pisarse. En la práctica solo el greeter escribe, así que no hay problema.

## README-tabs.md

### Tabs

Un tab es un módulo con `M.new(srv, theme)` que devuelve `{ widget, start, stop }`. El widget es lo que se monta en el `Stack` de un `TabbedPanel`. `start` y `stop` son opcionales y se llaman al activar/desactivar la pestaña. Algunos tabs aceptan un tercer argumento (`opts` o `parent_win`) para variantes de comportamiento.

Convención de nombres: el archivo `inicio.lua` define el tab de Inicio, `cpu.lua` el de CPU, etc. Los agregadores (por ejemplo `resources/init.lua`) componen un `TabbedPanel` con otros tabs. `general.lua` es el primer sub-tab de Recursos.

#### general.lua

**Propósito.**
Tab "General" del panel de Recursos. Muestra cuatro barras horizontales (CPU, RAM, GPU, SWAP) más el tab de temperaturas en modo compacto embebido debajo.

**Alcance.**
Cubre las cuatro barras y embebe el tab de temps en modo compacto (sin card exterior). No cubre detalles de CPU (eso es `cpu.lua`), ni de RAM (`ram.lua`), ni de GPU (`gpu.lua`). Los datos de cada subsistema se muestrean en una sola función de refresco.

**Cómo funciona.**

`M.new(srv, theme)` construye el tab de temperaturas primero, en modo compacto (`{ compact = true }`). Ese tab es en realidad un `{ widget, start, stop }` que se puede embeber. En el tab general se usa solo el `widget`; sus métodos `start` y `stop` se llaman explícitamente desde el `start` / `stop` del general.

Las barras se construyen con `W.BarRow` con `rows` predefinidas (cpu, ram, gpu, swap) y colores tomados de `theme.telemetry`. `warn_at = 0.7` y `crit_at = 0.9` disparan el cambio de color por umbral.

La card de barras se envuelve en un `Card` sin título (`title = nil`) para que las barras queden visualmente agrupadas y con fondo. El tab de temps en modo compacto ya trae su propia card interna con borde, así que no se envuelve otra vez.

El layout final es un `Group` vertical con la card de barras (weight 0) y el widget de temps (weight 1). El widget de temps ocupa el sobrante del alto.

`refresh()` es la función que actualiza las cuatro barras. Llama a los samplers:

- `D_cpu.sample()` para CPU: pct = uso, detail = `"<freq> MHz · <temp>°C"`.
- `D_ram.sample()` para RAM: pct = uso, detail = `"<used> / <total>"`.
- `D_gpu.status()` para GPU: pct = render, detail = `"<freq> MHz · <power> W"`. Si no hay servicio GPU, `set_empty("gpu", "sin servicio")`.
- El swap sale del mismo sampler de RAM (`r.swap_pct`, `r.swap_used`, `r.swap_total`). Si no hay swap, `set_empty("swap", "sin swap")`.

El `start` del tab hace dos cosas antes de arrancar el timer:

1. `D_cpu.reset()` para limpiar el estado previo del sampler (la primera lectura tras el reset no lleva cuenta del intervalo anterior).
2. Llama dos veces a `refresh()` seguidas. La primera muestra valores iniciales, la segunda tiene en cuenta el delta del sampler de CPU y da un uso real en lugar de 0. El comentario de `cpu.lua` explica el patrón.

Después arranca el timer de 2 s para `refresh`, más el `start` del tab de temps embebido (que arranca su propio timer de 5 s).

El `stop` cancela el timer y llama al `stop` del tab de temps.

**API.**

**Funciones.**

- **`M.new(srv, theme)`** — Devuelve `{ widget, start, stop }`.

**Campos del retorno.**

- `widget` — el `Group` con la card de barras y el tab de temps.
- `start` — resetea el sampler de CPU, llama `refresh` dos veces, arranca el tab de temps, y registra el timer de 2 s.
- `stop` — cancela el timer y para el tab de temps.

**Patrón.**

Es un sub-tab dentro de un `TabbedPanel` de Recursos. No se monta directamente.

**Anti-patrón.**

- **Llamar `M.new` sin un `srv` válido.** El tab de temps embebido y el general registran timers contra `srv`. Sin `srv`, `add_timer` falla.
- **Llamar `start` dos veces.** Arrancaría dos timers y dos tabs de temps. El `TabbedPanel` llama `start` una vez por activación, y `stop` antes de la siguiente activación. El contrato está garantizado por el tabbed, no por el tab.
- **Asumir que la card de temps es la misma que la del tab de temps cuando se activa por separado.** El tab de temps tiene dos modos (`compact` y normal). En General se usa `compact` (una sola card interna). En el tab principal de temps se usa el modo normal (tres cards con título). Son widgets distintos, cada uno con su propio timer.
- **Depender del orden de las llamadas a los samplers.** El `refresh` llama a los cuatro samplers en orden fijo. Los samplers tienen estado (cpu guarda el prev para el delta). Cambiar el orden no rompe nada, pero el delta de CPU depende de la diferencia entre dos llamadas, no del orden entre samplers.

**Notas.**

- El `D_cpu.reset()` al `start` es importante: sin él, la primera lectura de CPU en el tab tendría un delta enorme (el tiempo desde que el tab se activó la última vez o desde el arranque del proceso), dando un uso distorsionado.
- El doble `refresh()` al `start` es un patrón del toolkit. `cpu.lua` en el `start` no lo necesita porque su `M.new` ya hace dos samples. `general.lua` lo hace en el `start` para que la primera muestra sea real.
- El swap se lee del sampler de RAM porque ambos vienen de `/proc/meminfo` y `/proc/swaps`. No hay un sampler de swap separado.
- El `set_empty` de `BarRow` deja la fila sin barra y con un texto en su lugar. Es lo que permite mostrar "sin swap" o "sin servicio" cuando no hay dato. Ver `barrow.lua` en `README-widgets.md`.

---

#### cpu.lua

**Propósito.**
Tab detallado de CPU: anillo con uso, sparkline de 60 muestras, motores con uso por núcleo, y KV con modelo, frecuencia, temperatura, uptime y load average.

**Alcance.**
Cubre uso total, historia reciente, uso por núcleo, y datos estáticos o semi-estáticos del CPU. No cubre frecuencia por núcleo individual. No cubre temperaturas de núcleos más allá del paquete (eso es `temps.lua`). No cubre governor ni límites de frecuencia.

**Cómo funciona.**

`M.new` hace un muestreo inicial **antes** de construir los widgets, para saber cuántos núcleos tiene la máquina (`first.n_cores`). Ese valor determina cuántas filas construir en el `Motors`. El patrón de doble sample (`D.reset(); D.sample(); first = D.sample()`) sirve para que el primer `first` tenga un uso real y no 0.

`D.freq_range()` da el rango min/max de frecuencias de la CPU, usado para mostrar la frecuencia actual con contexto en el KV.

Los cinco widgets del tab:

- **`Ring`** con el uso total. `raw_range = {0, 100}` para pasar el uso como porcentaje sin normalizar. `text` es el porcentaje, `sub` es la frecuencia actual.
- **`Spark`** con `samples = 60`, `min = 0`, `max = 100`, `axis_width = 28`, `grid = true`. Muestra la historia de uso de los últimos 60 s.
- **`Motors`** con una fila por núcleo (`"core0"`, `"core1"`, ...) y `left_width = 48`, `row_height = 12` (compacto).
- **`KV`** con cinco filas: `model`, `freq`, `temp`, `uptime`, `load`. Los colores y tamaños están ajustados para el espacio del panel.
- **`Card`s** que envuelven cada widget con título y fondo.

El layout está en dos filas de dos cards cada una: arriba el anillo y la spark, abajo los motores y la info. Los `weights` dan el 50% a cada uno.

`refresh_fast()` corre cada 1 s y actualiza el anillo, la spark, los motores y la frecuencia del KV. La frecuencia se muestra con markup para resaltar el valor actual contra el rango. La temperatura viene del sampler de CPU (paquete o Core 0).

`refresh_slow()` corre cada 5 s y actualiza el modelo, uptime y load. El modelo no cambia nunca, pero leerlo de `/proc/cpuinfo` cada 5 s es barato y evita mantener una variable de estado. El uptime y el load cambian cada pocos segundos y necesitan refresco.

El `start` llama `refresh_slow` primero (para poblar los datos estáticos) y `refresh_fast` después, y registra los dos timers. El `stop` cancela ambos.

**API.**

**Funciones.**

- **`M.new(srv, theme)`** — Devuelve `{ widget, start, stop }`.

**Campos del retorno.**

- `widget` — el `Group` con las dos filas de cards.
- `start` — llama `refresh_slow`, `refresh_fast`, y registra timers de 1 s (fast) y 5 s (slow).
- `stop` — cancela ambos timers.

**Patrón.**

Como sub-tab del panel de Recursos (dentro del agregador), o directamente en el panel principal:

    local tab = require("lib.tabs.cpu").new(srv, theme)
    srv:add_timer(0, tab.start)  -- o dejarlo al TabbedPanel

**Anti-patrón.**

- **Llamar `M.new` sin que el sampler de CPU se haya inicializado.** El doble sample en `M.new` inicializa `prev_stat`. Si se llama `D.sample()` antes, el `first` de `M.new` no será el primero (pero sigue funcionando, porque el delta entre llamadas es el uso real en el intervalo).
- **Asumir que el número de núcleos es fijo.** `first.n_cores` se lee una vez al construir el tab. Si la máquina hace hotplug de CPUs (raro en desktop, común en servidores), el widget no se actualiza. Es una limitación aceptada.
- **Llamar `refresh_fast` antes que `refresh_slow`.** El orden en el `start` importa poco porque los timers son independientes, pero si se llama `refresh_fast` primero, el KV de modelo/uptime/load tendría valores vacíos durante el primer segundo. El código actual llama `refresh_slow` primero.
- **Ignorar `range`.** El KV de frecuencia usa `range.min` y `range.max` para mostrar el rango. Si el sistema no expone `cpuinfo_min_freq` / `cpuinfo_max_freq`, el sampler devuelve defaults (800-1100 MHz) que pueden ser incorrectos. Es un fallback, no un dato real.
- **Pasar un `theme` sin `telemetry.cpu`.** El color del anillo y la spark caen a verdes hardcodeados (`{0.55, 0.85, 0.60}` y `"#8ec07c"`). El resto de widgets sí usan `theme.*`.

**Notas.**

- El `Motors` con `row_height = 12` es muy compacto para CPUs con muchos núcleos. Con 16+ núcleos, el widget ocupa más alto del que el `Card` reserva y puede quedarse sin mostrar todas las filas. El `Group` con `weight = 1` reparte el espacio, pero el `Motors` no tiene scroll.
- El KV tiene `key_width = 90` fijo. Un label más largo que 90 px se recortará. Los labels del tab son cortos (`"Temperatura"`, `"Frecuencia"`), así que caben.
- `info:set_markup("freq", ...)` usa markup Pango para mostrar la frecuencia en `theme.fg_normal` y el rango en `theme.muted`. El markup de `KV` permite colores por fila, útil cuando el formato simple no alcanza.
- La actualización del spark es en cada tick del timer fast (1 s). Con `samples = 60`, el spark muestra los últimos 60 s. El rango 0-100 es fijo, así que no hay autoescalado.
- Los timers de 1 s y 5 s se registran con `srv:add_timer`, que no se repite automáticamente. El `Server` los reprograma tras cada ejecución. Eso significa que un `refresh_fast` que tarde más de 1 s empuja el siguiente tick. En la práctica, los refrescos son rápidos.

---

#### ram.lua

**Propósito.**
Tab detallado de RAM: anillo con porcentaje de uso, desglose por categoría en barra apilada, lista de módulos físicos vía `dmidecode`, swap con barra apilada y ajuste de swappiness, y card de acciones destructivas (drop caches, compactar memoria, liberar swap).

**Alcance.**
Cubre uso total y desglose (usado real, cached, free, buffers, reclaimable, shared), módulos físicos, swap, y tres acciones de mantenimiento. No cubre memoria por proceso (eso es `proc.lua`). No cubre zram ni zswap. No cubre cambios de swappiness sin `sudo -n`.

**Cómo funciona.**

El módulo define una clase interna `SwapBar`, subclase de `W.Text`, que dibuja una barra de dos colores con clip redondeado. El clip del rect exterior es necesario porque el rect de un widget puede ser más angosto que `2 * radius`; sin el clip, las esquinas del `rounded_rect` se salen. `SwapBar:set_data(total, used)` actualiza los datos y daña.

`make_swp_btn(text, size)` es un helper local que construye un `Button` pequeño con colores oscuros, usado para los botones `−` y `+` de swappiness. Devuelve el botón.

`M.new(srv, theme)` construye todos los widgets del tab. Los seis bloques principales:

1. **`Ring`** con el porcentaje de uso. `raw_range = {0, 100}`, color tomado de `theme.telemetry.ram`, tamaño 150, grosor 12.
2. **`BarMulti`** con seis segmentos: `used` (con color dinámico según umbral), `cached`, `free`, `buffers`, `srecl`, `shmem`. `legend_cols = 3` para que la leyenda se distribuya en tres columnas cuando hay espacio.
3. **`Text`** para los módulos físicos. `wrap = true` para que un módulo por línea larga se envuelva. `valign = "top"` para que el bloque empiece arriba. Se envuelve en un `Card` con título `"Módulos"` y `min_height = 80`.
4. **`SwapBar`** + un `Text` con el detalle. Ambos dentro de un `Card` con título `"Swap"`, junto con la fila de swappiness.
5. **Fila de swappiness**: un `Text` con el label `"swappiness"`, dos botones `−` y `+`, y un `Text` con el valor numérico. Los botones tienen `opts.on_click` que llaman a `D.set_swappiness` con clamp `[0, 100]`, actualizan `swappiness` local y refrescan el `Text` del valor. `D.set_swappiness` corre en background (`sudo -n`), así que el cambio real es asíncrono.
6. **`Actions`** con tres comandos: `drop caches`, `compactar memoria`, `liberar swap`. Cada uno con `sudo -n` para no bloquear en un prompt de contraseña. Se envuelven en un `Card` con título `"Acciones"`.

El layout tiene dos filas. Arriba: anillo (weight 0, tamaño natural) y `BarMulti` (weight 1, ocupa el resto). Abajo: módulos, swap, acciones, los tres con `weight = 1`.

`refresh_modules()` llama a `D.modules()`. Si devuelve `nil` (típicamente porque `sudo` no está configurado para `dmidecode` sin password), muestra un mensaje en muted en el `Text` con markup. Si devuelve módulos, construye markup con el tamaño en `theme.accent`, el tipo y la velocidad en `theme.fg_normal`, y los extras (fabricante, part number) en `theme.muted`. Los tres campos extra se filtran por `"?"`, `""`, `"Unknown"` y el patrón `[Empty]` para no mostrar basura del `dmidecode`.

`refresh()` llama a `D.sample()` y actualiza:

- El anillo con `pct` de uso.
- Los seis segmentos del `BarMulti`. El "usado real" es `total - free - cached - srecl - buffers`, que es más informativo que el "used" del sampler. El color del segmento `used` cambia por umbral: `theme.usage_crit` si `pct > 0.8`, `theme.usage_warn` si `pct > 0.5`, `theme.telemetry.ram` si no.
- La `SwapBar` con `set_data(swap_total, swap_used)`.
- El texto del swap con markup (usado en `fg_normal`, total en muted). Si no hay swap, muestra `"Sin swap configurada"` en muted.

`start` llama `refresh_modules()` y `refresh()`, y registra el timer de 2 s. `stop` cancela el timer.

**API.**

**Funciones.**

- **`M.new(srv, theme)`** — Devuelve `{ widget, start, stop }`.

**Campos del retorno.**

- `widget` — el `Group` con las dos filas de cards.
- `start` — llama `refresh_modules`, `refresh`, y registra el timer de 2 s.
- `stop` — cancela el timer.

**Patrón.**

Como sub-tab del panel de Recursos. No se monta directamente.

**Anti-patrón.**

- **Asumir que `refresh_modules` muestra módulos.** Necesita `sudo` sin password para `dmidecode`. Sin esa configuración, el tab muestra un mensaje de "Verifica sudoers". Es el comportamiento esperado: no se fuerza un prompt interactivo.
- **Contar con que el cambio de swappiness sea inmediato.** `D.set_swappiness` corre en background. El valor mostrado en el `Text` sí se actualiza inmediatamente, pero el kernel puede tardar unos ms en aplicar el cambio. Si se re-lee `D.swappiness()` en el próximo tick, coincidirá.
- **Asumir que las tres acciones tienen efecto inmediato.** `drop caches`, `compact memory` y `liberar swap` son operaciones del kernel que pueden tardar. El comando corre en background y el feedback de `Actions` es inmediato (no espera al resultado real). Es la limitación de `os.execute` que documenta `actions.lua`.
- **Modificar el `BarMulti` con segmentos que no suman 1.** El `frac()` de cada segmento usa `kb / total`, y la suma teórica es 1, pero en la práctica puede no serlo (por ejemplo, si el kernel reporta `used_real` como negativo, clampeado a 0). `G.stacked_bar` no valida.
- **Asumir que el `Text` de módulos con `wrap = true` re-mide al cambiar.** El `Text` mide al construir con `text = ""`. Al llamar `set_markup`, `_remeasure` recalcula `text_w`/`text_h` con el texto plano (sin markup). El alto real del texto envuelto puede ser mayor que `text_h`. El clip del `Card` recorta el exceso.

**Notas.**

- El `SwapBar` con `used = 0` dibuja solo el color de "libre" en todo el ancho. El check `if pct > 0` protege contra el `rounded_rect` con ancho 0.
- El `Text` del `SwapBar` usa `W.Text` como base, pero se sobreescribe `draw` para pintar la barra. El `Text` solo sirve como `Area` con la infraestructura común.
- Los botones de swappiness usan `−` (U+2212, signo menos) en lugar del guion `-`. Es una decisión tipográfica: el signo menos es visualmente más ancho y se centra mejor en el botón.
- El color del segmento "used" en el `BarMulti` cambia por umbral. Es una funcionalidad específica del tab, no del widget. El `BarMulti` permite `color` por segmento en cada `set`, así que el tab lo aprovecha.
- Los segmentos con `pct = 0` (como `shmem`, que se dibuja sin porcentaje en la barra) igual se muestran en la leyenda con su valor. Es intencional: el `shmem` es un dato que se quiere ver aunque no ocupe ancho en la barra.
- La `Card` de acciones tiene `weight = 1` como las otras dos. Con textos largos (`"Drop caches"`, `"Compactar memoria"`), los botones de `Actions` ocupan el ancho disponible. La `Card` con `button_width = 190` centra los botones.

---

#### gpu.lua

**Propósito.**
Tab detallado de GPU: anillo con frecuencia actual, sparkline de 60 muestras de uso del motor render, motores (render, blitter, video), y KV con estado (RC6, consumo, IRQs). Incluye un header con el modelo de GPU y especificaciones.

**Alcance.**
Cubre telemetría de la GPU Intel integrada (`i915`): frecuencia, RC6, potencia, IRQs, uso de motores render/blitter/video. No cubre GPUs dedicadas NVIDIA/AMD: el sampler `gpu.lua` solo lee el archivo de estado de i915. No cubre memoria de GPU. No cubre temperatura de GPU.

**Cómo funciona.**

`M.new(srv, theme)` lee primero `D.specs()` para obtener el rango de frecuencias (`min`, `max`, `boost`). El color del anillo y de la spark viene de `theme.telemetry.gpu` con fallback a un púrpura-rosado.

Los cuatro widgets:

1. **`Ring`** con la frecuencia actual en MHz. `raw_range = {0, 100}`, `sub = "MHz"`.
2. **`Spark`** con `samples = 60` y el uso del motor render como dato. Rango 0-100, `axis_width = 36`, `axis_format = "%d%%"`.
3. **`Motors`** con tres filas: `render`, `blitter`, `video`.
4. **`KV`** con tres filas: `rc6` (porcentaje), `power` (watts), `irqs` (por segundo).

Un quinto widget, un `Header` con `wrap = true` y `valign = "top"`, muestra el modelo y especificaciones de la GPU. Se coloca debajo del anillo dentro de la misma `Card` del anillo, en un `Group` vertical. El anillo tiene `weight = 1`, el header `weight = 0` con `min_height = 24`.

El layout es el mismo que el del tab de CPU: dos filas de dos cards. Arriba: GPU (anillo + header) y spark. Abajo: motores y estado.

`refresh_hw()` construye el markup del header con el modelo, año de arquitectura, proceso de fabricación, número de execution units y rango de frecuencias. El texto es específico del `"Intel HD Graphics"` de Sandy Bridge. En otras GPUs, el header miente. Es una limitación conocida: el tab fue diseñado para esa GPU concreta. El comentario del código no lo aclara, pero el texto hardcodeado del `set_markup` es evidente.

`refresh()` llama a `D.status()`. Si devuelve `nil` (archivo de estado no existe), retorna sin actualizar. Si hay datos:

- El anillo con la frecuencia (`s.freq`) como valor principal. `set_value` con `raw_range = {0, 100}` normaliza la frecuencia al `[0, 1]` interno del anillo. Esto es un bug latente: la frecuencia típica es de 350-1000 MHz, y el `raw_range` es `{0, 100}`, así que cualquier frecuencia > 100 MHz clampea a `1.0`. El anillo siempre se dibujará lleno si la frecuencia es > 100 MHz. El `text` sí muestra el valor real.
- El spark con `s.render` (uso del motor render, 0-100).
- Los motores con `render`, `blitter`, `video`.
- El KV con `rc6`, `power`, `irqs`.

El `start` llama `refresh_hw`, `refresh`, y registra el timer de 2 s. El `stop` cancela el timer.

**API.**

**Funciones.**

- **`M.new(srv, theme)`** — Devuelve `{ widget, start, stop }`.

**Campos del retorno.**

- `widget` — el `Group` con las dos filas de cards.
- `start` — llama `refresh_hw`, `refresh`, y registra el timer de 2 s.
- `stop` — cancela el timer.

**Patrón.**

Como sub-tab del panel de Recursos. No se monta directamente.

**Anti-patrón.**

- **Asumir que `refresh_hw` muestra información correcta en GPUs distintas a Intel HD Sandy Bridge.** El markup está hardcodeado a "Intel HD Graphics (Sandy Bridge GT1) · 32 nm · 6 EU". En otras GPUs, es falso. Para un tab reutilizable, habría que leer el modelo de `/sys` o `lspci`.
- **Confundir el anillo con una barra de progreso real.** El `raw_range = {0, 100}` normaliza la frecuencia al rango `[0, 100]`, lo que hace que cualquier frecuencia > 100 MHz aparezca como anillo lleno. El anillo está siempre lleno en la práctica. Es un bug conocido que no se ha corregido.
- **Asumir que `D.status()` devuelve datos.** En máquinas sin Intel integrada, o sin el servicio que escribe `/tmp/gpu-status.txt`, devuelve `nil` siempre y el `refresh` retorna sin dibujar. El widget queda con los valores iniciales (`"0"`, `"0"`, etc.).
- **Llamar `refresh` sin que `refresh_hw` se haya llamado antes.** El header queda vacío. El orden en el `start` importa.
- **Depender del color del header para el contraste.** El color del header es `{0.65, 0.65, 0.70}` fijo, no `theme.fg_normal` ni derivado del theme. Es una decisión estética del tab.

**Notas.**

- El `Header` dentro de la card del anillo tiene `min_height = 24`. Con textos largos en `wrap = true`, el alto real puede ser mayor. El `weight = 0` en el `Group` significa que el header recibe su mínimo (24 px), no el real. Si el texto ocupa tres líneas, la tercera se recorta (clip del `Card`).
- El `Motors` tiene `bar_height = 8` y `row_height = 14`. Es compacto para caber en la mitad inferior del panel.
- El `KV` tiene `key_width = 100` y `row_spacing = 5`. Los labels son cortos (`"RC6 reposo"`, `"Consumo"`, `"IRQs"`), caben en 100 px.
- El formato `"%d/s"` para IRQs y `"%.1f%%"` para RC6 y `"%.2f W"` para potencia. Los formatos son del KV, no del sampler.
- El tab no muestra el rango de frecuencias (min/max/boost) en un widget de texto. Solo lo menciona en el header hardcodeado. Si el header se cambia por uno dinámico, el rango debería mostrarse en un KV.

---

#### temps.lua

**Propósito.**
Tab de temperaturas del sistema: anillo con la temperatura máxima de CPU, sparkline de 10 min, y tabla de sensores con núcleos 0 y 1, paquete, placa (x86_pkg_temp), ACPI y disco. Soporta dos modos: normal (tres cards con título) y compacto (una sola card sin título, para embeber en otro tab).

**Alcance.**
Cubre seis sensores: `core0`, `core1`, `pkg` (Core temp), `x86` (x86_pkg_temp), `acpi` (acpitz), `disk` (leído de `/tmp/disk-temp.txt`). No cubre más núcleos. No cubre NVMe ni otros hwmon. No cubre ventiladores.

**Cómo funciona.**

`color_temp(theme, t)` es una función local que elige un color según el valor. Los umbrales: `>= 85` o `>= 75` → `theme.usage_crit`, `>= 60` → `theme.usage_warn`, `>= 40` → `theme.accent`, si no → `theme.telemetry.cpu`. Los dos primeros umbrales (85 y 75) devuelven el mismo color, lo cual es redundante. El comentario del código no lo menciona.

`M.new(srv, theme, opts)` acepta un tercer argumento `opts` con la clave `compact`. Si `compact = true`, el layout es una sola card sin título con el anillo, la spark y la tabla dentro. Si no, son tres cards con títulos.

Los tres widgets comunes:

1. **`Ring`** con la temperatura máxima de CPU. No tiene `raw_range`, así que `set_value(max_cpu / 100, ...)` normaliza la temperatura a `[0, 1]`. Es correcto: la temperatura va de 0 a 100 °C típicamente.
2. **`Spark`** con `samples = 300` (10 minutos a 2 s por muestra), `min = 30`, `max = 100`, `axis_format = "%dC"`, `axis_width = 42`.
3. **`Rows`** con seis filas. Cada fila tiene un grupo (`CPU`, `Placa`, `Disco`) y un nombre (`Core 0`, `Package`, `x86_pkg_temp`, `ACPI (acpitz)`, `ST320LT012`).

En modo `compact`, el layout es un `Group` vertical con `top` (anillo y spark en horizontal) y `sensors` en un solo `Card` con borde. El anillo y la spark comparten el ancho al 50%.

En modo normal, son tres `Card`s: uno para el anillo (título `"Temperatura máxima"`), uno para la spark (`"Historia (10 min)"`), uno para los sensores (`"Sensores"`). El primero y el segundo van arriba en un `Group` horizontal; el tercero va debajo en un `Group` vertical.

`update_row(id, temp)` actualiza el markup de una fila. Si `temp` es `nil`, muestra `"--"` en muted. Si no, muestra `"<valor>°C"` en el color de `color_temp`.

`refresh()` lee:

- `D.read_coretemp(coretemp_path)` → `{ core0, core1, pkg }`.
- `D.read_zones()` → `{ board, x86 }`.
- `D.read_smart(callback)` → llama al callback con la temperatura de disco o `nil`.

Actualiza las seis filas. Calcula la temperatura máxima de CPU entre `core0`, `core1` y `pkg` con un bucle `ipairs` sobre la lista. Actualiza el anillo con `max_cpu / 100` y el texto `"<valor>°C"` o `"0°C"` si todo es `nil`. Actualiza la spark.

El `start` llama `refresh` y registra el timer de 5 s. El `stop` cancela el timer.

**API.**

**Funciones.**

- **`M.new(srv, theme, opts?)`** — `opts.compact` cambia el layout. Devuelve `{ widget, start, stop }`.

**Campos del retorno.**

- `widget` — el `Group` o `Card` según el modo.
- `start` — llama `refresh`, registra timer de 5 s.
- `stop` — cancela el timer.

**Patrón.**

Modo normal (tab dedicado):

    local tab = require("lib.tabs.temps").new(srv, theme)

Modo compacto (embebido en otro tab):

    local tab = require("lib.tabs.temps").new(srv, theme, { compact = true })

Ver `general.lua` para el uso compacto.

**Anti-patrón.**

- **Asumir que `coretemp_path` está disponible.** En CPUs sin coretemp (algunos AMD, máquinas virtuales), `D.find_coretemp()` devuelve `nil`. `D.read_coretemp(nil)` devuelve `{ core0 = nil, core1 = nil, pkg = nil }`. Las tres filas de CPU quedan en `"--"`. Es correcto pero puede confundir si no se sabe que el driver no está.
- **Asumir que las filas de disco tienen temperatura.** El sensor de disco lee `/tmp/disk-temp.txt`, que un servicio externo debe escribir. Sin el servicio, la fila muestra `"--"` siempre.
- **Confundir el modo normal con el compacto.** El widget normal devuelve un `Group` con tres cards; el compacto devuelve un solo `Card`. El consumidor que espere uno u otro puede romperse si cambia el modo sin comprobar el tipo.
- **Asumir que los umbrales de `color_temp` son configurables.** Están hardcodeados. Cambiarlos requiere editar el módulo.
- **Ignorar el hecho de que dos umbrales devuelven el mismo color.** `>= 85` y `>= 75` ambos devuelven `usage_crit`. Los valores entre 75 y 84 se pintan de rojo crítico cuando tal vez deberían ser advertencia. Es un bug menor en la lógica de umbrales.

**Notas.**

- El `Rows` con `group_width = 60` es el mismo widget que usan los tabs de temp del proyecto original. Los grupos (`CPU`, `Placa`, `Disco`) actúan como columnas visuales para agrupar los sensores. Ver `rows.lua` en `README-widgets.md` para más detalle.
- La `Spark` con `samples = 300` y timer de 5 s cubre 25 minutos, no 10 como dice el título del `Card` en modo normal (`"Historia (10 min)"`). Es una inconsistencia entre el título y el `samples`. El comentario del código no lo menciona.
- En modo compacto, el título del `Card` es `nil`. El `Card` sin título reserva solo el padding, sin el bloque de título. El layout ocupa más espacio del disponible.
- La `Rows` con `row_height = 18` y `row_spacing = 6` da 24 px por fila, 144 px para seis filas. Más el padding del `Card` (10 + 10) y el título (si lo hay), la altura total del tab normal es de aproximadamente 400 px. Cabe en un panel 1024×600 con margen.
- `D.read_smart(cb)` es una función síncrona envuelta en callback por compatibilidad con el original. La llamada a `cb` ocurre inmediatamente. El tab no se bloquea.

#### inicio.lua

**Propósito.**
Tab portada del panel. Muestra un avatar circular (foto o inicial), la identidad del usuario (`user@host` más distro), dos cards con información de sistema y sesión, y un reloj con fecha y hora. Es el primer tab del panel de sistema por defecto.

**Alcance.**
Cubre identidad de usuario, distro, kernel, uptime, IP local, número de pantallas, WM, display, terminal, shell, y reloj. No cubre datos dinámicos de recursos (CPU, RAM, etc.): eso vive en los tabs de Recursos. No cubre acciones: es una pantalla de información, no interactiva salvo el avatar si se hace click (que hoy no tiene handler). No cubre wallpaper.

**Cómo funciona.**

El módulo define una clase interna `Avatar`, subclase de `W.Text`, que dibuja un círculo con una foto recortada o una inicial en su lugar. El constructor guarda el tamaño, la inicial, tres colores (`accent_rgb`, `bg_rgb`, `border_rgb`), y carga la superficie de la imagen con `cairo.load_png` si se pasa un path. `Avatar:set_path` permite cambiar la imagen, liberando la superficie anterior con `destroy_surface` antes de cargar la nueva.

`Avatar:draw` pinta primero el anillo exterior con `accent_rgb`. Luego hace un `save`, un `arc` de radio `r - 1` que actúa de clip, y dentro dibuja la imagen o la inicial. Si hay surface, calcula el escalado para que cubra el área completa del círculo (usa `max(target/nw, target/nh)` para que la imagen "cubra" y no "quepa"). Si no hay surface, pinta el `bg_rgb` y dibuja la inicial en `DejaVu Sans Bold 60` con color `#ebdbb2` (beige claro, hardcodeado). Al final `restore`.

El tab `M.new` monta todo el layout. La sección del avatar se centra horizontalmente con un `Group` de tres hijos: dos `Text` vacíos con `weight = 1` a cada lado del avatar con `weight = 0`. Es el patrón de centrado horizontal con pesos, sin necesidad de un widget `Align`.

La identidad es un `Group` vertical con `greet`, `user_host` y `distro`. El `greet` usa `F.greeting()` (que devuelve "Buenos días," según la hora). El `user_host` usa markup para mostrar `user@host` con el `user@host` en `theme.accent` y bold. La `distro` es texto plano en muted.

Las dos cards (Sistema y Sesión) comparten el patrón `kv_row(label, value_widget)`: un `Group` horizontal con el label a la izquierda (weight 1) y el valor a la derecha (weight 0). Cada valor es un `Text` con `DejaVu Sans Mono 10` y alineación derecha, actualizable con `set_text`.

La card de Sistema tiene cuatro filas: `Kernel`, `Uptime`, `Pantallas`, `IP local`. La card de Sesión tiene cuatro filas: `WM`, `Display`, `Terminal`, `Shell`. Los valores de `WM`, `Display` y `Terminal` están hardcodeados (`"Awesome 4.3"`, `"X11"`, `"terminology"`). `Kernel`, `Uptime`, `Pantallas`, `IP` y `Shell` vienen de `lib.data.inicio`.

El reloj es un `Group` vertical con `date_lbl` (fecha completa) y `time_lbl` (hora con formato `HH:MM:SS`). El reloj usa **tres funciones de refresh**:

1. **`refresh_static()`** — se llama una vez en `start`. Puebla el kernel, las pantallas, el WM, el display, la terminal y el shell.
2. **`refresh_clock()`** — corre cada 1 s. Actualiza solo el `time_lbl` con markup de dos colores: `HH:MM` en `theme.fg_normal`, `:SS` en `theme.accent`. El comentario del código aclara: **nada de IO** en este timer.
3. **`refresh_slow()`** — corre cada 30 s. Actualiza uptime, IP local y fecha. El comentario del código explica: `ip route` (que usa `D.ip_local()`) es un `popen`, así que se hace aquí y no en el timer de 1 s.

El `start` llama las tres funciones iniciales y registra los dos timers. El `stop` cancela ambos.

**API.**

**Funciones.**

- **`M.new(srv, theme)`** — Devuelve `{ widget, start, stop }`.

**Campos del retorno.**

- `widget` — el `Group` vertical con avatar, identidad, cards y reloj.
- `start` — llama `refresh_static`, `refresh_slow`, `refresh_clock`, y registra timers de 1 s (reloj) y 30 s (slow).
- `stop` — cancela ambos timers.

**Clase interna `Avatar`.**

- **`Avatar.new(opts)`** — `opts.size`, `opts.initial`, `opts.path`, `opts.accent_rgb`, `opts.bg_rgb`, `opts.border_rgb`.
- **`Avatar:set_path(path)`** — Cambia la imagen.

**Patrón.**

Es un tab standalone: se monta directo en una `Window`.

**Anti-patrón.**

- **Poner `ip_local()` (que usa `popen`) en el timer de 1 s.** El código lo hace bien: la IP local va en `refresh_slow`, que corre cada 30 s. Moverla al timer rápido congelaría el panel cada segundo.
- **Asumir que el avatar está disponible.** `D.find_avatar()` devuelve `nil` en máquinas sin foto de usuario, y el `Avatar` cae al modo inicial. Es correcto pero el consumidor puede sorprenderse si esperaba una foto.
- **Asumir que el avatar PNG está en tamaño cuadrado.** El recorte es circular y usa `max(target/nw, target/nh)` para cubrir. Una foto muy ancha o muy alta se recorta en los bordes para cubrir el círculo. Es el comportamiento esperado, pero el consumidor que prepare una foto debería usar un cuadrado para evitar recortes.
- **Esperar que el `WM` muestre el WM real.** El valor `"Awesome 4.3"` está hardcodeado. Si el usuario cambia de WM, el tab miente. Es un vestigio del proyecto original.
- **Llamar `Avatar:set_path(nil)` para "limpiar".** Destruye la superficie actual y deja el `Avatar` en modo inicial. Es el comportamiento esperado.
- **Confundir los dos formatos de color.** El `Avatar` usa tablas `{r, g, b}` de floats para `accent_rgb`, `bg_rgb`, `border_rgb`. El resto del tab usa tablas o strings hex indistintamente. La mezcla es del proyecto original y no rompe porque cada widget espera su formato.

**Notas.**

- El avatar se centra con el patrón de dos spacers con `weight = 1`. Es un truco habitual: como `Group` no tiene alineación propia, se rodea el widget a centrar con dos celdas que absorben el espacio sobrante.
- El `Avatar:draw` usa `cairo.arc` sin `new_sub_path` explícito antes. El `save` y `restore` aíslan el path en el contexto de Cairo. Es válido porque el clip ya consume el path del `arc`, y el `restore` limpia el estado.
- El `Avatar:set_path` destruye el surface viejo con `cairo.destroy_surface` antes de cargar el nuevo. Es correcto si el surface no está compartido con otros widgets. `cairo.load_png` (no `load_png_cached`) devuelve un surface nuevo por llamada, así que no hay conflicto con el cache global.
- La inicial se pasa como `D.user():sub(1, 1)`, el primer byte del nombre de usuario. Para usuarios con nombres de un solo carácter o con acentos, el resultado puede ser raro. Se sube a mayúscula con `:upper()` en el draw.
- El texto de la inicial se dibuja en `#ebdbb2` (beige) sobre el `bg_rgb`. El contraste funciona en temas oscuros pero puede fallar en temas claros. El color está hardcodeado.
- El reloj tiene tres timers separados por una razón de rendimiento: el de 1 s hace solo trabajo de CPU (formatear y actualizar un string), el de 30 s hace el `popen` de `ip route`. Es un patrón que se repite en varios tabs del toolkit.

---

#### config.lua

**Propósito.**
Tab de Configuración. Cicla entre los temas y paletas disponibles, alterna la animación del panel, ajusta la tasa de refresco de las animaciones, guarda la selección en `conf.lua`, y aplica el cambio recargando la paleta en caliente y reconstruyendo el panel. No incluye wallpapers, atajos ni ajustes del sistema.

**Alcance.**
Cubre ciclado de tema y paleta, toggle de animación del panel, campo de tasa de refresco (Hz), guardado de la selección, recarga en caliente y rebuild del panel vía `theme.rebuild`. No cubre la edición de la paleta en sí: el usuario edita el archivo `.lua` a mano. No cubre la creación de paletas nuevas. No cubre wallpapers (pendiente, ver `notes.md`). No cubre ajustes de atajos ni de comportamiento.

**Cómo funciona.**

`M.new(srv, theme)` empieza con un log de "factory inicio". El estado pendiente se guarda en una tabla local `pending`:

- `theme` — nombre del tema actual, de `D.get("theme")` con fallback `"gruvbox"`.
- `palette` — nombre de la paleta actual, de `D.get("palette")` con fallback `"ayu"`.
- `animate_panel` — booleano, de `D.get_bool("animate_panel", false)`.
- `anim_hz` — entero, de `D.get_int("anim_hz", 30)`.
- `dirty` — booleano que indica si hay cambios sin aplicar.

Se leen las listas de temas y paletas con `D.list_themes()` y `D.list_palettes()`. Los conteos se loguean para diagnóstico.

`update_status` es una función forward-declarada antes de su uso. El ciclador la llama antes de que esté definida, así que el módulo la declara vacía arriba y la asigna más abajo.

`make_cycler(label, getter, setter, list_getter)` es una factoría de cicladores. Cada ciclador es una fila con: título a la izquierda (weight 1), botón `<` (weight 0), valor actual (weight 0), botón `>` (weight 0). Los botones son `Button` planos con `flat = true`. La función interna `cycle(delta)`:

1. Lee la lista con `list_getter()`.
2. Encuentra el índice del valor actual con `getter()`.
3. Aplica el delta y envuelve al rango (`if idx < 1 then idx = #list end` y viceversa).
4. Actualiza el widget del valor con `set_text(new_val)`.
5. Llama a `setter(new_val)` (que muta `pending`).
6. Marca `pending.dirty = true`.
7. Llama a `update_status()` si está disponible.

Se construyen dos cicladores: uno para el tema, otro para la paleta.

`status_label` muestra el estado: `"Cambios pendientes - pulsa Aplicar"` si `dirty`, `"Sin cambios"` si no. `update_status` es una función que lee `pending.dirty` y actualiza el texto. Se llama tras cada ciclo y tras aplicar.

El botón `Aplicar` (`flat = true`, texto verde) tiene un `on_click` que:

1. Guarda `pending.theme`, `pending.palette`, `pending.animate_panel` y `pending.anim_hz` en `conf.lua` con `D.set`, `D.set_bool` y `D.set_int`.
2. Si el motor de animación está listo (`anim.is_ready()`), llama `anim.set_fps(pending.anim_hz)` para aplicar el nuevo Hz en caliente.
3. Carga `lib.theme` y llama `reload_in_place(theme, palette_path)` para mutar la tabla `theme` en su lugar. Si falla, muestra el error en `status_label` y retorna.
4. Si `theme.rebuild` está definido (lo inyecta el consumidor que quiera reconstruir su árbol al cambiar la paleta), actualiza el status y lanza un **timer de 50 ms** que llama `theme.rebuild()` y se cancela a sí mismo. El timer es necesario porque el botón vive dentro del árbol que el rebuild destruye; llamar a `rebuild` directamente desde el callback del botón dejaría al botón con una referencia colgando. El comentario del código lo menciona. Si `rebuild` no está definido, solo se aplica el cambio de paleta en la tabla `theme` y se informa al usuario.
5. Si `theme.rebuild` no existe, muestra `"Paleta recargada (sin panel para reconstruir)."`.

El resto del tab es un `Group` vertical con: los dos cicladores (tema, paleta), una fila con el toggle "Animar panel", una fila con el `TextInput` de Hz, una nota aclaratoria sobre el rango de Hz (1-240), el `status_label` y el botón `Aplicar`. Todo dentro de un `Card` con título `"Apariencia"` y `min_height = 300`. El `Card` se envuelve en un `Group` vertical con padding.

El `start` y `stop` solo loguean y no hacen nada más. El tab no tiene timers.

**API.**

**Funciones.**

- **`M.new(srv, theme)`** — Devuelve `{ widget, start, stop }`.

**Campos del retorno.**

- `widget` — el `Group` con el `Card` de apariencia.
- `start` — loguea.
- `stop` — no-op.

**Patrón.**

Es un tab standalone: se monta directo en una `Window`. Si el consumidor define `theme.rebuild` (una función que reconstruye su árbol), el tab lo llama tras cambiar la paleta. Sin `rebuild`, el cambio se aplica a la tabla `theme` pero los widgets existentes siguen con los colores viejos hasta que se reconstruyan por otra vía.

**Anti-patrón.**

- **Llamar `theme.rebuild()` directamente desde el `on_click`.** El comentario del código lo advierte: el botón vive dentro del árbol que se va a destruir. Llamar `rebuild` en el mismo tick del evento destruiría el árbol mientras el `on_click` está corriendo. El timer de 50 ms es la solución: el callback del botón termina, el event loop respira, y luego el timer dispara el rebuild.
- **Asumir que `theme.rebuild` existe siempre.** Solo está definido si el consumidor lo inyecta. Un consumidor que no lo defina aplica el cambio de paleta a la tabla `theme` pero los widgets existentes siguen con los colores viejos hasta que se reconstruyan por otra vía.
- **Llamar `D.set` sin haber llamado antes `D.get`.** El `write_conf_key` solo sobrescribe claves existentes. Si `conf.lua` no tiene la clave, `set` devuelve `false` sin escribir. El `M.new` hace `D.get` al principio, así que las claves están presentes si el archivo tiene la estructura esperada.
- **Asumir que `list_themes` y `list_palettes` devuelven al menos un elemento.** Si el directorio de temas o paletas está vacío o no existe, las listas están vacías. Los cicladores hacen `if #list == 0 then return end`, así que no fallan, pero los botones no hacen nada visible.
- **Esperar que el cambio de tema tenga efecto.** El tema del proyecto original (`~/.config/awesome/ui/themes`) no se aplica en el toolkit LaneTK: el toolkit solo usa paletas (`~/.config/lanetk/palettes`). El ciclador de temas existe por herencia del proyecto original pero hoy no tiene efecto visible. `notes.md` no lo menciona explícitamente, pero es una limitación conocida.
- **Confundir los dos `D`.** El `D` del config (`lib.data.config`) lee de `conf.lua`. El `D` de cada sampler (`lib.data.<x>`) lee del sistema. Son módulos distintos. En este tab solo se usa el primero.

**Notas.**

- El estado pendiente vive en la clausura de `M.new`. Cada instancia del tab tiene su propio `pending`. Si se reconstruye el panel, se crea una nueva instancia con el estado leído de `conf.lua`, no el de la instancia anterior. Es correcto: el estado que sobrevive es el que se guardó.
- `update_status` está forward-declarada. La convención del código es declarar la variable arriba (`local update_status`) y asignarla después. Es un patrón que `notes.md` documenta como necesario cuando los closures se referencian mutuamente.
- El timer de 50 ms para el rebuild es un valor empírico. Suficientemente largo para que el `on_click` termine y el event loop procese, suficientemente corto para que el usuario no note el retraso. En `examples/` hay otros usos del mismo patrón con valores similares.
- El tab de config no incluye wallpapers aunque `D.has_locker`, `D.has_greeter` y `D.has_wallpaper_conf` estén disponibles en el sampler. `notes.md` documenta wallpapers como pendiente: requiere validar los scripts de locker y greeter.
- Los logs de "factory inicio", "factory OK", "start" son de diagnóstico. Se ven con `LANETK_LOG=info`.
- El fallback de `theme` a `"gruvbox"` y `palette` a `"ayu"` son valores concretos. Si esos archivos no existen en los directorios correspondientes, el ciclador los muestra igual pero el `Aplicar` fallaría al intentar cargar una paleta inexistente. Es una asimetría: los cicladores muestran cualquier nombre sin validar, el `reload_in_place` sí valida.

#### bat.lua

**Propósito.**
Tab de batería. Muestra capacidad, estado, tiempo estimado, potencia, y datos de hardware y salud del pack. Fuentes: `/sys/class/power_supply/BAT*`.

**Alcance.**
Cubre una sola batería. No cubre sistemas con múltiples packs (por ejemplo, una batería interna más una extraíble). No cubre el estado del cargador AC ni el porcentaje de carga del sistema si no hay batería. No cubre acciones (cargar, descargar, calibrar).

**Cómo funciona.**

`fmt_time(hours)` formatea un número de horas a `"Xh YYm"` o `"Ym"` si son menos de una hora. Si `hours` es `nil`, 0 o mayor que 999, devuelve `"-"`. El tope de 999 horas evita mostrar tiempos absurdos cuando el sampler da valores raros.

`M.new(srv, theme)` empieza con `if not D.available()`. Si no hay batería (típico en desktop), devuelve `{ widget = msg }` con un `Text` que dice `"Sin batería detectada"`. El retorno no incluye `start` ni `stop`: el `TabbedPanel` que lo monte no arrancará ni parará nada. Es un caso especial: un tab sin timer y sin estado.

Si hay batería, se construyen cuatro widgets principales:

1. **`Ring`** con la capacidad (`raw_range = {0, 100}`). El color viene de `theme.telemetry.battery` con fallback a `theme.accent`. El `sub` cambia en cada refresco.
2. **`Spark`** con `samples = 60`, rango fijo 0-100, `axis_format = "%d%%"`.
3. **`KV` de hardware** con seis filas: modelo, fabricante, serial, tecnología, voltaje mínimo y voltaje actual.
4. **`KV` de estado** con cuatro filas: status, tiempo, consumo y corriente.
5. **`KV` de salud** con cuatro filas: ciclos, salud, capacidad actual y capacidad de diseño.

El layout tiene dos filas. Arriba: el `Card` del anillo (weight 0, tamaño natural), el `Card` de hardware (weight 1) y el `Card` de estado (weight 1). Abajo: el `Card` de salud (weight 1) y el `Card` del spark (weight 2). La proporción 1:2 en la fila de abajo le da más ancho al spark.

`refresh()` llama a `D.sample()`. Si devuelve `nil`, retorna sin tocar nada (raro pero posible si la batería se quita a mitad de sesión). El `sub` del anillo varía: `"CA"` si está cargando, `"lleno"` si está llena, `"X.XX W"` en cualquier otro estado. El color del anillo:

- `Charging` o `Full` → `theme.accent`.
- `capacity <= 15` → `theme.usage_crit`.
- `capacity <= 35` → `theme.usage_warn`.
- Otro → `theme.telemetry.battery` o `theme.accent`.

Esa prioridad significa que una batería cargando al 10% se pinta de `accent` (cargando) en vez de `usage_crit` (bajo). Es intencional: prioriza el estado "cargando" sobre el nivel.

Los voltajes se formatean con `V. / 1e6` (microvoltios a voltios). La corriente con `mA = current_now / 1000`. La capacidad con `mAh = charge / 1000`. El ciclo se muestra tal cual o `"N/A"` si es `nil`. La salud como `"NN%"` o `"N/A"` si `charge_full_pct` es 0.

El `start` llama `refresh` y registra el timer de 10 s. El `stop` lo cancela.

**API.**

**Funciones.**

- **`M.new(srv, theme)`** — Devuelve `{ widget, start, stop }` si hay batería, o `{ widget }` si no.

**Campos del retorno.**

- `widget` — el `Group` con las dos filas o el `Text` de "sin batería".
- `start` — llama `refresh`, registra timer de 10 s. Ausente si no hay batería.
- `stop` — cancela el timer. Ausente si no hay batería.

**Patrón.**

Como sub-tab del panel principal, o dentro de un agregador.

**Anti-patrón.**

- **Asumir que el retorno tiene `start` y `stop`.** En máquinas sin batería, el tab devuelve solo `{ widget }`. Un consumidor que haga `tab.start()` sin comprobar lanzará error. El `TabbedPanel` protege con `if tab.start then`, pero un consumidor directo no.
- **Confundir `current_now` con corriente en mA.** El sampler devuelve `current_now` en microamperios. La división por 1000 da miliamperios. El código lo hace bien, pero es fácil equivocarse al portar el patrón a otros samplers.
- **Esperar que el color del anillo indique "batería baja" siempre.** La prioridad del estado de carga sobre el nivel significa que una batería al 5% cargando se ve verde. Si se quiere que la baja capacidad domine, invertir la prioridad de los `if`.
- **Llamar `refresh` cada pocos segundos.** La batería no cambia rápido. 10 s es lo que usa el tab, y es más que suficiente.
- **Asumir que `voltage_min_design` está expuesto.** En algunos drivers es 0, y el formateo muestra `"0.00 V"`. El consumidor debe saber que es un dato opcional.

**Notas.**

- El `history` de G.history se crea pero no se usa en este tab. El spark mantiene su propio historial interno. Es un vestigio que no rompe nada pero ocupa memoria.
- El `spark` usa `theme.telemetry.battery or theme.accent` como color. La primera vez se resuelve al construir; si la paleta cambia en caliente, el spark mantiene el color viejo hasta que se reconstruya el tab.
- El color del anillo sí se actualiza en cada `refresh` asignando `ring.color`. Es una diferencia sutil: el anillo se recolorea dinámicamente, el spark no.
- El estado del cargador (`AC` conectado o no) no se muestra. Solo el estado de la batería (`Charging`, `Discharging`, `Full`).
- El tab no tiene card de acciones. El original de Awesome tenía botones para "suspend", "hibernate", etc. Ese tipo de acción vive en el tab de Configuración o en un menú contextual.

---

#### disks.lua

**Propósito.**
Tab de Discos. Muestra las particiones montadas como cards con barra de uso, más dos cards de datos SMART (salud y hardware) leídos de un archivo generado por un servicio externo.

**Alcance.**
Cubre todas las particiones montadas excepto los pseudo-filesystems y `/media`. Cubre un solo disco para SMART: la ruta del disco está hardcodeada a `/dev/sda`. No cubre múltiples discos: si el sistema tiene más de uno, solo el primero se muestra en la card de SMART. No cubre el detalle de atributos SMART individuales: solo los once predefinidos.

**Cómo funciona.**

Tres formateadores locales:

- `fmt_hours(h)` — horas a `"X h  (N días)"` o `"X h  (Y años Z días)"` si pasa de 365 días.
- `fmt_tb(lbas)` — número de LBAs a TB, asumiendo 512 bytes por LBA.
- `fmt_gb(b)` — bytes a GB o MB según magnitud.

`make_part_content(theme)` construye una card de partición. Devuelve un `{ content, update }`. El `content` es un `Group` vertical con: título (label o mount), fila de info (mount + device + filesystem), barra de progreso custom, y dos labels con el porcentaje y el espacio libre.

La **barra de progreso custom** es una clase local `Bar`, subclase de `W.Text`. `Bar:draw` pinta un rectángulo redondeado gris y encima otro con el porcentaje de ancho en verde. El piso de `min(fw, radius * 2)` clampa el radio del relleno para que las barras muy cortas no se vean deformadas. No usa `G.bar` porque necesita controlar el radio del relleno aparte del radio del fondo.

`update(d, theme)` rellena la card con los datos de la partición `d`. El título muestra el label si existe, si no el mount. El título se colorea con `theme.accent_rgb`. Los demás campos vienen del sampler: `mount`, `dev`, `fs_type`, `pct`, `used`, `size`, `avail`.

`M.new(srv, theme)` monta el layout. La card de particiones (`parts_card`) tiene `parts_row` como contenido: un `Group` horizontal vacío que se rellena con las cards de partición. La card de SMART tiene un `KV` con 10 filas. La card de hardware tiene otro `KV` con 8 filas. El layout es: `parts_card` arriba (weight 0), `mid` con smart+hw abajo (weight 1).

`rebuild_parts(list)` vacía `parts_row` y añade una card por partición. Cada card envuelve un `make_part_content` distinto. **CRÍTICO**: al final llama `parts_row:invalidate_layout()`. El comentario del código lo marca como el fix del bug "particiones desaparecen a los 10s": sin el relayout, las cards nuevas quedan con rect `0` y no se dibujan hasta el próximo `ConfigureNotify`. `notes.md` documenta el bug y el fix.

`refresh_parts()` llama `D.partitions()` y pasa el resultado a `rebuild_parts`. Se llama cada 10 s.

`refresh_smart()` lee `D.smart_read()`. Si devuelve `nil`, muestra `"(sin datos)"` en el título del card de SMART. Si hay datos, compone un markup de título con `"Salud SMART  ·  PASSED"` o `"FALLANDO"` según `s.passed`. Los colores vienen de `theme.telemetry.cpu` (verde) o `theme.usage_crit` (rojo). Rellena los dos KV con los datos formateados.

El `start` llama `refresh_parts` y `refresh_smart`, lanza `D.smart_trigger("/dev/sda")` en background, y registra dos timers: uno de 10 s para `refresh_parts`, otro de 60 s que relanza `smart_trigger` y llama `refresh_smart`. El `stop` cancela ambos.

**API.**

**Funciones.**

- **`M.new(srv, theme)`** — Devuelve `{ widget, start, stop }`.

**Campos del retorno.**

- `widget` — el `Group` con la card de particiones y la fila de smart+hw.
- `start` — refresca, lanza `smart_trigger`, registra timers de 10 s y 60 s.
- `stop` — cancela ambos timers.

**Patrón.**

Como sub-tab del panel principal.

**Anti-patrón.**

- **Llamar `rebuild_parts` sin `invalidate_layout`.** Es el bug clásico del toolkit. Las cards nuevas quedan con rect `0` y no se dibujan hasta el próximo resize. El código lo hace bien; un port a otro widget debe replicar el `invalidate_layout`.
- **Asumir que la ruta del disco es `/dev/sda`.** El `smart_trigger` está hardcodeado a esa ruta. En sistemas con `nvme0n1` u otro esquema de nombres, el comando falla silenciosamente y el card de SMART muestra `"(sin datos)"` para siempre.
- **Interpretar `fmt_tb` como capacidad total del disco.** El `fmt_tb` de `lba_written` y `lba_read` es el total escrito/leído desde el arranque, no la capacidad del disco. El `fmt_gb(s.cap_bytes)` es la capacidad.
- **Confundir `sec_logical` con `sec_physical`.** Se muestran juntos como `"N B / M B"`. Un sector lógico de 512 B con uno físico de 4096 B indica un disco Advanced Format que no está alineado. Es un dato interesante para diagnóstico, pero puede confundir a quien no lo conozca.
- **Asumir que `rotation = 0` significa SSD.** Es la convención ATA, pero no todos los SSD lo reportan así y algunos discos híbridos pueden reportar valores distintos. El código lo usa como parte del campo `phys`, no para decidir el tipo de disco.

**Notas.**

- El card de particiones tiene `min_height = 130`. Con muchas particiones, las cards se encogen para caber, y el contenido (barra, labels) puede quedar apretado. Con pocas particiones, queda espacio vacío.
- Los `KV` de SMART y hardware tienen `min_height = 180`. El `weight = 1` en el `Group` les da la mitad del espacio disponible en la fila inferior.
- La barra custom `Bar` usa `G_` (con guion bajo) para el require local de `lib.helpers.graphics`, para no chocar con la variable `G` del módulo que sería `lib.helpers.graphics` también. Es una duplicación de require dentro de la clase.
- El card de SMART cambia su título con `set_title` en cada refresco. Eso re-mide el título con `pango.measure`. Es aceptable: el timer corre cada 60 s, no cada segundo.
- El markup del título de SMART usa `<span foreground="..." weight="bold">` para el estado `PASSED`/`FALLANDO`. Es la única parte del tab con markup complejo.
- `rebuild_parts` con lista vacía añade un `Text` de `"Sin particiones montadas"` y sale. Sin la guarda, el `Group` quedaría vacío y el card sin contenido visible.
- La ruta `/dev/sda` está hardcodeada en el `start` y en el timer de 60 s. Cambiarla requiere editar dos sitios. Un port más genérico usaría el primer disco detectado por `lsblk`.

---

#### launcher.lua

**Propósito.**
Tab launcher: buscador de aplicaciones y comandos. Muestra un `TextInput` arriba, una lista con scroll en el medio, y un pie con atajos. Al escribir, filtra las apps con la puntuación del sampler. Enter ejecuta el resultado seleccionado. Esc cierra la ventana.

**Alcance.**
Cubre búsqueda incremental, navegación por la lista, ejecución de apps y comandos, cierre con Esc, y renderizado de iconos (PNG o SVG). No cubre atajos de teclado para mover el cursor entre resultados (flechas arriba/abajo): el pie menciona `Arriba/Abajo` pero el `TextInput` no implementa navegación de lista. No cubre historial de búsqueda: solo historial de uso de apps. No cubre previews ni descripciones extendidas.

**Cómo funciona.**

`ROW_H = 52` es el alto fijo de cada fila de resultado. Es una constante del módulo.

El estado vive en una tabla local `st` con `query`, `results` y `selected`. La variable `input` está forward-declarada antes de la `ScrollView` porque el `on_click` de la lista la necesita.

**`ScrollView`** — construido con `row_height = ROW_H`, un `on_click` que ejecuta la app y cierra la ventana, y un `draw_row` custom:

- Si la fila es la seleccionada, pinta un fondo `accent` con alpha 0.20 y una barra `accent` de 3 px de ancho a la izquierda.
- Si no, pero hay hover, pinta un fondo `separator` con alpha 0.30.
- Dibuja el icono 32×32 con `cairo.draw_surface`. Si no hay icono, dibuja un cuadrado redondeado con la primera letra del nombre.
- Dibuja el nombre con clip al ancho disponible, coloreado en `accent` si está seleccionado o `fg_normal` si no.
- Dibuja el subtitle (`comment` o `"Ejecutar: <name>"` para comandos) con clip y color muted.
- Un divisor de 1 px al final.

`get_icon_surface(path)` mantiene un cache local (a nivel de clausura, no del módulo). Si la extensión es `svg`, usa `svg.load`; si no, `cairo.load_png_cached`. Los fallos se cachean como `false` para no reintentar.

**`ScrollBar`** — vertical, con `width = 14`, `handle_r = 4`, colores del theme. Se conecta a la lista con `W.ScrollLink.link(list, slider)`. El `ScrollLink` gestiona el flujo bidireccional sin bucles.

**`rows_area`** — un `Group` horizontal con la lista (weight 1) y el slider (weight 0).

**`input`** — un `TextInput` con `min_height = 44`, sin fondo ni borde (`color_bg = nil`, `color_border = nil`). Los tres callbacks:

- `on_change` guarda el texto en `st.query`.
- `on_submit` cierra el foco del input y ejecuta el resultado seleccionado.
- `on_cancel` cierra la ventana.

El campo `input.opts.on_focus_request` se sobreescribe tras construir el widget para que al recibir click el input se autoenfoque con `input:set_focused(true)`.

El `refresh()` tiene cache: si la query no cambió desde el último ciclo, retorna sin hacer trabajo. Si cambió, llama `D.search`, recorre los resultados rellenando `_icon_path` con `D.find_icon(e.icon)` (usando el cache de iconos del sampler), resetea `selected` a 1, `list:set_items` y resetea el offset a 0. El comentario implícito en el código es que el `last_query = nil` inicial fuerza el primer refresh.

El **footer** es un `Text` con markup y un `Group` horizontal con padding de 8. El texto es `"Arriba/Abajo navegar - Enter ejecutar - Esc cerrar"` en muted.

El layout es un `Group` vertical con el input (weight 0), el `rows_area` (weight 1) y el footer (weight 0).

El **retorno** tiene cuatro campos en lugar de los tres habituales:

- `widget` — el layout.
- `focus()` — método que activa el input vía `input.window:set_focus_widget(input)`. Se usa desde el `on_focus_in` del `Window` padre, para que al recibir foco el input quede listo sin necesidad de click.
- `start` — llama `D.scan()`, activa el input con `set_focused(true)`, y registra el timer de 80 ms para `refresh`.
- `stop` — cancela el timer, limpia el cache local de iconos y llama `svg.clear_cache()`.

**API.**

**Funciones.**

- **`M.new(srv, theme)`** — Devuelve `{ widget, focus, start, stop }`.

**Campos del retorno.**

- `widget` — el `Group` con input, lista y footer.
- `focus()` — activa el input programáticamente. Se llama desde el `on_focus_in` del `Window`.
- `start` — escanea apps, activa el input, registra el timer de 80 ms.
- `stop` — cancela el timer, limpia caches.

**Patrón.**

Se monta en una `Window` `kind = "dialog"` con `on_focus_in` que llama `focus()`:

    local launcher_tab = require("lib.tabs.launcher").new(srv, theme)

    local win = Window.new(srv, {
        kind = "dialog",
        width = 640, height = 480,
        x = "cursor-screen", y = "cursor-screen",
        on_focus_in = function()
            launcher_tab.focus()
        end,
    })
    win:set_root(launcher_tab.widget)

Ver `examples/19-launcher.lua`.

**Anti-patrón.**

- **Asumir que `focus` existe en todos los tabs.** Es un método específico del launcher. El `TabbedPanel` no lo conoce ni lo llama. Un consumidor que espere `focus` en otros tabs fallará.
- **Olvidar limpiar el cache de iconos en `stop`.** El cache local y el de `svg` acumulan surfaces. Sin limpieza, abrir y cerrar el launcher varias veces multiplica el uso de memoria. El código lo hace bien.
- **Confiar en que las flechas mueven el cursor entre resultados.** El footer dice "Arriba/Abajo navegar", pero el `TextInput` no implementa esa navegación. Hoy el cursor siempre está en el primer resultado (`selected = 1`). El texto del footer es aspiracional, no una descripción del comportamiento real.
- **Llamar `refresh` sin cambiar la query.** El cache de `last_query` hace que la función retorne sin trabajo. Es una optimización para el timer de 80 ms. Si se necesita forzar un refresco, resetear `last_query` a `nil` (no hay API pública para ello).
- **Asumir que el input recibe foco automáticamente al montar la ventana.** El `set_focused(true)` del `start` se ejecuta cuando el tab se activa, pero el foco X11 real depende del WM. Para ventanas `kind = "dialog"`, el `on_focus_in` es lo que dispara `focus()`, que a su vez hace `set_focus_widget`. Sin ese callback en la ventana, el input no recibe teclado hasta un click.
- **Confundir `_icon_path` (con guion bajo) con un campo del sampler.** Es un campo que el launcher añade a cada entrada de `st.results` para cachear la ruta del icono resuelto. No modifica el sampler. Si el mismo item vuelve a aparecer en otra búsqueda, el `_icon_path` se conserva porque el item es la misma referencia.
- **Ejecutar el resultado seleccionado sin comprobar `st.results[st.selected]`.** Si la lista está vacía, el índice `1` devuelve `nil`. El `on_submit` del input protege con `if e then`. El consumidor que añada su propio handler debe hacer lo mismo.

**Notas.**

- El timer de 80 ms para `refresh` es un compromiso: suficientemente rápido para que la lista se sienta reactiva al teclear, suficientemente lento para no saturar el event loop con llamadas a `D.search`. La cache de `last_query` evita el trabajo real cuando la query no cambió.
- El `draw_row` del launcher es uno de los más complejos del toolkit: hace cinco operaciones de dibujo distintas (highlight, barra lateral, icono, título, subtitle, divisor). Es la razón por la que el launcher tiene `ROW_H = 52` en lugar de los 18-24 típicos de otras listas.
- El icono de reserva (cuadrado con inicial) usa `theme.separator` como fondo y `theme.fg_normal` para la letra. Es coherente con el resto del theme, pero los colores se leen en cada `draw_row`, no se cachean.
- El `svg.clear_cache()` en `stop` afecta a todos los widgets que usen SVG. Si hay otro componente con SVG en uso en el mismo proceso, se verá afectado. En la práctica, el launcher es el único consumidor de `svg.lua` hoy, así que no hay conflicto.
- El `on_click` de la lista ejecuta la app y cierra la ventana con `list.window:close("launcher ejecutado")`. El `on_submit` del input hace lo mismo. Duplicación intencional: el usuario puede ejecutar con Enter o con click, y ambos caminos cierran la ventana.
- El input tiene `min_height = 44`, más alto que el default de `TextInput` (26). Es para que la barra de búsqueda se vea como un campo de entrada prominente, no como un campo pequeño.
- El footer no tiene fondo ni borde. Es solo texto. El `padding = 8` del `Group` que lo envuelve da el margen inferior.
- El launcher asume que `D.find_icon` está cacheado (lo está: el sampler mantiene un índice en disco). La primera llamada con un icono nuevo puede tardar segundos; las siguientes son instantáneas. El `start` llama `D.scan()` que prepara el cache de apps, pero no fuerza la construcción del índice de iconos. La primera búsqueda que use `find_icon` lo disparará.

---

#### proc.lua

**Propósito.**
Tab de Procesos. Lista ordenable de los procesos del sistema, con filtro por nombre, pills de telemetría del sistema arriba, y un menú contextual de acciones (matar, señales, prioridad) al hacer click derecho sobre una fila.

**Alcance.**
Cubre la lista de procesos con `ps`, ordenación por columnas, filtro de nombre, pills de CPU/RAM/GPU/temperatura/batería/red/uptime, y un menú contextual con cinco acciones más dos de renice. No cubre árbol de procesos (parentesco visual). No cubre `pgrep` por otros campos. No cubre vista de hilos. No cubre terminar árboles completos: solo procesos individuales.

**Cómo funciona.**

El módulo define constantes a nivel de archivo: `VISIBLE_ROWS = 14` y `ROW_H = 22`. La lista de columnas `COLS` describe cada columna con `key`, `label`, `width` o `flex`, `align` y `pssort` (el flag correspondiente de `ps --sort`). Hay tres columnas fijas (`pid`, `user`, `pri`), una flex media (`cpu`), una columna `mem` con flex 1, una `time` fija, y una `comm` con flex 3. El `pssort` de cada una mapea al flag de `ps`.

`compute_cols(avail)` es una **función pura**: dado el ancho disponible, devuelve las anchuras de cada columna. Suma las fijas y reparte el espacio libre entre las columnas flexibles proporcionalmente a su `flex`. Si el espacio libre es menor que `MIN_FLEX`, cae a anchos mínimos y deja que el clip recorte. La misma función la usan el header y las filas, garantizando que las columnas coincidan. El comentario del código lo remarca: es lo que evita bugs de desalineación entre header y filas.

`draw_aligned(cr, text, font, color, x, y, w, h, align)` es un helper de dibujo que mide el texto con `pango.measure`, calcula la `tx` según la alineación, y llama a `pango.draw_text`. Simplifica el `draw_row` y el `HeaderRow:draw`.

`read_procs(sort_pssort, sort_dir)` ejecuta `ps -eo pid,ppid,user,pri,pcpu,pmem,rss,time,comm --sort=<flag> --no-headers`. El flag es `-<pssort>` para descendente y `<pssort>` para ascendente. Filtra las líneas de `ps` que sean del propio comando (`ps`, `sh`, `awk`). Convierte `rss` (en KB) a un formato legible (`"NN MB"` o `"N.N GB"`). El campo `mem` combina el porcentaje (`pmem`) y el valor absoluto en un solo string.

La clase `HeaderRow` es un `Area` que dibuja las etiquetas de las columnas con la ordenación activa marcada con `v` o `^`. Tiene `right_reserve = 20` para no pisar el scrollbar (que ocupa 14 px más un margen). `on_mouse_press` recibe las coordenadas locales, recorre las columnas, y si el click cae en una, cambia el estado de ordenación (toggle de dirección si es la misma, o nueva columna descendente por defecto) y llama a `refresh()`.

Los **pills de telemetría** son un `PillRow` con siete entradas: CPU, RAM, GPU, TMP, BAT, NET, UP. Cada uno con un color derivado del theme. `refresh_pills()` los actualiza:

- CPU, RAM, GPU desde sus samplers respectivos. GPU cae a `"off"` si `D_gpu.status()` devuelve `nil`.
- TMP desde `D_temps.find_coretemp()` y `read_coretemp`. Toma el máximo de los tres valores (core0, core1, pkg).
- BAT desde `D_bat`. Si cargando o llena, `"CA"`; si no, el porcentaje. Si no hay batería, `"N/A"`.
- NET desde `net_default_iface()` (con cache de 30 s) y `read_net_speed` (diferencial de bytes desde la última lectura). El formato es `"^<tx> v<rx>"`.
- UP desde `read_uptime`.

La **lista** es un `ScrollView` con `compare = proc_equal`. La función `proc_equal(a, b)` compara todos los campos visibles (`pid`, `user`, `pri`, `cpu`, `mem`, `time`, `comm`). Si dos entradas tienen esos campos iguales, no se dañan. Es la optimización que evita repintar las 14 filas cada 2 s cuando solo cambia el CPU de un proceso. `notes.md` documenta esta decisión.

`list.draw_row` pinta:

- Fondo de selección (accent con alpha 0.20) o hover (separator con alpha 0.35) o fila alterna (separator con alpha 0.12).
- Barra lateral de 3 px si la fila está seleccionada.
- Cada columna con `compute_cols(width)` y `draw_aligned`. El color de la columna varía:
  - `user == "root"` → accent.
  - `cpu > 80` → crit, `cpu > 50` → warn.
  - `mem_pct > 40` → crit, `> 20` → warn.

El **filtro** es un `TextInput` con `on_change` que actualiza `state.filter` y llama `refresh`. `on_submit` desenfoca. `on_cancel` limpia el filtro.

El **count_label** muestra el número de procesos totales y, si hay filtro, cuántos se muestran de cuántos.

El **context menu** se crea con `CM.new(srv, nil, theme)`. El parent se rellena en el `open_context_menu` la primera vez que se abre. Las acciones:

- `Terminar (PID N)` — `kill -TERM`.
- `Forzar cierre` — `kill -KILL`, con color rojo.
- `Pausar` — `kill -STOP`.
- `Continuar` — `kill -CONT`.
- Un separador.
- `Prioridad: bajar (+10)` — `renice +10`.
- `Prioridad: subir (-10)` — `sudo -n renice -10`.

Para abrir el menú, `open_context_menu` lee el puntero global con `xcb.query_pointer`, convierte a coordenadas locales restando `pwin.x` y `pwin.y`, y llama `context_menu:show(lx, ly, items)`. Si el `parent_win` cambió (por ejemplo, tras un rebuild del panel), recrea el `ContextMenu`.

El **layout** tiene tres filas: pills (weight 0), top_bar con count y filtro (weight 0), y `table_card` con header y lista (weight 1). El header va dentro de `table_inner` con la lista.

El **refresh** hace tres cosas: `refresh_pills()`, leer los procesos con el orden actual, aplicar el filtro, y `list:set_items` con el resultado. **NO** resetea el offset: el comentario del código explica que el usuario puede haber scrolleado y no se le debe saltar la vista. Si el offset excede el máximo (porque la lista se acortó), `_recalc_max` de `ScrollView` ya lo clampea.

El `start` llama `refresh` y registra el timer de 2 s. El `stop` cancela el timer y cierra el menú contextual si estaba abierto.

**API.**

**Funciones.**

- **`M.new(srv, theme)`** — Devuelve `{ widget, start, stop }`.

**Campos del retorno.**

- `widget` — el `Group` con pills, barra superior y tabla.
- `start` — llama `refresh`, registra timer de 2 s.
- `stop` — cancela el timer, cierra el `ContextMenu` si estaba abierto.

**Patrón.**

Como sub-tab del panel principal.

**Anti-patrón.**

- **Llamar `refresh` sin `list.window`.** El `ContextMenu` requiere `list.window` para funcionar. En el `start`, `refresh` se llama sin comprobar `window`, pero el `refresh` en sí no usa `window` más allá de los samplers. La comprobación está en `open_context_menu`, que retorna sin abrir el menú si `list.window` es `nil`. Es la protección correcta.
- **Resetear el offset en cada refresco.** El `refresh` llama `list:set_items` sin resetear `offset`. El comentario del código lo remarca como decisión de UX. Un usuario que esté mirando la mitad de la lista no quiere que se le salte al inicio cada 2 s.
- **Asumir que `ps --sort=comm` ordena alfabéticamente.** `ps` ordena por `comm` con el locale actual. Sin `LC_ALL=C`, en algunos sistemas puede ordenar distinto. El código no fuerza el locale. Es una limitación aceptada.
- **Confundir `cpu` con el uso instantáneo.** El campo `pcpu` de `ps` es el **promedio desde el arranque del proceso**, no el uso instantáneo. `notes.md` lo documenta como decisión de diseño: coincide con `ps aux` y `htop`, no con la primera columna de `top`.
- **Asumir que `read_net_speed` da una velocidad real en la primera llamada.** La primera llamada guarda el estado y devuelve `(0, 0)`. El valor real empieza a aparecer en la segunda. Es el patrón de diferencial: sin dos muestras no hay velocidad.
- **Usar `sudo -n renice` sin `sudoers` configurado.** Falla silenciosamente (el `>/dev/null 2>&1` oculta el error). La prioridad no cambia. Es el comportamiento esperado: no se fuerza un prompt interactivo.
- **Asumir que las acciones del menú son instantáneas.** `os.execute` bloquea el event loop. Para `kill` es rápido, pero `renice +10 -p` también. Aceptable dado el uso. En comandos más lentos habría que usar `helpers/async`.

**Notas.**

- La constante `net_iface_cache` con TTL de 30 s es la optimización documentada en `notes.md`: `ip route show default` corría cada 2 s y era caro. La cache lo baja a una vez cada 30 s.
- El `proc_equal` con `compare = proc_equal` en el `ScrollView` es la optimización de daño granular. Sin él, cada refresco de la lista dispararía un full redraw del scrollview. `notes.md` documenta el bug original y el fix.
- El `filter_input` tiene `on_focus_request` sobrescrito para que el click sobre el input lo enfoque. Es el patrón general del toolkit para widgets con foco que no quieren que el click solo ponga el foco sin más.
- El `table_card` tiene `border` y `padding = 6`, pero no tiene `title`. El `border` da el contorno, el `padding` separa el contenido del borde. El `header_wrap` va dentro del card, separado de las filas por `spacing = 0`. La barra de columnas no tiene separador visual con las filas, se distingue por color (bold + colores del theme).
- El `HeaderRow` recibe las coordenadas locales del click, no globales. Esto es porque el `Card` que lo contiene delega `getByXY` al contenido con coordenadas ya traducidas. El `on_mouse_press` compara contra `mx` directamente. Es coherente con el patrón general del toolkit.
- La función `draw_aligned` evita el `save`/`restore` y el clip. Los callers que necesitan clip lo aplican fuera. En el `draw_row`, cada columna se dibuja con `save`+`clip`+`draw_aligned`+`restore` para no salirse de su celda.
- El `menu contextual` se recrea cuando cambia el `parent_win`. Es correcto: cada `Window` child solo puede ser hija de una `Window` padre. Si el panel se reconstruye, el `ContextMenu` original queda huérfano y hay que rehacerlo.
- La ruta `/dev/sda` en el tab de Discos está hardcodeada. Aquí no hay equivalente: el tab de procesos no tiene rutas hardcodeadas.
- El comentario del código sobre `open_context_menu` dice "el menu aparece con la posición del puntero actual". Usa `query_pointer` para obtener la posición. Es la forma correcta de anclar el menú donde está el cursor.

---

#### files.lua

**Propósito.**
File manager mínimo. Lista el contenido de un directorio, permite navegar (entrar a carpetas, volver, subir, ir a home), filtrar por nombre, mostrar/ocultar ocultos, y abrir archivos con `xdg-open`. Vista de lista con cuatro columnas (nombre, tamaño, fecha, tipo) e iconos del tema activo de GTK.

**Alcance.**
Cubre navegación, listado, filtro local, filtro recursivo con `fd`, apertura de archivos con `xdg-open`, y toggle de archivos ocultos. No cubre renombrar, borrar, crear carpeta, copiar/mover, ni papelera. No cubre preview de contenido ni miniaturas. No cubre grid view (solo lista). No cubre selección múltiple ni clipboard de archivos.

**Cómo funciona.**

`M.new(srv, theme, opts)` recibe `opts.initial_path` (default `$HOME`). El tab mantiene un estado interno:

- `cwd` — directorio actual.
- `entries` — lista de items visibles (ya filtrados).
- `history` — array de rutas visitadas.
- `history_idx` — posición en el historial (para back/forward).
- `show_hidden` — booleano.
- `filter` — string del filtro.

`list_dir(path)` ejecuta `ls -la --time-style=+%s <path>` y parsea la salida. El `--time-style=+%s` hace que la fecha venga como timestamp Unix, evitando problemas de locale. Los nombres que terminan en `" -> target"` (symlinks) se limpian. Los items `.` y `..` se excluyen. Los resultados se ordenan: directorios primero, después alfabético case-insensitive.

`apply_filter(entries)` filtra los items por `state.filter`. Si `filter` está vacío, solo aplica el filtro de ocultos (`show_hidden`). Si tiene texto, busca el texto como substring case-insensitive en el nombre.

`list_recursive(pattern)` usa `fd` con `--max-depth 5 --max-results 500 --hidden --ignore-case --type f --type d` para buscar recursivamente en `cwd`. Los paths devueltos por `fd` son relativos a `cwd`; se normalizan a absolutos y después a relativos otra vez para mostrarse en la lista. Para cada resultado, un `stat -c '%s %Y'` extrae tamaño y mtime. `fd` corre con `nice -n 19 ionice -c 3 timeout 5` para no competir con el resto del sistema. El resultado se ordena alfabéticamente.

`refresh()` decide entre local y recursivo según el filtro:
- Si `filter` empieza con `**`, se activa el modo recursivo. El patrón es lo que sigue después de `**` (con espacios recortados).
- Si no, aplica el filtro local sobre `list_dir(cwd)`.

`navigate_to(path, push)` cambia el directorio. Si `push` es true, trunca el historial hacia adelante y agrega la nueva ruta. Si es false (back/forward), solo actualiza el índice. Siempre limpia el filtro y desenfoca el input.

Los botones de navegación son `NavButton`, un widget interno simple que dibuja un icono PNG tintado con el color de `fg` normal (o `accent` en hover). Iconos: `back`, `forward`, `up`, `home`. Vienen de `icons-png/88/files/`.

`list.draw_row` (callback del `ScrollView`) dibuja cada fila:

- Fondo: `bg_focus` con alpha 0.55 si hover, `bg_rgb` normal en el resto. **Siempre pinta el fondo**, con o sin hover (fix de stale pixels, ver Apéndice E 7.5).
- Icono: 22×22, del tema activo vía `icon_theme.resolve(mime_for(item), 22)`. Si el icono específico no existe, cae a `text-x-generic`.
- Nombre, tamaño, fecha, tipo. El nombre se clipea a la columna. Las otras tres usan color `muted`. Los directorios no muestran tamaño (guión `—`).

`mime_for(entry)` mapea la extensión del archivo a un nombre freedesktop de mimetype. Por ejemplo `.lua` → `text-x-script`, `.png` → `image-x-generic`, `.pdf` → `application-pdf`. Los directorios siempre son `folder`. Los archivos sin extensión caen a `text-x-generic`.

`on_key(key)` maneja:

- `Ctrl+H` — toggle `show_hidden`.
- `/` sin input enfocado — enfoca el filtro.
- `BackSpace` — sube al directorio padre.
- `Escape` — si el filtro está enfocado, lo limpia. Si no, retorna `false` y la ventana maneja el cierre.

`start()` inicializa el historial con `cwd` y llama a `refresh()` una vez.

**API.**

**Construcción.**

- **`M.new(srv, theme, opts)`** — devuelve `{ widget, start, stop, on_key }`.
  - `opts.initial_path` — directorio inicial. Default `$HOME`.

**Campos del retorno.**

- `widget` — el `Group` raíz.
- `start()` — inicializa el historial y hace el primer `refresh()`.
- `stop()` — no-op (el tab no tiene timers ni recursos).
- `on_key(key)` — handler de teclado. Retorna `true` si consumió la tecla.

**Patrón.**

File manager abierto en `$HOME`:

    local files = require("lib.tabs.files").new(srv, theme)

File manager abierto en un directorio específico:

    local files = require("lib.tabs.files").new(srv, theme, {
        initial_path = "/home/user/proyectos",
    })

El consumidor es responsable de crear la `Window` y montar el widget. Ver `apps/files.lua` para el uso completo.

**Anti-patrón.**

- **Asumir que `stop()` limpia recursos.** El tab no tiene timers ni conexiones abiertas. `stop()` es un no-op por simetría con la convención `{ widget, start, stop }`.
- **Llamar `start()` dos veces.** Re-inicializaría el historial con el `cwd` actual, perdiendo el historial previo. El `TabbedPanel` garantiza una sola llamada por activación.
- **Ignorar el retorno de `on_key`.** El tab retorna `true` cuando consumió la tecla. Si el consumidor no lo respeta y procesa la tecla igual, `Escape` con filtro activo podría limpiar el filtro Y cerrar la ventana a la vez.
- **Asumir que `list_dir` lee directorios con espacios.** El comando se arma con `string.format("...'%s'...", path)`. Los paths con apóstrofos rompen el comando. Es un caso raro en la práctica pero hay que saberlo.
- **Llamar `refresh()` con `list.window` nulo.** El `refresh` funciona igual (los cambios quedan en estado interno), pero el `list` no se entera hasta el primer `draw`. El `start` corre después de `set_root` en el consumidor típico.

**Notas.**

- El historial funciona como el de un navegador: `back` retrocede, `forward` avanza, navegar a algo nuevo desde el medio del historial trunca el futuro.
- El filtro recursivo (`**`) usa `fd` con `--max-depth 5` y `--max-results 500`. Búsquedas en directorios con árboles muy profundos pueden no mostrar todo. Subir el límite si hace falta.
- Los iconos de archivos vienen del tema activo de GTK (`icon_theme.resolve`). Los iconos de los botones de navegación (`back`, `forward`, `up`, `home`) son propios del toolkit (`icons-png/88/files/`) y no cambian con el tema.
- La fecha se formatea como `YYYY-MM-DD HH:MM`. Los archivos muy viejos o muy nuevos muestran la misma granularidad. No hay opción de mostrar segundos o tiempo relativo.
- Los directorios se ordenan antes que los archivos, siempre. No hay forma de ordenar alfabéticamente mezclando ambos.
- El status bar muestra `N elementos` o `N de M (filtro)` cuando hay filtro activo. No muestra el directorio actual con un label grande (a diferencia del file manager clásico): la ruta está en la barra de navegación superior.

#### screenshot.lua

**Propósito.**
Panel de captura de pantalla con dos tabs: Foto y Video. Cada tab muestra una grid de modos (pantalla completa, cada monitor, área, ventana). El tab Video incluye además una fila para elegir la calidad de grabación con un botón "Avanzado" para personalizar preset de ffmpeg y CRF.

**Alcance.**
Cubre la selección del modo de captura en una grid de `CardButton`. Cubre la persistencia de la última calidad elegida. No cubre la ejecución de la captura en sí: la foto o el video los lanza el `apps/screenshot.lua` (daemon). Este tab es puramente UI. No cubre la vista previa de los resultados (eso es otra ventana del daemon).

**Cómo funciona.**

`M.new(srv, theme, opts)` recibe:

- `opts.on_select(kind, mode, quality, custom_preset, custom_crf)` — callback al elegir un modo. `kind` es `"foto"` o `"video"`. `mode` es una tabla `{ kind = "full" }`, `{ kind = "monitor", mon = {...} }`, `{ kind = "area" }` o `{ kind = "window" }`. `quality` es `"low" | "mid" | "high" | "custom"`.
- `opts.initial_quality`, `opts.initial_preset`, `opts.initial_crf` — estado inicial leído de la config del daemon.
- `opts.on_quality_change(quality, preset, crf)` — callback cuando el usuario cambia la calidad.
- `opts.on_advanced()` — callback cuando el usuario pulsa "Avanzado".

Los modos se construyen en `make_mode_grid(kind)`. La grid es de 3 columnas y N filas:

- Fila 1: `Pantalla` (todos los monitores), `Area`, `Ventana`.
- Filas siguientes: un `CardButton` por monitor, dos por fila.
- Si `kind == "video"`, la última celda de la grid se rellena con `Avanzado`. Si no, queda un spacer invisible.

Los monitores se obtienen de `screens.list()` al construir. Cada uno con título `VGA-1`, `LVDS-1`, etc. y subtítulo `1024 x 768`. Los colores de hover rotan entre una lista de cinco (`azul`, `turquesa`, `violeta`, `naranja`, `ámbar`).

En el tab Video, después de la grid, hay una fila de calidad:

- Etiqueta "Calidad" a la izquierda.
- Cuatro `CardButton` chicos (55×45) para `Baja`, `Media`, `Alta`, `Custom`, con un color de hover distinto cada uno y el actual marcado con `selected = true`.

Un separador visual de 6 px separa la grid de la fila de calidad.

El estado de la calidad vive en una tabla `state` interna (`quality`, `custom_preset`, `custom_crf`). Cuando el usuario cambia la calidad, se actualiza `state`, se llama `opts.on_quality_change` (que el daemon usa para persistir el cambio), y se actualizan los `selected` de los botones.

El tab no ejecuta nada. `on_select` es la señal al daemon de que el usuario eligió un modo. El daemon cierra el panel y actúa.

**API.**

**Construcción.**

- **`M.new(srv, theme, opts)`** — devuelve `{ widget, start, stop }`.
  - `opts.on_select(kind, mode, quality, preset, crf)` — obligatorio. Callback al elegir un modo.
  - `opts.on_quality_change(quality, preset, crf)` — opcional. Callback al cambiar la calidad.
  - `opts.on_advanced()` — opcional. Callback al pulsar "Avanzado" en el tab Video.
  - `opts.initial_quality` — `"low"`, `"mid"`, `"high"` o `"custom"`.
  - `opts.initial_preset` — nombre de preset de ffmpeg (`"ultrafast"`, `"veryfast"`, `"medium"`, `"slow"`).
  - `opts.initial_crf` — número entre 0 y 51.

**Campos del retorno.**

- `widget` — `TabbedPanel` con dos tabs (Foto, Video).
- `start`, `stop` — no-ops.

**Patrón.**

Montar el panel y manejar la selección:

    local screenshot = require("lib.tabs.screenshot").new(srv, theme, {
        on_select = function(kind, mode, quality, preset, crf)
            if kind == "foto" then
                do_photo(mode)
            else
                do_video(mode, quality, preset, crf)
            end
        end,
        on_quality_change = function(quality, preset, crf)
            save_conf { quality = quality, preset = preset, crf = crf }
        end,
        on_advanced = function()
            show_advanced_panel()
        end,
        initial_quality = "mid",
        initial_preset  = "veryfast",
        initial_crf     = 23,
    })

Ver `apps/screenshot.lua` para el flujo completo con el daemon.

**Anti-patrón.**

- **Llamar `on_select` desde el consumidor.** El tab lo llama solo cuando el usuario pulsa un `CardButton`. El consumidor solo recibe el callback.
- **Asumir que `screens.list()` está actualizado.** La lista de monitores se obtiene una vez al construir el tab. Si el usuario conecta/desconecta un monitor mientras el panel está abierto, la lista no se actualiza.
- **Asumir que `state.quality` coincide con la última persistida en el daemon.** El tab mantiene su propio estado. Si algo externo modifica la config, el tab no se entera hasta que se reconstruya. El daemon debería reconstruir el panel tras cambios externos.
- **Renderizar el `widget` sin `TabbedPanel`.** Aunque el tab devuelve el `TabbedPanel` completo, la estructura interna (grid de modos + fila de calidad) asume que el layout externo da un ancho de al menos ~440 px. En un panel más chico, las cards se salen.
- **Esperar que `Custom` haga algo por sí solo.** El botón `Custom` solo cambia `state.quality`. Los campos de preset y CRF viven en el sub-panel "Avanzado", que es otra ventana del daemon. El tab no los edita directamente.

**Notas.**

- Los iconos de los modos (`screen-full`, `monitor`, `area`, `window`) y de calidad (`quality-low`, `quality-mid`, `quality-high`, `quality-custom`) están en `icons-png/88/screenshot/`. Los SVG fuente están en `icons-src/screenshot/`.
- Los iconos de los tabs (`tab-foto`, `tab-video`) también están en `icons-png/32/` porque el `TabsBar` los busca ahí por convención.
- Los colores de hover por modo están hardcodeados a propósito. Los `theme.telemetry` de la paleta ayu no son lo bastante saturados para dar el contraste deseado con el texto negro del hover. La constante `mix_rgb` permite ajustar la intensidad (hoy 0.72, sobre el color hardcodeado como "vivo").
- Los `CardButton` no crecen si el rect que les da el `Group` es mayor. Tienen `min == max` en ambos ejes. La grid queda compacta, sin estirarse.
- El estado de la calidad persiste entre invocaciones del panel porque el daemon lo guarda en `~/.config/lanetk/screenshot.conf` y lo pasa de vuelta en `initial_quality`, `initial_preset` y `initial_crf`.

#### search.lua

**Propósito.**
Tab de búsqueda de archivos. Buscador por nombre con filtros por root (Inicio, DATA, OptiOS, Todas, Sistema), tipo (Todo, Archivos, Carpetas, Imágenes, Audio, Vídeo, Docs), tamaño mínimo/máximo y fecha. Lista ordenable por columnas, con apertura por doble click o click, y copia de ruta al portapapeles con click derecho.

**Alcance.**
Cubre búsqueda asíncrona con `fd` (o `find` como fallback), filtros de root/tipo/tamaño/fecha, ordenación por columnas, apertura con `xdg-open`, copia de ruta con `xclip`. No cubre búsqueda por contenido. No cubre paginación: el límite está fijo en el sampler (`MAX_RESULTS = 500`). No cubre previews ni metadatos extendidos. No cubre historial de búsquedas.

**Cómo funciona.**

El módulo define tres tablas de opciones a nivel de archivo:

- **`ROOTS`** — cinco entradas: Inicio (`$HOME`), DATA (`/mnt/DATA`), OptiOS (`/mnt/OptiOS`), Todas (con `multi` que pasa los tres paths anteriores a `fd`), Sistema (`/` con `max_depth = 6`).
- **`TYPES`** — siete entradas: all, file, dir, image, audio, video, doc. Cada una con `key` que el sampler interpreta.
- **`SIZES`** — siete entradas: cualquiera, `>1KB`, `>10KB`, `>100KB`, `>1MB`, `>10MB`, `<1MB`. Cada una con `min` y/o `max`.
- **`DATES`** — cinco entradas: cualquiera, 24h, Semana, Mes, Año. Cada una con `days` o `nil`.

La definición de columnas (`COL_DEFS`) tiene cinco: `icon`, `name` (flex 4), `path` (flex 6), `size` (fijo 80), `date` (fijo 90). Igual que en `proc.lua`, `compute_cols(avail)` es pura: mismo `avail` → mismo reparto. El header y las filas la llaman con el mismo argumento y garantizan la alineación.

La clase `HeaderRow` es igual que la de `proc.lua` pero toma `get_sort` y `on_sort` como callbacks en `opts`. El header es configurable desde el tab: el tab le pasa el estado de ordenación y la función de cambio. Es más limpio que en `proc.lua`, donde el `HeaderRow` accede directamente a `state`.

`make_cycler(theme, label, get_idx, set_idx, list_ref, on_change)` es una factoría local. Crea una fila con label, botón `<`, valor, botón `>`. Cada ciclador mantiene un índice en el estado del tab y llama a `on_change` al cambiar. Se usa para los cuatro filtros (root, type, size, date). En particular, los cicladores de root y type llaman `trigger_search` al cambiar (porque cambian el comando `fd`); los de size y date solo llaman `apply_filters_and_sort` (porque el filtrado es local, en memoria).

El `ScrollView` de la lista tiene `row_height = 20`, `bg_color = theme.bg_card`. `on_click` ejecuta `xdg-open <path>` en background con `&`. `on_right_click` copia la ruta al portapapeles con `xclip`. Ambos en background.

`list.draw_row` pinta:

- Fondo de hover o fila alterna (par/impar).
- Icono: cuadrado de 8×6 con color `accent` para directorios, `muted` para archivos.
- Nombre con clip a la celda.
- Ruta del padre (`path:match("(.+)/[^/]+$")`) con clip.
- Tamaño alineado a la derecha. Para directorios, `"-"`.
- Fecha formateada con `os.date("%Y-%m-%d", mtime)`. Para directorios, `"-"`.

El **`query_input`** es un `TextInput` con `on_change` que actualiza `st.query` (sin disparar búsqueda: solo Enter o el botón disparan). `on_submit` desenfoca y llama `trigger_search`. `on_cancel` limpia el input.

El **botón `case_btn`** cicla entre case-sensitive e insensitive. Su texto cambia entre `"Aa"` y `"[Aa]"` como indicador visual. Al cambiar, relanza la búsqueda si hay query.

El **`trigger_search`** cancela la búsqueda anterior si sigue activa (`st.search_handle:cancel()`), limpia el estado si la query está vacía, y llama a `D.search(srv, ...)` con los parámetros actuales. El callback del sampler setea `st.raw_items`, llama `apply_filters_and_sort`, `list:set_items` con el resultado filtrado, y `update_status`.

La **`apply_filters_and_sort`** filtra los `raw_items` por tamaño y fecha (los filtros locales), y luego los ordena por la columna activa. Los directorios no se filtran por tamaño (no aplica) pero sí por nombre.

`update_status` muestra el número de resultados. Si la query está vacía, no muestra nada. Si hay filtros aplicados (resultados < total), muestra `"N de M (filtros)"`.

El **layout** tiene cinco filas: barra de query (input, case_btn, botón Buscar), barra de filtros (los cuatro cicladores en un `Group` horizontal con weights iguales), barra de status, header, y lista. El header y la lista van fuera de una `Card`, directamente en el `Group` principal con padding 10.

El `start` es no-op. El `stop` cancela el `search_handle` si sigue activo. No hay timer: la búsqueda se dispara por acción del usuario (submit, click en Buscar, cambio de filtro de root/tipo/case).

**API.**

**Funciones.**

- **`M.new(srv, theme)`** — Devuelve `{ widget, start, stop }`.

**Campos del retorno.**

- `widget` — el `Group` con las cinco filas.
- `start` — no-op.
- `stop` — cancela la búsqueda en curso.

**Patrón.**

Como sub-tab del panel principal.

**Anti-patrón.**

- **Asumir que el tab busca al escribir.** El `on_change` del input solo actualiza `st.query`. La búsqueda se dispara con Enter, con el botón Buscar, o al cambiar root/tipo/case. Es una decisión de UX: en un filesystem grande, buscar en cada tecla sería prohibitivo. El usuario debe pulsar Enter o el botón.
- **Llamar `trigger_search` sin `st.query`.** Si la query está vacía, la función limpia `st.raw_items` y `st.filtered`, y llama `list:set_items({})`. Es el comportamiento correcto: una búsqueda vacía muestra lista vacía, no todos los archivos.
- **Asumir que `SIZES` y `DATES` filtran del lado del servidor.** No lo hacen. El `fd` no soporta filtro por tamaño/mtime. El tab filtra localmente sobre los 500 resultados que devuelve el sampler. Si el archivo que buscas está entre los primeros 500 y no cumple el filtro, no aparece. Es una limitación conocida.
- **Llamar `trigger_search` mientras la búsqueda anterior corre.** El `st.search_handle:cancel()` la cancela. `async_shell` cancela el timer de polling pero el proceso `fd` sigue corriendo hasta terminar. El callback se ignora (no se llama), pero el proceso no. Es la limitación documentada en `helpers/async.lua`.
- **Confundir `st.filtered` con `st.raw_items`.** `raw_items` son los resultados del sampler (500 máx). `filtered` es la aplicación de los filtros locales y la ordenación. La lista muestra `filtered`. El status compara ambos para mostrar `"N de M (filtros)"`.
- **Asumir que el orden por `size` o `date` funciona en directorios.** Los directorios tienen `size = 0` y `mtime = 0` en el sampler. Se ordenan entre ellos como si tuvieran esos valores. El efecto es que los directorios quedan al principio o al final según la dirección. Es el comportamiento correcto del comparador, pero puede sorprender.

**Notas.**

- La función `compute_cols` tiene la misma forma que la de `proc.lua`, pero con constantes propias. Es intencional: cada tab tiene sus columnas y su lógica de reparto. Un helper compartido en `helpers/` sería posible pero acopla los dos tabs.
- El icono es un rectángulo de 8×6 en lugar de un icono de archivo/carpeta. Es una representación mínima: da información visual sin cargar PNGs. El tab no usa `W.Icon`.
- Los `on_click` y `on_right_click` usan `os.execute` con `&` para lanzar en background. `xdg-open` puede tardar y bloquear el event loop. El `&` lo previene.
- El `os.execute` con `printf ... | xclip` es una forma minimalista de copiar al portapapeles. No usa una librería FFI de X11 para el clipboard. `notes.md` documenta el portapapeles como pendiente para otras aplicaciones (Notas, editor de texto).
- El tab no tiene historial de búsquedas. El usuario debe reescribir la query cada vez. Es una limitación aceptada para el MVP.
- `ROOTS` incluye `/mnt/DATA` y `/mnt/OptiOS`, que son rutas específicas del sistema del autor. En otros sistemas no existen y las búsquedas en esas raíces devolverían vacío sin error.

---

#### notes.lua

**Propósito.**
Tab de Notas. Lista de notas con check de completada, título y preview; vista de detalle con el cuerpo de la nota en un `ScrollView`, botones para volver, marcar como hecha, editar (abre `micro` en `terminology`) y eliminar. Cada nota es un archivo `.md` bajo `~/.config/awesome/notes/`.

**Alcance.**
Cubre listar, ver, crear, editar, marcar/desmarcar y borrar notas. La creación pasa por un `password_prompt` que se usa como diálogo de texto (con `mask = false`). La edición abre un editor externo en una terminal externa, sin integración con el toolkit. No cubre edición inline dentro del tab. No cubre exportar ni compartir. No cubre adjuntos ni imágenes.

**Cómo funciona.**

El módulo define una clase interna `ListRow`, subclase de `W.Text`, que dibuja una fila de la lista. Aunque la clase está definida, el tab no la usa directamente: el `draw_row` del `ScrollView` reimplementa la lógica. Es un vestigio: la clase quedó sin uso tras refactorizar el dibujo hacia el callback del `ScrollView`.

`M.new(srv, theme, parent_win)` recibe `parent_win` como tercer argumento. Es necesario para el `password_prompt`, que necesita una ventana padre para crear el diálogo modal de entrada de texto.

El tab crea un `password_prompt` con `require("lib.password_prompt")` (módulo no documentado en `data/`, es de `lib/` directamente). El `prompt:show` se usa con `mask = false` para actuar como campo de texto, no como campo de contraseña.

El **layout** es un `holder` — un `Group` vertical con padding 10 — que se vacía y se repuebla según la vista activa. Dos vistas: lista y detalle.

**`show_list_view()`** limpia el `holder` y construye la vista de lista:

- Un `ScrollView` con `row_height = 44`, `bg_color = theme.bg_card`.
- Un `ScrollBar` vertical conectado con `ScrollLink`.
- `draw_row` custom que dibuja: fondo hover, check (`☑`/`☐`) según `done`, título con color según estado, preview del cuerpo, y un separador inferior.
- `on_click` que llama `show_detail(item.path)`.
- Un botón `"+ Nueva nota"` y otro `"Abrir carpeta"` en una fila de acciones.

`refresh_list()` llama `D.list()` y `list:set_items`. Se llama desde `show_list_view`.

**`show_detail(path)`** lee la nota con `D.read(path)` y construye la vista de detalle:

- Un `ScrollView` con `row_height = 18` y `draw_row` que dibuja cada línea del cuerpo.
- El cuerpo se divide en líneas con `gmatch("(.-)\n")` y se pasa a `set_items`.
- Un `ScrollBar` conectado con `ScrollLink`.
- Cuatro botones: `← Atrás`, `Marcar hecha`/`Marcar pendiente`, `Editar`, `Eliminar`. Los callbacks son respectivamente: volver a la lista, toggle del estado, abrir editor, eliminar y volver.
- Un título con markup que colorea según `done`.

Los botones `Editar` y `Abrir carpeta` usan `os.execute` para lanzar `terminology -e micro <path>` (o `micro <dir>`) en background con `&`. Si `terminology` falla, cae a `x-terminal-emulator`.

`show_list_view` y `show_detail` mutan el `holder` con `clear()`, `add()` y `invalidate_layout()`. Es el patrón general para mutar el árbol sin dejar rects obsoletos.

El `start` es no-op. El `stop` cierra el `password_prompt` si estaba abierto.

**API.**

**Funciones.**

- **`M.new(srv, theme, parent_win)`** — Devuelve `{ widget, start, stop }`.

**Campos del retorno.**

- `widget` — el `Group` holder.
- `start` — no-op.
- `stop` — cierra el prompt.

**Clase interna `ListRow`.**

- **`ListRow.new(item, theme, on_click)`** — No se usa en el código actual. Es un vestigio.

**Patrón.**

Como sub-tab del panel principal, pero con `parent_win`:

    local tab = require("lib.tabs.notes").new(srv, theme, window)

**Anti-patrón.**

- **Asumir que `parent_win` puede ser `nil`.** El `password_prompt` necesita una ventana padre para crear el diálogo. Sin `parent_win`, el prompt falla. El tab depende de que el consumidor le pase la ventana.
- **Usar `ListRow`.** La clase existe pero no se usa. El `draw_row` del `ScrollView` reimplementa la lógica. Confundir la clase con el comportamiento real lleva a errores. Si en el futuro se limpia el código, `ListRow` debería borrarse.
- **Asumir que `holder:clear()` sin `invalidate_layout` deja el árbol consistente.** El `show_list_view` y `show_detail` llaman `invalidate_layout` después de mutar. Sin él, los hijos nuevos quedan con rect `0`. El patrón general de mutación de árbol documentado en `notes.md`.
- **Asumir que la edición es dentro del tab.** `Editar` abre una terminal externa. El tab no edita texto. Para editar sin salir del panel, habría que implementar un editor de texto con `TextInput` multilínea (que el toolkit no tiene).
- **Llamar `D.migrate_legacy` en cada construcción.** `M.new` la llama al principio. La migración es idempotente (renombra el original a `.migrated`), pero se ejecuta en cada construcción del tab. Es barato: `U.read_file` de un archivo que ya no existe y retorno temprano.
- **Asumir que `D.DIR` y `D.LEGACY` existen siempre.** En un sistema sin notas y sin archivo legacy, `D.list()` devuelve tabla vacía y el tab muestra la vista de lista vacía. No hay mensaje de "sin notas": la lista simplemente está vacía.
- **Confundir `parent_win` con el `Window` del tab.** El `parent_win` es la ventana padre para el prompt. El `Window` del tab lo asigna el `Panel` o `TabbedPanel` cuando monta el árbol. Son dos cosas distintas.

**Notas.**

- El módulo `lib.password_prompt` no está documentado en este README. Es un módulo que crea un diálogo modal con un `TextInput`. Se usa aquí como editor de texto de una línea para el título de la nota nueva. `notes.md` lo menciona como bloqueador de la migración de notas originalmente.
- La división del cuerpo en líneas con `gmatch("(.-)\n")` añade un `\n` al final del body antes de hacer match, para que la última línea (que puede no tener `\n`) también se capture. Es el patrón habitual de split por líneas en Lua.
- El `ScrollView` de la vista de detalle tiene `row_height = 18`, mucho más bajo que el de la lista (44). Es coherente: las líneas del cuerpo son de texto plano, no filas con check y preview.
- El título del detalle usa markup para colorear según `done`. Si la nota está hecha, el título va en `theme.muted`; si no, en `theme.fg_normal`.
- Los botones de la vista de detalle tienen `flat = true` para que no tengan fondo en estado normal. Solo se ven al hover. Es el patrón general del toolkit para botones de barra.
- El `Eliminar` tiene `color_text` rojo. Es la única indicación visual de que es una acción destructiva. No hay paso de confirmación: el click borra la nota directamente. Es un caso donde un `ContextMenu` con "Sí / No" tendría sentido, pero no se implementó.
- La apertura del editor (`terminology -e micro <path>`) es específica del entorno del autor. En otros sistemas con otro terminal o editor, habría que cambiar el comando. No hay configuración.

---

## README-helpers.md

### Helpers

Utilidades que no dependen de X11 ni del árbol de widgets. Viven en `src/lib/helpers/`. Se pueden usar desde scripts sueltos con `LUA_PATH` apuntando a `src/`.

#### util.lua

**Propósito.**
Utilidades genéricas: manipulación de strings, lectura y escritura de archivos, ejecución de comandos shell bloqueante, listado de archivos por extensión, y lectura/escritura de claves en archivos Lua planos.

**Alcance.**
Cubre las operaciones básicas que no encajan en otros módulos y que se pueden testear fuera del toolkit. No cubre shell en background (vive en `helpers/async.lua`). No cubre parseo de Lua: `read_conf_key` y `write_conf_key` son match de texto sobre el archivo, no evalúan el chunk. No cubre serialización: `write_file` escribe string cruda.

**Cómo funciona.**

Todas las funciones son puras respecto al estado del toolkit: no consultan ni modifican la tabla `theme`, no requieren conexión XCB, no conocen widgets.

`trim(s)` recorta espacios con dos `gsub`. Si el argumento no es string, devuelve tal cual. Es el único camino rápido y no lanza error.

`read_file` y `write_file` son envoltorios de `io.open`, con `nil` y `false` como fallo respectivamente. `write_file` no crea directorios intermedios: si el path tiene un directorio que no existe, devuelve `false`.

`shell_once` ejecuta un comando con `io.popen(cmd, "r")` y lee la salida completa. `io.popen` bloquea hasta que el comando termina. Para comandos que devuelven en decenas de milisegundos es aceptable; para `dmidecode`, `smartctl` o similares, hay que usar `helpers/async.lua`. `notes.md` documenta esta distinción.

`list_files` ejecuta `ls -1 <dir>` con `io.popen` y filtra por extensión. Devuelve el nombre base sin extensión, excluye `README` explícitamente y ordena alfabéticamente. El escape de comillas en `dir` cubre apóstrofos pero no comillas dobles ni `$`.

`read_conf_key` y `write_conf_key` operan sobre archivos Lua planos con la forma `key = "value"`. `read_conf_key` construye el patrón `key%s*=%s*"([^"]*)"` y devuelve la primera captura, o `nil` si no hay match. `write_conf_key` construye el patrón `(key%s*=%s*")([^"]*)(")` y sustituye con `%1 <value> %3`. Si el patrón no encuentra match, devuelve `false` sin tocar el archivo: si la clave no existe, no se añade. Claves numéricas, booleanas o con comentarios en la misma línea no se detectan.

`home()` devuelve `$HOME` o `/` si no está definido.

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `trim(s)` | string | Recorta espacios al inicio y al final. Devuelve `s` tal cual si no es string. |
| `read_file(path)` | string o `nil` | Contenido completo. `nil` si no se puede abrir. |
| `write_file(path, content)` | `bool` | Sobrescribe. `false` si no se puede abrir. |
| `shell_once(cmd)` | string | Bloquea hasta que el comando termina. `""` si falla. |
| `list_files(dir, ext?)` | tabla de strings | Nombres base sin extensión, excluye `README`, ordenados. `ext` default `"lua"`. |
| `read_conf_key(file, key)` | string o `nil` | Match de texto. No evalúa Lua. |
| `write_conf_key(file, key, value)` | `bool` | `false` si la clave no existe. |
| `home()` | string | `$HOME` o `/` si no está definido. |

**Patrón.**

Lectura y escritura de una clave de configuración:

    local U = require("lib.helpers.util")
    local conf = U.home() .. "/.config/lanetk/conf.lua"

    local current = U.read_conf_key(conf, "palette")
    if current ~= "nord" then
        U.write_conf_key(conf, "palette", "nord")
    end

Listado de paletas disponibles:

    for _, name in ipairs(U.list_files(theme.PALETTE_DIR, "lua")) do
        -- name: "gruvbox-warm", "nord", ...
    end

**Anti-patrón.**

- **Llamar `shell_once` con comandos lentos desde un callback del event loop.** Bloquea el repintado y todos los eventos X. Para `dmidecode`, `smartctl`, `ps` sobre sistemas grandes, usar `helpers/async.lua`. `notes.md` lo documenta como regla.
- **Asumir que `write_conf_key` añade la clave si no existe.** Solo sobrescribe el valor de una clave existente. Añadir una clave nueva requiere editar el archivo a mano o reescribirlo completo.
- **Pasar `dir` con comillas dobles a `list_files`.** El escape solo cubre apóstrofos. Nombres con `"` o `$` no se neutralizan.
- **Asumir que `read_file` devuelve todo el contenido de un archivo binario.** El archivo se lee como texto. Un `\0` en el contenido trunca la lectura a partir de ahí. No es un problema para configuraciones Lua, pero sí para binarios.

**Notas.**

- `shell_once` captura solo `stdout`. El `stderr` va al terminal del proceso llamante. Para capturar ambos, redirigir con `2>&1` en el comando.
- `home()` no cachea el valor de `$HOME`. Cada llamada consulta el entorno. Es trivialmente barato.
- `list_files` ordena con `table.sort`, que compara byte a byte. No usa locale.
- `write_file` no crea directorios intermedios. Si la carpeta no existe, devuelve `false` sin escribir nada.

---

#### format.lua

**Propósito.**
Formateadores de valores numéricos a strings legibles para mostrar en pantalla: tamaños, velocidades, tiempos y fechas. Todos devuelven strings listos para pasar a `pango.draw_text`.

**Alcance.**
Cubre conversión de magnitudes numéricas a strings con unidades, y formateo de fecha y saludo. No cubre formato con separador de miles ni alineación: eso es responsabilidad del widget que dibuja. No cubre localización: los strings están en español, sin opción de cambio de idioma. No cubre parseo inverso (string a número).

**Cómo funciona.**

Todas las funciones son puras. Reciben un número (o nada, en el caso de `date` y `greeting`), devuelven un string. No leen estado del toolkit ni del entorno, salvo `date` y `greeting`, que consultan la hora del sistema con `os.date`.

`mb(kb)` recibe kilobytes (la unidad que devuelve `/proc/meminfo` en Linux). Si el valor es mayor o igual a 1 GB (1024×1024 KB), devuelve el número en GB con un decimal. Si es mayor o igual a 1 MB, devuelve el número en MB sin decimales. Por debajo, devuelve `"0 MB"`. El nombre `mb` es engañoso: la unidad de entrada es KB, no MB. `notes.md` no lo menciona, pero el uso en los tabs lo confirma.

`bytes(b)` recibe bytes y elige la unidad por magnitud: B, KB, MB o GB. El número de decimales varía: entero para B, un decimal para KB y MB, dos decimales para GB. Los GB llevan más decimales porque una décima de GB son cientos de MB.

`speed(bps)` es un envoltorio de `bytes` que añade `"/s"` al final.

`uptime(secs)` devuelve el formato más corto que tenga sentido: `"3d 4h 12m"` si hay días, `"4h 12m"` si hay horas sin días, `"45m"` si solo hay minutos. Los segundos sueltos no se muestran.

`date()` consulta `os.date("*t")` y arma una cadena como `"Domingo, 20 de septiembre de 2026"`. Los nombres de días y meses están en tablas locales del módulo, escritos sin acentos (`"Miercoles"` en vez de `"Miércoles"`) para evitar problemas de codificación en el archivo fuente.

`greeting(hour)` recibe una hora (`0-23`) y devuelve `"Buenos días,"`, `"Buenas tardes,"` o `"Buenas noches,"`. Si no se pasa hora, consulta la hora actual. Los cortes son: mañana de 6 a 12, tarde de 12 a 20, noche de 20 a 6.

**API.**

**Funciones.**

| Función | Retorno | Ejemplo |
|---|---|---|
| `mb(kb)` | string | `1234567` → `"1.2 GB"`. Acepta KB. |
| `bytes(b)` | string | `1536` → `"1.5 KB"`, `1048576` → `"1.0 MB"`. |
| `speed(bps)` | string | `1048576` → `"1.0 MB/s"`. |
| `uptime(secs)` | string | `183845` → `"2d 3h 4m"`. |
| `date()` | string | `"Domingo, 20 de septiembre de 2026"`. |
| `greeting(hour?)` | string | `"Buenas tardes,"`. `hour` default la hora actual. |

**Patrón.**

Formatear valores de telemetría antes de pasarlos a un widget de texto:

    local F = require("lib.helpers.format")
    local D_ram = require("lib.data.ram")

    local sample = D_ram.sample()
    ram_widget:set(F.mb(sample.used) .. " / " .. F.mb(sample.total))

Velocidad de red:

    local down, up = D_net.iface_bytes(iface)
    net_widget:set("↓ " .. F.speed(down) .. "  ↑ " .. F.speed(up))

Ver `examples/13-tab-cpu.lua` y `examples/15-tab-ram.lua`.

**Anti-patrón.**

- **Pasar bytes a `mb` o KB a `bytes`.** Las funciones esperan unidades específicas. `mb` espera KB; `bytes` espera bytes. Confundirlas da el valor correcto por el factor 1024 pero la unidad mal: `mb(1024)` devuelve `"1 MB"` (correcto para KB de entrada) mientras que `bytes(1024)` devuelve `"1.0 KB"` (correcto para bytes de entrada). Un valor de 1024 KB pasado a `bytes` se vería como `"1.0 KB"` cuando realmente son 1 MB.
- **Usar `date()` en un timer de alta frecuencia.** Llama a `os.date`, que internamente consulta el reloj. No es caro, pero no tiene sentido llamarlo varias veces por segundo. El formato cambia como mucho una vez al día.
- **Ignorar los acentos ausentes.** El string devuelto tiene `"Miercoles"` y no `"Miércoles"`. Si el consumidor compara o busca por substring, debe usar los nombres tal cual los devuelve la función.
- **Asumir que `greeting` incluye el nombre del usuario.** Solo devuelve `"Buenos días,"` con la coma. El nombre va aparte.

**Notas.**

- Los valores negativos o `nil` devuelven `"0 B"`, `"0 MB"` o equivalentes. Las funciones no lanzan error por entrada inválida.
- `uptime` con segundos negativos se trata como 0.
- La tabla de días indexa por `wday` de `os.date("*t")`, que va de 1 (domingo) a 7 (sábado). La tabla tiene 7 entradas y usa el índice directamente.
- `greeting` con `hour` fuera de rango cae al caso `else`, devolviendo `"Buenas noches,"`.
- No hay función para formatear porcentajes (`0.42` → `"42%"`). Los consumidores concatenan `math.floor(pct * 100) .. "%"` directamente, o usan `string.format("%d%%", ...)`.

---

#### async.lua

**Propósito.**
Ejecutar un comando shell en background sin bloquear el event loop. Reporta el resultado (código de salida, stdout, stderr) al llamador mediante un callback cuando el comando termina.

**Alcance.**
Cubre ejecución asíncrona de comandos shell con captura de salida y notificación por callback. Cubre cancelación. No cubre comandos con entrada interactiva: el comando corre desatendido. No cubre streaming de salida línea a línea: el callback recibe la salida completa de golpe. No cubre múltiples comandos encadenados: cada llamada es un comando independiente.

**Cómo funciona.**

`async_shell` genera un nombre de archivo temporal único con la forma `/tmp/lanetk-async-<timestamp>-<counter>`. El contador es una variable local al módulo que incrementa en cada llamada. La combinación garantiza unicidad dentro de un mismo proceso.

Escribe tres archivos de trabajo: un script `<base>.sh` con el shebang y el comando, y dos archivos de salida `<base>.out` (stdout) y `<base>.err` (stderr). El script ejecuta el comando redirigiendo `stdout` a `.out`, `stderr` a `.err`, y guarda el código de salida en un cuarto archivo `<base>.done`. Tras guardar el código, el script se borra a sí mismo. Este esquema evita depender de señales o del PID: el llamador solo mira si `.done` existe.

El script se lanza con `os.execute("chmod +x <sh>; <sh> >/dev/null 2>&1 &")`. El `&` al final deja el comando en background; `>/dev/null 2>&1` silencia cualquier salida suelta del script shell en sí.

El llamador registra un timer con `srv:add_timer(150, ...)` que cada 150 ms comprueba si existe el archivo `.done`. Cuando existe, lee el código de salida, el contenido de `.out` y el contenido de `.err`, borra los tres archivos y cancela el timer. Luego llama al callback con `(code, out, err)`. El callback se ejecuta con `pcall`; si lanza, se loguea a `stderr` y se descarta.

El handle devuelto tiene un método `:cancel()` que cancela el timer si sigue activo, borra los archivos temporales y deja el proceso hijo corriendo (no hay forma limpia de matarlo desde Lua sin conocer el PID, que el script no expone).

**API.**

**Funciones.**

- **`async_shell(srv, cmd, cb)`** — Lanza `cmd` en background. Devuelve un handle con `:cancel()`.
  - `srv` — instancia de `Server`, para registrar el timer de polling.
  - `cmd` — string a ejecutar con `sh`.
  - `cb(code, out, err)` — callback al terminar. `code` es el exit code, o `-1` si falla escribir el script.

**Handle devuelto.**

- `:cancel()` — cancela el timer y borra los archivos temporales. No mata el proceso hijo.

**Patrón.**

Ejecución de un comando que tarda (por ejemplo, `smartctl`), con actualización de un widget al terminar:

    local A = require("lib.helpers.async")

    function tab:refresh_smart()
        A.async_shell(self.srv, "smartctl -A /dev/sda", function(code, out, err)
            if code == 0 then
                self.smart_widget:set(parse_smart(out))
            else
                log.warn("smart", "fallo: %s", err)
            end
        end)
    end

Cancelar una operación pendiente al destruir el widget:

    function tab:stop()
        if self.pending then
            self.pending:cancel()
            self.pending = nil
        end
    end

Ver `examples/18-tab-disks.lua` para el uso completo.

**Anti-patrón.**

- **Llamar `async_shell` sin guardar el handle y sin posibilidad de cancelarlo.** El timer sigue hasta que el comando termine. Si el widget que pidió la operación se destruye antes, el callback corre sobre estado liberado y puede fallar. Guardar el handle y cancelarlo en `stop` o en el `on_close` del contenedor.
- **Lanzar `async_shell` en bucle corto.** Cada llamada crea cuatro archivos y un proceso. Con un timer de 1 s y un comando que tarda 3 s, se acumulan procesos corriendo. Para refrescos periódicos, comprobar si hay una operación pendiente antes de lanzar otra.
- **Asumir que el proceso hijo muere con `:cancel()`.** `cancel` solo cancela la comprobación del timer y borra archivos. El comando sigue corriendo hasta que termina por sí mismo. Si el comando es destructivo o largo, hay que esperar a que termine o matarlo por fuera.
- **Usar `async_shell` para comandos instantáneos.** El coste de crear archivos, lanzar `sh`, hacer polling a 150 ms y leer resultados es mucho mayor que un `shell_once`. Para comandos que devuelven en menos de ~100 ms, `helpers/util.shell_once` es más simple y más rápido.
- **Construir `cmd` con interpolación de datos no controlados.** El comando se ejecuta con `sh` sin escape. Un `cmd` que incluya input del usuario es una inyección de shell. Si hay que pasar parámetros, validarlos o usar argumentos separados con un ejecutable wrapper.

**Notas.**

- El polling es de 150 ms. Un comando que tarda 10 ms tarda al menos 150 ms en reportarse al llamador. Aceptable para comandos largos, malo para comandos rápidos.
- Los archivos temporales se crean en `/tmp`. En sistemas con `/tmp` en tmpfs, se borran al reiniciar. En sistemas con `/tmp` persistente, si el proceso muere antes de limpiar, quedan restos. No hay recolección automática.
- El `counter` local no se reinicia. Si el proceso corre durante mucho tiempo y lanza muchos comandos, el sufijo numérico crece sin límite. No es un problema práctico.
- El comando se ejecuta con `sh`, no con `bash`. Los comandos que usen características específicas de bash (arrays, `[[ ]]`, `<( )`) deben invocar bash explícitamente: `bash -c '...'`.
- El callback recibe `out` y `err` como strings completos. Para comandos que producen mucho output, esto carga todo en memoria.

---

#### graphics.lua

**Propósito.**
Primitivas de dibujo Cairo sobre formas y colores: conversión de colores hex a floats, barras con relleno, barras apiladas, anillos de progreso, sparklines y un buffer circular para historiales.

**Alcance.**
Cubre lo que los widgets de telemetría necesitan para dibujar sus gráficos: barras, anillos y sparklines. No cubre texto: vive en `pango.lua`. No cubre iconos ni imágenes: vive en `cairo.lua`. No cubre clipping ni transforms: el consumidor aplica los que necesite. No cubre formas que no sean las cuatro anteriores: rectángulos y paths sueltos se hacen directamente con `cairo`.

**Cómo funciona.**

`hex_to_rgba` normaliza una cadena `#RRGGBB` o `#RGB` a cuatro floats `[0, 1]`. El cuarto valor es el alpha pasado como segundo argumento (default `1.0`). Devuelve cuatro valores sueltos, no una tabla: los consumidores los pasan directamente a `cairo.set_rgba(cr, r, g, b, a)`. La decisión de devolver valores sueltos en vez de una tabla sigue el estilo del proyecto de no alocar tablas en caminos calientes. `notes.md` documenta la confusión típica de envolver el retorno en una tabla.

`set_color` es un atajo que combina `hex_to_rgba` con `cairo.set_rgba`. Es la forma habitual de fijar un color a partir de un string hex dentro de un `draw`.

`bar` dibuja una barra horizontal con relleno proporcional. El fondo se dibuja primero como un rectángulo redondeado con radio `h/2` por defecto, luego el relleno sobre la parte proporcional del ancho. El relleno usa `rounded_rect` con radio clampeado a `fw/2` para que las barras muy cortas no dibujen un radio mayor que su propio ancho. El porcentaje se clampea a `[0, 1]`.

`stacked_bar` dibuja varios segmentos apilados horizontalmente. Primero el fondo redondeado, luego cada segmento como rectángulo simple. Al final, un segundo paso con `cairo.clip` sobre el contorno redondeado vuelve a dibujar los segmentos, para que las esquinas queden limpias sin que los bordes rectangulares se salgan del contorno.

`ring` dibuja un anillo con progreso. El anillo base se dibuja con `cairo_arc` más `stroke`, con `new_sub_path` previo para que el arco no se conecte con paths anteriores. El arco del valor se dibuja de la misma forma sobre el ángulo proporcional al porcentaje. El ángulo de inicio por defecto es `-π/2` (arriba) y el final es `inicio + 2π`.

`sparkline` dibuja una línea con relleno opcional bajo ella. Los datos son un array de números; el rango se calcula automáticamente del mínimo y máximo si no se especifica `min`/`max`. Si todos los valores son iguales, el rango se ensancha artificialmente (`vmax = vmin + 1`) para evitar división por cero. El relleno se dibuja primero, con alpha `0.18` del mismo color que la línea. La línea usa `cairo_set_line_width`.

`history` devuelve un objeto con métodos `:push`, `:get` y `:clear`. Internamente mantiene un array de tamaño fijo. `push` añade al final; si el array está lleno, desplaza todos los elementos una posición hacia la izquierda y descarta el más viejo. El desplazamiento es O(n), pero n es pequeño (decenas de muestras).

**API.**

**Funciones.**

| Función | Retorno | Notas |
|---|---|---|
| `hex_to_rgba(hex, alpha?)` | `r, g, b, a` | Cuatro valores sueltos. `alpha` default `1.0`. |
| `set_color(cr, hex, alpha?)` | — | Atajo de `cairo.set_rgba` sobre `hex_to_rgba`. |
| `bar(cr, x, y, w, h, pct, opts?)` | — | Barra con relleno proporcional. |
| `stacked_bar(cr, x, y, w, h, segments, opts?)` | — | Segmentos apilados con clip redondeado. |
| `ring(cr, cx, cy, radius, pct, opts?)` | — | Anillo de progreso. |
| `sparkline(cr, x, y, w, h, data, opts?)` | — | Línea con relleno opcional. |
| `history(size)` | objeto | Buffer circular. |

Campos de `opts` en `bar`:

- `fg` — color del relleno (hex). Default `"#8ec07c"`.
- `bg` — color del fondo (hex). Default `"#3c3836"`.
- `radius` — radio de las esquinas. Default `h/2`.

Campos de `opts` en `stacked_bar`:

- `bg` — color del fondo (hex). Default `"#3c3836"`.
- `radius` — radio de las esquinas. Default `h/2`.

`segments` es una lista de tablas con `pct` (0..1) y `color` (hex). La suma ideal de `pct` es 1.

Campos de `opts` en `ring`:

- `thickness` — grosor del anillo. Default `4`.
- `fg` — color del arco de progreso. Default `"#8ec07c"`.
- `bg` — color del anillo base. Default `"#3c3836"`.
- `start_angle` — ángulo inicial en radianes. Default `-π/2`.
- `end_angle` — ángulo final. Default `start_angle + 2π`.

Campos de `opts` en `sparkline`:

- `fg` — color de la línea. Default `"#8ec07c"`.
- `fill` — booleano. Default `true`. Si `false`, solo la línea.
- `width` — grosor de la línea. Default `1.5`.
- `min`, `max` — rango fijo. Sin estos, se calcula del array.
- `alpha` — multiplicador de opacidad (0..1). Se aplica al fill
  (base 0.18) y a la línea (base 1.0). Default `1.0`. Usado por
  `Spark`/`DualSpark` para el fade de entrada.
- `reveal` — recorte horizontal (0..1). Recorta el área visible a
  `w * reveal` desde la izquierda. Default `1.0` (sin clip). Usado
  para el efecto "la línea se dibuja de izquierda a derecha".
- `tail` — trazo progresivo del último segmento (0..1). Trunca el
  segmento final a `px(n-1) + dx*tail`. Default `1.0`. Usado para
  dibujar el punto nuevo de izquierda a derecha.
- `scroll` — desplazamiento global (0..1). Desplaza todo el contenido
  `dx * scroll` a la derecha. `scroll = 1` es el estado pre-shift;
  `scroll = 0` el final. Se anima junto con `tail` para que el scroll
  del sparkline sea fluido en lugar de instantáneo.
- `size` — número total de muestras del buffer. Fija `dx = w / (size-1)`
  para que el ancho por muestra no dependa de `#data` durante el
  llenado inicial. Default `#data`.

Métodos del objeto de `history`:

- `:push(v)` — añade una muestra. Si el buffer está lleno, descarta la más vieja.
- `:get()` — devuelve el array interno.
- `:clear()` — vacía el buffer.

**Patrón.**

Anillo de progreso con color según umbral:

    local G = require("lib.helpers.graphics")

    function Widget:draw(cr)
        local color = self.pct > 0.9 and "#fb4934"
                   or self.pct > 0.7 and "#fabd2f"
                   or "#8ec07c"
        G.ring(cr, self.x0 + r, self.y0 + r, r, self.pct, {
            thickness = 6,
            fg = color,
        })
    end

Sparkline con historial:

    self.history = G.history(60)
    -- en cada tick del timer:
    self.history:push(cpu_pct)
    -- en draw:
    G.sparkline(cr, x, y, w, h, self.history:get(), {
        fg = "#83a598",
        fill = true,
    })

Barra simple con color fijo:

    G.bar(cr, x, y, w, 8, ram_pct, {
        fg = theme.telemetry.ram or theme.accent,
        bg = "#282828",
    })

Ver `examples/13-tab-cpu.lua` y `examples/15-tab-ram.lua`.

**Anti-patrón.**

- **Envolver el retorno de `hex_to_rgba` en una tabla.** Devuelve cuatro valores sueltos. La forma correcta es `local r, g, b, a = G.hex_to_rgba(hex)`. Si se necesita una tabla, construirla explícitamente.
- **Llamar `sparkline` con menos de 2 puntos.** El `#data < 2` hace que la función retorne sin dibujar nada. No lanza error, pero tampoco dibuja. Si el widget dibuja un sparkline desde el primer tick, hay que protegerse contra el caso inicial.
- **Pasar porcentajes fuera de `[0, 1]` a `bar`, `stacked_bar` o `ring`.** El rango se clampea silenciosamente. Un `pct = 1.5` dibuja como `1.0`; un `pct = -0.2` dibuja como `0`. No es un error pero puede ocultar bugs en los samplers.
- **Reutilizar el objeto de `history` entre dos widgets.** El array interno es mutable y compartido. Dos widgets que usen el mismo objeto verán los mismos datos. Cada widget que necesite historial crea el suyo.
- **Llamar `history:push` sin dañar el widget.** `history` no genera damage ni repinta. El widget que lo contiene debe llamar a `self:damage()` tras el push si quiere que se vea. Ver `Spark:push` en `widgets/spark.lua`.

**Notas.**

- `bar` y `stacked_bar` con `h = 0` o `w = 0` no dibujan nada útil pero no lanzan error. El clamp del radio a la mitad del menor lado evita el caso degenerado.
- `ring` con `pct = 0` dibuja solo el anillo base. Con `pct = 1` dibuja el círculo completo sobre el base.
- `ring` con ángulos personalizados permite dibujar arcos parciales (por ejemplo, un dial de 270°). El porcentaje se aplica sobre el rango `[start_angle, end_angle]`.
- `sparkline` no redondea los valores del array: si los datos son enteros y el rango es pequeño, la línea será escalonada. Para suavizar, aplicar media móvil antes de pasarla.
- El alpha del relleno del sparkline es fijo (`0.18`). No se puede cambiar por opciones. Si un consumidor necesita otro alpha, hay que dibujar el relleno a mano.
- El buffer circular de `history` no expone la capacidad máxima ni el número actual de muestras. Si un consumidor necesita saber cuántas muestras hay antes del llenado completo, tiene que llevar su propia cuenta.

---

#### init.lua

**Propósito.**
Reexporta `util` y `format` como campos de una tabla para que un consumidor pueda hacer `H.util.trim(...)` sin requerir cada módulo por separado.

**Alcance.**
Reexporta `util` y `format`. No reexporta `graphics` ni `async`: se importan por ruta completa cuando se necesitan.

**Cómo funciona.**

Es un módulo de dos líneas efectivas: crea `M`, asigna `M.util` y `M.format` con `require` de los módulos correspondientes, y lo devuelve. No hay lógica de inicialización ni orden de carga particular.

**API.**

**Campos.**

- `util` — el módulo `lib.helpers.util`.
- `format` — el módulo `lib.helpers.format`.

**Patrón.**

    local H = require("lib.helpers")
    H.util.trim("  x  ")
    H.format.bytes(1024)

**Anti-patrón.**

- **Asumir que `graphics` está en el registry.** No lo está. Importar `lib.helpers.graphics` por ruta completa.
- **Requerir `lib.helpers` cuando solo se necesita un módulo.** Carga los dos (`util` y `format`) y sus dependencias.

**Notas.**

- El módulo es de conveniencia. En el toolkit, la mayoría de los consumidores importan directamente `lib.helpers.util` o `lib.helpers.format` por claridad.
- Si en el futuro se añaden más módulos de helpers (por ejemplo, `poll`, `timer`), se pueden reexportar aquí o dejar fuera según su frecuencia de uso.
