# LaneTK — Referencia de API

Documentación de referencia de los módulos de `src/lib/`. Para el historial de decisiones y bugs, ver `docs/notes.md`. Para ejemplos ejecutables, ver `examples/`.

## Índice

- [0. Convenciones generales](#0-convenciones-generales)
- [1. Núcleo gráfico](#1-núcleo-gráfico)
  - [1.1 xcb.lua](#11-xcblua)
  - [1.2 cairo.lua](#12-cairolua)
  - [1.3 pango.lua](#13-pangolua)
  - [1.4 xkb.lua](#14-xkblua)
  - [1.5 svg.lua](#15-svglua)
- [2. Infraestructura](#2-infraestructura)
- [3. Widgets](#3-widgets)
- [4. Aplicaciones](#4-aplicaciones)
- [5. Barra superior](#5-barra-superior)
- [6. Samplers](#6-samplers)
- [Apéndice A. Anti-patrones](#apéndice-a-anti-patrones)

---

## 0. Convenciones generales

- **Construcción:** las clases se instancian con `Clase.new(opts)`, que devuelve una tabla con metatable `__index`.
- **Métodos:** se invocan con `obj:metodo(args)`.
- **Callbacks:** se pasan en `opts` con prefijo `on_`: `on_click`, `on_hover`, `on_draw`, `on_key`, `on_mouse`, `on_resize`, `on_close`, `on_focus_in`.
- **Logs:** `log.info("modulo", "mensaje %s", valor)`. Niveles: `error`, `warn`, `info`, `debug`, `trace`. Se controla con `LANETK_LOG=info`.
- **Errores:** los constructores usan `error()` para fallos duros. Las funciones de uso normal devuelven `nil, mensaje` para fallos esperables (cargar PNG, abrir SVG).
- **Coordenadas:** enteros en píxeles, origen arriba-izquierda.
- **Colores:** floats `r, g, b` en `[0,1]` para Cairo; strings `#rrggbb` en spec y theme.
- **Puntos de extensión:** registry (constructores), spec (`layout.lua`), theme (paleta).

---

## 1. Núcleo gráfico

Bindings FFI sobre las librerías C. Ningún módulo de esta capa conoce el concepto de "widget".

### 1.1 xcb.lua

Conexión XCB, creación y configuración de ventanas, eventos, propiedades y foco.

**Depende de:** `bindings.cdef.xcb`, `bit`, `libxcb`, `libxcb-util.so.1`. Carga `libxcb-icccm.so.4` de forma lazy.

#### Constantes

| Constante | Contenido |
|---|---|
| `CW` | Bits del `value_mask` de `create_window`. |
| `CONFIG` | Bits del `value_mask` de `configure_window`. |
| `PROP_MODE` | `Replace`, `Prepend`, `Append`. |
| `EVENT_MASK` | Máscara de eventos al crear ventana. |
| `EVENT` | Código numérico por tipo de evento (`KeyPress`, `Expose`, `ClientMessage`, etc.). |
| `WIN_CLASS` | `InputOutput`, `InputOnly`. |
| `ICCCM` | Flags de `WM_NORMAL_HINTS` y `WM_HINTS`. |

#### Conexión

| Función | Retorno | Notas |
|---|---|---|
| `connect(displayname?)` | `conn, screen_num` | Lanza `error` si falla. |
| `disconnect(conn)` | — | Cierra la conexión. |
| `flush(conn)` | — | Fuerza el envío de la cola. |
| `sync(conn)` | — | Round-trip para forzar procesado. |
| `get_file_descriptor(conn)` | `fd` | Para usar con `poll()`. |
| `generate_id(conn)` | `id` | Genera un ID X11. |

#### Pantalla y visual

| Función | Retorno |
|---|---|
| `get_screen(conn, idx?)` | `xcb_screen_t*`. `idx` default 0. |
| `get_visualtype(conn, screen_idx, visual_id)` | `xcb_visualtype_t*`. |

#### Ventanas

| Función | Retorno | Notas |
|---|---|---|
| `create_window(conn, opts)` | `wid, screen` o `nil, screen, err` | Hace `xcb_request_check`. Revisar el tercer retorno. |
| `map_window(conn, wid)` | — | Hace `flush`. |
| `unmap_window(conn, wid)` | — | |
| `destroy_window(conn, wid)` | — | |
| `configure_window(conn, wid, mask, values)` | — | `values` es tabla con `x`, `y`, `width`, `height`, `border`, `sibling`, `stack`. |

Campos de `opts` en `create_window`:

| Campo | Default | Descripción |
|---|---|---|
| `screen` | `0` | Índice de pantalla. |
| `parent` | root de la pantalla | Ventana padre. |
| `x`, `y` | `0`, `0` | Posición. |
| `width`, `height` | `400`, `300` | Tamaño. |
| `border_width` | `0` | Ancho del borde. |
| `depth` | `root_depth` | Profundidad de color. |
| `class` | `InputOutput` | `WIN_CLASS.*`. |
| `visual` | `root_visual` | Visual X11. |
| `background_pixel` | — | uint32. |
| `border_pixel` | — | uint32. |
| `override_redirect` | — | Booleano. |
| `event_mask` | — | OR de `EVENT_MASK.*`. |

#### Átomos y propiedades

| Función | Retorno |
|---|---|
| `intern_atom(conn, name, only_if_exists?)` | `atom`, o `0` si falla. |
| `change_property(conn, win, prop, ptype, format, data_len, data)` | — (siempre en modo `Replace`). |

#### Hints y foco

| Función | Notas |
|---|---|
| `set_wm_normal_hints(conn, win, hints)` | `hints` es tabla con campos opcionales: `x`, `y`, `width`, `height`, `min_width`, `min_height`, `max_width`, `max_height`, `width_inc`, `height_inc`, `min_aspect_num`, `min_aspect_den`, `max_aspect_num`, `max_aspect_den`, `base_width`, `base_height`. |
| `set_wm_hints(conn, win, hints)` | `hints.input` booleano. |
| `set_input_focus(conn, wid, revert_to?)` | `revert_to` default `2` (Parent). |
| `get_input_focus(conn)` | Devuelve el window id con foco, o `0`. |
| `set_input_focus_revert(conn)` | Devuelve el foco a PointerRoot. |
| `query_pointer(conn)` | Devuelve `x, y` raíz, o `nil, nil`. |
| `grab_pointer(conn, window)` | Captura botones y motion. Usado por `ContextMenu`. |
| `ungrab_pointer(conn)` | Libera la captura. |

#### Notas

- `create_window` hace `request_check`. Si el servidor rechaza la petición (por ejemplo, por `value_list` desordenado), devuelve `nil, screen, err` sin lanzar excepción Lua.
- `query_pointer` requiere un window id válido. Se usa el root, nunca `0`.
- El `value_list` de `create_window` va **en el orden de los bits** del `value_mask` del protocolo X11. Si se amplía la función, mantener ese orden.
- `configure_window` construye el array de valores según el orden en que aparezcan los campos de la tabla `values`. El `mask` lo arma el llamador. Ambos deben coincidir con el orden del protocolo.
- `set_input_focus` no hace `sync`. Si se necesita confirmar el cambio, usar `sync`.

#### Anti-patrones

- **No ignorar el tercer retorno de `create_window`.** Un `value_list` desordenado produce `BadValue` silencioso. Ver `notes.md`, entrada "value_list orden de bits".
- **No pasar `0` como window id a `query_pointer`.** Ver `notes.md`, entrada "query_pointer requiere window válido".

---

### 1.2 cairo.lua

Wrapper de Cairo: superficies, atajos de dibujo, formas, imágenes y cache de PNG.

**Depende de:** `bindings.cdef.cairo`, `libcairo.so.2`.

#### Constantes

| Constante | Contenido |
|---|---|
| `OPERATOR` | `CLEAR`, `SOURCE`, `OVER`, `IN`, `OUT`, `ATOP`, `DEST`, `XOR`, `ADD`, `SATURATE`, `MULTIPLY`. |
| `FORMAT` | `ARGB32`, `RGB24`, `A8`, `A1`. |

#### Superficies y contexto

| Función | Retorno | Notas |
|---|---|---|
| `surface_for_window(conn, drawable, visualtype, w, h)` | surface | Lanza `error` si el status es distinto de 0. |
| `image_surface_create(w, h, format?)` | surface | `format` default `ARGB32`. |
| `context(surface)` | `cairo_t*` | Lanza `error` si el status es distinto de 0. |
| `destroy_context(cr)` | — | |
| `destroy_surface(s)` | — | |
| `flush_surface(s)` | — | Fuerza flush tras escribir a mano. |
| `surface_width(s)` | `int` | Ancho en píxeles. |
| `surface_height(s)` | `int` | Alto en píxeles. |

#### Atajos de dibujo

`set_rgb(cr, r, g, b)`, `set_rgba(cr, r, g, b, a)`, `set_line_width(cr, w)`, `paint(cr)`, `rectangle(cr, x, y, w, h)`, `arc(cr, xc, yc, r, a1, a2)`, `move_to(cr, x, y)`, `line_to(cr, x, y)`, `close_path(cr)`, `fill(cr)`, `stroke(cr)`, `save(cr)`, `restore(cr)`, `clip(cr)`, `clip_preserve(cr)`, `new_path(cr)`, `new_sub_path(cr)`, `set_source_surface(cr, surface, x, y)`, `set_operator(cr, op)`, `translate(cr, tx, ty)`.

#### Formas

| Función | Notas |
|---|---|
| `rounded_rect(cr, x, y, w, h, r)` | Rectángulo redondeado. Usa `new_sub_path` internamente. Clampea `r` a la mitad del menor lado. |

#### Imágenes

| Función | Retorno | Notas |
|---|---|---|
| `load_png(path)` | surface o `nil, mensaje` | |
| `load_png_cached(path)` | surface o `nil, mensaje` | Cache global por ruta. |
| `clear_surface_cache()` | — | Libera todos los surfaces cacheados. |
| `write_png(surface, path)` | `bool` | |
| `draw_surface(cr, s, x, y, w?, h?)` | — | Si `w`/`h` son `nil`, usa el tamaño nativo. Escala con filtro GOOD. |
| `draw_surface_tinted(cr, s, x, y, w, h, r, g, b)` | — | Tintado con color sólido. Preserva el alpha del source. Para iconos monocromo. |

#### Notas

- `arc` **no resetea el path**. Antes de un arco suelto, hacer `new_path()`. Tras el arco, `close_path()` más `fill()` o `stroke()`. `rounded_rect` ya lo maneja.
- `draw_surface_tinted` construye un surface temporal ARGB32 transparente y aplica el color con `IN`. Sin ese surface, el tintado pinta el área completa del icono en lugar de solo la silueta.
- `load_png_cached` cachea para siempre. Si se recargan iconos en caliente (por ejemplo, cambio de tema), llamar a `clear_surface_cache()`.
- `draw_surface` con `w`/`h` distintos del nativo escala en cada frame. Para iconos fijos, cachear o dejar tamaño nativo.

#### Anti-patrones

- **No llamar `arc` sin `new_path` antes y después.** El path anterior se arrastra y los arcos se cierran mal. Ver `notes.md`, entrada "cairo_arc no resetea path".
- **No usar `draw_surface_tinted` para iconos en color.** Usa `IN` y colapsa a un solo color.

---

### 1.3 pango.lua

Dibujo y medición de texto con Pango + Cairo, y traducción de entidades HTML a Unicode.

**Depende de:** `bindings.cdef.pango`, `libpango-1.0.so.0`, `libpangocairo-1.0.so.0`, `libgobject-2.0.so.0`, `libcairo.so.2`, `libfontconfig.so.1`. Llama `FcInit()` al cargar.

#### Constantes

| Constante | Contenido |
|---|---|
| `ALIGN` | `LEFT`, `CENTER`, `RIGHT`. |
| `WRAP` | `WORD`, `CHAR`, `WORD_CHAR`. |

#### Funciones

| Función | Retorno | Notas |
|---|---|---|
| `measure(text, font?)` | `w, h` | Crea layout y surface temporal 1×1. |
| `draw_text(cr, x, y, text, font?, opts?)` | — | Texto plano. |
| `draw_markup(cr, x, y, markup, font?, opts?)` | — | Markup Pango. |
| `html_entities(s)` | string | Traduce entidades HTML con nombre a Unicode. Deja las XML básicas (`amp`, `lt`, `gt`, `quot`, `apos`) para Pango. |
| `escape(s)` | string | Escapa `&`, `<`, `>` para markup. |

`opts` de `draw_text` y `draw_markup`:

| Campo | Tipo | Descripción |
|---|---|---|
| `r`, `g`, `b` | float | Color. |
| `wrap_width` | int | Ancho de wrap en píxeles. |
| `wrap` | `WRAP.*` | Modo de wrap. |
| `align` | `ALIGN.*` | Alineación. |

#### Notas

- `measure` crea layout y surface temporal cada vez. No llamar en bucles por frame. Cachear medidas.
- `draw_text` y `draw_markup` crean un layout por llamada. Igual: cachear si el texto se repite.
- `draw_markup` pasa la cadena por `html_entities` antes de Pango. Si el usuario puede inyectar texto, escapar con `escape` primero.
- El peso del texto se controla desde el string `font` (`"Cantarell 10"`, `"monospace bold 9"`). No hay API dedicada.

#### Anti-patrones

- **No llamar `measure` dentro de `on_draw`.** Se paga cada frame. Medir al construir el widget o al cambiar texto.
- **No pasar texto del usuario a `draw_markup` sin `escape`.** `<`, `&` y `>` rompen el layout o se interpretan como etiquetas.

---

### 1.4 xkb.lua

Traducción de keycodes X11 a keysym, nombre, texto UTF-8 y modificadores, vía xkbcommon.

**Depende de:** `bindings.cdef.xkb`, `libxkbcommon.so.0`.

#### Constantes

| Constante | Contenido |
|---|---|
| `KEY_UP`, `KEY_DOWN` | Dirección para `update_key`. |
| `X11_MOD` | Máscaras X11: `SHIFT`, `LOCK`, `CTRL`, `MOD1` hasta `MOD5`. |
| `SYM` | Keysyms comunes para binds por nombre. |

#### Funciones

| Función | Retorno | Notas |
|---|---|---|
| `new_state(names?)` | `State` | `names` puede ser `nil` (usa env vars `XKB_DEFAULT_*` o defaults) o tabla `{ rules, model, layout, variant, options }`. |
| `from_name(name)` | keysym numérico | |

#### Métodos de `State`

| Método | Retorno | Notas |
|---|---|---|
| `update_key(keycode, direction)` | — | `direction` es `KEY_DOWN` o `KEY_UP`. |
| `key_sym(keycode)` | keysym numérico | `0` si no mapeado. |
| `key_name(keycode)` | string | `"Return"`, `"F1"`, `"a"`, etc. |
| `key_utf8(keycode)` | string UTF-8 | `""` si la tecla no produce texto. |
| `decode_mods(x11_state)` | tabla | `{ shift, lock, ctrl, alt, num, mod3, super, mod5 }`. |
| `make_event(keycode, x11_state, pressed)` | tabla | `{ keycode, sym, name, text, mods, raw_mods, pressed }`. Actualiza el estado interno antes de leer. |
| `destroy()` | — | Libera estado, keymap y contexto. |

#### Notas

- `make_event` llama a `update_key` internamente. Si se lee `key_utf8` sin pasar por `make_event`, primero hay que llamar a `update_key` para que Shift más `a` produzca `"A"`.
- Desde X solo llega `keycode`. El layout se resuelve vía xkbcommon.
- `mods` es un subconjunto amigable (`alt`, `super`, `ctrl`, `shift`). El estado X11 crudo queda en `raw_mods`.

#### Anti-patrones

- **No leer `key_utf8` sin haber llamado antes a `make_event` o `update_key`.** El estado interno queda desincronizado y Shift no funciona. Ver `notes.md`.

---

### 1.5 svg.lua

Renderiza SVG a un `cairo_image_surface` vía librsvg. Carga lazy de la librería y cache de surfaces.

**Depende de:** `bindings.cdef.svg`, `lib.cairo`, `lib.log`. Carga lazy `librsvg-2.so.2` y `libgobject-2.0.so.0`.

#### Funciones

| Función | Retorno | Notas |
|---|---|---|
| `load(path)` | surface o `nil` | Cachea por ruta. Renderiza a 64×64 fijo. |
| `invalidate(path)` | — | Invalida una entrada del cache. |
| `clear_cache()` | — | Libera todos los surfaces cacheados. |

#### Notas

- El tamaño natural del SVG no se lee. Se renderiza a 64×64 y se escala al blitear con `cairo.draw_surface`.
- El cache es por ruta. Cambiar el archivo en disco no invalida el surface en memoria.
- La librería no se descarga una vez cargada. `clear_cache` libera los bitmaps pero mantiene la `.so`.
- En este proyecto los iconos se pre-convierten a PNG con `tools/convert-icons.sh`. `svg.lua` queda para SVG en runtime.

#### Anti-patrones

- **No llamar `load` en cada frame.** Cada llamada fallida genera `log.warn` y reintenta leer del disco. Usar `invalidate` cuando se sepa que el archivo cambió.
- **No asumir que el SVG respeta su tamaño natural.** Siempre se renderiza a 64×64.

---

## 2. Infraestructura

_(pendiente)_

## 2. Infraestructura

Servicios que usan los widgets y las aplicaciones: logging, paleta, event loop, ventana, monitores y utilidades varias.

### 2.1 log.lua

Logging con niveles, escrito a `stderr`.

**Depende de:** nada.

#### Constantes

| Constante | Contenido |
|---|---|
| `EVENT_NAMES` | Tabla `código de evento X11 -> nombre`, usada por `event_name`. |

#### Funciones

| Función | Notas |
|---|---|
| `error(prefix, fmt, ...)` | Nivel 1. |
| `warn(prefix, fmt, ...)` | Nivel 2. Es el nivel default. |
| `info(prefix, fmt, ...)` | Nivel 3. |
| `debug(prefix, fmt, ...)` | Nivel 4. |
| `trace(prefix, fmt, ...)` | Nivel 5. |
| `event_name(etype)` | Nombre del tipo de evento X11 (numérico), o `"unknown(N)"`. |

Nivel activo: leído de la variable de entorno `LANETK_LOG`. Valores: `error`, `warn`, `info`, `debug`, `trace`. Default `warn`. Se relee en cada emisión, no en el arranque.

#### Notas

- Los mensajes van a `stderr`, con formato `[HH:MM:SS LEVEL prefix] mensaje`. No hay API para cambiar el destino.
- `LANETK_LOG=info` no muestra `log.debug`, y `LANETK_LOG=debug` no muestra `log.trace`.

#### Anti-patrones

- **No asumir que `LANETK_LOG=info` muestra los `debug`.** Ajustar el valor de la variable al nivel que se quiere ver. Ver `notes.md`.

---

### 2.2 theme.lua

Carga una paleta de `palettes/` y la expone como la tabla `theme` que consumen widgets y tabs.

**Depende de:** `lib.helpers.graphics` (para `hex_to_rgba`).

#### Constantes

| Constante | Contenido |
|---|---|
| `PALETTE_DIR` | Ruta absoluta al directorio `palettes/`. Se localiza subiendo desde la ubicación del archivo hasta encontrar una carpeta `palettes/`. |
| `CONFIG_FILE` | `$HOME/.config/lanetk/palette`. Archivo de una sola línea con el nombre de la paleta. |

#### Funciones

| Función | Retorno | Notas |
|---|---|---|
| `find_palette_path()` | ruta absoluta | Orden: `LANETK_PALETTE` (ruta absoluta o nombre), `CONFIG_FILE`, `gruvbox-warm.lua`. Lanza `error` si no encuentra nada. |
| `list_palettes()` | tabla de strings | Nombres sin `.lua`, ordenados. |
| `load(palette_path?)` | tabla `theme` | Si no se pasa ruta, usa `find_palette_path()`. Lanza `error` si la paleta no tiene `colors` y `semantic`. |
| `palette_path(name)` | ruta absoluta | Concatenación directa, no comprueba existencia. |
| `reload_in_place(T, palette_path?)` | `true` o `false, msg` | Muta `T` en su lugar. Quien tenga referencia a `T` ve los cambios. |

#### Campos de la tabla `theme`

- `path` — ruta de la paleta cargada.
- `bg`, `bg_card`, `bg_focus`, `fg_normal`, `fg_on_color`, `accent`, `urgent` — strings `#rrggbb`.
- `muted`, `ghost`, `separator`, `usage_warn`, `usage_crit` — strings `#rrggbb` de la sección `semantic`.
- `telemetry` — tabla libre (viene de la paleta), colores por clave de widget de barra.
- `bg_rgb`, `bg_card_rgb`, `bg_focus_rgb`, `separator_rgb`, `accent_rgb`, `urgent_rgb`, `fg_rgb`, `muted_rgb` — tablas `{r, g, b}` con floats listos para `cairo.set_rgb`.

#### Notas

- `find_palette_path` usa `io.popen("test -d ...")`; no usa FFI para no depender de `<sys/stat.h>`.
- Los campos `*_rgb` son tablas `{r, g, b}`, no floats sueltos. Para usar con Cairo hay que indexar, o usar `G.set_color(cr, t.accent)`.
- `reload_in_place` no reenvía la nueva paleta a los widgets: solo actualiza la tabla `theme`. Los widgets que capturaron colores en construcción siguen con los viejos hasta que se reconstruyan (ver `PanelApp:rebuild`).

#### Anti-patrones

- **No llamar `find_palette_path()` en bucle.** Escanea el disco con `test -d` varias veces. Llamar una vez y guardar el resultado.
- **No asumir que `reload_in_place` repinta la UI.** Es una mutación del estado: hay que disparar un rebuild del árbol que consuma los colores.

---

### 2.3 server.lua

Conexión XCB con event loop basado en `poll()`, timers y trigger file. Enruta eventos a las ventanas registradas.

**Depende de:** `ffi`, `bit`, `lib.xcb`, `lib.log`, `lib.poll`, `lib.timer`.

#### Construcción

- **`Server.new(opts)`** — Abre conexión XCB, obtiene pantalla y visual, interna átomos y prepara la tabla de ventanas.
  - `opts.displayname` — nombre del display (opcional).
  - `opts.exit_on_empty` — default `true`. Si no hay ventanas registradas, el loop termina.

#### Campos públicos

- `conn` — conexión XCB.
- `screen_num`, `screen`, `visualtype` — pantalla y visual del server.
- `atoms` — tabla de átomos internados (`WM_PROTOCOLS`, `_NET_WM_NAME`, `UTF8_STRING`, etc.).
- `fd` — file descriptor del socket XCB, usado por `poll`.
- `windows` — tabla `id -> Window`.
- `timers` — conjunto de handles activos.
- `running` — booleano.
- `exit_on_empty` — booleano.

#### Métodos

| Método | Retorno | Notas |
|---|---|---|
| `add_window(win)` | — | Registra una ventana por `id`. |
| `remove_window(win)` | — | Desregistra. |
| `count()` | `int` | Cuenta ventanas registradas. |
| `stop()` | — | Pone `running=false`. El loop termina al final del ciclo. |
| `flush()` | — | `xcb.flush`. |
| `add_timer(interval_ms, callback)` | handle con `:cancel()` | Timers únicos, no repetidos por ciclo. Se reprograman al ejecutarse. |
| `watch_trigger(path, callback)` | — | Observa el archivo `path`. Al aparecer, lo lee, lo borra, y llama a `callback(contenido)` (`"toggle"` si está vacío). |
| `cancel_all_timers()` | — | Vacía la tabla de timers. |
| `run()` | — | Ejecuta el loop. Captura `SIGINT` (`interrupted!`) y limpia. |

#### Notas

- Antes de bloquearse en `poll()`, el loop **vacía el buffer interno de XCB** con `xcb.poll_event`. Necesario porque `xcb.sync` (llamado por `map_window` y otras operaciones síncronas) puede haber leído eventos del socket y guardado en el buffer interno, donde `poll(fd)` no los ve.
- Los callbacks de timer corren con `pcall`. Si lanzan, se loguea y el loop sigue.
- `exit_on_empty` (`true` por defecto) hace que el server termine cuando no hay ventanas. Adecuado para apps de una sola ventana; para daemons, pasar `exit_on_empty=false`.
- `watch_trigger` revisa cada 200 ms. Si no hay timers ni trigger, `poll` bloquea indefinidamente.

#### Anti-patrones

- **No bloquear el loop dentro de un callback.** `Server:_loop` es single-thread: un callback de timer o de trigger que tarde bloquea el repintado y los eventos X.
- **No registrar timers de intervalo corto (menos de ~50 ms) si son varios.** El `poll` se reprograma con el más cercano, pero con muchos timers cortos el loop no descansa.

---

### 2.4 window.lua

Ventana X11 con backing store, damage tracking, dispatch de eventos a un árbol de widgets y foco de teclado.

**Depende de:** `ffi`, `bit`, `lib.xcb`, `lib.cairo`, `lib.server`, `lib.log`, `lib.xkb`, `lib.screens` (lazy, solo si `x`/`y` usan `cursor-screen`).

#### Construcción

- **`Window.new(opts)`** — Crea un `Server` propio.
- **`Window.new(server, opts)`** — Usa el `Server` dado.

Campos de `opts`:

| Campo | Default | Descripción |
|---|---|---|
| `width`, `height` | `400`, `300` | Especificadores de tamaño. |
| `x`, `y` | `0`, `0` | Especificadores de posición. |
| `kind` | `"normal"` | `normal`, `dock`, `dialog`, `menu`, `child`, `transient`. |
| `parent_window` | — | Requerido para `kind` `child` y `transient`. |
| `title` | — | Establece `_NET_WM_NAME` y `WM_NAME`. |
| `app_name`, `class_name` | `"LaneTK"`, `"LaneTK"` | Para `WM_CLASS`. |
| `aspect` | — | Flotante ancho/alto. Fija el `WM_NORMAL_HINTS` de aspecto. |
| `min_width`, `min_height` | `0` | Especificadores de bound. |
| `max_width`, `max_height` | `0` | Especificadores de bound. |
| `strut` | — | Tabla con `left`, `right`, `top`, `bottom` y los `*_start_*`/`*_end_*` opcionales. Publica `_NET_WM_STRUT` y `_NET_WM_STRUT_PARTIAL`. |
| `event_mask` | máscara estándar | Ver fuente para los bits. |
| `disable_q_close` | `false` | Si es `true`, la tecla `q` no cierra la ventana. |
| `on_draw` | — | `function(cr, w, h)`. Se llama antes del árbol. |
| `on_key` | — | `function(key)`. Recibe la tabla de `xkb:make_event`. |
| `on_mouse` | — | `function(x, y, detail, state)`. Solo si el árbol no consumió el click. |
| `on_mouse_move` | — | `function(x, y)`. |
| `on_mouse_release` | — | `function(x, y, detail, state)`. |
| `on_resize` | — | `function(w, h)`. |
| `on_close` | — | `function()`. Se llama antes de destruir. |
| `on_focus_in`, `on_focus_out` | — | `function()`. |
| `on_measure` | — | `function()` que devuelve `w, h` cuando `width`/`height` son `"auto"`. |

Especificadores de tamaño (`width`, `height`):

- número — píxeles.
- `"screen"` — dimensión completa de la pantalla.
- `"auto"` — llama a `opts.on_measure()` para obtener el valor.
- `"free"` — 0 (el WM decide).
- `"N%"` — porcentaje de la dimensión de la pantalla.

Especificadores de posición (`x`, `y`):

- número — píxeles.
- `"center"` — centrado en la pantalla.
- `"cursor-screen"` — centrado en el monitor donde está el cursor. Requiere `lib.screens`.

Especificadores de bound (`min_*`, `max_*`):

- número, `"screen"` (dimensión de la pantalla), `"free"` (0).

#### Campos públicos

- `id` — window id X11.
- `width`, `height`, `x`, `y` — geometría actual.
- `root` — `Area` raíz del árbol de widgets, o `nil`.
- `xkb` — `State` de `lib.xkb`.
- `hover_element`, `active_element` — referencias al `Area` con hover o click activo.
- `focus_widget` — `Area` con foco de teclado. Se gestiona con `set_focus_widget`.
- `damage_list` — lista de rectángulos `{x0, y0, x1, y1}`.
- `force_redraw` — booleano.
- `destroyed` — booleano.

#### Métodos

| Método | Notas |
|---|---|
| `set_root(area)` | Establece el árbol, hace relayout y draw inmediato. |
| `move(x, y)` | Mueve la ventana. Para top-level es una petición al WM. |
| `move_by(dx, dy)` | Relativa a la posición actual. |
| `set_title(title)` | Actualiza `_NET_WM_NAME` y `WM_NAME`. |
| `add_damage(x0, y0, x1, y1)` | Añade un rect dañado. |
| `damage_all()` | Marca la ventana completa como dañada. |
| `draw()` | Si hay damage pendiente o `force_redraw`, renderiza al backing store y blitea a X11. |
| `set_focus_widget(widget)` | Cambia el foco de teclado. Notifica al anterior y al nuevo con `set_focused`. |
| `clear_focus_widget()` | Equivale a `set_focus_widget(nil)`. |
| `set_input_focus()` | Pide el foco a X. Guarda el `_prev_focus` la primera vez. |
| `restore_input_focus()` | Devuelve el foco guardado o a PointerRoot. |
| `close(reason)` | Llama a `on_close`, marca `running=false` y destruye. |
| `run()` | `server:run()`. |

#### Notas

- El render es doble: se dibuja al `image_surface` (RGB24) y se blitea al `surface` X11 solo la región con damage.
- El damage tracking decide entre partial y full por área cubierta (`_damage_union_ratio`, grilla 16×16), no por cantidad de rects.
- La tecla `q` cierra la ventana por defecto, salvo `disable_q_close = true` o que un widget con foco la consuma.
- Los eventos de input (KeyPress, ButtonPress, MotionNotify, EnterNotify, LeaveNotify, FocusIn, FocusOut) llevan el window id en el offset 12. Los eventos "notify" (Expose, ConfigureNotify, DestroyNotify, etc.) lo llevan en el offset 4. La función `extract_window_id` de `server.lua` los distingue por `etype`.
- `kind = "child"` requiere `parent_window`. La ventana se crea como child X11 y se marca `WM_TRANSIENT_FOR`. No recibe `_NET_WM_WINDOW_TYPE`.
- Al cerrar, si `kind` es child/transient, se devuelve el foco al `parent_window`. Si se pidió foco manualmente con `set_input_focus`, se restaura la ventana previa.

#### Anti-patrones

- **No crear `Window` sin `Server`.** `Window.new(opts)` crea uno propio, pero si la aplicación tiene varias ventanas conviene compartir el `Server`.
- **No llamar `set_root` con un `Area` ya usado por otra ventana.** El árbol guarda referencias al `window` en cada `Area`.
- **No disparar `force_redraw` por cualquier cambio.** El damage tracking existe para evitar repintados completos. Ver `notes.md`, entradas sobre `_damage_covers_most`.
- **No usar `kind = "dock"` sin `strut`.** El WM no reservará espacio y otras ventanas se solaparán con la barra.

---

### 2.5 screens.lua

Lista de monitores activos. Parsea `xrandr --query`.

**Depende de:** `lib.helpers.util` (para `shell_once`).

#### Funciones

| Función | Retorno | Notas |
|---|---|---|
| `list()` | tabla de `{ name, x, y, w, h }` | Cachea el resultado. |
| `invalidate()` | — | Limpia el cache. |
| `at(cx, cy)` | monitor | Monitor que contiene el punto. Si ninguno, el primero. |
| `center(s)` | `cx, cy` | Centro del monitor `s`. |

#### Notas

- `list()` usa `io.popen("xrandr --query")`. Es una llamada bloqueante al arranque; el resultado queda cacheado.
- Si el usuario cambia la configuración de monitores, hay que llamar a `invalidate()` para releer.

#### Anti-patrones

- **No llamar `list()` en cada `on_draw`.** Cachear. Ver `notes.md`.

---

### 2.6 helpers/util.lua

Utilidades sin dependencias. `trim`, lectura y escritura de archivos, shell, y parseo simple de config.

**Depende de:** nada.

#### Funciones

| Función | Retorno | Notas |
|---|---|---|
| `trim(s)` | string | Quita espacios al inicio y al final. Devuelve `s` tal cual si no es string. |
| `read_file(path)` | string o `nil` | Contenido completo. |
| `write_file(path, content)` | `bool` | Sobrescribe. |
| `shell_once(cmd)` | string | **Bloquea el event loop** mientras el comando corre. Vacío si falla. |
| `list_files(dir, ext?)` | tabla de strings | Nombres base (sin extensión), excluye `README`, ordenados. `ext` default `"lua"`. |
| `read_conf_key(file, key)` | string o `nil` | Busca `key = "valor"` con match de texto. No evalúa Lua. |
| `write_conf_key(file, key, value)` | `bool` | Reescribe el valor. `false` si la clave no existe. |
| `home()` | string | `$HOME` o `/`. |

#### Notas

- `shell_once` **bloquea**. Para comandos que tardan (por ejemplo `dmidecode`, `smartctl`), usar `helpers/async.lua` o `Server:add_timer` con `io.popen` desde un proceso aparte.
- `read_conf_key` y `write_conf_key` operan sobre archivos Lua planos con `key = "value"`. No soportan valores numéricos, ni tablas, ni comentarios en la misma línea.

#### Anti-patrones

- **No llamar `shell_once` con comandos lentos desde un callback del event loop.** Bloquea el repintado. Ver `notes.md`.

---

### 2.7 helpers/format.lua

Formateadores de valores numéricos a string legible.

**Depende de:** nada.

#### Funciones

| Función | Retorno | Ejemplo |
|---|---|---|
| `mb(kb)` | string | `1234567` → `"1.2 GB"`. Acepta KB; formatea en MB o GB. |
| `bytes(b)` | string | `"512 B"`, `"1.5 KB"`, `"1.2 MB"`, `"2.30 GB"`. |
| `speed(bps)` | string | `bytes(bps) .. "/s"`. |
| `uptime(secs)` | string | `"3d 4h 12m"`, `"4h 12m"`, `"45m"`. |
| `date()` | string | `"Domingo, 20 de septiembre de 2026"`. |
| `greeting(hour?)` | string | `"Buenos días,"` / `"Buenas tardes,"` / `"Buenas noches,"`. `hour` default la hora actual. |

#### Notas

- `mb` y `bytes` esperan unidades diferentes: `mb` recibe KB, `bytes` recibe bytes.
- `date` y `greeting` están en español, sin acentos en los nombres de día y mes (para evitar problemas de codificación en el archivo). No se traducen automáticamente.

---

### 2.8 helpers/async.lua

Ejecuta un comando shell en background sin bloquear el event loop. Reporta al terminar con un callback.

**Depende de:** nada del proyecto; usa `srv:add_timer`.

#### Funciones

- **`async_shell(srv, cmd, cb)`** — Lanza `cmd` en background. Devuelve un handle con `:cancel()`.
  - `srv` — instancia de `Server` (para el timer).
  - `cmd` — string a ejecutar con `sh`.
  - `cb(code, out, err)` — llamado cuando el comando termina. `code` es el exit code (`-1` si falla lanzarlo).

#### Notas

- Escribe el comando a `/tmp/lanetk-async-<timestamp>-<counter>.sh` y lo ejecuta en background. El resultado se recoge en archivos `.out`, `.err`, `.done`.
- Polling cada 150 ms vía `srv:add_timer`. El timer se cancela al terminar.
- Los archivos temporales se borran al terminar (éxito o cancelación).

#### Anti-patrones

- **No usar `async_shell` con comandos que escriben a `/tmp` con nombres predecibles.** El helper usa nombres únicos, pero si el comando en sí escribe ahí, no hay aislamiento.

---

### 2.9 helpers/graphics.lua

Primitivas de dibujo sobre Cairo: colores, barras, anillos, sparklines, historial circular.

**Depende de:** `lib.cairo`.

#### Funciones

| Función | Retorno | Notas |
|---|---|---|
| `hex_to_rgba(hex, alpha?)` | `r, g, b, a` (4 valores sueltos) | Acepta `#RRGGBB` o `#RGB`. `alpha` default `1.0`. |
| `set_color(cr, hex, alpha?)` | — | Atajo de `cairo.set_rgba` con `hex_to_rgba`. |
| `bar(cr, x, y, w, h, pct, opts?)` | — | Barra horizontal con relleno proporcional. `opts.fg`, `opts.bg`, `opts.radius`. |
| `stacked_bar(cr, x, y, w, h, segments, opts?)` | — | Varias porciones apiladas. `segments = { { pct, color }, ... }`. |
| `ring(cr, cx, cy, radius, pct, opts?)` | — | Anillo de progreso. `opts.thickness`, `opts.fg`, `opts.bg`, `opts.start_angle`, `opts.end_angle`. |
| `sparkline(cr, x, y, w, h, data, opts?)` | — | Línea con relleno opcional. `opts.fg`, `opts.fill`, `opts.width`, `opts.min`, `opts.max`. |
| `history(size)` | objeto | Buffer circular. Métodos `:push(v)`, `:get()`, `:clear()`. |

#### Notas

- `hex_to_rgba` devuelve 4 valores sueltos, no una tabla. Uso: `local r, g, b, a = G.hex_to_rgba("#8ec07c")`.
- `bar` y `stacked_bar` redondean las esquinas con clip. El `radius` por defecto es `h/2`.
- `sparkline` con `fill = true` (default) rellena el área bajo la línea con alpha `0.18`.
- `history` no guarda una ventana temporal: solo `size` muestras.

#### Anti-patrones

- **No envolver el retorno de `hex_to_rgba` en una tabla.** Son valores sueltos para `cairo.set_source_rgba`. Ver `notes.md`.
- **No llamar `sparkline` con menos de 2 puntos.** No hace nada (no lanza error).

---

### 2.10 helpers/init.lua

Reexporta `util` y `format` como campos.

- `require("lib.helpers").util` — `lib.helpers.util`.
- `require("lib.helpers").format` — `lib.helpers.format`.

#### Notas

- No reexporta `graphics` ni `async`; se importan por ruta completa.

---
## 3. Widgets

_(pendiente)_

## 3. Widgets

Todos los widgets heredan de `Area`. La API base (opts, campos, layout, hit-test, damage, hover, pressed) está en 3.1. Cada widget documenta solo su API propia, sin repetir lo heredado.

### 3.1 area.lua

Clase base de todos los widgets. Un `Area` ocupa un rectángulo `(x0, y0, x1, y1)` que le asigna su padre o la `Window`. Sabe medirse y dibujarse.

**Depende de:** nada.

#### Construcción

- **`Area.new(opts)`** — `opts.min_width`, `opts.min_height`, `opts.max_width`, `opts.max_height` (todos default `0`).

#### Campos

- `opts` — referencia a la tabla de opciones original.
- `x0, y0, x1, y1` — rectángulo asignado por el padre.
- `min_w, min_h, max_w, max_h` — del constructor.
- `parent` — referencia al `Area` padre.
- `window` — referencia a la `Window` que lo contiene.
- `hover`, `pressed` — estado de interacción.

#### Métodos

| Método | Retorno | Notas |
|---|---|---|
| `askMinMax(minw, minh, maxw, maxh)` | `minw, minh, maxw, maxh` | Recibe los bounds acumulados del padre y devuelve los acumulados del subárbol. Sobrescribir para sumar mínimos y tomar máximos. |
| `layout(x0, y0, x1, y1)` | — | Asigna el rect. Los contenedores sobrescriben para repartir entre hijos. |
| `should_draw()` | `bool` | `true` si el widget interseca el damage actual del `Window`. Los contenedores filtran hijos con esto. |
| `draw(cr)` | — | La base no dibuja nada. |
| `getByXY(x, y)` | `Area` o `nil` | Hit-test. La base comprueba solo su propio rect. Los contenedores deben delegar en los hijos. |
| `on_mouse_move(x, y)` | — | Coordenadas locales al widget. |
| `on_mouse_press(x, y, button)` | — | `button` 1=izq, 3=der, 4=wheel-up, 5=wheel-down. |
| `on_mouse_release(x, y, button)` | — | |
| `on_wheel(direction)` | — | `direction` 4 o 5. |
| `invalidate_layout()` | — | Fuerza `damage_all` + `_relayout` + `draw` inmediato. Usar cuando cambia el tamaño mínimo (por ejemplo, cambio de página en un `Stack`). |
| `getRect()` | `x0, y0, x1, y1` | |
| `getWidth()` / `getHeight()` | `int` | |
| `damage()` | — | Acumula el rect en el damage list del `Window`. Repinta solo esa región en el próximo ciclo. |
| `set_hover(v)` | — | Llama a `opts.on_hover`. Solo genera damage si `self._hover_visual` es `true`. |
| `set_pressed(v)` | — | Llama a `opts.on_press`. Solo genera damage si `self._pressed_visual` es `true`. |
| `newClass()` | clase | Factoría. Devuelve una clase con `__index = self`. |

#### Callbacks (`opts`)

- `on_hover(self, v)` — cambio de hover.
- `on_press(self, v)` — cambio de pressed.

#### Notas

- `askMinMax` es acumulativo, no absoluto. La firma `(minw, minh, maxw, maxh)` recibe los mínimos y máximos que pide el padre y devuelve los del subárbol. Los contenedores suman mínimos y toman el máximo de los máximos.
- `getByXY` en la base solo comprueba el rect propio. Los contenedores **deben** sobrescribirlo y delegar en los hijos. Si no, ningún click llega a los hijos.
- `should_draw` depende de `window.force_redraw`, `window.damage_list` y del rect propio. Si el rect es degenerado (`x0 == x1`), devuelve `true` para forzar el primer draw.
- `set_hover` y `set_pressed` **no repintan por defecto**. Los widgets con visual de hover o pressed deben declarar `self._hover_visual = true` / `self._pressed_visual = true` en su constructor.
- `invalidate_layout` llama a `window:draw()` inmediatamente, no espera al próximo ciclo. Usar con moderación.

#### Anti-patrones

- **No olvidar `_hover_visual` / `_pressed_visual` en widgets con visual de estado.** El estado cambia pero la UI no se repinta. Ver `notes.md`.
- **No mutar los hijos de un contenedor sin llamar `invalidate_layout()`.** El árbol queda con rects obsoletos. Ver `notes.md`.
- **No llamar `damage()` con rects fuera del área del widget.** El `Window` no recorta el rect; un damage grande fuerza `full redraw`.

---

### 3.2 widgets/init.lua

Registry de widgets. Mapea nombres cortos (`W.Text`, `W.Group`, etc.) a las clases.

**Depende de:** todos los módulos de `lib/widgets/`.

#### Campos

Todos los campos son clases (tablas con `__index`), no instancias. Se usan como `W.Nombre.new(opts)`.

- `W.Text`, `W.Group`, `W.Button`, `W.Card`, `W.Ring`, `W.Spark`, `W.Header`, `W.Bignum`, `W.KV`, `W.BarRow`, `W.Motors`, `W.DualSpark`, `W.Rows`, `W.BarMulti`, `W.Actions`, `W.Pills`, `W.ScrollView`, `W.ScrollBar`, `W.ScrollLink`, `W.Stack`, `W.TabsBar`, `W.Icon`, `W.TabbedPanel`, `W.CloseButton`, `W.TextInput`, `W.PillRow`, `W.ContextMenu`.

#### Notas

- Es un registry de carga completa: importar `lib.widgets` carga los 27 widgets. No hay carga lazy.

---

### 3.3 group.lua

Contenedor con varios hijos en fila o columna, con pesos.

**Depende de:** `lib.area`.

#### Construcción

- **`Group.new(opts)`** — `opts.orientation` (`"h"` o `"v"`, default `"v"`), `opts.spacing` (px), `opts.padding` (px).

#### Métodos

| Método | Notas |
|---|---|
| `add(child, weight)` | Añade un hijo. `weight` default `1`. |
| `remove(child)` | Quita un hijo. |
| `clear()` | Vacía el grupo. |
| `set_window(win)` | Propaga el `window` a los hijos. Lo llama `Window:set_root`. |

#### Notas

- El reparto del espacio usa `askMinMax` de cada hijo. Los mínimos se respetan; el espacio sobrante se reparte por `weight`.
- `spacing` se aplica entre hijos, no en los bordes. `padding` se aplica en los cuatro lados del grupo.
- Al mutar hijos (`add`, `remove`, `clear`) hay que llamar `invalidate_layout()` en el grupo o en un ancestro para recalcular.

#### Anti-patrones

- **No mutar hijos y esperar que se vea sin `invalidate_layout()`.** Los rects de los hijos quedan obsoletos. Ver `notes.md`.

---

### 3.4 stack.lua

Contenedor con varios hijos, uno visible a la vez. Base de páginas, tabs y sub-paneles.

**Depende de:** `lib.area`.

#### Construcción

- **`Stack.new(opts)`** — ver fuente para opts propios.

#### Métodos

| Método | Retorno | Notas |
|---|---|---|
| `add(name, widget)` | — | Registra una página por nombre. |
| `remove(name)` | — | |
| `set_active(name)` | — | Muestra la página `name`. |
| `get_active()` | `string` o `nil` | |
| `get(name)` | `Area` o `nil` | |
| `set_window(win)` | — | Propaga `window` a los hijos. |

#### Notas

- Solo la página activa recibe `layout` y `draw`. Las otras no consumen recursos de dibujo.
- Al cambiar de página se recalcula el `askMinMax` con el nuevo activo. Llamar `invalidate_layout()` si el mínimo cambia.

---

### 3.5 card.lua

Tarjeta con título opcional y un hijo (`Group`).

**Depende de:** `lib.area`, `lib.widgets.group`.

#### Construcción

- **`Card.new(opts)`** — `opts.title` (string), `opts.padding`, `opts.radius`, `opts.bg`.

#### Métodos

| Método | Notas |
|---|---|
| `set_title(text)` | Actualiza el título. |
| `set_window(win)` | Propaga a los hijos. |

#### Notas

- El `Card` dibuja fondo redondeado, título (si hay) y delega el resto en el `Group` interno.
- `askMinMax` suma el alto del título al mínimo del hijo.

---

### 3.6 text.lua

Texto simple: plano o markup Pango.

**Depende de:** `lib.area`, `lib.cairo`, `lib.pango`.

#### Construcción

- **`Text.new(opts)`** — `opts.text` (string), `opts.font` (string Pango), `opts.color` (string `#rrggbb` o `{r, g, b}`), `opts.align` (`"left"`, `"center"`, `"right"`), `opts.wrap_width` (px).

#### Métodos

| Método | Notas |
|---|---|
| `set_text(text)` | Reemplaza el texto. Re-mide. |
| `set_markup(markup)` | Reemplaza por markup Pango. |
| `set_color(r, g, b)` | Cambia el color (floats `[0,1]`). |

#### Notas

- La medición (`pango.measure`) se hace al construir y al cambiar texto. No en `draw`.

---

### 3.7 header.lua

Título de sección. Texto grande, plano o markup.

**Depende de:** `lib.area`, `lib.pango`.

#### Construcción

- **`Header.new(opts)`** — `opts.text` (string), `opts.markup` (bool), `opts.font`, `opts.color`.

#### Métodos

| Método | Notas |
|---|---|
| `set(text)` | Reemplaza el texto. |
| `set_markup(markup)` | Reemplaza por markup. |

#### Notas

- Se mide al construir y al cambiar texto.

---

### 3.8 bignum.lua

Número grande con caption y unidad.

**Depende de:** `lib.area`, `lib.pango`.

#### Construcción

- **`Bignum.new(opts)`** — `opts.value`, `opts.caption`, `opts.unit`, `opts.font_value`, `opts.font_caption`, `opts.color_value`, `opts.color_caption`.

#### Métodos

- **`set(value, caption, unit)`** — Actualiza los tres campos. `caption` y `unit` opcionales.

#### Notas

- Re-mide al `set`.

---

### 3.9 button.lua

Botón rectangular con texto y callback `on_click`.

**Depende de:** `lib.area`, `lib.cairo`, `lib.pango`.

#### Construcción

- **`Button.new(opts)`** — `opts.text`, `opts.font`, `opts.padding`, `opts.bg`, `opts.fg`, `opts.bg_hover`, `opts.radius`, `opts.on_click`.

#### Métodos

- **`set_text(text)`** — Actualiza el texto.

#### Notas

- Declara `_hover_visual` y `_pressed_visual` en el constructor, así que el hover y el click repintan.
- `opts.on_click(self, button)` recibe el botón del ratón.

---

### 3.10 closebutton.lua

Botón pequeño con una X. Uso típico: cerrar panel, popup o tab.

**Depende de:** `lib.area`, `lib.cairo`, `lib.helpers.graphics`.

#### Construcción

- **`CloseButton.new(opts)`** — `opts.size` (px), `opts.color`, `opts.color_hover`, `opts.on_click`.

#### Notas

- Captura clicks con `on_mouse_press`. No hay `on_mouse_release`: la acción se dispara al presionar.

---

### 3.11 icon.lua

Dibuja una imagen PNG en un `Area`. Soporta tintado preservando alpha.

**Depende de:** `lib.area`, `lib.cairo`.

#### Construcción

- **`Icon.new(opts)`** — `opts.path` (ruta al PNG), `opts.size` (px, cuadrado), `opts.color` (`{r, g, b}`), `opts.on_click`.

#### Métodos

| Método | Notas |
|---|---|
| `set_path(path)` | Cambia el PNG. |
| `set_color(r, g, b)` | Cambia el color de tinte (floats). |
| `set_color_hex(hex)` | Cambia el color desde string `#rrggbb`. |

#### Notas

- Usa `cairo.load_png_cached`, así que el surface PNG se comparte entre iconos con la misma ruta.
- Si hay color de tinte, usa `draw_surface_tinted` (colapsa el icono a un color preservando alpha). Sin color, dibuja el PNG tal cual.
- `on_mouse_press` dispara `on_click`.

---

### 3.12 ring.lua

Anillo de progreso con texto central.

**Depende de:** `lib.area`, `lib.cairo`, `lib.pango`.

#### Construcción

- **`Ring.new(opts)`** — `opts.value` (0..1), `opts.thickness`, `opts.color`, `opts.bg`, `opts.text`, `opts.sub`.

#### Métodos

- **`set_value(v, text, sub)`** — Actualiza el valor y los textos. `text` y `sub` opcionales.

#### Notas

- El valor se clampea a `[0, 1]`.

---

### 3.13 spark.lua

Sparkline con un solo canal.

**Depende de:** `lib.area`, `lib.cairo`, `lib.pango`, `lib.helpers.graphics`.

#### Construcción

- **`Spark.new(opts)`** — `opts.size` (nº de muestras), `opts.color`, `opts.fill`, `opts.min`, `opts.max`, `opts.line_width`.

#### Métodos

| Método | Notas |
|---|---|
| `push(v)` | Añade una muestra y daña. |
| `set_range(vmin, vmax)` | Fija el rango manualmente. |
| `clear()` | Vacía el historial. |

---

### 3.14 dualspark.lua

Sparkline con dos canales superpuestos.

**Depende de:** `lib.area`, `lib.cairo`, `lib.pango`, `lib.helpers.graphics`.

#### Construcción

- **`DualSpark.new(opts)`** — `opts.size`, `opts.color_a`, `opts.color_b`, `opts.fill`, `opts.min`, `opts.max`.

#### Métodos

| Método | Notas |
|---|---|
| `push_a(v)` | Añade muestra al canal A y daña. |
| `push_b(v)` | Añade muestra al canal B y daña. |
| `set_range(vmin, vmax)` | Fija el rango común. |
| `clear()` | Vacía ambos canales. |

#### Notas

- Si el rango no se fija, se calcula sobre la unión de ambos canales.

---

### 3.15 rows.lua

Lista de filas con formato `[grupo] nombre = valor`.

**Depende de:** `lib.area`, `lib.widgets.text`, `lib.widgets.rowparse`.

#### Construcción

- **`Rows.new(opts)`** — `opts.font_name`, `opts.font_value`, `opts.color_name`, `opts.color_value`, `opts.row_height`, `opts.padding`.

#### Métodos

| Método | Notas |
|---|---|
| `add_row(id, group, name)` | Añade una fila. `group` opcional (string). |
| `set_window(win)` | Propaga a los hijos. |
| `set(id, value, format)` | Actualiza el valor. `format` opcional. |
| `set_markup(id, markup)` | Actualiza con markup Pango. |

#### Notas

- Acepta filas como tabla con keys (`{ id = ..., label = ... }`) o como array posicional (`{ "id", "label" }`). El parseo lo hace `rowparse.lua`.
- `format` en `set` puede ser una función `function(value) -> string`.

---

### 3.16 kv.lua

Lista de pares clave-valor con columnas alineadas.

**Depende de:** `lib.area`, `lib.pango`, `lib.widgets.group`, `lib.widgets.text`, `lib.widgets.rowparse`.

#### Construcción

- **`KV.new(opts)`** — `opts.font_key`, `opts.font_value`, `opts.color_key`, `opts.color_value`, `opts.row_height`, `opts.padding`.

#### Métodos

| Método | Notas |
|---|---|
| `add_row(id, label, format)` | Añade una fila. `format` opcional. |
| `set(id, value)` | Actualiza el valor. |
| `set_markup(id, markup)` | Actualiza con markup. |
| `set_title(markup)` | No hace nada (no-op, ver fuente). |
| `set_window(win)` | Propaga a los hijos. |

#### Notas

- Misma aceptación de formato que `Rows` (keys o array posicional, vía `rowparse`).
- `set_title` es un no-op: existe por compatibilidad, pero no dibuja título. El consumidor debe usar un `Header` si lo necesita.

---

### 3.17 barrow.lua

Filas con barra de progreso (`label` + barra + valor).

**Depende de:** `lib.area`, `lib.cairo`, `lib.pango`, `lib.widgets.text`, `lib.widgets.rowparse`, `lib.helpers.graphics`.

#### Construcción

- **`BarRow.new(opts)`** — `opts.font_label`, `opts.font_value`, `opts.row_height`, `opts.padding`, `opts.bar_height`, `opts.bar_radius`.

#### Métodos

| Método | Notas |
|---|---|
| `add_row(id, label, color)` | Añade una fila. `color` opcional. |
| `remove_all_rows()` | Vacía. |
| `set_window(win)` | Propaga a los hijos. |
| `set(id, data)` | Actualiza. `data` es tabla `{ pct, value, color }`. |
| `set_empty(id, text)` | Marca la fila vacía con un texto. |

#### Notas

- Los colores de barra y texto pueden cambiar por umbral (`_bar_color_for`, `_text_color_for`). La fuente del umbral está en el propio widget.

---

### 3.18 barmulti.lua

Barra horizontal con varios segmentos apilados y leyenda dinámica.

**Depende de:** `lib.area`, `lib.cairo`, `lib.pango`, `lib.helpers.graphics`.

#### Construcción

- **`BarMulti.new(opts)`** — `opts.font_label`, `opts.bar_height`, `opts.legend_visible`.

#### Métodos

| Método | Notas |
|---|---|
| `add_segment(id, color, label)` | Registra un segmento. |
| `set(values)` | Actualiza todos los segmentos. `values[id] = pct`. |

#### Notas

- La leyenda (nombres y porcentajes por segmento) se recalcula en `draw` según el ancho disponible. El layout de la leyenda es dinámico.

---

### 3.19 motors.lua

Configuración concreta de `BarRow`: solo label más barra, sin valor.

**Depende de:** `lib.widgets.barrow`.

#### Construcción

- **`Motors.new(opts)`** — ver `BarRow.new`.

#### Métodos

- **`set(id, pct)`** — Atajo sobre `BarRow:set` con solo porcentaje.

#### Notas

- Subclase de `BarRow`. Todo lo demás (filas, colores, umbrales) se hereda.

---

### 3.20 pills.lua

Columna de pills. Cada pill es un texto con color de fondo.

**Depende de:** `lib.area`, `lib.cairo`, `lib.pango`, `lib.helpers.graphics`.

#### Construcción

- **`Pills.new(opts)`** — `opts.font`, `opts.padding`, `opts.spacing`, `opts.radius`.

#### Métodos

| Método | Notas |
|---|---|
| `add(id, text, color)` | Añade un pill. `color` es el fondo. |
| `set(id, text)` | Actualiza el texto. |
| `set_color(id, color)` | Actualiza el color. |

#### Notas

- Los pills se apilan en columna. El alto total se recalcula en `askMinMax` y `layout`.

---

### 3.21 pillrow.lua

Fila horizontal de pills con formato `[LABEL VALOR]`. El label va en muted, el valor en su color.

**Depende de:** `lib.area`, `lib.cairo`, `lib.pango`, `lib.helpers.graphics`.

#### Construcción

- **`PillRow.new(opts)`** — `opts.font`, `opts.padding`, `opts.spacing`, `opts.radius`, `opts.color_label`.

#### Métodos

| Método | Notas |
|---|---|
| `add(id, label, value, color)` | Añade un pill. |
| `set(id, value, color)` | Actualiza valor y color. |
| `set_color(id, color)` | Actualiza solo el color. |

#### Notas

- El layout se recalcula al añadir o cambiar. No hay scroll horizontal: si no cabe, se recorta.

---

### 3.22 actions.lua

Lista de botones de acción. Cada botón ejecuta un comando shell y muestra feedback de éxito o error.

**Depende de:** `lib.area`, `lib.widgets.text`, `lib.widgets.button`, `lib.widgets.group`, `lib.timer`.

#### Construcción

- **`Actions.new(opts)`** — `opts.row_height`, `opts.padding`, `opts.spacing`.

#### Métodos

| Método | Notas |
|---|---|
| `add_action(label, cmd, ok_msg)` | Añade una acción. `ok_msg` opcional. |
| `set_window(win)` | Propaga a los hijos. |

#### Notas

- Cada acción corre su comando al click. El resultado se muestra al lado. El timer de reset del mensaje está en el propio widget.

---

### 3.23 scrollview.lua

Lista con scroll pixel-perfect. El contenido se dibuja por callback.

**Depende de:** `lib.area`.

#### Construcción

- **`ScrollView.new(opts)`** — `opts.row_height`, `opts.draw_row` (`function(cr, item, idx, y, row_h, width, hover, view)`), `opts.on_click` (`function(item, idx)`), `opts.on_hover_row` (`function(idx)`).

#### Métodos

| Método | Notas |
|---|---|
| `set_items(items)` | Reemplaza la lista. Compara con `_items_equal` para no dañar si es idéntica. |
| `set_offset(px, silent?)` | Fija el offset. Si `silent`, no llama a los `on_change`. |
| `get_offset()` | Offset actual. |
| `get_offset_max()` | Máximo offset. |
| `get_row_height()` | Alto de fila. |
| `get_count()` | Nº de items. |
| `set_window(win)` | Propaga. |
| `on_change(fn)` | Registra callback. `fn(offset, offset_max)`. |
| `set_hover(v)` | Override: repinta la fila bajo hover. |

#### Callbacks (`opts`)

- `draw_row(cr, item, idx, y, row_h, width, hover, view)` — Dibuja una fila.
- `on_click(item, idx)` — Click sobre una fila.
- `on_hover_row(idx)` — Cambio de fila bajo el cursor.

#### Notas

- El `ScrollView` no pinta el scrollbar: se combina con `ScrollBar` vía `scrolllink.lua`.
- El offset se aplica como `translate` y se recorta con clip. Solo se dibujan las filas visibles.
- `_damage_row` daña solo la fila afectada por hover o cambio de contenido.

---

### 3.24 scrollbar.lua

Scrollbar vertical u horizontal. Se ata a un `ScrollView` por callbacks.

**Depende de:** `lib.area`.

#### Construcción

- **`ScrollBar.new(opts)`** — `opts.orientation` (`"v"` o `"h"`), `opts.width`, `opts.color`, `opts.color_hover`, `opts.radius`.

#### Métodos

| Método | Notas |
|---|---|
| `on_change(fn)` | Registra callback. `fn(offset)` cuando el usuario mueve el handle. |
| `set_offset(px, silent?)` | Fija el offset del handle. |
| `set_offset_max(px)` | Fija el máximo. Si es `0`, el scrollbar se oculta y no captura eventos. |
| `set_step(px)` | Paso por click de rueda. |
| `get_offset()`, `get_offset_max()` | Lecturas. |
| `is_visible()` | `true` si `offset_max > 0`. |

#### Notas

- Interacción: click izquierdo y arrastre mueven el handle; rueda mueve por `step`.
- Auto-oculto cuando `offset_max == 0` (no se dibuja, no captura eventos, `is_visible()` devuelve `false`).

---

### 3.25 scrolllink.lua

Cablea un `ScrollView` con un `ScrollBar` sin bucles de feedback.

**Depende de:** nada.

#### Funciones

- **`M.link(list, sb)`** — Establece la conexión bidireccional.
  - `list:on_change` → `sb:set_offset(silent)` + `sb:set_offset_max`.
  - `sb:on_change` → `list:set_offset`.

#### Notas

- Es la forma recomendada de combinar `ScrollView` y `ScrollBar`. Cablearlo a mano sin `silent` produce bucles.

---

### 3.26 tabsbar.lua

Barra de tabs. Dos modos: `compact = false` (icono arriba, texto abajo, tabs principales) y `compact = true` (icono y texto lado a lado, sub-tabs).

**Depende de:** `lib.area`.

#### Construcción

- **`TabsBar.new(opts)`** — `opts.compact` (bool), `opts.font`, `opts.icon_size`, `opts.pad_x`, `opts.pad_y`, `opts.on_change` (`function(id)`).

#### Métodos

| Método | Notas |
|---|---|
| `add(id, label, icon_name)` | Añade un tab. `icon_name` es el nombre base del PNG en `icons-png/`. |
| `set_active(id)` | Marca un tab como activo. |
| `get_active()` | Id del tab activo. |
| `set_hover(v)` | Override: repinta el tab bajo hover. |

#### Notas

- Colores por defecto: activo bg=accent fg=bg_normal; inactivo bg=bg_normal fg=muted. Los iconos se tiñen con el color fg correspondiente.
- `on_change(id)` se llama al cambiar de tab.

---

### 3.27 tabbedpanel.lua

`TabsBar` + `Stack` con lazy loading. Sin close button, sin padding (los decide el consumidor).

**Depende de:** `lib.area`, `lib.widgets.group`, `lib.widgets.stack`, `lib.widgets.tabsbar`.

#### Construcción

- **`TabbedPanel.new(opts)`** — `opts.compact` (para la `TabsBar`), `opts.tabs` (lista de definiciones `{ id, label, icon, build }`). El campo `build` es una función que devuelve el widget de la pestaña; se llama la primera vez que se activa la pestaña.

#### Métodos

| Método | Notas |
|---|---|
| `set_tab(id)` | Activa la pestaña. Construye el contenido si es la primera vez. |
| `get_tab(id)` | Devuelve el widget ya construido, o `nil`. |
| `get_active()` | Id de la pestaña activa. |
| `stop()` | Detiene el contenido activo si expone un método `stop`. |
| `set_window(win)` | Propaga. |

#### Notas

- Lazy loading: la función `build` de una pestaña solo se llama al activarla por primera vez.
- `_stop_active` llama a `stop()` en la pestaña que se desactiva si lo expone. Útil para detener timers o samplers.

---

### 3.28 textinput.lua

Campo de texto editable minimalista. Sin scroll horizontal, sin selección. Cursor en posición actual.

**Depende de:** `lib.area`, `lib.cairo`, `lib.pango`.

#### Construcción

- **`TextInput.new(opts)`** — `opts.text`, `opts.font`, `opts.color`, `opts.color_focus`, `opts.cursor_color`, `opts.on_change` (`function(text)`), `opts.on_submit` (`function(text)`).

#### Métodos

| Método | Notas |
|---|---|
| `set_text(t)` | Reemplaza el contenido. |
| `get_text()` | Devuelve el contenido. |
| `set_focused(v)` | Activa o desactiva el cursor. Se llama desde `Window:set_focus_widget`. |
| `on_key(key)` | Procesa teclas cuando el widget tiene foco. Devuelve `true` si consume la tecla. |

#### Notas

- Se auto-registra como `window.focus_widget` al recibir click (`on_mouse_press`).
- `on_key` maneja edición básica: insertar caracteres, borrar, mover cursor, home/end. Enter dispara `on_submit`.
- El cursor se dibuja solo cuando `focused` es `true`.

---

### 3.29 contextmenu.lua

Menú contextual flotante anclado a un punto de la ventana padre. Uso típico: click derecho sobre un item.

**Depende de:** `lib.area`, `lib.window`.

#### Instancia

`ContextMenu` se usa como singleton: no tiene `new`, sino `:show`.

#### Métodos

| Método | Notas |
|---|---|
| `show(x, y, items, opts)` | Abre el menú en `(x, y)` con los items dados. `items` es lista de `{ label, on_click }`. `opts` puede incluir `parent_window`, `font`, colores. |
| `close()` | Cierra el menú. |
| `is_open()` | `true` si está abierto. |

#### Notas

- Usa una ventana `child` del padre más `xcb_grab_pointer`. Mientras está abierto, todos los clicks van al menú.
- El primer click fuera de su rect cierra el menú y se consume (no llega al padre).
- Escape cierra el menú.
- El índice bajo el cursor se calcula con `_index_at(my)`.

#### Anti-patrones

- **No abrir un `ContextMenu` sin un `parent_window`.** Sin padre no hay ventana `child` ni grab.

---

### 3.30 rowparse.lua

Parser común de filas para widgets que aceptan `{ id, label, ... }` (tabla con keys) o `{ "id", "label" }` (array posicional, estilo proyecto original).

**Depende de:** nada.

#### Funciones

- **`parse(row, keys)`** — Devuelve `id, label, extra`. `keys` es una lista de claves a leer en el formato con tabla. Si la fila no las tiene, se cae al formato posicional.

#### Notas

- Es un helper compartido por `Rows`, `KV`, `BarRow`, `Actions`. Cualquier widget que documente "acepta ambos formatos" lo usa por dentro.

---
## 4. Aplicaciones

_(pendiente)_

## 4. Aplicaciones

Aplicaciones completas: proceso que mantiene el server vivo, ventana con `TabbedPanel`, y los tabs concretos que dan contenido al panel del sistema.

### 4.1 panelapp.lua

Proceso que mantiene un `Server` vivo y crea o destruye paneles bajo demanda. Cuando el usuario cierra el panel, el proceso sigue esperando un nuevo trigger.

**Depende de:** `lib.server`, `lib.panel`, `lib.log`.

#### Construcción

- **`PanelApp.new(opts)`** — `opts.trigger_path` (ruta a observar), `opts.panel_opts` (opciones que se pasan a `Panel.new`), `opts.server` (reutilizar un `Server` existente), `opts.theme`.

#### Campos

- `server` — instancia de `Server`. Si no se pasa, se crea uno con `exit_on_empty = false`.
- `panel` — instancia de `Panel` o `nil`.
- `panel_opts` — copia de las opciones de `opts.panel_opts`.
- `trigger_path` — ruta del trigger file.
- `theme` — referencia al theme pasado en `opts`, con el campo `rebuild` inyectado.

#### Métodos

| Método | Notas |
|---|---|
| `show()` | Crea el panel si no existe. Encadena `on_close` para liberar la referencia. |
| `hide()` | Cierra el panel si existe. |
| `toggle()` | `show` o `hide` según el estado. |
| `quit()` | Cierra el panel y detiene el `Server`. |
| `rebuild()` | Cierra y recrea el panel con el theme actual. Recuerda el tab activo y lo restaura. |
| `run()` | `server:run()`. Bloquea hasta `quit`. |

#### Trigger

Si `trigger_path` está definido, `PanelApp` observa el archivo vía `server:watch_trigger`. Los comandos aceptados en su contenido son:

- `toggle` (o vacío) — `self:toggle()`.
- `show` — `self:show()`.
- `hide` — `self:hide()`.
- `quit` — `self:quit()`.

Cualquier otro comando se loguea como desconocido.

#### Notas

- Con `theme`, se inyecta `theme.rebuild = function() self:rebuild() end`. La tab de configuración puede entonces llamar `theme.rebuild()` tras cambiar la paleta.
- `rebuild` conserva el id del tab activo antes de cerrar y lo restaura tras reabrir. Si el panel no estaba visible, no hace nada.
- `show` encadena el `on_close` que pase `panel_opts`: primero llama al del usuario, luego libera la referencia y ejecuta `collectgarbage("collect")`.

---

### 4.2 panel.lua

Ventana con un `TabbedPanel` dentro. Toda la lógica de tabs y lazy loading vive en `TabbedPanel`; este módulo solo crea la ventana, pinta el fondo y gestiona Esc.

**Depende de:** `lib.window`, `lib.widgets`, `lib.cairo`, `lib.log`.

#### Construcción

- **`Panel.new(opts)`** — `opts.tabs` (lista de definiciones), `opts.spacing`, `opts.padding`, `opts.theme`, `opts.bg`, `opts.kind`, `opts.parent_window`, `opts.title`, `opts.width`, `opts.height`, `opts.x`, `opts.y`, `opts.server`, `opts.on_close`.

Defaults de geometría: `width = "80%"`, `height = "80%"`, `x = "center"`, `y = "center"`.

#### Campos

- `window` — la `Window` creada.
- `tabbed` — el `TabbedPanel`.
- `outer` — el `Group` que envuelve al tabbed y aplica `padding`.
- `bg` — `{r, g, b}` del fondo.

#### Métodos

| Método | Notas |
|---|---|
| `set_tab(id)` | Atajo a `tabbed:set_tab(id)`. |
| `get_tab(id)` | Atajo a `tabbed:get_tab(id)`. |
| `get_window()` | Devuelve la `Window`. |
| `close()` | `window:close("panel")`. |
| `run()` | `window:run()`. |

#### Notas

- El `padding` se aplica en un `Group` exterior, no en el `TabbedPanel`, para no sumarse con el `padding` de sub-`TabbedPanel` anidados.
- El `bg` se resuelve en este orden: `opts.bg` → `theme.bg_rgb` → `{0.10, 0.10, 0.13}`.
- Esc cierra el panel solo si `window.focus_widget` es `nil`. Si hay un `TextInput` con foco, Esc se le entrega primero.
- `on_close` del `Window` llama a `tabbed:_stop_active()` antes del `on_close` del usuario.
- Crea la ventana con `disable_q_close = true`: la tecla `q` no cierra el panel.
- Si `opts.tabs` tiene al menos un elemento, activa el primero tras `set_root`.

#### Anti-patrones

- **No pasar `padding` al `TabbedPanel` directamente.** Se sumaría con el padding interno de los sub-`TabbedPanel`. El `padding` exterior va aquí.

---

### 4.3 system.lua

Super panel de sistema. Coordina todos los tabs del panel original de Awesome: Inicio, Recursos, Red, Batería, Discos, Procesos, Buscar. El tab Laboratorio queda pendiente.

**Depende de:** `lib.panelapp`, `lib.widgets`, `lib.log`.

#### Construcción

- **`M.new(srv, theme)`** — Devuelve la lista de definiciones de tabs, lista para pasarse a `PanelApp` / `Panel` como `opts.tabs`.

#### Notas

- Es un módulo de coordinación: no define widgets propios ni estado. Solo arma la spec de tabs y sus `build`.
- El tab "Recursos" es un sub-`TabbedPanel` con General, CPU, RAM, GPU (ver 4.4).

---

### 4.4 tabs/

Cada archivo define un módulo con `M.new(srv, theme)` que devuelve el widget de la pestaña. Firma uniforme: el tab recibe el `Server` para timers y el `theme` para colores.

Todos los tabs dependen de `lib.widgets`. Algunos también de `lib.helpers.*`, `lib.cairo`, `lib.pango` y `lib.data.*`.

| Archivo | Propósito |
|---|---|
| `inicio.lua` | Portada. Avatar circular + identidad + cards Sistema/Sesión + reloj. |
| `general.lua` | Recursos → General. Barras CPU/RAM/GPU/SWAP + temps embebido. |
| `cpu.lua` | Recursos → CPU. Anillo + spark + motors + KV info. |
| `ram.lua` | Recursos → RAM. Anillo + breakdown + módulos + swap + acciones. |
| `gpu.lua` | Recursos → GPU. Anillo + spark + motors + KV estado. |
| `temps.lua` | Temperaturas. Portado del original de Awesome. |
| `disks.lua` | Discos. Particiones + SMART + hardware. |
| `proc.lua` | Procesos. Lista ordenable + filtro + pills + menú contextual. |
| `search.lua` | Buscar. Header y filas comparten una función pura `compute_cols(avail)`. |
| `bat.lua` | Batería. Telemetría de sysfs. |
| `config.lua` | Configuración (versión mínima). Cicla tema/paleta + aplicar. |
| `launcher.lua` | Launcher. Buscador de apps y comandos. |
| `notes.lua` | Notas. Lista + detalle con editor externo. |
| `sys.lua` | Agregador de sub-tabs del sistema. |

#### Clases auxiliares internas

Algunos tabs definen clases locales, no exportadas:

- `inicio.lua` → `Avatar` — círculo con foto. Métodos `Avatar.new(opts)`, `Avatar:set_path(path)`, `Avatar:draw(cr)`.
- `ram.lua` → `SwapBar` — barra de swap con total y usado. Métodos `SwapBar.new(opts)`, `SwapBar:set_data(total, used)`, `SwapBar:draw(cr)`.
- `notes.lua` → `ListRow` — fila de la lista de notas. Métodos `ListRow.new(item, theme, on_click)`, `ListRow:draw(cr)`.
- `search.lua` → `HeaderRow` — cabecera de columnas ordenable. Métodos `HeaderRow.new(opts)`, `HeaderRow:draw(cr)`, `HeaderRow:on_mouse_press(mx, my, button)`.

No son parte de la API pública: se usan solo dentro de su tab.

#### Notas

- `notes.lua` recibe un tercer argumento opcional: `M.new(srv, theme, parent_win)`. Lo usa para abrir el editor externo como ventana hija del panel.
- `temps.lua` recibe un tercer argumento opcional: `M.new(srv, theme, opts)`.
- El resto de tabs usan la firma uniforme `M.new(srv, theme)`.
- `config.lua` no aplica la paleta por su cuenta: muta el theme y llama a `theme.rebuild()` (inyectado por `PanelApp`). Ver 4.1.

#### Anti-patrones

- **No construir tabs fuera de `M.new`.** El tab debe construirse en la llamada a `M.new(srv, theme)` y devolver el widget. `TabbedPanel` es quien decide cuándo llamarlo (lazy).
- **No guardar estado global entre tabs.** Cada tab arma su propio árbol; la comunicación va por `srv:add_timer`, `theme` o el `PanelApp`.

---
## 4. Aplicaciones

Aplicaciones completas: proceso que mantiene el server vivo, ventana con `TabbedPanel`, y los tabs concretos que dan contenido al panel del sistema.

### 4.1 panelapp.lua

Proceso que mantiene un `Server` vivo y crea o destruye paneles bajo demanda. Cuando el usuario cierra el panel, el proceso sigue esperando un nuevo trigger.

**Depende de:** `lib.server`, `lib.panel`, `lib.log`.

#### Construcción

- **`PanelApp.new(opts)`** — `opts.trigger_path` (ruta a observar), `opts.panel_opts` (opciones que se pasan a `Panel.new`), `opts.server` (reutilizar un `Server` existente), `opts.theme`.

#### Campos

- `server` — instancia de `Server`. Si no se pasa, se crea uno con `exit_on_empty = false`.
- `panel` — instancia de `Panel` o `nil`.
- `panel_opts` — copia de las opciones de `opts.panel_opts`.
- `trigger_path` — ruta del trigger file.
- `theme` — referencia al theme pasado en `opts`, con el campo `rebuild` inyectado.

#### Métodos

| Método | Notas |
|---|---|
| `show()` | Crea el panel si no existe. Encadena `on_close` para liberar la referencia. |
| `hide()` | Cierra el panel si existe. |
| `toggle()` | `show` o `hide` según el estado. |
| `quit()` | Cierra el panel y detiene el `Server`. |
| `rebuild()` | Cierra y recrea el panel con el theme actual. Recuerda el tab activo y lo restaura. |
| `run()` | `server:run()`. Bloquea hasta `quit`. |

#### Trigger

Si `trigger_path` está definido, `PanelApp` observa el archivo vía `server:watch_trigger`. Los comandos aceptados en su contenido son:

- `toggle` (o vacío) — `self:toggle()`.
- `show` — `self:show()`.
- `hide` — `self:hide()`.
- `quit` — `self:quit()`.

Cualquier otro comando se loguea como desconocido.

#### Notas

- Con `theme`, se inyecta `theme.rebuild = function() self:rebuild() end`. La tab de configuración puede entonces llamar `theme.rebuild()` tras cambiar la paleta.
- `rebuild` conserva el id del tab activo antes de cerrar y lo restaura tras reabrir. Si el panel no estaba visible, no hace nada.
- `show` encadena el `on_close` que pase `panel_opts`: primero llama al del usuario, luego libera la referencia y ejecuta `collectgarbage("collect")`.

---

### 4.2 panel.lua

Ventana con un `TabbedPanel` dentro. Toda la lógica de tabs y lazy loading vive en `TabbedPanel`; este módulo solo crea la ventana, pinta el fondo y gestiona Esc.

**Depende de:** `lib.window`, `lib.widgets`, `lib.cairo`, `lib.log`.

#### Construcción

- **`Panel.new(opts)`** — `opts.tabs` (lista de definiciones), `opts.spacing`, `opts.padding`, `opts.theme`, `opts.bg`, `opts.kind`, `opts.parent_window`, `opts.title`, `opts.width`, `opts.height`, `opts.x`, `opts.y`, `opts.server`, `opts.on_close`.

Defaults de geometría: `width = "80%"`, `height = "80%"`, `x = "center"`, `y = "center"`.

#### Campos

- `window` — la `Window` creada.
- `tabbed` — el `TabbedPanel`.
- `outer` — el `Group` que envuelve al tabbed y aplica `padding`.
- `bg` — `{r, g, b}` del fondo.

#### Métodos

| Método | Notas |
|---|---|
| `set_tab(id)` | Atajo a `tabbed:set_tab(id)`. |
| `get_tab(id)` | Atajo a `tabbed:get_tab(id)`. |
| `get_window()` | Devuelve la `Window`. |
| `close()` | `window:close("panel")`. |
| `run()` | `window:run()`. |

#### Notas

- El `padding` se aplica en un `Group` exterior, no en el `TabbedPanel`, para no sumarse con el `padding` de sub-`TabbedPanel` anidados.
- El `bg` se resuelve en este orden: `opts.bg` → `theme.bg_rgb` → `{0.10, 0.10, 0.13}`.
- Esc cierra el panel solo si `window.focus_widget` es `nil`. Si hay un `TextInput` con foco, Esc se le entrega primero.
- `on_close` del `Window` llama a `tabbed:_stop_active()` antes del `on_close` del usuario.
- Crea la ventana con `disable_q_close = true`: la tecla `q` no cierra el panel.
- Si `opts.tabs` tiene al menos un elemento, activa el primero tras `set_root`.

#### Anti-patrones

- **No pasar `padding` al `TabbedPanel` directamente.** Se sumaría con el padding interno de los sub-`TabbedPanel`. El `padding` exterior va aquí.

---

### 4.3 system.lua

Super panel de sistema. Coordina todos los tabs del panel original de Awesome: Inicio, Recursos, Red, Batería, Discos, Procesos, Buscar. El tab Laboratorio queda pendiente.

**Depende de:** `lib.panelapp`, `lib.widgets`, `lib.log`.

#### Construcción

- **`M.new(srv, theme)`** — Devuelve la lista de definiciones de tabs, lista para pasarse a `PanelApp` / `Panel` como `opts.tabs`.

#### Notas

- Es un módulo de coordinación: no define widgets propios ni estado. Solo arma la spec de tabs y sus `build`.
- El tab "Recursos" es un sub-`TabbedPanel` con General, CPU, RAM, GPU (ver 4.4).

---

### 4.4 tabs/

Cada archivo define un módulo con `M.new(srv, theme)` que devuelve el widget de la pestaña. Firma uniforme: el tab recibe el `Server` para timers y el `theme` para colores.

Todos los tabs dependen de `lib.widgets`. Algunos también de `lib.helpers.*`, `lib.cairo`, `lib.pango` y `lib.data.*`.

| Archivo | Propósito |
|---|---|
| `inicio.lua` | Portada. Avatar circular + identidad + cards Sistema/Sesión + reloj. |
| `general.lua` | Recursos → General. Barras CPU/RAM/GPU/SWAP + temps embebido. |
| `cpu.lua` | Recursos → CPU. Anillo + spark + motors + KV info. |
| `ram.lua` | Recursos → RAM. Anillo + breakdown + módulos + swap + acciones. |
| `gpu.lua` | Recursos → GPU. Anillo + spark + motors + KV estado. |
| `temps.lua` | Temperaturas. Portado del original de Awesome. |
| `disks.lua` | Discos. Particiones + SMART + hardware. |
| `proc.lua` | Procesos. Lista ordenable + filtro + pills + menú contextual. |
| `search.lua` | Buscar. Header y filas comparten una función pura `compute_cols(avail)`. |
| `bat.lua` | Batería. Telemetría de sysfs. |
| `config.lua` | Configuración (versión mínima). Cicla tema/paleta + aplicar. |
| `launcher.lua` | Launcher. Buscador de apps y comandos. |
| `notes.lua` | Notas. Lista + detalle con editor externo. |
| `sys.lua` | Agregador de sub-tabs del sistema. |

#### Clases auxiliares internas

Algunos tabs definen clases locales, no exportadas:

- `inicio.lua` → `Avatar` — círculo con foto. Métodos `Avatar.new(opts)`, `Avatar:set_path(path)`, `Avatar:draw(cr)`.
- `ram.lua` → `SwapBar` — barra de swap con total y usado. Métodos `SwapBar.new(opts)`, `SwapBar:set_data(total, used)`, `SwapBar:draw(cr)`.
- `notes.lua` → `ListRow` — fila de la lista de notas. Métodos `ListRow.new(item, theme, on_click)`, `ListRow:draw(cr)`.
- `search.lua` → `HeaderRow` — cabecera de columnas ordenable. Métodos `HeaderRow.new(opts)`, `HeaderRow:draw(cr)`, `HeaderRow:on_mouse_press(mx, my, button)`.

No son parte de la API pública: se usan solo dentro de su tab.

#### Notas

- `notes.lua` recibe un tercer argumento opcional: `M.new(srv, theme, parent_win)`. Lo usa para abrir el editor externo como ventana hija del panel.
- `temps.lua` recibe un tercer argumento opcional: `M.new(srv, theme, opts)`.
- El resto de tabs usan la firma uniforme `M.new(srv, theme)`.
- `config.lua` no aplica la paleta por su cuenta: muta el theme y llama a `theme.rebuild()` (inyectado por `PanelApp`). Ver 4.1.

#### Anti-patrones

- **No construir tabs fuera de `M.new`.** El tab debe construirse en la llamada a `M.new(srv, theme)` y devolver el widget. `TabbedPanel` es quien decide cuándo llamarlo (lazy).
- **No guardar estado global entre tabs.** Cada tab arma su propio árbol; la comunicación va por `srv:add_timer`, `theme` o el `PanelApp`.

---
## 5. Barra superior

_(pendiente)_

## 6. Samplers

_(pendiente)_

## Apéndice A. Anti-patrones

_(pendiente — se completará con los anti-patrones extraídos de `docs/notes.md`)_
