# Índice

## [01. Núcleo Gráfico (Core FFI)](#01-núcleo-gráfico-core-ffi)

### [1.1 `xcb.lua`](#11-xcblua)
- [Constantes](#constantes)
- [API](#api)
  - [Conexión](#conexión)
  - [Pantalla y visual](#pantalla-y-visual)
  - [Ventanas](#ventanas)
  - [Átomos y propiedades](#átomos-y-propiedades)
  - [Hints, foco y puntero](#hints-foco-y-puntero)
  - [Pixmaps, GC y PutImage](#pixmaps-gc-y-putimage)
  - [XShape](#xshape)
  - [Teclado](#teclado)
  - [Eventos](#eventos)
- [Anti-patrones](#anti-patrones)

### [1.2 `cairo.lua`](#12-cairolua)
- [Constantes](#constantes-1)
- [API](#api-1)
  - [Superficies y contextos](#superficies-y-contextos)
  - [Estado gráfico](#estado-gráfico)
  - [Primitivas de trazado](#primitivas-de-trazado)
  - [Relleno y trazo](#relleno-y-trazo)
  - [Formas predefinidas](#formas-predefinidas)
  - [Imágenes](#imágenes)
- [Anti-patrones](#anti-patrones-1)

### [1.3 `pango.lua`](#13-pangolua)
- [Constantes](#constantes-2)
- [API](#api-2)
- [Anti-patrones](#anti-patrones-2)

### [1.4 `xkb.lua`](#14-xkblua)
- [Constantes](#constantes-3)
- [API](#api-3)
- [Anti-patrones](#anti-patrones-3)

### [1.5 `svg.lua`](#15-svglua)
- [API](#api-4)
- [Anti-patrones](#anti-patrones-4)

## [02. Infraestructura](#02-infraestructura)

### [2.1 `server.lua`](#21-serverlua)
- [Cómo funciona](#cómo-funciona)
- [API](#api-5)
- [Hook de eventos del root](#hook-de-eventos-del-root)
- [Uso típico](#uso-típico)
- [Anti-patrones](#anti-patrones-5)

### [2.2 `window.lua`](#22-windowlua)
- [Cómo funciona](#cómo-funciona-1)
- [API](#api-6)
- [Campos de `opts`](#campos-de-opts)
- [Diferencias entre `child` y `transient`](#diferencias-entre-child-y-transient)
- [Anti-patrones](#anti-patrones-6)

### [2.3 `theme.lua`](#23-themelua)
- [Cómo funciona](#cómo-funciona-2)
- [API](#api-7)
- [Campos de la tabla de tema](#campos-de-la-tabla-de-tema)
- [Anti-patrones](#anti-patrones-7)

### [2.4 `log.lua`](#24-loglua)
- [Cómo funciona](#cómo-funciona-3)
- [API](#api-8)
- [Anti-patrones](#anti-patrones-8)

### [2.5 `screens.lua`](#25-screenslua)
- [Cómo funciona](#cómo-funciona-4)
- [API](#api-9)
- [Anti-patrones](#anti-patrones-9)

### [2.6 `anim.lua`](#26-animlua)
- [Cómo funciona](#cómo-funciona-5)
- [API](#api-10)
- [Tipos de paso en `sequence`](#tipos-de-paso-en-sequence)
- [Opciones de `crossfade`](#opciones-de-crossfade)
- [Funciones de easing](#funciones-de-easing)
- [Handles de animación](#handles-de-animación)
- [Anti-patrones](#anti-patrones-10)

### [2.7 `xshape_anim.lua`](#27-xshape_animlua)
- [Cómo funciona](#cómo-funciona-6)
- [API](#api-11)
- [Campos de `opts` en `attach`](#campos-de-opts-en-attach)
- [Uso](#uso)
- [Anti-patrones](#anti-patrones-11)

## [03. Widgets](#03-widgets)

### [3.1 El contrato base: `Area`](#31-el-contrato-base-area)
- [Cómo funciona](#cómo-funciona-7)
- [API principal](#api-principal)
- [Callbacks de entrada](#callbacks-de-entrada)
- [Anti-patrones](#anti-patrones-12)

### [3.2 Contenedores](#32-contenedores)
- [`Group`](#group)
- [`Stack`](#stack)
- [`Card`](#card)

### [3.3 Navegación](#33-navegación)
- [`TabsBar`](#tabsbar)
- [`TabbedPanel`](#tabbedpanel)
- [`SidebarItem`](#sidebaritem)
- [`ScrollBar`](#scrollbar)
- [`ScrollView`](#scrollview)
- [`ScrollLink`](#scrolllink)

### [3.4 Entrada de usuario](#34-entrada-de-usuario)
- [`Button`](#button)
- [`TextInput`](#textinput)
- [`Dropdown`](#dropdown)
- [`RadioGroup`](#radiogroup)
- [`Gallery`](#gallery)
- [`ContextMenu`](#contextmenu)

### [3.5 Visualización](#35-visualización)
- [`Text`](#text)
- [`Header`](#header)
- [`Icon`](#icon)
- [`Bignum`](#bignum)
- [`KV`](#kv)
- [`Rows`](#rows)
- [`BarRow`](#barrow)
- [`Motors`](#motors)
- [`BarMulti`](#barmulti)
- [`Pills`](#pills)
- [`PillRow`](#pillrow)
- [`Ring`](#ring)
- [`Spark`](#spark)
- [`DualSpark`](#dualspark)
- [`PalettePreview`](#palettepreview)

### [3.6 Botones especializados](#36-botones-especializados)
- [`CardButton`](#cardbutton)
- [`LogoutButton`](#logoutbutton)
- [`CloseButton`](#closebutton)

### [3.7 Composición](#37-composición)
- [`Actions`](#actions)
- [`Intro`](#intro)
- [`RowParse`](#rowparse)

### [3.8 Convenciones del árbol de widgets](#38-convenciones-del-árbol-de-widgets)

## [04. Samplers del Sistema](#04-samplers-del-sistema)

### [4.1 Registro central](#41-registro-central)
- [`init.lua`](#initlua)

### [4.2 Hardware y recursos](#42-hardware-y-recursos)
- [`cpu.lua`](#cpulua)
- [`ram.lua`](#ramlua)
- [`gpu.lua`](#gpulua)
- [`temps.lua`](#tempslua)

### [4.3 Almacenamiento y red](#43-almacenamiento-y-red)
- [`disk.lua`](#disklua)
- [`net.lua`](#netlua)
- [`wifi.lua`](#wifilua)
- [`ping.lua`](#pinglua)

### [4.4 Estado del sistema y sesión](#44-estado-del-sistema-y-sesión)
- [`bat.lua`](#batlua)
- [`brightness.lua`](#brightnesslua)
- [`volume.lua`](#volumelua)
- [`users.lua`](#userslua)
- [`last_user.lua`](#last_userlua)
- [`session.lua`](#sessionlua)

### [4.5 Utilidades de datos](#45-utilidades-de-datos)
- [`config.lua`](#configlua)
- [`notes.lua`](#noteslua)
- [`search.lua`](#searchlua)
- [`launcher.lua`](#launcherlua)
- [`dispositivos.lua`](#dispositivoslua)
- [`inicio.lua`](#iniciolua)

### [4.6 Convenciones y anti-patrones](#46-convenciones-y-anti-patrones)

## [05. Integración con el Entorno](#05-integración-con-el-entorno)

### [5.1 `ewmh.lua`](#51-ewmhlua)
- [Cómo funciona](#cómo-funciona-8)
- [API](#api-12)
- [Uso](#uso-1)
- [Anti-patrones](#anti-patrones-13)

### [5.2 `greetd.lua`](#52-greetdlua)
- [Cómo funciona](#cómo-funciona-9)
- [API](#api-13)
- [Tipos de mensaje recibidos por el callback](#tipos-de-mensaje-recibidos-por-el-callback)
- [Uso](#uso-2)
- [Anti-patrones](#anti-patrones-14)

### [5.3 `reload.lua`](#53-reloadlua)
- [Cómo funciona](#cómo-funciona-10)
- [API](#api-14)
- [Uso](#uso-3)
- [Anti-patrones](#anti-patrones-15)

### [5.4 `xsessions.lua`](#54-xsessionslua)
- [Cómo funciona](#cómo-funciona-11)
- [API](#api-15)
- [Uso](#uso-4)
- [Anti-patrones](#anti-patrones-16)

### [5.5 `wallpaper.lua`](#55-wallpaperlua)
- [Cómo funciona](#cómo-funciona-12)
- [API](#api-16)
- [Uso](#uso-5)
- [Anti-patrones](#anti-patrones-17)

### [5.6 `thumbs.lua`](#56-thumbslua)
- [Cómo funciona](#cómo-funciona-13)
- [API](#api-17)
- [Uso](#uso-6)
- [Anti-patrones](#anti-patrones-18)

### [5.7 `icon_theme.lua`](#57-icon_themelua)
- [Cómo funciona](#cómo-funciona-14)
- [API](#api-18)
- [Uso](#uso-7)
- [Anti-patrones](#anti-patrones-19)

### [5.8 `icons.lua`](#58-iconslua)
- [Cómo funciona](#cómo-funciona-15)
- [API](#api-19)
- [Uso](#uso-8)
- [Anti-patrones](#anti-patrones-20)

## [06. Helpers](#06-helpers)

### [6.1 `util.lua`](#61-utillua)
- [API](#api-20)
- [Anti-patrones](#anti-patrones-21)

### [6.2 `format.lua`](#62-formatlua)
- [API](#api-21)
- [Notas](#notas)

### [6.3 `async.lua`](#63-asynclua)
- [Cómo funciona](#cómo-funciona-16)
- [API](#api-22)
- [Uso](#uso-9)
- [Anti-patrones](#anti-patrones-22)

### [6.4 `graphics.lua`](#64-graphicslua)
- [API](#api-23)
- [Opciones de `sparkline`](#opciones-de-sparkline)
- [Anti-patrones](#anti-patrones-23)

### [6.5 `json.lua`](#65-jsonlua)
- [Cómo funciona](#cómo-funciona-17)
- [Convenciones del encoder](#convenciones-del-encoder)
- [Marcadores públicos](#marcadores-públicos)
- [API](#api-24)
- [Uso](#uso-10)
- [Anti-patrones](#anti-patrones-24)

### [6.6 `init.lua`](#66-initlua)
# 01. Núcleo Gráfico (Core FFI)

Bindings FFI puros sobre las librerías C del sistema. Esta capa no conoce el concepto de "widget" ni de "ventana"; solo expone las funciones de las librerías nativas de forma segura y directa a LuaJIT.

---

## 1.1 `xcb.lua`

**Propósito**  
Wrapper FFI sobre `libxcb`, `libxcb-util`, `libxcb-icccm` y `libxcb-shape`. Expone las operaciones del protocolo X11: conexión, creación de ventanas, eventos, átomos, propiedades, hints ICCCM, foco, pixmaps, GC y máscaras de recorte.

**Cómo funciona**  
Al cargar, hace `ffi.load("xcb")` y `ffi.load("libxcb-util.so.1")`. Las librerías `libxcb-icccm.so.4` y `libxcb-shape.so.0` se cargan de forma lazy, solo cuando se invoca la primera función que las requiere. Las funciones de creación de ventanas, pixmaps y GC usan las variantes `_checked` seguidas de `xcb_request_check`, lo que permite detectar errores del servidor de forma temprana en lugar de fallar silenciosamente.

**Dependencias**  
`libxcb`, `libxcb-util.so.1`, `libxcb-icccm.so.4` (lazy), `libxcb-shape.so.0` (lazy).

### Constantes

| Constante | Contenido |
|---|---|
| `CW` | Bits del `value_mask` de `create_window`: `BackPixmap`, `BackPixel`, `BorderPixmap`, `BorderPixel`, `BitGravity`, `WinGravity`, `BackingStore`, `BackingPlanes`, `BackingPixel`, `OverrideRedirect`, `SaveUnder`, `EventMask`, `DontPropagate`, `Colormap`, `Cursor`. |
| `CONFIG` | Bits del `value_mask` de `configure_window`: `X`, `Y`, `Width`, `Height`, `Border`, `Sibling`, `Stack`. |
| `PROP_MODE` | Modos de `change_property`: `Replace`, `Prepend`, `Append`. |
| `EVENT_MASK` | Máscara de eventos: `KeyPress`, `KeyRelease`, `ButtonPress`, `ButtonRelease`, `EnterWindow`, `LeaveWindow`, `PointerMotion`, `Exposure`, `VisibilityChange`, `StructureNotify`, `ResizeRedirect`, `SubstructureNotify`, `SubstructureRedirect`, `FocusChange`, `PropertyChange`, `ColormapChange`. |
| `EVENT` | Códigos numéricos de evento: `KeyPress = 2`, `Expose = 12`, `ConfigureNotify = 22`, `ClientMessage = 33`, etc. |
| `WIN_CLASS` | `CopyFromParent`, `InputOutput`, `InputOnly`. |
| `ICCCM` | Flags de `WM_NORMAL_HINTS` (`US_POSITION`, `US_SIZE`, `P_POSITION`, `P_SIZE`, `P_MIN_SIZE`, `P_MAX_SIZE`, `P_RESIZE_INC`, `P_ASPECT`, `BASE_SIZE`, `P_WIN_GRAVITY`) y de `WM_HINTS` (`WM_HINT_INPUT`). |
| `IMAGE_FORMAT` | Formatos de `put_image`: `XYBitmap` (0), `XYPixmap` (1), `ZPixmap` (2). |
| `SHAPE_OP` | Operaciones de XShape: `Set`, `Union`, `Intersect`, `Subtract`, `Invert`. |
| `SHAPE_KIND` | Tipos de máscara XShape: `Bounding`, `Clip`, `Input`. |

### API

**Conexión**

| Función | Retorno | Notas |
|---|---|---|
| `connect(displayname?)` | `conn, screen_num` | Lanza `error` si falla. `displayname` nulo usa la variable de entorno `DISPLAY`. |
| `disconnect(conn)` | — | Cierra la conexión. |
| `flush(conn)` | — | Fuerza el envío de la cola de peticiones pendientes. |
| `sync(conn)` | — | Realiza un round-trip al servidor. Fuerza el procesamiento de lo pendiente. |
| `get_file_descriptor(conn)` | `fd` | Descriptor para usar con `poll(2)`. |
| `generate_id(conn)` | `id` | Genera un identificador X11 único (window, pixmap, GC, átomo). |
| `now_ms()` | `ms` | Milisegundos del reloj de pared. Lee `gettimeofday`. |

**Pantalla y visual**

| Función | Retorno |
|---|---|
| `get_screen(conn, idx?)` | `xcb_screen_t*`. Por defecto `idx = 0`. |
| `get_visualtype(conn, screen_idx, visual_id)` | `xcb_visualtype_t*`. |

**Ventanas**

| Función | Retorno | Notas |
|---|---|---|
| `create_window(conn, opts)` | `wid, screen` o `nil, screen, err` | Hace `request_check`. El `value_list` debe ir en el orden de los bits del protocolo. |
| `map_window(conn, wid)` | — | Hace `flush` internamente. |
| `unmap_window(conn, wid)` | — | |
| `destroy_window(conn, wid)` | — | |
| `configure_window(conn, wid, mask, values)` | — | `values` es una tabla con los campos `x`, `y`, `width`, `height`, `border`, `sibling`, `stack`. Solo se envían los valores cuyos bits estén activos en `mask`. |

**Campos de `opts` en `create_window`**: `screen`, `parent`, `x`, `y`, `width`, `height`, `border_width`, `depth`, `class`, `visual`, `background_pixel`, `background_pixmap`, `border_pixel`, `override_redirect`, `backing_store`, `event_mask`.

**Átomos y propiedades**

| Función | Retorno | Notas |
|---|---|---|
| `intern_atom(conn, name, only_if_exists?)` | `atom` o `0` | Devuelve `0` si falla. |
| `change_property(conn, win, prop, ptype, format, data_len, data)` | — | Siempre modo `Replace`. `format` es 8, 16 o 32. |
| `get_property(conn, win, prop, ptype, long_length)` | tabla `{ type, format, data }` o `nil` | `ptype = 0` significa cualquier tipo. `format = 8` devuelve string, `16` o `32` devuelven tabla de enteros. |
| `change_window_attributes(conn, win, mask)` | — | Modifica los atributos de la ventana. Típicamente se usa para suscribir `PropertyChange` en el root. |
| `change_window_attributes_values(conn, win, mask, values)` | — | Variante genérica. `values` es un array en el orden de los bits del mask. |
| `send_event(conn, dest, event_mask, ev)` | — | Envía un evento X11 arbitrario. `ev` es una tabla con `window`, `type`, `format`, `data` (array de hasta 5 números). |
| `send_client_message_root(conn, root, ev)` | — | Atajo que envía un `ClientMessage` al root con la máscara estándar de EWMH (`SubstructureRedirect \| SubstructureNotify`). |

**Hints, foco y puntero**

| Función | Notas |
|---|---|
| `set_wm_normal_hints(conn, win, hints)` | `hints` con campos opcionales: `x`, `y`, `width`, `height`, `min_width`, `min_height`, `max_width`, `max_height`, `width_inc`, `height_inc`, `min_aspect_num`, `min_aspect_den`, `max_aspect_num`, `max_aspect_den`, `base_width`, `base_height`, `flags`. |
| `set_wm_hints(conn, win, hints)` | `hints.input` booleano. |
| `set_input_focus(conn, wid, revert_to?)` | Por defecto `revert_to = 2` (Parent). Time `0` significa `CurrentTime`. |
| `set_input_focus_revert(conn)` | Devuelve el foco a `PointerRoot` con `RevertToParent`. Usado como fallback. |
| `get_input_focus(conn)` | Window id con foco de teclado, o `0`. |
| `query_pointer(conn)` | `x, y` en coordenadas raíz, o `nil, nil`. Requiere el root como ventana válida. |
| `grab_pointer(conn, window)` | Captura botones y movimiento. Los eventos llegan al `window` especificado con coordenadas relativas a él. |
| `ungrab_pointer(conn)` | Libera la captura. |

**Pixmaps, GC y PutImage**

| Función | Notas |
|---|---|
| `create_pixmap_checked(conn, depth, pid, drawable, w, h)` | Devuelve el cookie `_checked`. Se verifica con `check_cookie`. |
| `free_pixmap(conn, pid)` | Libera el pixmap. |
| `create_gc_checked(conn, cid, drawable)` | Crea un graphics context con valores por defecto. |
| `free_gc(conn, gc)` | Libera el GC. |
| `put_image_checked(conn, drawable, gc, w, h, x, y, depth, format, data)` | Sube una imagen cruda al servidor. `data` es un string Lua con los bytes. |
| `check_cookie(conn, cookie, context)` | Devuelve `nil` si la operación fue aceptada, o un string descriptivo del error. Libera el struct de error internamente. |

**XShape**

| Función | Notas |
|---|---|
| `shape_rectangles(conn, wid, rects, opts)` | `rects` es una lista de `{x, y, w, h}`. `opts.op` es un valor de `SHAPE_OP`, `opts.kind` es `SHAPE_KIND.Bounding` o `SHAPE_KIND.Input`. |
| `shape_clear(conn, wid, kind)` | Elimina la máscara. |
| `shape_mask(conn, wid, pixmap, x, y, opts)` | Usa un pixmap de 1 bit como máscara. |
| `shape_combine(conn, dst, src, opts)` | Combina la máscara de dos ventanas. |
| `shape_offset(conn, wid, x, y, kind)` | Desplaza la máscara existente. |
| `shape_rounded_rect(conn, wid, w, h, r, visible_h)` | Helper de alto nivel: genera la máscara redondeada con fusión de runs y opción de altura visible para el efecto de cortina. |

**Teclado**

| Función | Retorno | Notas |
|---|---|---|
| `query_keymap(conn)` | `keys` | Devuelve los 32 bytes del estado del teclado. |
| `key_pressed(keys, keycode)` | `bool` | Consulta si una tecla está presionada. |

**Eventos**

| Función | Retorno | Notas |
|---|---|---|
| `poll_event(conn)` | `ev` o `nil` | No bloquea. Devuelve `nil` cuando no hay más eventos. El evento debe liberarse con `ffi.C.free(ev)`. |

### Anti-patrones

- **No ignorar el tercer retorno de `create_window`.** Un `value_list` desordenado produce `BadValue` silencioso en top-level y error explícito en child windows.
- **No asumir que `poll_event` refleja lo que hay en el socket.** Consulta primero el buffer interno de XCB; el socket puede estar vacío con eventos pendientes.
- **No pasar `0` como window id a `query_pointer`.** Debe ser un id válido, normalmente el root.
- **No confundir `EVENT` con `EVENT_MASK`.** Son tablas distintas: códigos de evento contra bits de máscara. Confundirlas produce errores de tipo al operar con `bit.bor`.
- **No olvidar liberar los eventos con `ffi.C.free(ev)`.** `free` está en libc, no en libxcb. Se invoca con `ffi.C.free`.

---

## 1.2 `cairo.lua`

**Propósito**  
Wrapper FFI sobre `libcairo.so.2`. Superficies, contextos, primitivas de dibujo, formas redondeadas, carga de PNG, cache y tintado de iconos.

**Cómo funciona**  
Todas las funciones de creación verifican el status de Cairo inmediatamente y lanzan `error` si no es `0`. `load_png_cached` mantiene una tabla global de rutas a superficies. `draw_surface_tinted` construye una superficie temporal ARGB32 y aplica el operador `IN` para preservar el canal alfa del icono original.

**Dependencias**  
`libcairo.so.2`.

### Constantes

| Constante | Contenido |
|---|---|
| `OPERATOR` | `CLEAR`, `SOURCE`, `OVER`, `IN`, `OUT`, `ATOP`, `DEST`, `DEST_OVER`, `DEST_IN`, `DEST_OUT`, `DEST_ATOP`, `XOR`, `ADD`, `SATURATE`, `MULTIPLY`. |
| `FORMAT` | `ARGB32` (0), `RGB24` (1), `A8` (2), `A1` (3). |
| `FILTER` | `FAST` (0), `GOOD` (1), `BEST` (2), `NEAREST` (3), `BILINEAR` (4). |

### API

**Superficies y contextos**

| Función | Retorno | Notas |
|---|---|---|
| `surface_for_window(conn, drawable, visualtype, w, h)` | surface | Superficie XCB. Lanza `error` si el status no es 0. |
| `image_surface_create(w, h, format?)` | surface | Formato por defecto `ARGB32`. |
| `context(surface)` | `cairo_t*` | Lanza `error` si el status no es 0. |
| `destroy_context(cr)` | — | Libera el contexto. |
| `destroy_surface(s)` | — | Libera la superficie. |
| `flush_surface(s)` | — | Necesario tras escribir a mano en el búfer de la superficie. |
| `surface_width(s)` / `surface_height(s)` | `int` | Dimensiones de la superficie de imagen. |

**Estado gráfico**

`save`, `restore`, `translate`, `scale`, `clip`, `clip_preserve`, `new_path`, `new_sub_path`, `set_operator`, `set_line_width`, `set_source_rgb`, `set_source_rgba`, `set_source_surface`, `get_source`, `set_filter`.

**Primitivas de trazado**

`move_to`, `line_to`, `rectangle`, `arc`, `close_path`.

**Relleno y trazo**

`fill`, `stroke`, `fill_preserve`, `stroke_preserve`, `paint`, `paint_with_alpha`.

**Formas predefinidas**

| Función | Notas |
|---|---|
| `rounded_rect(cr, x, y, w, h, r)` | Clampea `r` a la mitad del menor lado. Usa `new_sub_path` internamente para cada arco. |

**Imágenes**

| Función | Retorno | Notas |
|---|---|---|
| `load_png(path)` | surface o `nil, msg` | Sin cache. |
| `load_png_cached(path)` | surface o `nil, msg` | Cache global por ruta. |
| `clear_surface_cache()` | — | Libera todas las superficies cacheadas. |
| `write_png(surface, path)` | `bool` | Guarda una superficie a disco. |
| `draw_surface(cr, s, x, y, w?, h?, filter?)` | — | Escala al tamaño especificado. Si `w` y `h` son nulos, usa el tamaño nativo. |
| `draw_surface_tinted(cr, s, x, y, w, h, r, g, b)` | — | Tintado monocromo preservando el alfa original. |

### Anti-patrones

- **No llamar `arc` sin `new_path` o `new_sub_path` antes.** El path anterior se arrastra y produce líneas diagonales no deseadas.
- **No usar `draw_surface_tinted` sobre iconos en color.** El operador `IN` colapsa la imagen a un solo color plano.
- **No llamar `load_png_cached` en cada frame tras un cambio de tema.** Llamar `clear_surface_cache()` para liberar el cache previo.
- **No olvidar `flush_surface` tras escribir a mano en `cairo_image_surface_get_data`.** Sin el flush, Cairo no propaga los cambios.

---

## 1.3 `pango.lua`

**Propósito**  
Dibujo y medición de texto con Pango y Cairo, y traducción de entidades HTML a Unicode.

**Cómo funciona**  
Inicializa fontconfig con `FcInit()` al cargar. Cada llamada a `measure` o a las funciones de dibujo crea un layout temporal, lo aplica y lo destruye. El módulo no mantiene cache de layouts: para textos repetidos conviene medir una vez y guardar el resultado en el consumidor.

**Dependencias**  
`libpango-1.0.so.0`, `libpangocairo-1.0.so.0`, `libgobject-2.0.so.0`, `libcairo.so.2`, `libfontconfig.so.1`.

### Constantes

| Constante | Contenido |
|---|---|
| `ALIGN` | `LEFT` (0), `CENTER` (1), `RIGHT` (2). |
| `WRAP` | `WORD` (0), `CHAR` (1), `WORD_CHAR` (2). |

### API

| Función | Retorno | Notas |
|---|---|---|
| `measure(text, font?)` | `w, h` | Crea un layout y una superficie dummy 1×1. No llamar en bucles por frame. |
| `draw_text(cr, x, y, text, font?, opts?)` | — | Texto plano. `opts`: `r`, `g`, `b`, `wrap_width`, `wrap`, `align`. |
| `draw_markup(cr, x, y, markup, font?, opts?)` | — | Texto con markup Pango. Pasa por `html_entities` automáticamente. |
| `html_entities(s)` | string | Traduce entidades HTML con nombre (`&middot;`, `&times;`, etc.) a Unicode. Respeta las cinco básicas de XML para que Pango las procese. |
| `escape(s)` | string | Escapa `&`, `<` y `>` para construir markup seguro a partir de texto plano. |

### Anti-patrones

- **No llamar `measure` dentro de `on_draw`.** Se paga cada frame. Medir una vez y cachear en el consumidor.
- **No pasar texto del usuario a `draw_markup` sin `escape`.** Los caracteres `<` y `&` rompen el layout de Pango.

---

## 1.4 `xkb.lua`

**Propósito**  
Traducción de keycodes X11 a keysym, nombre, texto UTF-8 y modificadores, vía `libxkbcommon`.

**Cómo funciona**  
Encapsula el contexto, el keymap y el estado de xkbcommon en una tabla `State` con métodos. Al decodificar un evento de tecla, actualiza el estado interno antes de leer el texto, lo que garantiza que Shift y otros modificadores produzcan el resultado correcto.

**Dependencias**  
`libxkbcommon.so.0`.

### Constantes

| Constante | Contenido |
|---|---|
| `KEY_UP` | `0`. Dirección de liberación de tecla. |
| `KEY_DOWN` | `1`. Dirección de pulsación. |
| `X11_MOD` | Máscaras X11: `SHIFT` (1), `LOCK` (2), `CTRL` (4), `MOD1` (8, típicamente Alt), `MOD2` (16, NumLock), `MOD3` (32), `MOD4` (64, típicamente Super), `MOD5` (128). |
| `SYM` | Tabla de keysyms conocidos: `RETURN`, `ESCAPE`, `BACKSPACE`, `TAB`, `SPACE`, `DELETE`, `HOME`, `END`, `PAGE_UP`, `PAGE_DOWN`, `LEFT`, `UP`, `RIGHT`, `DOWN`, `F1` a `F12`. |

### API

| Función / Método | Retorno | Notas |
|---|---|---|
| `new_state(names?)` | `State` | `names` puede ser `nil` (usa variables de entorno `XKB_DEFAULT_*`) o una tabla con `rules`, `model`, `layout`, `variant`, `options`. |
| `from_name(name)` | keysym | Convierte un nombre de keysym a su valor numérico. Útil para definir atajos por nombre. |
| `State:update_key(keycode, dir)` | — | Actualiza el estado interno. `dir` es `KEY_DOWN` o `KEY_UP`. |
| `State:key_sym(keycode)` | keysym | Devuelve `0` si la tecla no está mapeada. |
| `State:key_name(keycode)` | string | Nombre del keysym: `"Return"`, `"F1"`, `"a"`, etc. |
| `State:key_utf8(keycode)` | string | Carácter UTF-8 producido. Cadena vacía para teclas que no generan texto. |
| `State:decode_mods(x11_state)` | tabla | Devuelve `{ shift, lock, ctrl, alt, num, mod3, super, mod5 }`. |
| `State:make_event(keycode, x11_state, pressed)` | tabla | Devuelve `{ keycode, sym, name, text, mods, raw_mods, pressed }`. Actualiza el estado interno con la tecla antes de leer el resultado. |
| `State:destroy()` | — | Libera estado, keymap y contexto. |

### Anti-patrones

- **No leer `key_utf8` sin llamar antes a `make_event` o a `update_key`.** El estado interno queda desincronizado y Shift deja de funcionar.
- **No reutilizar una instancia de `State` entre ventanas con layouts distintos.** El keymap es único por instancia.

---

## 1.5 `svg.lua`

**Propósito**  
Renderizado de SVG a superficies Cairo mediante `resvg`. Proporciona cache de superficies por combinación de ruta y tamaño.

**Cómo funciona**  
Sustituye a la integración previa con librsvg. `resvg` es una biblioteca autocontenida escrita en Rust, con ABI C estable y dependencia única de fontconfig. El consumo de memoria de la biblioteca es de aproximadamente 3 MB frente a los 20 MB que arrastraba librsvg con toda la pila de GNOME.

`resvg_render` escribe en un búfer RGBA premultiplicado. La conversión a una superficie Cairo con formato `ARGB32` se realiza invirtiendo el orden de los canales rojo y azul en cada píxel.

**Dependencias**  
`libresvg.so.0.48` (cargada por ruta absoluta, ya que Void Linux no registra el symlink en el caché de ldconfig).

### API

| Función | Retorno | Notas |
|---|---|---|
| `load(path, w?, h?)` | surface o `nil, err` | Cachea por combinación `path:WxH`. Si se especifican `w` y `h`, renderiza al tamaño exacto. Si solo uno, calcula el otro respetando el aspect ratio. Si ninguno, usa el tamaño intrínseco del SVG. |
| `invalidate(path)` | — | Destruye todas las entradas del cache correspondientes a la ruta dada, en cualquier tamaño. |
| `clear_cache()` | — | Libera todas las superficies cacheadas. |

### Anti-patrones

- **No llamar `load` en cada frame.** Cada llamada fallida reintenta leer del disco. Usar el cache.
- **No asumir que el SVG respeta su tamaño natural.** Se renderiza al tamaño especificado o al intrínseco del archivo, no a 64×64 como en la versión anterior basada en librsvg.
- **No compartir superficies de SVG entre procesos.** El cache es local al proceso y se libera al terminar.
# 02. Infraestructura

Servicios de alto nivel que gestionan el ciclo de vida, el renderizado, el estado y la comunicación con el sistema. Ningún widget debe comunicarse directamente con XCB; debe hacerlo a través de esta capa.

---

## 2.1 `server.lua`

**Propósito**  
Bucle de eventos basado en `poll(2)`. Gestiona la conexión XCB, los timers, los descriptores externos, la observación de archivos trigger y el enrutamiento de eventos X11 a las ventanas registradas.

**Cómo funciona**  
Mantiene la conexión XCB y un bucle principal que ejecuta las siguientes fases en cada iteración:

1. Vacía el buffer interno de eventos de XCB mediante `xcb_poll_for_event`. Este paso es obligatorio: las operaciones síncronas como `xcb_sync` o `xcb_intern_atom_reply` pueden haber leído eventos del socket y guardado en el buffer interno, dejando el descriptor sin datos pendientes aunque haya eventos por procesar.
2. Si no había eventos, bloquea en `poll(2)` esperando actividad en el descriptor de XCB, los timers o los descriptores externos registrados.
3. Ejecuta los callbacks de timers vencidos y verifica la existencia del archivo trigger.
4. Procesa los descriptores externos que estén listos.
5. Llama a `Window:draw()` en todas las ventanas registradas.

Si el descriptor de XCB reporta `POLLHUP`, `POLLERR` o `POLLNVAL`, el bucle termina de inmediato. Esto ocurre cuando el cliente se cierra por `XKillClient` o cuando el servidor X finaliza. Sin esta comprobación, `poll` devolvería inmediatamente en cada iteración y el proceso entraría en un bucle de CPU al 100%.

**Dependencias**  
`lib.xcb`, `lib.log`, `lib.poll`, `lib.timer`.

### API

| Función / Método | Parámetros | Retorno | Notas |
|---|---|---|---|
| `Server.new(opts)` | `opts.displayname`, `opts.exit_on_empty` | `server` | `exit_on_empty` (por defecto `true`) termina el bucle cuando no quedan ventanas. |
| `server:add_window(win)` | `win` (instancia de `Window`) | — | Registra la ventana para recibir eventos y ser dibujada en cada ciclo. |
| `server:remove_window(win)` | `win` | — | Desregistra la ventana. |
| `server:count()` | — | `int` | Número de ventanas registradas. |
| `server:add_timer(ms, cb)` | `interval_ms`, `callback` | `handle` | Timer no repetitivo. El handle expone `handle:cancel()`. |
| `server:add_fd(fd, cb)` | `fd` (número), `callback` | `fd` | Registra un descriptor externo. El callback se invoca cuando el descriptor está listo para lectura. |
| `server:watch_trigger(path, cb)` | `path` (string), `callback` | — | Observa un archivo. Al aparecer, lee su contenido, lo borra y llama al callback con ese contenido. |
| `server:cancel_all_timers()` | — | — | Cancela todos los timers registrados. |
| `server:flush()` | — | — | Fuerza el envío de la cola de peticiones pendientes a XCB. |
| `server:stop()` | — | — | Detiene el bucle al final del ciclo actual. |
| `server:run()` | — | — | Inicia el bucle. Bloquea hasta `server:stop()` o hasta que se cumpla la condición de `exit_on_empty`. |

### Hook de eventos del root

`server.on_root_event` es una función opcional que el bucle invoca para los eventos dirigidos al root de la pantalla. El módulo `lib.ewmh` la utiliza para procesar las notificaciones de cambio de propiedades. El hook recibe `(etype, ev)`.

### Uso típico

Una aplicación con una sola ventana crea el servidor, la ventana y entra en el bucle:

```lua
local Server = require("lib.server")
local Window = require("lib.window")

local srv = Server.new()
local win = Window.new(srv, { title = "App", width = 400, height = 300 })
win:set_root(root_widget)
win:run()
```

Una aplicación con múltiples ventanas comparte el mismo servidor:

```lua
local srv = Server.new()
local win1 = Window.new(srv, { ... })
local win2 = Window.new(srv, { ... })
srv:run()
```

Los daemons con trigger file pasan `exit_on_empty = false` para permanecer activos aunque no haya ventanas:

```lua
local srv = Server.new({ exit_on_empty = false })
srv:watch_trigger("/tmp/panel.cmd", function(cmd)
    if cmd == "show" then open_panel(srv) end
end)
srv:run()
```

### Anti-patrones

- **No bloquear el bucle dentro de un callback.** Un timer o un callback de trigger que ejecute un comando lento bloquea el repintado y el procesamiento de eventos X11. Para operaciones que tardan más de 50 ms, usar `lib.helpers.async`.
- **No registrar timers con intervalos muy cortos en masa.** El `poll` se reprograma con el vencimiento más cercano, pero una acumulación de timers de pocos milisegundos impide que el bucle descanse.
- **No llamar `server:run()` dos veces.** El bucle no está diseñado para reentrar. Una vez detenido, el servidor no puede reanudarse.

---

## 2.2 `window.lua`

**Propósito**  
Gestión de ventanas X11 con doble buffer, seguimiento selectivo de daños, foco de teclado, overlays para composición y enrutamiento de eventos al árbol de widgets.

**Cómo funciona**  
Cada ventana mantiene dos superficies Cairo:

1. `image_surface`: búfer en memoria donde los widgets dibujan mediante un contexto `image_cr`. Se crea con formato `RGB24`.
2. `surface`: superficie XCB que refleja los píxeles visibles.

En cada ciclo, `Window:draw()` calcula la unión de los rectángulos marcados como dañados. Si la unión cubre más del 80 % del área o si hay un overlay activo, ejecuta un redibujado completo. En caso contrario, aplica un clip a la superficie de imagen y redibuja únicamente las zonas sucias. Después copia la región dañada a la superficie XCB y hace `flush`.

El algoritmo de unión de rectángulos divide el área de la ventana en una grilla de 16 × 16 celdas y cuenta cuántas están cubiertas por al menos un rectángulo de daño. Es más robusto que contar rectángulos individuales, ya que una ráfaga de eventos `MotionNotify` puede generar decenas de rectángulos pequeños que en conjunto cubren una fracción mínima de la ventana.

**Dependencias**  
`lib.xcb`, `lib.cairo`, `lib.server`, `lib.xkb`, `lib.screens` (carga diferida).

### API

| Método | Parámetros | Retorno | Notas |
|---|---|---|---|
| `Window.new(server, opts)` | `opts` (ver sección siguiente) | `window` | Crea la ventana X11, las superficies Cairo y el estado de teclado. |
| `Window.new(opts)` | `opts` | `window` | Variante que crea un servidor nuevo internamente. Útil para aplicaciones de una sola ventana. |
| `win:set_root(area)` | `area` (instancia de `Area`) | — | Establece el árbol de widgets, ejecuta el layout inicial y dibuja. |
| `win:set_title(title)` | `title` (string) | — | Actualiza `_NET_WM_NAME` y `WM_NAME`. |
| `win:move(x, y)` | `x`, `y` (números) | — | Mueve la ventana. Para ventanas top-level es una petición al WM; para child se aplica directamente. |
| `win:move_by(dx, dy)` | `dx`, `dy` | — | Desplaza la ventana de forma relativa. |
| `win:add_damage(x0, y0, x1, y1)` | Coordenadas absolutas del rectángulo | — | Añade una región a la lista de daño. |
| `win:damage_all()` | — | — | Marca la ventana completa para redibujado. |
| `win:set_input_focus()` | — | — | Solicita el foco de teclado. Guarda la ventana previamente enfocada para restaurarla. |
| `win:restore_input_focus()` | — | — | Devuelve el foco a la ventana previa o a `PointerRoot`. |
| `win:restore_parent_focus()` | — | — | Devuelve el foco a la ventana padre. Usado por ventanas child. |
| `win:set_focus_widget(widget)` | `widget` (instancia de `Area`) | — | Asigna el foco de teclado a un widget específico del árbol. |
| `win:clear_focus_widget()` | — | — | Elimina el foco del widget actual. |
| `win:set_overlay(surface, x, y, alpha)` | `surface`, `x`, `y`, `alpha` | — | Dibuja una superficie encima del árbol, con el nivel de opacidad indicado. Usado por los crossfades. |
| `win:clear_overlay()` | — | — | Elimina el overlay y marca la ventana completa como dañada. |
| `win:close(reason)` | `reason` (string) | — | Invoca el callback `on_close`, marca la ventana como cerrada y libera los recursos. |
| `win:run()` | — | — | Atajo que invoca `server:run()`. |

### Campos de `opts`

**Geometría**

- `width`, `height`: número en píxeles, `"screen"`, `"auto"`, `"free"` (0) o `"N%"`.
- `x`, `y`: número en píxeles, `"center"` o `"cursor-screen"` (centrado en el monitor del cursor).
- `min_width`, `min_height`, `max_width`, `max_height`: límites publicados vía `WM_NORMAL_HINTS`.
- `aspect`: relación de aspecto expresada como número decimal.
- `strut`: tabla con los campos `left`, `right`, `top`, `bottom` y los rangos `*_start`, `*_end`. Reserva espacio en el escritorio.

**Comportamiento**

- `kind`: `"normal"`, `"dock"`, `"dialog"`, `"menu"`, `"child"`, `"transient"` o `"desktop"`.
- `title`: título publicado en `_NET_WM_NAME` y `WM_NAME`.
- `parent_window`: instancia de `Window` de la que esta ventana depende. Aplica a `kind = "child"` y `kind = "transient"`.
- `override_redirect`: si es `true`, el gestor de ventanas ignora la ventana. Se activa implícitamente para `kind = "menu"`, `kind = "desktop"` y ventanas child.
- `disable_q_close`: si es `true`, la tecla `q` sin modificadores no cierra la ventana. Útil en aplicaciones con campos de texto.
- `app_name`, `class_name`: identificadores publicados en `WM_CLASS`.
- `background_pixel`, `background_pixmap`, `backing_store`, `event_mask`: pasan directamente a `xcb_create_window`.

**Callbacks**

- `on_draw(cr, w, h)`: se invoca antes de dibujar el árbol de widgets. Se usa habitualmente para pintar el fondo.
- `on_close()`: se invoca al cerrar la ventana.
- `on_resize(w, h)`: se invoca tras un cambio de tamaño.
- `on_key(key)`: recibe los eventos de teclado no consumidos por el widget con foco.
- `on_mouse(x, y, button, state)`: hook global para clics no consumidos por el árbol.
- `on_mouse_move(x, y)`: hook global para movimientos del puntero.
- `on_mouse_release(x, y, button, state)`: hook global para liberaciones de botón.
- `on_focus_in()`, `on_focus_out()`: notificaciones de cambio de foco.
- `on_measure()`: función que devuelve el tamaño mínimo cuando `width` o `height` son `"auto"`.

### Diferencias entre `child` y `transient`

Ambos tipos declaran `WM_TRANSIENT_FOR` apuntando a la ventana padre, pero su relación con la jerarquía X es distinta.

- `child`: se crea como ventana X hija de la ventana padre. Comparte su ciclo de vida con el padre en el servidor X. Los eventos de ratón llegan con coordenadas relativas al padre. El WM no interviene en su gestión.
- `transient`: se crea como ventana top-level con `WM_TRANSIENT_FOR` publicado. El WM la gestiona como cualquier otra ventana, pero la asocia a la padre para efectos de apilamiento, minimización y foco.

Los diálogos modales con decoración del WM se implementan como `transient`. Los menús contextuales y popups sin decoración se implementan como `child`.

### Anti-patrones

- **No crear una instancia de `Server` por ventana.** Todas las ventanas de un mismo proceso deben compartir el mismo servidor.
- **No llamar `damage_all()` ante cualquier cambio.** El seguimiento de daños existe precisamente para evitarlo.
- **No usar `kind = "dock"` sin especificar `strut`.** El WM no reservará espacio y otras ventanas se solaparán.
- **No usar `"N%"` como tamaño en configuraciones multi-monitor sin verificar la geometría.** Los porcentajes se calculan sobre la pantalla virtual, que abarca todos los monitores. Un 70 % de la pantalla virtual puede exceder las dimensiones de cualquier monitor individual.

---

## 2.3 `theme.lua`

**Propósito**  
Carga de paletas de colores, gestión de la paleta activa y recarga en caliente.

**Cómo funciona**  
Resuelve la paleta activa en este orden:

1. Variable de entorno `LANETK_PALETTE`. Si contiene una ruta absoluta, se usa directamente. Si contiene un nombre, se busca en el directorio de paletas.
2. Archivo `~/.config/lanetk/palette`. Contiene el nombre de la paleta a usar.
3. Paleta por defecto: `gruvbox-warm.lua`.

El directorio de paletas se localiza ascendiendo desde la ubicación del propio módulo hasta encontrar una carpeta llamada `palettes`. Si no se encuentra, se usa la ruta indicada por la variable de entorno `THEME_PALETTES_DIR`. El archivo de configuración puede sobreescribirse con `THEME_CONFIG_FILE`.

La recarga en caliente se realiza mediante `reload_in_place`, que muta la tabla de tema existente en lugar de crear una nueva. Los consumidores que mantienen una referencia a la tabla ven los cambios. Después de la mutación, el módulo notifica a los observadores registrados mediante `watch`.

**Dependencias**  
`lib.helpers.graphics` para la conversión de valores hexadecimales a componentes RGB.

### API

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `load(path?)` | `path` (opcional) | tabla de tema | Si `path` es nulo, resuelve la paleta activa. |
| `find_palette_path()` | — | string | Ruta absoluta de la paleta resuelta. |
| `list_palettes()` | — | tabla | Nombres de las paletas disponibles, sin extensión, ordenados alfabéticamente. |
| `palette_path(name)` | `name` (string) | string | Ruta completa de la paleta indicada por nombre. |
| `reload_in_place(T, path?)` | `T` (tabla de tema), `path` | `bool` o `bool, err` | Muta la tabla en su lugar. Notifica a los observadores al terminar. |
| `watch(fn)` | `fn` (callback) | `fn` | Registra una función que se ejecuta tras cada `reload_in_place`. Devuelve la misma función. |
| `unwatch(fn)` | `fn` | `bool` | Elimina el observador. |

### Campos de la tabla de tema

**Rutas**

- `path`: ruta absoluta de la paleta cargada.

**Colores como cadenas hexadecimales**

- `bg`: fondo del panel y superficies principales.
- `bg_card`: fondo de tarjetas y contenedores secundarios.
- `bg_focus`: fondo de hover y elementos con foco.
- `fg_normal`: texto principal.
- `fg_on_color`: texto sobre superficies saturadas, como botones.
- `accent`: color de énfasis.
- `urgent`: color de señales críticas.
- `muted`: texto secundario.
- `ghost`: relleno de elementos inactivos.
- `separator`: líneas divisorias.
- `usage_warn`, `usage_crit`: umbrales de advertencia y crítico.

**Colores como tablas RGB**

Cada campo de color hexadecimal tiene su equivalente con sufijo `_rgb`, expresado como tabla `{r, g, b}` con componentes en el rango `[0, 1]`, listo para Cairo:

`bg_rgb`, `bg_card_rgb`, `bg_focus_rgb`, `separator_rgb`, `accent_rgb`, `urgent_rgb`, `fg_rgb`, `muted_rgb`.

**Telemetría**

`telemetry` es una tabla con los colores asignados a cada magnitud del sistema, indexada por clave: `cpu`, `ram`, `gpu`, `temp`, `bright`, `volume`, `battery`, `disk`, `internet`.

### Anti-patrones

- **No llamar `find_palette_path()` dentro de un bucle.** Escanea el disco. Llamarlo una vez y guardar el resultado.
- **No asumir que `reload_in_place` provoca un repintado.** Solo muta el estado. Los widgets que capturaron colores en su constructor deben reconstruirse para reflejar los cambios.

---

## 2.4 `log.lua`

**Propósito**  
Sistema de logging con niveles, escribiendo a `stderr`.

**Cómo funciona**  
El nivel activo se controla mediante la variable de entorno `LANETK_LOG`. Los valores admitidos son `error`, `warn`, `info`, `debug` y `trace`. El nivel por defecto es `warn`. La variable se relee en cada emisión, de forma que es posible ajustar el nivel en caliente sin reiniciar el proceso.

Cada mensaje se prefija con la marca temporal en formato `HH:MM:SS`, el nombre del nivel y el prefijo pasado por el llamador.

### API

| Función | Parámetros | Notas |
|---|---|---|
| `error(prefix, fmt, ...)` | `prefix`, formato y argumentos | Nivel 1. Siempre visible. |
| `warn(prefix, fmt, ...)` | ídem | Nivel 2. Nivel por defecto. |
| `info(prefix, fmt, ...)` | ídem | Nivel 3. |
| `debug(prefix, fmt, ...)` | ídem | Nivel 4. |
| `trace(prefix, fmt, ...)` | ídem | Nivel 5. Máxima verbosidad. |
| `event_name(etype)` | `etype` (número) | Devuelve el nombre legible del evento X11: `"Expose"`, `"KeyPress"`, `"ConfigureNotify"`, etc. |

### Anti-patrones

- **No asumir que `LANETK_LOG=info` muestra los mensajes de nivel `debug`.** Ajustar la variable al nivel deseado.

---

## 2.5 `screens.lua`

**Propósito**  
Detección y consulta de la geometría de los monitores activos.

**Cómo funciona**  
Ejecuta `xrandr --query`, analiza la salida y construye una lista con el nombre y el rectángulo de cada monitor activo. El resultado se cachea en memoria. La caché se invalida mediante `invalidate()`, que debe llamarse cuando cambie la configuración de monitores.

El analizador admite las variantes de línea que produce `xrandr`: prescinde de la palabra `primary`, acepta coordenadas negativas y verifica que el monitor esté efectivamente conectado antes de procesar su geometría.

**Dependencias**  
`lib.helpers.util` para la ejecución de comandos.

### API

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `list()` | — | tabla | Lista de monitores, cada uno con los campos `name`, `x`, `y`, `w`, `h`. |
| `invalidate()` | — | — | Vacía la caché. |
| `at(cx, cy)` | `cx`, `cy` (números) | monitor | Monitor que contiene el punto. Si ninguno lo contiene, devuelve el primero de la lista. |
| `center(s)` | `s` (monitor) | `cx, cy` | Centro del monitor indicado. |

### Anti-patrones

- **No llamar `list()` desde `on_draw`.** Ejecuta `xrandr` de forma bloqueante. Usar la caché.

---

## 2.6 `anim.lua`

**Propósito**  
Motor de animaciones para interpolación de valores numéricos, colores, propiedades arbitrarias y transiciones entre contenidos.

**Cómo funciona**  
Mantiene un conjunto de animaciones activas. El timer global se registra únicamente mientras hay animaciones en curso, por lo que el motor no consume recursos en reposo. Admite interpolación lineal con funciones de easing, animación basada en física de muelle, composición de secuencias, repetición indefinida y entrada progresiva por escalonado.

Para usar el motor es obligatorio llamar antes a `anim.init(srv, opts)`.

### API

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `init(server, opts)` | `server`, `opts.fps` (por defecto 30) | — | Inicialización obligatoria. |
| `count()` | — | `int` | Número de animaciones activas. |
| `fps()` | — | `int` | Frecuencia actual. |
| `set_fps(n)` | `n` (número) | — | Cambia la frecuencia. Si hay un timer activo, lo reinicia con el nuevo intervalo. |
| `is_ready()` | — | `bool` | Devuelve `true` si el motor está inicializado. |
| `tween(area, prop, from, to, ms, easing, on_done)` | `area`, `prop` (string), `from`, `to`, `ms`, `easing`, `on_done` | handle | Interpola `area[prop]` numéricamente. Llama a `area:damage()` en cada frame. |
| `tween_rgb(area, prop, from, to, ms, easing, on_done)` | Tablas `{r, g, b}` | handle | Interpola colores. Escribe el resultado en `area[prop]`. |
| `tween_custom(area, apply_fn, ms, easing, on_done)` | `apply_fn(eased, raw)` | handle | Interpolación con callback arbitrario. Recibe el valor con y sin easing aplicado. |
| `spring(area, prop, target, opts, on_done)` | `opts.tension`, `opts.friction`, `opts.velocity` | handle | Animación basada en física de muelle. |
| `delay(ms, fn)` | `ms`, `fn` (callback) | handle | Ejecuta `fn` tras el retardo indicado. |
| `sequence(steps, on_done)` | `steps` (tabla) | — | Ejecuta animaciones en cadena. |
| `loop(area, prop, from, to, ms, easing, mode, on_cycle)` | `mode`: `"repeat"` o `"ping-pong"` | handle | Repite la animación indefinidamente. |
| `stagger(list, opts)` | `list` (tabla de tuplas), `opts.delay`, `opts.duration`, `opts.easing`, `opts.on_done` | handle | Inicia animaciones progresivamente con un retardo entre cada una. |
| `snapshot(area, opts)` | `opts.w`, `opts.h` | surface | Renderiza un `Area` a una superficie de imagen. |
| `crossfade(win, old_area, swap_fn, ms, opts)` | `swap_fn` (función) | handle | Toma una instantánea del área vieja, invoca `swap_fn` para cambiar el contenido y anima la opacidad del overlay de 1 a 0. |
| `stop_all()` | — | — | Cancela todas las animaciones activas. |

### Tipos de paso en `sequence`

El parámetro `steps` de `sequence` es un array de tablas. Cada elemento declara su tipo mediante el campo `kind`:

| `kind` | Campos requeridos |
|---|---|
| `"tween"` | `area`, `prop`, `from`, `to`, `duration`, `easing` |
| `"tween_rgb"` | `area`, `prop`, `from`, `to`, `duration`, `easing` |
| `"custom"` | `area`, `apply`, `duration`, `easing` |
| `"spring"` | `area`, `prop`, `to`, `opts` |
| `"delay"` | `duration` |
| `"fn"` | `fn` |

Los tipos `"fn"` y `"delay"` no modifican propiedades. `"fn"` ejecuta una función inmediatamente y pasa al paso siguiente. `"delay"` espera el tiempo indicado antes de continuar.

### Opciones de `crossfade`

`anim.crossfade(window, old_area, swap_fn, duration_ms, opts)` acepta las siguientes opciones en `opts`:

| Opción | Descripción |
|---|---|
| `fps` | Frecuencia de refresco durante el crossfade. Si se especifica, el motor la aplica durante el fade y la restaura al terminar. |
| `easing` | Función de easing. Por defecto `out_cubic`. |
| `extra_damage_area` | Área adicional que se marca como dañada en cada frame. Se usa para forzar el repintado de widgets que quedan fuera del rectángulo del overlay. |
| `on_done` | Callback que se invoca al terminar el fade. |

El módulo permite un único crossfade activo por proceso. Iniciar un segundo crossfade mientras el primero está en curso cancela el anterior y destruye su superficie.

### Funciones de easing

La tabla `anim.EASE` contiene las siguientes funciones, todas puras:

`linear`, `in_quad`, `out_quad`, `in_out_quad`, `in_cubic`, `out_cubic`, `in_out_cubic`, `in_quart`, `out_quart`, `in_out_quart`, `in_expo`, `out_expo`, `in_out_expo`, `out_back`, `in_back`, `out_elastic`, `out_bounce`.

### Handles de animación

Las funciones que devuelven un handle exponen el método `handle:cancel()`, que marca la animación como terminada sin ejecutar el callback `on_done`. Los handles devueltos por `loop` y `stagger` exponen además un método `cancel()` que detiene la secuencia completa.

### Anti-patrones

- **No iniciar animaciones sin llamar previamente a `anim.init(srv)`.** El motor lanza un error si `srv` es nulo.
- **No modificar el layout del área durante un crossfade.** Si el rectángulo del área cambia tras ejecutarse `swap_fn`, el overlay queda desalineado respecto al contenido nuevo.
- **No conservar handles más allá del ciclo de vida del área animada.** Un handle sobre un área destruida provoca un error al aplicar el siguiente fotograma.

---

## 2.7 `xshape_anim.lua`

**Propósito**  
Animación de revelado por cortina para ventanas completas, implementada mediante la manipulación directa de la máscara de recorte XShape del servidor X, sin necesidad de compositor.

**Cómo funciona**  
La animación consiste en variar progresivamente la altura visible de una ventana. El módulo genera, en cada fotograma, una máscara de recorte con la forma redondeada de la ventana limitada a la altura visible actual.

Para reducir el coste de la operación, la máscara se construye fusionando filas consecutivas con el mismo ancho en un único rectángulo. Una máscara redondeada de 300 píxeles de alto se traduce típicamente en veinte o cuarenta rectángulos, en lugar de trescientos. La operación se completa con una sola llamada a `xcb_shape_rectangles`.

La máscara tiene dos canales: `Bounding`, que define qué parte de la ventana se dibuja, y `Input`, que define qué parte recibe eventos de ratón. El canal `Bounding` se actualiza en cada fotograma. El canal `Input` se actualiza únicamente en el fotograma final, ya que los clics durante la animación no aportan valor y su cómputo es costoso.

El ritmo de la animación se controla con `usleep`, lo que produce un efecto uniforme independiente de la latencia de eventos del servidor X.

**Dependencias**  
`lib.xcb`, `ffi` de LuaJIT para `usleep`.

### API

| Función / Método | Parámetros | Retorno | Notas |
|---|---|---|---|
| `attach(opts)` | `srv`, `win`, `w`, `h`, `radius`, `ms`, `steps` | handle | Prepara la ventana para animaciones XShape. |
| `handle:show()` | — | — | Anima la máscara desde altura 0 hasta la altura completa. |
| `handle:hide()` | — | — | Anima la máscara desde la altura completa hasta altura 0. |
| `handle:reset()` | — | — | Establece la máscara a altura 0 sin animación. |
| `handle:visible()` | — | `bool` | Devuelve `true` si el objetivo actual es la altura completa. |

### Campos de `opts` en `attach`

| Campo | Descripción |
|---|---|
| `srv` | Instancia de `Server`. Obligatorio. |
| `win` | Instancia de `Window`. Obligatorio. |
| `w`, `h` | Dimensiones de la ventana. Obligatorios. |
| `radius` | Radio de las esquinas redondeadas de la máscara. Por defecto 12. |
| `ms` | Duración total de la animación en milisegundos. Por defecto 240. |
| `steps` | Número de fotogramas. Por defecto 16. |

### Uso

El módulo se emplea típicamente al abrir o cerrar popups y menús sin decoración del gestor de ventanas.

```lua
local xshape_anim = require("lib.xshape_anim")

local reveal = xshape_anim.attach {
    srv = srv,
    win = win,
    w = win.width,
    h = win.height,
    radius = 12,
    ms = 240,
}

reveal:show()
-- ... tras un tiempo o un evento:
reveal:hide()
```

### Anti-patrones

- **No usar este módulo para animar propiedades internas de widgets.** Está diseñado exclusivamente para la geometría de recorte de ventanas completas.
- **No olvidar el `override_redirect`.** La máscara XShape se aplica con independencia del tipo de ventana, pero en ventanas gestionadas por el WM el resultado puede no ser el esperado por la interacción con decoraciones.
- **No omitir `backing_store = 2` (Always).** Sin el modo de almacenamiento continuo, el servidor X no conserva los píxeles ocultos por la máscara y cada fotograma de la animación obliga a redibujar el árbol completo, anulando la optimización. El consumidor debe activarlo explícitamente al crear la ventana.
# 03. Widgets

El árbol de componentes visuales de LaneTK. Todos los widgets heredan de una clase base común, comparten un ciclo de vida de layout y renderizado, y se comunican con el sistema a través de la ventana que los contiene.

---

## 3.1 El contrato base: `Area`

**Propósito**  
Clase base de la que heredan todos los widgets. Define el contrato mínimo para que un elemento pueda ser medido, posicionado y dibujado por el motor.

**Cómo funciona**  
Un `Area` no dibuja nada por sí mismo. Su función es gestionar el rectángulo que ocupa (`x0`, `y0`, `x1`, `y1`), propagar el estado de la ventana a sus hijos, y proporcionar los métodos `askMinMax`, `layout` y `draw`. Implementa la lógica central de seguimiento de daños: `should_draw()` consulta la lista de daño de la ventana y devuelve `true` solo si el rectángulo del widget interseca con alguna zona sucia, evitando redibujados innecesarios.

Los widgets que contienen hijos (`Group`, `Card`, `Stack`, `TabbedPanel`) deben filtrar con `should_draw` antes de invocar el dibujo de cada hijo. Los widgets hoja no lo necesitan, porque el contenedor ya los filtra.

**API principal**

| Método | Parámetros | Retorno | Notas |
|---|---|---|---|
| `Area.new(opts)` | `opts.min_width`, `opts.min_height`, `opts.max_width`, `opts.max_height` | `area` | Inicializa el rectángulo en 0×0 y los límites en 0. |
| `area:askMinMax(minw, minh, maxw, maxh)` | Acumuladores del padre | `minw, minh, maxw, maxh` | Devuelve el tamaño requerido sumado a los acumuladores recibidos. No debe mutar el estado del widget. |
| `area:layout(x0, y0, x1, y1)` | Coordenadas absolutas | — | Asigna el rectángulo final. |
| `area:draw(cr)` | Contexto Cairo | — | Dibuja el widget. La implementación base no hace nada. |
| `area:should_draw()` | — | `bool` | `true` si el widget interseca la lista de daño, si `force_redraw` está activo, o si hay un overlay en la ventana. |
| `area:damage()` | — | — | Añade el rectángulo del widget a la lista de daño de la ventana. |
| `area:invalidate_layout()` | — | — | Marca la ventana completa como dañada y ejecuta un relayout. |
| `area:getByXY(x, y)` | Coordenadas absolutas | `area` o `nil` | Devuelve el widget más profundo que contiene el punto. La implementación base se compara consigo misma. |
| `area:getWidth()` / `area:getHeight()` | — | número | Dimensiones del rectángulo actual. |
| `area:getRect()` | — | `x0, y0, x1, y1` | Cuatro valores de retorno. |
| `area:set_window(win)` | `win` (instancia de `Window`) | — | Asigna la ventana a este widget y, si el widget lo reimplementa, a sus hijos. |
| `area:set_hover(v)` / `area:set_pressed(v)` | `v` (booleano) | — | Actualizan el estado. Solo disparan un `damage` si el widget declara `_hover_visual` o `_pressed_visual`. |
| `area:newClass()` | — | tabla | Construye una subclase con `Area` como `__parent`. |

**Callbacks de entrada**

Los siguientes métodos se invocan desde la ventana cuando el widget recibe un evento. Reciben coordenadas locales al widget:

| Método | Parámetros |
|---|---|
| `area:on_mouse_move(x, y)` | Coordenadas locales |
| `area:on_mouse_press(x, y, button)` | Coordenadas locales y número de botón (1, 3, 4, 5) |
| `area:on_mouse_release(x, y, button)` | Ídem |
| `area:on_wheel(direction)` | `4` para arriba, `5` para abajo |

**Anti-patrones**

- **No llamar `damage()` cuando cambia el tamaño mínimo.** El cambio de tamaño afecta el layout del padre. Usar `invalidate_layout()`.
- **No mutar el estado interno en `askMinMax`.** Solo debe calcular dimensiones. Cualquier mutación provoca inconsistencias en el layout.
- **No declarar `_hover_visual` si el widget no cambia de aspecto con el hover.** Genera daños innecesarios.

---

## 3.2 Contenedores

Widgets diseñados para agrupar, organizar y gestionar el ciclo de vida de otros widgets.

### `Group`

Contenedor con layout flexible en una sola dirección.

**Constructor**

| Campo | Descripción |
|---|---|
| `orientation` | `"horizontal"` o `"vertical"`. Por defecto horizontal. |
| `spacing` | Espacio entre hijos. Por defecto 0. |
| `padding` | Margen interno uniforme. Por defecto 0. |
| `children` | Lista de hijos. Cada elemento puede ser un widget o una tabla `{ widget = ..., weight = ... }`. |

**Métodos**

| Método | Parámetros | Notas |
|---|---|---|
| `group:add(child, weight)` | `child` (widget), `weight` (número) | Si `child` es una tabla con el campo `widget`, se extrae automáticamente. |
| `group:remove(child)` | `child` | Devuelve `true` si lo encontró. |
| `group:clear()` | — | Elimina todos los hijos. |

**Comportamiento del layout**

El eje principal reparte el espacio disponible entre los hijos. El eje transversal toma el máximo de los hijos. La clasificación de hijos en rígidos y flexibles es la siguiente:

- Rígidos: declaran `min == max` en el eje principal (por ejemplo, un `TabsBar`). Reciben su tamaño exacto y no se encogen mientras haya espacio para ellos.
- Flexibles: declaran `min < max`. Absorben el espacio sobrante o se recortan proporcionalmente si no alcanza.

El espacio extra se reparte entre los hijos según su `weight`. Un hijo con `weight = 0` recibe su mínimo y no crece.

### `Stack`

Contenedor que muestra un solo hijo visible a la vez.

**Constructor**

| Campo | Descripción |
|---|---|
| `min_width`, `min_height` | Tamaño mínimo propio. |

**Métodos**

| Método | Parámetros | Notas |
|---|---|---|
| `stack:add(name, widget)` | `name` (string), `widget` | Registra una página. |
| `stack:remove(name)` | `name` | Elimina la página. Devuelve `true` si existía. |
| `stack:set_active(name)` | `name` | Activa una página. |
| `stack:get(name)` | `name` | Devuelve la página indicada. |
| `stack:get_active()` | — | Nombre de la página activa. |

**Comportamiento del layout**

`askMinMax` mide todas las páginas, no solo la activa. Esto garantiza que el rectángulo del `Stack` sea estable cuando cambia la página activa, condición necesaria para que las animaciones de crossfade no se desalineen.

### `Card`

Contenedor visual con fondo, borde y título opcional.

**Constructor**

| Campo | Descripción |
|---|---|
| `title` | Título. Puede contener markup si incluye `<`. |
| `content` | Widget del contenido. |
| `padding` | Margen interno. Por defecto 10. |
| `spacing` | Espacio entre título y contenido. Por defecto 8. |
| `corner_radius` | Radio de las esquinas. Por defecto 8. |
| `bg` | Color de fondo como tabla `{r, g, b}`. |
| `border` | Color del borde. Opcional. |
| `title_font`, `title_color` | Fuente y color del título. |
| `min_width`, `min_height` | Tamaño mínimo. |

**Métodos**

| Método | Parámetros | Notas |
|---|---|---|
| `card:set_title(text)` | `text` (string) | Detecta automáticamente si contiene markup. |

---

## 3.3 Navegación

### `TabsBar`

Barra de pestañas con dos modos de presentación.

**Constructor**

| Campo | Descripción |
|---|---|
| `items` | Lista de tablas `{ id, label, icon }`. |
| `active` | Identificador del tab activo. |
| `on_select` | Callback que recibe el `id` del tab pulsado. |
| `theme` | Tabla de tema. |
| `compact` | Si es `true`, usa el modo compacto (icono al lado del texto). |
| `pad_x`, `pad_y` | Padding interno. Valores por defecto dependen del modo. |
| `icon_size` | Tamaño del icono. |
| `font` | Fuente del texto. |
| `radius` | Radio de las esquinas. |
| `color_active_bg`, `color_active_fg` | Colores del tab activo. |
| `color_inactive_bg`, `color_inactive_fg` | Colores de los tabs inactivos. |

**Modos**

- Principal (`compact = false`): icono arriba, texto abajo. Padding 10×6, icono 22.
- Compacto (`compact = true`): icono y texto lado a lado. Padding 8×2, icono 16.

Los iconos se resuelven desde `~/proyectos/lanetk/icons-png/32/` y se tintan con el color de texto del estado correspondiente. El nombre del icono puede llevar prefijo `tab-` o no.

**Métodos**

| Método | Parámetros |
|---|---|
| `tabsbar:add(id, label, icon)` | Registra un tab. |
| `tabsbar:set_active(id)` | Activa el tab e invoca `on_select`. |
| `tabsbar:get_active()` | Devuelve el `id` activo. |

### `TabbedPanel`

Composición de `TabsBar` y `Stack` con carga diferida.

**Constructor**

| Campo | Descripción |
|---|---|
| `tabs` | Lista de tablas `{ id, label, icon, factory }`. La `factory` es una función sin argumentos que devuelve una tabla `{ widget, start, stop }`. |
| `anim` | Si es `true`, activa el crossfade entre tabs. |
| `anim_duration`, `anim_fps` | Duración y frecuencia del crossfade. |
| `theme` | Tabla de tema. |
| `spacing` | Espacio entre TabsBar y Stack. Por defecto 6. |
| `tabsbar_opts` | Opciones pasadas directamente al `TabsBar` interno. |
| `compact` | Se pasa al `TabsBar`. |
| `bg` | Color de fondo. |

**Ciclo de vida de una pestaña**

La `factory` se invoca la primera vez que el usuario activa la pestaña. El resultado se conserva en un cache. En cada activación se invocan los métodos `start` y `stop` de la pestaña, que deben cancelar y reinstalar sus timers según corresponda.

**Métodos**

| Método | Parámetros | Notas |
|---|---|---|
| `panel:set_tab(id)` | `id` | Activa la pestaña. |
| `panel:get_tab(id)` | `id` | Devuelve la pestaña cargada, o `nil` si no se ha cargado. |
| `panel:get_active()` | — | Identificador de la pestaña activa. |
| `panel:stop()` | — | Detiene la pestaña activa. |

### `SidebarItem`

Item clickeable para barra lateral.

**Constructor**

| Campo | Descripción |
|---|---|
| `id` | Identificador del item. |
| `label` | Texto visible. |
| `theme` | Tabla de tema. |
| `header` | Si es `true`, el item se comporta como encabezado no clickeable. |
| `indent` | Desplazamiento horizontal. |
| `height` | Altura del item. Por defecto 30. |
| `min_w` | Ancho mínimo. |

**Métodos**

| Método | Parámetros |
|---|---|
| `item:set_selected(v)` | Activa o desactiva el estado seleccionado. |

### `ScrollBar`

Barra de desplazamiento vertical u horizontal.

**Constructor**

| Campo | Descripción |
|---|---|
| `orientation` | `"vertical"` o `"horizontal"`. |
| `length` | Longitud del track. |
| `width` | Grosor del área. |
| `thickness` | Grosor del track. |
| `handle_r` | Radio del handle. |
| `step` | Desplazamiento por rueda. |
| `color_track`, `color_handle` | Colores. |
| `auto_hide` | Si es `true`, se oculta cuando no hay desplazamiento. |
| `on_change` | Callback invocado tras cada cambio de offset. |

**Métodos**

| Método | Parámetros | Notas |
|---|---|---|
| `bar:on_change(fn)` | Callback | Añade un observador. |
| `bar:set_offset(px, silent)` | `px`, `silent` | El segundo argumento suprime la notificación. |
| `bar:set_offset_max(px)` | `px` | Rango máximo del desplazamiento. |
| `bar:get_offset()` | — | Offset actual. |
| `bar:get_offset_max()` | — | Offset máximo. |
| `bar:set_step(px)` | `px` | Ajusta el paso de la rueda. |
| `bar:is_visible()` | — | `true` si hay desplazamiento pendiente. |

### `ScrollView`

Lista con desplazamiento pixel-perfect y renderizado diferido.

**Constructor**

| Campo | Descripción |
|---|---|
| `row_height` | Altura de cada fila. |
| `draw_row` | Callback `function(cr, item, idx, y, row_h, width, hover, view)`. Obligatorio. |
| `on_click` | Callback invocado al hacer clic en una fila. Recibe `(item, idx)`. |
| `on_right_click` | Callback equivalente para el botón derecho. |
| `bg_color` | Color de fondo. Opcional. |
| `items` | Lista inicial de datos. |
| `compare` | Función `function(a, b)` que devuelve `true` si dos items son iguales. Si se especifica, el widget daña solo las filas visibles que cambiaron. |
| `min_width`, `min_height` | Tamaño mínimo. |

**Contrato de `draw_row`**

El callback debe pintar el fondo de la fila completa, con o sin hover, antes de dibujar su contenido. Omitir el fondo en el caso sin hover deja los píxeles del frame anterior y produce artefactos visuales cuando los items cambian.

**Métodos**

| Método | Parámetros | Notas |
|---|---|---|
| `view:set_items(items)` | Lista de datos | Sustituye los items. Respeta el comparador si está definido. |
| `view:set_offset(px, silent)` | `px`, `silent` | Desplazamiento vertical. |
| `view:get_offset()` / `view:get_offset_max()` | — | Consulta del desplazamiento. |
| `view:get_row_height()` / `view:get_count()` | — | Consulta de geometría. |
| `view:on_change(fn)` | Callback | Notificación de cambio de offset. |

### `ScrollLink`

Vinculación entre `ScrollView` y `ScrollBar`.

| Función | Parámetros | Notas |
|---|---|---|
| `link(list, sb)` | `list` (`ScrollView`), `sb` (`ScrollBar`) | Cablea el flujo bidireccional sin bucles de realimentación. |

---

## 3.4 Entrada de usuario

### `Button`

Botón interactivo con estados de reposo, hover y pulsado.

**Constructor**

| Campo | Descripción |
|---|---|
| `text` | Etiqueta. |
| `font` | Fuente Pango. |
| `padding_x`, `padding_y` | Padding interno. |
| `corner_radius` | Radio de las esquinas. |
| `flat` | Si es `true`, sin fondo salvo en hover. |
| `color_normal`, `color_hover`, `color_pressed` | Tablas `{r, g, b}`. |
| `color_border`, `color_text` | Colores del borde y del texto. |
| `min_width` | Ancho mínimo. |
| `on_click` | Callback `function(self, button)`. |
| `on_hover`, `on_press` | Callbacks opcionales. |

**Métodos**

| Método | Parámetros |
|---|---|
| `button:set_text(text)` | Actualiza el texto y remide. |

### `TextInput`

Campo de texto editable de una sola línea.

**Constructor**

| Campo | Descripción |
|---|---|
| `text` | Texto inicial. |
| `font` | Fuente. |
| `padding_x`, `padding_y` | Padding interno. |
| `color_text`, `color_cursor` | Colores de texto y cursor. |
| `color_bg`, `color_border` | Colores de fondo y borde. Opcionales. |
| `corner_radius` | Radio de esquinas. |
| `mask` | Si es `true`, los caracteres se muestran como puntos. |
| `placeholder` | Texto mostrado cuando el contenido está vacío. |
| `color_placeholder` | Color del placeholder. |
| `right_widget` | Widget anclado a la derecha, dentro del rectángulo del input. |
| `right_widget_width`, `right_widget_gap` | Dimensiones del widget anclado. |
| `on_submit`, `on_cancel`, `on_change` | Callbacks. |
| `on_up`, `on_down` | Callbacks para las teclas de flecha. Si se definen, la tecla se consume. |
| `min_width`, `min_height` | Tamaño mínimo. |

**Métodos**

| Método | Parámetros | Notas |
|---|---|---|
| `input:set_text(t)` | `t` (string) | Sustituye el contenido y coloca el cursor al final. |
| `input:get_text()` | — | Contenido actual. |
| `input:set_focused(v)` | `v` (booleano) | Registra o desregistra el widget como receptor de teclado en la ventana. |
| `input:insert_char(ch)` | `ch` | Inserta un carácter en la posición del cursor. |
| `input:backspace()` / `input:delete()` | — | Edición del contenido. |
| `input:move_left()` / `input:move_right()` | — | Movimiento del cursor. |
| `input:move_home()` / `input:move_end()` | — | Movimiento a los extremos. |
| `input:on_key(key)` | Tabla de evento de tecla | Procesa una tecla. Devuelve `true` si la consumió. |

### `Dropdown`

Selector con lista desplegable.

**Constructor**

| Campo | Descripción |
|---|---|
| `items` | Lista de tablas `{ id, label }`. |
| `selected` | Identificador del item seleccionado. |
| `placeholder` | Texto mostrado cuando no hay selección. |
| `theme` | Tabla de tema. |
| `row_h` | Altura de cada fila. |
| `pad` | Padding interno. |
| `visible_rows` | Número de filas visibles en la lista desplegable. |
| `draw_preview` | Callback opcional para dibujar una previsualización en cada fila. |
| `on_select` | Callback que recibe el `id` seleccionado. |

La altura del widget es fija y corresponde al header más las filas visibles. Abrir y cerrar la lista no modifica la altura, de modo que los hermanos del widget no se reacomodan.

**Métodos**

| Método | Parámetros |
|---|---|
| `dd:set_items(items)` | Reemplaza la lista. |
| `dd:set_selected(id)` | Cambia la selección. |
| `dd:set_open(v)` | Abre o cierra la lista. |

### `RadioGroup`

Lista vertical de opciones con selección única.

**Constructor**

| Campo | Descripción |
|---|---|
| `items` | Lista de tablas `{ id, label }`. |
| `selected` | Identificador seleccionado. |
| `theme` | Tabla de tema. |
| `row_h` | Altura de cada fila. |
| `on_select` | Callback que recibe el `id`. |

**Métodos**

| Método | Parámetros |
|---|---|
| `rg:set_selected(id)` | Cambia la selección. |

### `Gallery`

Rejilla de miniaturas clickeables.

**Constructor**

| Campo | Descripción |
|---|---|
| `items` | Lista de tablas `{ path, thumb }`. |
| `item_size` | Tamaño de cada celda. |
| `gap` | Separación entre celdas. |
| `theme` | Tabla de tema. |
| `selected` | Ruta seleccionada. |
| `on_select` | Callback que recibe la ruta del item pulsado. |

**Métodos**

| Método | Parámetros |
|---|---|
| `gallery:set_items(items)` | Reemplaza la lista y recalcula la rejilla. |
| `gallery:set_selected(path)` | Marca una miniatura como seleccionada. |

### `ContextMenu`

Menú contextual flotante.

**Constructor**

| Función | Parámetros | Retorno |
|---|---|---|
| `new(srv, parent_win, theme)` | Instancia del servidor, ventana padre, tabla de tema | Instancia del menú |

**Métodos**

| Método | Parámetros | Notas |
|---|---|---|
| `menu:show(x, y, items, opts)` | Coordenadas, lista de items, opciones | Muestra el menú en la posición indicada. |
| `menu:close()` | — | Cierra el menú. |
| `menu:is_open()` | — | Devuelve `true` si el menú está visible. |

**Formato de los items**

Cada elemento de la lista es una tabla con los campos `label`, `on_click`, `color` (opcional), `enabled` (opcional). El elemento `{ sep = true }` dibuja un separador.

**Comportamiento**

El menú se crea como una ventana hija de la ventana padre. Mientras está abierto, captura el puntero, de modo que cualquier clic fuera de su rectángulo lo cierra sin propagarse al padre. La tecla Escape también lo cierra.

---

## 3.5 Visualización

### `Text`

Texto plano o con markup Pango.

**Constructor**

| Campo | Descripción |
|---|---|
| `text` | Contenido plano. |
| `markup` | Contenido con markup. Tiene prioridad sobre `text`. |
| `font` | Fuente Pango. |
| `r`, `g`, `b` | Color en el rango `[0, 1]`. |
| `align` | `"left"`, `"center"` o `"right"`. |
| `valign` | `"top"`, `"center"` o `"bottom"`. |
| `wrap` | Si es `true`, ajusta el texto al ancho disponible. |

**Métodos**

| Método | Parámetros |
|---|---|
| `text:set_text(t)` | Sustituye el contenido plano. |
| `text:set_markup(m)` | Sustituye el contenido con markup. |
| `text:set_color(r, g, b)` | Cambia el color. Solo dispara un `damage` si cambió. |

### `Header`

Encabezado con alineación y ajuste de línea.

**Constructor**

Campos idénticos a `Text`, más:

| Campo | Descripción |
|---|---|
| `markup` | Si es `true`, trata `text` como markup. |

**Métodos**

| Método | Parámetros |
|---|---|
| `header:set(text)` | Sustituye el texto. |
| `header:set_markup(markup)` | Sustituye el texto marcándolo como markup. |

### `Icon`

Imagen PNG o SVG con tintado opcional.

**Constructor**

| Campo | Descripción |
|---|---|
| `path` | Ruta del archivo. |
| `surface` | Superficie ya cargada. Tiene prioridad sobre `path`. |
| `width`, `height` | Tamaño de dibujo. Si se omiten, se usa el tamaño nativo. |
| `color` | Tabla `{r, g, b}` para tintar. |
| `color_hex` | Alternativa a `color` como cadena hexadecimal. |
| `halign`, `valign` | Alineación dentro del rectángulo asignado. |
| `fit` | `"contain"` escala respetando el aspect ratio. |
| `on_click` | Callback invocado al pulsar. |

**Métodos**

| Método | Parámetros |
|---|---|
| `icon:set_path(path)` | Cambia la imagen. |
| `icon:set_color(r, g, b)` | Aplica o retira el tintado. |
| `icon:set_color_hex(hex)` | Variante con cadena hexadecimal. |

### `Bignum`

Número destacado con unidad y caption.

**Constructor**

| Campo | Descripción |
|---|---|
| `value` | Valor inicial. |
| `unit` | Texto bajo el número, en tamaño menor. |
| `caption` | Texto bajo la unidad. |
| `size`, `caption_size` | Tamaños de fuente. |
| `color`, `unit_color`, `caption_color` | Colores. |

**Métodos**

| Método | Parámetros |
|---|---|
| `bn:set(value, caption, unit)` | Actualiza los tres campos. Los argumentos nulos se conservan. |

### `KV`

Lista clave-valor con columnas alineadas.

**Constructor**

| Campo | Descripción |
|---|---|
| `rows` | Lista inicial de tablas `{ id, label, format }`. |
| `key_width` | Ancho reservado para la clave. |
| `row_height` | Altura de cada fila. |
| `row_spacing` | Separación entre filas. |
| `key_color`, `value_color` | Colores. |
| `value_align` | Alineación del valor. |
| `key_font`, `value_font` | Fuentes. |
| `col_gap` | Separación entre columnas. |

**Métodos**

| Método | Parámetros | Notas |
|---|---|---|
| `kv:add_row(id, label, format)` | Registra una fila. |
| `kv:set(id, value)` | Actualiza un valor. Aplica el formato si es numérico. |
| `kv:set_markup(id, markup)` | Actualiza un valor con markup. |
| `kv:set_alpha(a)` | Aplica un multiplicador global a los colores. |

### `Rows`

Lista de tres columnas.

**Constructor**

Campos análogos a `KV`, más:

| Campo | Descripción |
|---|---|
| `rows` | Lista de tablas `{ id, group, name }`. |
| `group_width`, `name_width`, `value_width` | Anchos mínimos de columna. |
| `group_font`, `group_color` | Fuente y color de la primera columna. |
| `name_font`, `name_color` | Fuente y color de la segunda columna. |

**Métodos**

| Método | Parámetros |
|---|---|
| `rows:add_row(id, group, name)` | Registra una fila. |
| `rows:set(id, value, format)` | Actualiza el valor. |
| `rows:set_markup(id, markup)` | Actualiza el valor con markup. |

### `BarRow`

Lista de filas con barra horizontal y umbrales de advertencia.

**Constructor**

| Campo | Descripción |
|---|---|
| `rows` | Lista de tablas `{ id, label, color }`. |
| `left_width` | Ancho reservado a la etiqueta. |
| `pct_width` | Ancho reservado al porcentaje. `0` lo oculta. |
| `detail_width` | Ancho reservado al detalle. `0` lo oculta. |
| `row_height`, `row_spacing` | Dimensiones de fila. |
| `bar_height` | Altura de la barra. |
| `bar_color`, `bar_bg` | Colores de la barra. |
| `warn_at`, `crit_at` | Umbrales `[0, 1]`. |
| `warn_color`, `crit_color` | Colores de los umbrales. |
| `text_warn` | Si es `true`, el porcentaje cambia de color según umbrales. |
| `label_font`, `pct_font`, `detail_font` | Fuentes. |
| `label_color`, `pct_color`, `detail_color` | Colores. |

**Métodos**

| Método | Parámetros | Notas |
|---|---|---|
| `br:add_row(id, label, color)` | Registra una fila. |
| `br:set(id, data)` | `data` es una tabla `{ pct = ..., detail = ... }`. |
| `br:set_animated(id, data, duration)` | Variante con interpolación del porcentaje. |
| `br:set_empty(id, text)` | Marca una fila sin valor y muestra un texto alternativo. |
| `br:remove_all_rows()` | Elimina todas las filas. |

### `Motors`

Configuración específica de `BarRow` sin columna de porcentaje ni detalle.

**Constructor**

Acepta los campos de `BarRow`, con `pct_width` y `detail_width` forzados a 0 y `left_width` por defecto 40.

**Métodos**

| Método | Parámetros |
|---|---|
| `motors:set(id, pct)` | Actualiza el porcentaje. |
| `motors:set_animated(id, pct, duration)` | Variante animada. |

### `BarMulti`

Barra horizontal con segmentos apilados y leyenda adaptativa.

**Constructor**

| Campo | Descripción |
|---|---|
| `segments` | Lista de tablas `{ id, color, label }`. |
| `bar_height` | Altura de la barra. |
| `legend_cols`, `legend_cols_min` | Número máximo y mínimo de columnas de la leyenda. |
| `legend_gap_x`, `legend_gap_y` | Separaciones. |
| `legend_dot` | Tamaño del indicador de color. |
| `legend_font`, `legend_color` | Fuente y color de la leyenda. |
| `value_format` | Formato de número para el valor. |
| `bar_bg`, `bar_radius` | Fondo y radio de la barra. |

La leyenda se distribuye dinámicamente. El widget prueba configuraciones desde el máximo de columnas hasta el mínimo, y elige la primera que quepa en el ancho y alto disponibles. El espacio sobrante se reparte entre las separaciones.

**Métodos**

| Método | Parámetros |
|---|---|
| `bm:add_segment(id, color, label)` | Registra un segmento. |
| `bm:set(values)` | `values` es una lista de tablas `{ id, pct, value_str, color }`. |

### `Pills`

Fila de etiquetas con fondo redondeado.

**Constructor**

| Campo | Descripción |
|---|---|
| `items` | Lista de tablas `{ id, text, color }`. |
| `gap` | Separación entre elementos. |
| `pad_x`, `pad_y` | Padding interno. |
| `font` | Fuente del texto. |
| `text_color` | Color del texto. |
| `radius` | Radio. Por defecto `altura / 2`. |

**Métodos**

| Método | Parámetros |
|---|---|
| `pills:add(id, text, color)` | Registra un elemento. |
| `pills:set(id, text)` | Actualiza el texto. |
| `pills:set_color(id, color)` | Cambia el color de fondo. |

### `PillRow`

Fila de pills con etiqueta y valor diferenciados.

**Constructor**

Campos análogos a `Pills`, más:

| Campo | Descripción |
|---|---|
| `theme` | Tabla de tema. |
| `label_font`, `value_font` | Fuentes de etiqueta y valor. |
| `bg` | Color de fondo. |
| `label_color` | Color de la etiqueta. |

**Métodos**

| Método | Parámetros |
|---|---|
| `pr:add(id, label, value, color)` | Registra un elemento. |
| `pr:set(id, value, color)` | Actualiza el valor y, opcionalmente, el color. |
| `pr:set_color(id, color)` | Cambia el color del valor. |

### `Ring`

Anillo de progreso con texto central.

**Constructor**

| Campo | Descripción |
|---|---|
| `value` | Valor inicial en el rango `[0, 1]`. |
| `text` | Texto principal. |
| `sub` | Texto secundario. |
| `thickness` | Grosor del anillo. |
| `color`, `color_bg` | Colores del arco y del fondo. |
| `value_font`, `sub_font` | Fuentes. |
| `value_color`, `sub_color` | Colores del texto. |
| `size` | Diámetro mínimo. |
| `raw_range` | Tabla `{min, max}` para normalizar valores externos. |

**Métodos**

| Método | Parámetros | Notas |
|---|---|---|
| `ring:set_value(v, text, sub)` | Actualiza el valor y los textos. |
| `ring:animate_to(v, text, sub, duration)` | Variante con interpolación. Cancela la animación previa si la hay. |

### `Spark`

Gráfico de líneas con buffer circular.

**Constructor**

| Campo | Descripción |
|---|---|
| `samples` | Número de muestras. |
| `min`, `max` | Rango del eje. Si se omiten, se autocalcula. |
| `color` | Color de la línea. |
| `fill` | Si es `true`, rellena el área bajo la línea. |
| `axis_format`, `axis_width` | Formato y ancho de las etiquetas del eje. |
| `grid` | Si es `true`, dibuja líneas guía. |
| `min_width`, `min_height`, `max_width`, `max_height` | Dimensiones. |

**Métodos**

| Método | Parámetros | Notas |
|---|---|---|
| `spark:push(v)` | Añade una muestra. |
| `spark:push_animated(v, duration)` | Añade una muestra animando el trazado del último segmento y, si el buffer está lleno, el desplazamiento horizontal. |
| `spark:set_range(vmin, vmax)` | Fija el rango del eje. |
| `spark:clear()` | Vacía el buffer. |

### `DualSpark`

Gráfico de dos series con eje compartido.

**Constructor**

Campos análogos a `Spark`, más:

| Campo | Descripción |
|---|---|
| `color_a`, `color_b` | Colores de las series. |
| `fill_a`, `fill_b` | Relleno bajo cada serie. |
| `auto_max` | Escala automática al máximo entre ambas series. |
| `floor_max` | Valor mínimo del máximo calculado. |

**Métodos**

| Método | Parámetros |
|---|---|
| `ds:push_a(v)` / `ds:push_b(v)` | Añaden muestras a cada serie. |
| `ds:push_a_animated(v, duration)` | Variante animada de la serie A. |
| `ds:set_range(vmin, vmax)` | Fija el rango. |
| `ds:clear()` | Vacía ambas series. |

### `PalettePreview`

Fila de muestras de color de una paleta.

**Constructor**

| Campo | Descripción |
|---|---|
| `path` | Ruta del archivo de paleta. |
| `keys` | Lista de claves a mostrar. Por defecto `{ "bg", "bg_card", "accent", "fg", "urgent" }`. |
| `swatch_h` | Altura de cada muestra. |
| `gap` | Separación. |
| `corner_radius` | Radio. |

**Métodos**

| Método | Parámetros |
|---|---|
| `pp:set_palette(path)` | Cambia la paleta mostrada. |

---

## 3.6 Botones especializados

### `CardButton`

Botón con icono, título y subtítulo, con hover animado.

**Constructor**

| Campo | Descripción |
|---|---|
| `icon`, `icon_dir` | Nombre y directorio del icono PNG. |
| `icon_size` | Tamaño del icono. |
| `title`, `subtitle` | Textos. |
| `bg_color`, `hover_color`, `border_color` | Colores de fondo y borde. |
| `fg_color`, `fg_dark_color` | Color del texto y su variante en hover. |
| `fg_sub_color` | Color del subtítulo. |
| `accent_color` | Color del borde cuando `selected` es verdadero. |
| `font_title`, `font_sub` | Fuentes. |
| `width`, `height` | Dimensiones fijas. |
| `corner_radius` | Radio. |
| `on_click` | Callback. |

**Campos públicos**

| Campo | Descripción |
|---|---|
| `selected` | Si es `true`, dibuja un borde con el color de acento. |

### `LogoutButton`

Botón con icono e intercambio de variante clara u oscura en hover.

**Constructor**

| Campo | Descripción |
|---|---|
| `icon`, `label`, `icon_dir` | Icono y texto. |
| `icon_size` | Tamaño del icono. |
| `hover_color`, `bg_color` | Colores de fondo. |
| `fg_color`, `fg_dark` | Colores del texto. |
| `border_color` | Color del borde. |
| `font` | Fuente. |
| `corner_radius` | Radio. |
| `wide` | Si es `true`, el icono va a la izquierda del texto. |
| `width`, `height` | Dimensiones. |

El icono `nombre.png` se muestra en reposo y `nombre-dark.png` en hover. El intercambio se realiza cuando la interpolación alcanza 0.5.

### `CloseButton`

Botón compacto con una X.

**Constructor**

| Campo | Descripción |
|---|---|
| `size` | Tamaño cuadrado. |
| `color`, `color_hover`, `color_pressed` | Colores del trazo. |
| `color_hover_bg`, `color_pressed_bg` | Colores del fondo. |
| `corner_radius` | Radio. |
| `on_click` | Callback. |

---

## 3.7 Composición

### `Actions`

Lista de botones que ejecutan comandos con retroalimentación.

**Constructor**

| Campo | Descripción |
|---|---|
| `actions` | Lista de tablas `{ label, cmd, ok_msg }`. |
| `feedback_time` | Duración del mensaje de resultado. |
| `button_width` | Ancho mínimo de cada botón. |
| `row_spacing` | Separación entre botones. |
| `feedback_color`, `feedback_error_color` | Colores del mensaje. |
| `on_run` | Función alternativa que reemplaza la ejecución por defecto. |

**Métodos**

| Método | Parámetros |
|---|---|
| `actions:add_action(label, cmd, ok_msg)` | Añade un botón. |

### `Intro`

Animaciones de entrada automáticas para widgets animables.

Los widgets declaran su tipo de animación mediante el campo `_anim_kind`. Los valores admitidos son `"ring"`, `"spark"`, `"dualspark"`, `"barrow"` y `"kv"`.

**Funciones**

| Función | Parámetros | Notas |
|---|---|---|
| `reset(root)` | `root` (widget raíz) | Recorre el árbol y establece los campos de animación a su estado inicial. |
| `play(root)` | `root` | Recorre el árbol y dispara las animaciones correspondientes a cada widget. |
| `cancel(root)` | `root` | Cancela todas las animaciones en curso. |

`TabbedPanel` invoca automáticamente estas funciones al cambiar de pestaña. El comportamiento puede desactivarse mediante la opción `animate_widgets` de la configuración del tema.

### `RowParse`

Utilidad interna para normalizar filas en los widgets que aceptan listas.

**Función**

| Función | Parámetros | Notas |
|---|---|---|
| `parse(row, keys)` | `row` (tabla), `keys` (lista de nombres) | Devuelve los valores en el orden de las claves. Admite formato de tabla con claves o formato posicional. |

---

## 3.8 Convenciones del árbol de widgets

1. **Propagación de ventana.** Al añadir un hijo a un contenedor, este debe llamar a `child:set_window(self.window)` o asignar `child.window = self.window`. Sin esta asignación, el hijo no puede solicitar daños ni acceder al servidor.

2. **Medición en dos pasos.** `askMinMax` no debe modificar el estado interno del widget ni disparar redibujados. Solo calcula y devuelve dimensiones.

3. **Filtrado por daño.** Los contenedores deben invocar `should_draw()` sobre cada hijo antes de dibujarlo. Los widgets hoja no lo necesitan.

4. **Gestión del foco.** Solo un widget puede estar registrado como `window.focus_widget` a la vez. Los widgets que aceptan entrada deben gestionar su propio registro y desregistro.

5. **Optimización de hover y pulsado.** Por defecto, cambiar el estado `hover` o `pressed` no dispara un redibujado. El widget debe declarar `_hover_visual = true` o `_pressed_visual = true` en su constructor si su apariencia cambia con estos estados.

6. **Contrato de `draw_row`.** En widgets con callback de dibujo de filas, el callback debe pintar el fondo completo de la fila, con o sin hover, antes de dibujar su contenido.

7. **Reconstrucción tras mutación de hijos.** Cuando un widget añade, elimina o reemplaza hijos en tiempo de ejecución, debe llamar a `invalidate_layout()` para forzar un relayout. Sin esta llamada, los hijos nuevos quedan con rectángulo nulo y no se dibujan hasta el próximo cambio de tamaño de la ventana.
# 04. Samplers del Sistema

Módulos independientes que leen telemetría y estado del sistema. No dependen del árbol de widgets ni del bucle de eventos, lo que permite usarlos desde scripts externos, desde aplicaciones sin interfaz gráfica o desde cualquier capa del toolkit.

Los samplers se dividen en dos grupos según su coste:

- **Lectura directa**: leen archivos virtuales del kernel (`/proc`, `/sys`). Son seguros para invocar en cada ciclo de refresco.
- **Ejecución de comandos**: invocan utilidades externas. Bloquean el bucle de eventos mientras corren y deben usarse con moderación, desde timers con intervalos largos o mediante `lib.helpers.async`.

---

## 4.1 Registro central

### `init.lua`

**Propósito**  
Reexporta los samplers en una tabla única.

**Uso**

```lua
local D = require("lib.data")
local cpu = D.cpu.sample()
local ram = D.ram.sample()
```

La tabla expone las claves `cpu`, `ram`, `gpu`, `temps`, `disk`, `dispositivos`, `notes`, `config`, `inicio`, `search`, `bat`, `brightness` y `volume`. Los módulos `net`, `wifi`, `ping`, `launcher`, `users`, `last_user` y `session` no están incluidos en el registro y deben requerirse por su ruta completa.

---

## 4.2 Hardware y recursos

### `cpu.lua`

**Propósito**  
Lectura de uso, frecuencia y temperatura del procesador.

**Cómo funciona**  
Parsea `/proc/stat` para calcular el delta entre el tiempo activo y el tiempo inactivo desde el muestreo anterior. Este cálculo requiere conservar el estado entre llamadas, por lo que el módulo debe usarse como instancia única y no recrearse en cada ciclo.

Busca la ruta del sensor `coretemp` en `/sys/class/hwmon/` la primera vez que se invoca y la conserva en cache. Lee la temperatura del paquete (`Package id 0`) o del primer núcleo según disponibilidad.

Obtiene la frecuencia actual del procesador leyendo `scaling_cur_freq` del subsistema `cpufreq`.

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `reset()` | — | — | Limpia el estado previo. Necesario antes del primer muestreo para evitar valores inflados. |
| `sample()` | — | tabla | Campos: `usage` (float entre 0 y 1), `per_core` (tabla indexada por número de núcleo), `n_cores` (número), `freq` (MHz), `temp` (°C). |
| `info()` | — | tabla | Campos `model`, `uptime` (segundos) y `loadavg` (cadena). |
| `freq_range()` | — | tabla | Campos `min` y `max` en MHz. Si el sistema no publica los límites, devuelve 800 y 1100 como valores por defecto. |

**Dependencias**  
`lib.helpers.util`.

### `ram.lua`

**Propósito**  
Lectura de uso de memoria principal y de swap.

**Cómo funciona**  
Parsea `/proc/meminfo` para obtener los valores de memoria total, disponible, usada, caché, buffers, swap total y swap usado. Calcula los porcentajes de uso correspondientes. Lee la configuración de swappiness de `/proc/sys/vm/swappiness`.

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `sample()` | — | tabla | Campos: `total`, `free`, `avail`, `used`, `cached`, `buffers`, `srecl`, `shmem`, `pct`, `swap_total`, `swap_used`, `swap_pct`. Los valores de memoria están en kilobytes. |
| `swappiness()` | — | número | Valor actual, entre 0 y 100. |
| `set_swappiness(v)` | `v` (número) | número | Ajusta el valor. Requiere privilegios y devuelve el valor efectivo. |
| `modules()` | — | tabla o `nil, len` | Lista de módulos de memoria física obtenidos con `dmidecode`. Requiere privilegios. |

**Dependencias**  
`lib.helpers.util`, `dmidecode` (opcional).

### `gpu.lua`

**Propósito**  
Lectura del estado del acelerador gráfico desde un archivo publicado por un servicio externo.

**Cómo funciona**  
Lee `/tmp/gpu-status.txt`, cuyo formato es una línea con siete valores separados por el carácter `|`:

| Campo | Significado |
|---|---|
| `freq` | Frecuencia actual en MHz. |
| `rc6` | Porcentaje de tiempo en estado de bajo consumo. |
| `power` | Consumo estimado en vatios. |
| `irqs` | Número de interrupciones. |
| `render` | Porcentaje de uso del motor de renderizado. |
| `blitter` | Porcentaje de uso del motor de copia. |
| `video` | Porcentaje de uso del motor de vídeo. |

El archivo debe ser mantenido por un servicio del sistema, ya sea un script de `runit`, un servicio de `systemd` o una tarea programada.

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `status()` | — | tabla o `nil` | Devuelve los siete campos. `nil` si el archivo no existe o no tiene el formato esperado. |
| `specs()` | — | tabla | Campos `min`, `max` y `boost` en MHz. Lee los límites desde `/sys/class/drm/card0/`. |

**Dependencias**  
`lib.helpers.util`.

### `temps.lua`

**Propósito**  
Lectura de sensores de temperatura de la CPU y de la placa base.

**Cómo funciona**  
Para la CPU, busca el `hwmon` de `coretemp` en `/sys/class/hwmon/` y lee los archivos `temp*_input` y `temp*_label`. Los nombres de etiqueta habituales son `Package id 0`, `Core 0` y `Core 1`.

Para la placa base, lee las zonas térmicas en `/sys/class/thermal/thermal_zone*/temp`.

El módulo mantiene cache de la lista de archivos una vez escaneada, ya que las rutas no cambian durante la vida del sistema.

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `find_coretemp()` | — | ruta o `nil` | Directorio del hwmon de `coretemp`. |
| `read_coretemp(path)` | `path` | tabla | Campos `core0`, `core1` y `pkg` en grados Celsius. |
| `read_zones()` | — | tabla | Campos `board` y `x86` según las zonas disponibles. |
| `read_smart(cb)` | `cb` (callback) | — | Invoca el callback con la temperatura del disco leída de `/tmp/disk-temp.txt`, o con `nil` si el archivo no existe. |

**Dependencias**  
`lib.helpers.util`.

---

## 4.3 Almacenamiento y red

### `disk.lua`

**Propósito**  
Listado de particiones montadas y lectura de atributos SMART.

**Cómo funciona**  
Ejecuta `df -hP` para obtener las particiones montadas. Descarta las que corresponden a sistemas de archivos virtuales (`tmpfs`, `devtmpfs`, `udev`, `squashfs`, `efivarfs`) y las que están montadas en directorios del sistema (`/run`, `/sys`, `/proc`, `/dev`, `/media`). Enriquece cada entrada con la etiqueta y el tipo de sistema de archivos obtenidos de `lsblk`.

La lectura de SMART se delega a un servicio externo que escribe los atributos en `/tmp/lanetk-smart.tsv`. El archivo se actualiza en segundo plano con `smartctl` y se lee bajo demanda. Esta separación evita bloquear el bucle de eventos con operaciones que tardan varios segundos.

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `partitions()` | — | tabla | Lista de particiones con los campos `dev`, `size`, `used`, `avail`, `pct`, `mount`, `label`, `fs_type`. |
| `smart_read()` | — | tabla o `nil` | Atributos SMART leídos del archivo temporal. |
| `smart_trigger(device)` | `device` (string) | — | Lanza la lectura SMART en segundo plano. `device` por defecto `/dev/sda`. |

**Dependencias**  
`lib.helpers.util`, `df`, `lsblk`, `smartctl`, `jq`.

### `net.lua`

**Propósito**  
Resumen de tráfico de red acumulado por día y datos de la interfaz activa.

**Cómo funciona**  
Lee archivos TSV con formato `timestamp|interfaz|ssid|bytes_rx|bytes_tx` en `~/.local/share/awesome/traffic/`, un archivo por día. Agrega los datos por día, por semana y por mes. El resultado se conserva en cache con un tiempo de vida de 30 segundos.

La información de la interfaz activa se obtiene mediante `ip`, `iwgetid` y lectura de `/sys/class/net/`.

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `traffic_summary()` | — | tabla | Campos `hoy`, `semana` y `mes`, cada uno con `rx`, `tx` y `by_net`. |
| `iface_info(iface)` | `iface` (string) | tabla | Campos `iface`, `tipo`, `ip`, `gw`, `ssid`. |
| `iface_bytes(iface)` | `iface` | tabla o `nil` | Campos `rx` y `tx` en bytes. |

**Dependencias**  
`lib.helpers.util`, `ip`, `iwgetid`.

### `wifi.lua`

**Propósito**  
Información de la conexión inalámbrica activa.

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `iface()` | — | string | Interfaz asociada a la ruta por defecto. |
| `wifi_iface()` | — | string | Primera interfaz inalámbrica detectada. |
| `ssid()` | — | string | SSID de la red activa. |
| `signal_bars(sig)` | `sig` (número) | string | Representación en barras del porcentaje de señal, más el valor numérico. |
| `find_saved(ssid)` | `ssid` (string) | string o `nil` | Nombre de la conexión guardada que coincide con el SSID. |

**Dependencias**  
`lib.helpers.util`, `iw`, `iwgetid`, `nmcli`.

### `ping.lua`

**Propósito**  
Medición de latencia hacia hosts configurables.

**Cómo funciona**  
Mantiene una lista de hosts en `~/.config/awesome/ping-hosts.conf`. El host activo se marca con un asterisco al inicio de la línea. Si el archivo no existe, se usan `1.1.1.1`, `8.8.8.8` y `google.com`.

La ejecución del ping es asíncrona. El comando escribe el resultado en `/tmp/lanetk-ping.txt` y la lectura posterior devuelve el valor si no ha caducado.

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `hosts()` | — | tabla | Campos `list` y `active`. |
| `save(list, active)` | `list`, `active` | — | Persiste la configuración. |
| `add(state, host)` | `state`, `host` | `bool` | Añade un host y lo marca como activo. |
| `set_active(state, host)` | `state`, `host` | `bool` | Marca un host como activo. |
| `ping_async(host)` | `host` | — | Lanza el ping en segundo plano. |
| `ping_read(max_age)` | `max_age` (número) | tabla o `nil` | Campos `ms` y `age`. `max_age` por defecto 5 segundos. |

**Dependencias**  
`lib.helpers.util`, `ping`.

---

## 4.4 Estado del sistema y sesión

### `bat.lua`

**Propósito**  
Lectura del estado de la batería.

**Cómo funciona**  
Localiza el primer dispositivo en `/sys/class/power_supply/BAT*` y lee los archivos de estado, capacidad, corriente y voltaje. Cuando el dispositivo no publica la potencia directamente, la calcula a partir del producto de corriente y voltaje.

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `available()` | — | `bool` | `true` si se detecta una batería. |
| `sample()` | — | tabla o `nil` | Campos: `base`, `status`, `capacity`, `capacity_level`, `technology`, `model`, `vendor`, `serial`, `cycle_count`, `charge_now`, `charge_full`, `charge_full_design`, `current_now`, `voltage_now`, `voltage_min_design`, `power_w`, `charge_full_pct`, `time_hours`. |

**Dependencias**  
`lib.helpers.util`.

### `brightness.lua`

**Propósito**  
Lectura del nivel de brillo de pantalla.

**Cómo funciona**  
Localiza el primer dispositivo en `/sys/class/backlight/` y lee los valores de brillo actual y máximo.

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `available()` | — | `bool` | `true` si se detecta un dispositivo de brillo. |
| `sample()` | — | tabla o `nil` | Campos `pct` (float entre 0 y 1), `cur` y `max`. |

### `volume.lua`

**Propósito**  
Lectura del nivel de volumen y del estado de silencio.

**Cómo funciona**  
Detecta el backend de audio disponible en el sistema siguiendo el orden `pactl`, `wpctl`, `amixer`. La detección se realiza la primera vez y se conserva en cache. Normaliza la salida al mismo formato independientemente del backend.

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `available()` | — | `bool` | `true` si se detecta al menos un backend. |
| `sample()` | — | tabla o `nil` | Campos `pct` (float entre 0 y 1) y `muted` (booleano). |

**Dependencias**  
`pactl`, `wpctl` o `amixer` según disponibilidad.

### `users.lua`

**Propósito**  
Listado de usuarios válidos del sistema.

**Cómo funciona**  
Parsea `/etc/passwd` y filtra por identificador de usuario mayor o igual a 1000 y menor que 60000, shell de login válida y ausencia en la lista negra.

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `list(opts)` | `opts.blacklist` | tabla | Lista de usuarios con los campos `username`, `uid`, `gid`, `home`, `shell`, `display`. El campo `display` proviene del campo GECOS del archivo. |

### `last_user.lua`

**Propósito**  
Persistencia del último usuario autenticado.

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `get()` | — | string o `nil` | Usuario leído del archivo de estado. |
| `set(name)` | `name` (string) | `bool` | Escribe el nombre en el archivo. |

El archivo de estado está en `/var/lib/lefty/last-user` y requiere permisos de escritura.

### `session.lua`

**Propósito**  
Persistencia de preferencias de sesión, principalmente el gestor de ventanas elegido.

**Cómo funciona**  
Lee y escribe el archivo `~/.config/lanetk/session.conf`, que contiene pares `clave = valor`. El módulo mantiene una lista de gestores de ventanas conocidos con nombre y descripción, y filtra los que están instalados en el sistema consultando `$PATH`.

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `get(key)` | `key` (string) | string o `nil` | Lectura de una clave. |
| `set(key, value)` | `key`, `value` | `bool` | Escritura de una clave. |
| `get_wm()` | — | string o `nil` | Gestor de ventanas guardado. |
| `set_wm(name)` | `name` (string) | `bool` | Persiste el gestor seleccionado. |
| `list_installed()` | — | tabla | Gestores de ventanas detectados en el sistema, con los campos `id`, `name`, `desc`, `path`. |

**Dependencias**  
`lib.helpers.util`.

---

## 4.5 Utilidades de datos

### `config.lua`

**Propósito**  
Lectura y escritura de la configuración del entorno almacenada como pares clave-valor en texto plano.

**Cómo funciona**  
Trabaja sobre `~/.config/lane/conf.lua`. El archivo tiene formato `clave = "valor"` y se manipula mediante expresiones regulares. El contenido nunca se evalúa como Lua, lo que permite tratar el archivo como datos y no como código.

Soporta claves con valor booleano, entero o cadena. Las claves nuevas se añaden antes de la línea `return` del archivo, o al final si no existe.

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `get(key)` | `key` (string) | string o `nil` | Lectura como cadena. |
| `set(key, value)` | `key`, `value` | `bool` | Escritura como cadena. |
| `get_bool(key, default)` | `key`, `default` | `bool` | Interpreta los valores `"true"` y `"false"`. |
| `set_bool(key, value)` | `key`, `value` | `bool` | Escritura de un booleano. |
| `get_int(key, default)` | `key`, `default` | número | Interpreta el valor como entero. |
| `set_int(key, value)` | `key`, `value` | `bool` | Escritura de un entero. |
| `list_themes()` | — | tabla | Nombres de los temas disponibles. |
| `list_palettes()` | — | tabla | Nombres de las paletas disponibles. |
| `get_anim_opts()` | — | tabla | Opciones de animación: `animate`, `tabs`, `widgets`, `values`, `hz`, `duration`. |
| `has_locker()` / `has_greeter()` / `has_wallpaper_conf()` | — | `bool` | Comprobaciones de presencia de scripts auxiliares. |

**Dependencias**  
`lib.helpers.util`.

### `notes.lua`

**Propósito**  
Gestión de notas en formato Markdown.

**Cómo funciona**  
Almacena las notas en `~/.config/awesome/notes/`, un archivo por nota. El formato del archivo es `[ ] Título` o `[x] Título` en la primera línea, seguido del cuerpo. El nombre del archivo se deriva del título mediante un proceso de normalización que elimina acentos y caracteres no alfanuméricos.

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `list()` | — | tabla | Notas con los campos `path`, `title`, `done`, `body`, `preview`. |
| `create(title)` | `title` (string) | string | Crea una nota y devuelve su ruta. |
| `delete(path)` | `path` | — | Elimina la nota. |
| `toggle_done(path)` | `path` | — | Alterna el estado de completado. |
| `read(path)` | `path` | tabla o `nil` | Lectura de una nota. |
| `migrate_legacy()` | — | `bool` | Convierte el archivo `notes.txt` del formato antiguo al nuevo. |

**Dependencias**  
`lib.helpers.util`.

### `search.lua`

**Propósito**  
Búsqueda de archivos de forma asíncrona.

**Cómo funciona**  
La búsqueda se realiza en dos fases. La primera invoca `fd` para obtener la lista de rutas que coinciden con la consulta. La segunda ejecuta `stat` sobre cada ruta para enriquecerla con tamaño, fecha de modificación y tipo.

Ambas fases utilizan `lib.helpers.async`, por lo que no bloquean el bucle de eventos. El comando `fd` se ejecuta con `nice` e `ionice` para limitar su impacto en el sistema. Los resultados se limitan a 500 entradas.

Si `fd` no está disponible, la primera fase usa `find` como alternativa.

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `has_fd()` | — | `bool` | Indica si `fd` está disponible. |
| `search(srv, query, root, type, case_sensitive, multi_root, max_depth, cb)` | Ver abajo | — | Ejecuta la búsqueda. `cb` recibe la lista de resultados. |

**Parámetros de `search`**

| Parámetro | Descripción |
|---|---|
| `srv` | Instancia de `Server` para registrar los timers de sondeo. |
| `query` | Consulta de búsqueda. |
| `root` | Directorio raíz. |
| `type` | Filtro por tipo: `"file"`, `"dir"`, `"image"`, `"audio"`, `"video"`, `"doc"` o `nil`. |
| `case_sensitive` | Booleano. |
| `multi_root` | Ruta alternativa cuando se busca en varias raíces. |
| `max_depth` | Profundidad máxima. |
| `cb` | Callback que recibe la lista de resultados. Cada resultado tiene los campos `path`, `name`, `size`, `mtime`, `is_dir`. |

**Dependencias**  
`lib.helpers.async`, `lib.helpers.util`, `fd` o `find`, `stat`, `xargs`.

### `launcher.lua`

**Propósito**  
Escaneo, búsqueda y ejecución de aplicaciones a partir de archivos `.desktop`.

**Cómo funciona**  
Lee los archivos `.desktop` de `/usr/share/applications`, `/usr/local/share/applications` y `~/.local/share/applications`. Descarta las entradas con `NoDisplay = true` o `Hidden = true` y las que no declaran nombre o comando. Limpia los marcadores de posición del comando.

Mantiene un historial de uso en `~/.cache/lanetk-launcher-history`, con el número de veces que se ha lanzado cada aplicación. El historial permite priorizar las aplicaciones más usadas en los resultados de búsqueda.

El índice de iconos se construye una sola vez, filtrando por los nombres declarados por las aplicaciones instaladas, y se conserva en `~/.cache/lanetk-icon-index.tsv`.

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `scan()` | — | número | Reescanea los directorios de aplicaciones. Devuelve el número de entradas encontradas. |
| `search(query)` | `query` (string) | tabla | Búsqueda por relevancia. La consulta `"> comando"` devuelve una entrada que ejecuta el comando directamente. Una consulta vacía devuelve el historial seguido del resto de aplicaciones. |
| `execute(entry)` | `entry` (tabla) | — | Ejecuta la entrada y registra el uso en el historial. |
| `history_top(n)` | `n` (número) | tabla | Devuelve las `n` aplicaciones más lanzadas. |
| `record_usage(entry)` | `entry` | — | Registra el uso de una entrada. |
| `find_icon(name)` | `name` (string) | ruta o `nil` | Localiza el icono por nombre. |

**Dependencias**  
`lib.helpers.util`, `find`.

### `dispositivos.lua`

**Propósito**  
Descubrimiento de dispositivos en la red local.

**Cómo funciona**  
Lee la tabla de vecinos ARP del kernel con `ip neigh` y enriquece cada entrada con información adicional: fabricante, resuelto mediante una tabla OUI parcial y heurística sobre direcciones localmente administradas; nombre de host, resuelto con `avahi-resolve` o `getent hosts`; y estado de la última vez vista, persistido en `~/.cache/awesome-net-seen`.

Los dispositivos propios se detectan comparando las direcciones MAC con las interfaces locales y se priorizan en el listado.

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `local_macs()` | — | tabla | Direcciones MAC de las interfaces locales, indexadas por interfaz. |
| `scan(use_arpscan, cb)` | `use_arpscan` (booleano), `cb` (callback) | — | Ejecuta el escaneo y llama al callback con la lista de dispositivos. |

**Dependencias**  
`lib.helpers.util`, `ip`, `avahi-resolve` o `getent`.

### `inicio.lua`

**Propósito**  
Datos estáticos y de presentación para la pantalla de bienvenida.

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `user()` | — | string | Nombre del usuario actual. |
| `host()` | — | string | Nombre del equipo. |
| `distro()` | — | string | Nombre de la distribución, extraído de `/etc/os-release`. |
| `kernel()` | — | string | Versión del kernel. |
| `uptime_secs()` | — | número | Tiempo de actividad en segundos. |
| `ip_local()` | — | string | Dirección IP local, o `"sin red"`. |
| `screens()` | — | número | Número de pantallas conectadas. |
| `shell_name()` | — | string | Nombre del shell del usuario. |
| `find_avatar(username)` | `username` (opcional) | ruta o `nil` | Localiza el avatar del usuario. Si el archivo no está en formato PNG, lo convierte y lo cachea en `~/.cache/lanetk/avatar-<usuario>.png`. |

**Dependencias**  
`lib.helpers.util`, `hostname`, `uname`, `ip`, `xrandr`, `ffmpeg` o `magick` o `convert` (para conversión de avatares).

---

## 4.6 Convenciones y anti-patrones

1. **Sin bloqueo del bucle de eventos.** Los samplers que ejecutan comandos externos (`ping`, `search`, `dispositivos`, `disk.smart_trigger`) usan `lib.helpers.async` o se invocan desde timers con intervalos largos. Los samplers de lectura directa (`cpu`, `ram`, `bat`, `brightness`, `volume`, `temps`) son seguros para invocar en cada ciclo de refresco.

2. **Estado entre muestreos.** Los samplers que calculan deltas (`cpu`, `net`) conservan el estado entre llamadas. Deben usarse como instancia única. Crear una instancia nueva en cada ciclo produce valores incorrectos.

3. **Rutas estándar.** Los samplers asumen las rutas habituales de Linux en `/proc` y `/sys`. En sistemas con configuraciones personalizadas puede ser necesario ajustar las rutas en el código del sampler.

4. **Cacheo de rutas.** Módulos que localizan un dispositivo concreto (`cpu` para `coretemp`, `brightness` para el dispositivo de brillo) cachean la ruta tras el primer escaneo. Esto evita recorrer directorios en cada muestreo.

5. **Persistencia de configuración.** Los samplers que leen o escriben configuración del usuario (`ping`, `session`, `config`, `notes`) respetan las rutas convencionales de XDG y son tolerantes a la ausencia del archivo.
# 05. Integración con el Entorno

Módulos que conectan LaneTK con servicios externos del sistema: gestores de ventanas, protocolos de sesión, sistema de archivos, temas de iconos y demás. Ninguno pertenece al núcleo del motor gráfico ni al catálogo de widgets, pero todos son parte de la API pública del toolkit.

---

## 5.1 `ewmh.lua`

**Propósito**  
Lectura y escritura de propiedades EWMH del root de la pantalla y de las ventanas cliente. Proporciona una capa de abstracción sobre el protocolo que permite interactuar con gestores de ventanas compatibles sin depender de comandos externos como `wmctrl` o `bspc`.

**Cómo funciona**  
Al construirse, la instancia interna todos los átomos EWMH utilizados por la API y los cachea por conexión. Los átomos no cambian durante la vida de una conexión X, por lo que el cacheo es seguro y evita round-trips innecesarios.

La lectura de propiedades utiliza `xcb_get_property` con la longitud adecuada al tipo. Los formatos de 8 bits se devuelven como cadenas, y los de 16 o 32 bits como tablas de enteros.

La escritura se realiza mediante dos mecanismos distintos según la propiedad:

- Las propiedades que expresan una petición al gestor de ventanas (`_NET_CURRENT_DESKTOP`, `_NET_ACTIVE_WINDOW`, `_NET_CLOSE_WINDOW`, `_NET_WM_STATE`) se envían como `ClientMessage` al root. El gestor de ventanas las recibe y actúa según su política.
- Las propiedades que expresan un atributo de la ventana (`_NET_WM_DESKTOP`) se escriben directamente con `change_property`.

El módulo permite un único observador de eventos del root a la vez. La suscripción se realiza mediante `subscribe`, que registra el hook `on_root_event` del servidor y activa `PropertyChange` sobre el root.

**Dependencias**  
`lib.xcb`, `lib.log`, `bit`, `ffi`.

### API

| Función / Método | Parámetros | Retorno | Notas |
|---|---|---|---|
| `new(srv)` | `srv` (instancia de `Server`) | instancia EWMH | Interna los átomos por conexión. |
| `ewmh:wm_name()` | — | string o `nil` | Nombre del gestor de ventanas activo. |
| `ewmh:supported()` | — | tabla | Lista de átomos EWMH soportados por el WM. |
| `ewmh:client_list()` | — | tabla | Lista de ventanas gestionadas, en orden de creación. |
| `ewmh:client_list_stacking()` | — | tabla | Lista de ventanas en orden de apilamiento. |
| `ewmh:active_window()` | — | window id o `nil` | Ventana que tiene el foco. |
| `ewmh:current_desktop()` | — | número o `nil` | Índice del escritorio activo, base 0. |
| `ewmh:desktop_count()` | — | número o `nil` | Número total de escritorios. |
| `ewmh:desktop_names()` | — | tabla | Nombres de los escritorios. |
| `ewmh:window_name(wid)` | `wid` | string o `nil` | Nombre de la ventana. Prueba `_NET_WM_NAME` y cae a `WM_NAME`. |
| `ewmh:window_desktop(wid)` | `wid` | número o `nil` | Índice del escritorio de la ventana. `nil` si la ventana es sticky. |
| `ewmh:set_current_desktop(n)` | `n` (número) | `bool` | Envía `_NET_CURRENT_DESKTOP`. Base 0. |
| `ewmh:activate_window(wid, source?)` | `wid`, `source` | `bool` | Envía `_NET_ACTIVE_WINDOW`. `source` por defecto 0. |
| `ewmh:close_window(wid)` | `wid` | `bool` | Envía `_NET_CLOSE_WINDOW`. El cliente puede cancelar el cierre. |
| `ewmh:move_window_to_desktop(wid, n)` | `wid`, `n` | `bool` | Escribe `_NET_WM_DESKTOP`. Algunos gestores lo ignoran. |
| `ewmh:wm_state(wid, action, state1, state2)` | `wid`, `action` (0, 1 o 2), `state1`, `state2` | `bool` | Envía `_NET_WM_STATE`. Acciones: 0 = remove, 1 = add, 2 = toggle. |
| `ewmh:subscribe(cb)` | `cb` (callback) | — | Se suscribe a `PropertyNotify` del root. El callback recibe `(atom, wid)`. |
| `ewmh:unsubscribe()` | — | — | Cancela la suscripción. |

### Uso

```lua
local ewmh = require("lib.ewmh").new(srv)

print(ewmh:wm_name())
for _, wid in ipairs(ewmh:client_list()) do
    print(wid, ewmh:window_name(wid))
end

ewmh:set_current_desktop(2)
ewmh:activate_window(0x1400003)
```

### Anti-patrones

- **No asumir que el gestor de ventanas soporta todas las propiedades.** Consultar `ewmh:supported()` antes de operaciones críticas. Los mensajes no soportados se descartan silenciosamente.
- **No crear dos instancias de EWMH sobre la misma conexión.** Los átomos se duplicarían en el cache y la suscripción se pisaría.
- **No usar EWMH para operaciones por debajo del nivel del gestor de ventanas.** Si el WM es un tiling gestor propio (por ejemplo `bspwm`), sus comandos nativos (`bspc`) ofrecen un control más fino que el protocolo EWMH.

---

## 5.2 `greetd.lua`

**Propósito**  
Cliente síncrono del protocolo de greetd sobre socket Unix. Permite autenticar un usuario, crear una sesión y lanzarla, cerrando la conexión al terminar.

**Cómo funciona**  
El protocolo de greetd es JSON con delimitación por longitud. Cada mensaje se envía con un prefijo de 32 bits little-endian que indica la longitud del payload JSON. Los mensajes son de cuatro tipos:

| Tipo | Dirección | Propósito |
|---|---|---|
| `create_session` | cliente → servidor | Inicia el flujo de autenticación para un usuario. |
| `auth_message` | servidor → cliente | Solicita una respuesta (contraseña, confirmación, etc.). |
| `post_auth_message_response` | cliente → servidor | Envía la respuesta al mensaje previo. |
| `start_session` | cliente → servidor | Arranca la sesión autenticada. |
| `cancel_session` | cliente → servidor | Cancela el flujo de autenticación. |

El socket se obtiene de la variable de entorno `GREETD_SOCK`, que greetd exporta antes de lanzar el greeter.

La llamada a `start_session` no espera respuesta. Greetd procesa el mensaje, mata al proceso del greeter y lanza la sesión del usuario. Si el cliente esperara una respuesta, quedaría en deadlock. El método cierra el socket inmediatamente después de enviar el mensaje.

**Dependencias**  
`bindings.cdef.net`, `lib.helpers.json`, `lib.log`, `bit`.

### API

| Función / Método | Parámetros | Retorno | Notas |
|---|---|---|---|
| `connect(sock_path?)` | `sock_path` (opcional) | cliente o `nil, err` | Si `sock_path` es nulo, usa `GREETD_SOCK`. |
| `client:create_session(username, cb)` | `username`, `cb(kind, data)` | — | Inicia el flujo. El callback recibe el tipo y los datos del mensaje. |
| `client:post_auth_response(response, cb)` | `response`, `cb` | — | Responde al último `auth_message`. `response` puede ser nulo. |
| `client:start_session(cmd)` | `cmd` (tabla de strings) | — | Arranca la sesión. No espera respuesta. Cierra el socket. |
| `client:cancel_session()` | — | — | Cancela el flujo. |
| `client:close()` | — | — | Cierra el socket si sigue abierto. |

### Tipos de mensaje recibidos por el callback

El callback registrado en `create_session` recibe un primer argumento que identifica el tipo de mensaje:

| Tipo | Significado |
|---|---|
| `"auth_message"` | El servidor solicita una respuesta. `data.auth_message_type` indica si el input es visible o secreto. |
| `"success"` | Autenticación completada. A continuación se debe llamar a `start_session`. |
| `"error"` | Error de autenticación. `data.error_type` y `data.description` describen el problema. |
| `"io_error"` | Falla de comunicación con el socket. |
| `"parse_error"` | El mensaje recibido no pudo decodificarse. |

### Uso

```lua
local greetd = require("lib.greetd")

local cli, err = greetd.connect()
if not cli then error(err) end

local function on_message(kind, data)
    if kind == "auth_message" then
        local respuesta = obtener_input_del_usuario(data)
        cli:post_auth_response(respuesta, on_message)
    elseif kind == "success" then
        cli:start_session({ "startx" })
        os.exit(0)
    elseif kind == "error" then
        mostrar_error(data.description)
    end
end

cli:create_session("ansmoun", on_message)
```

### Anti-patrones

- **No esperar respuesta de `start_session`.** Produce deadlock. El método cierra el socket intencionalmente.
- **No compartir una instancia de cliente entre autenticaciones simultáneas.** El protocolo es secuencial.
- **No cerrar el socket antes de tiempo.** Greetd interpreta el cierre del cliente como abandono de la sesión.

---

## 5.3 `reload.lua`

**Propósito**  
Mecanismo de recarga en caliente entre procesos mediante señales POSIX, sin handlers en Lua. Permite que un cambio de configuración en un proceso se propague a los demás sin reiniciarlos.

**Cómo funciona**  
El mecanismo se apoya en `signalfd`, una interfaz de Linux que representa las señales como descriptores de archivo legibles. Esto evita el uso de handlers de señal en Lua, que serían inseguros porque LuaJIT no permite reentrar su runtime desde un contexto de señal.

El procedimiento es el siguiente:

1. `install` bloquea `SIGUSR1` en el proceso mediante `sigprocmask`. Al estar bloqueada, la señal no interrumpe la ejecución: queda pendiente en el kernel.
2. Se crea un `signalfd` asociado a `SIGUSR1` y se registra en el servidor mediante `add_fd`.
3. Cuando llega una señal, el descriptor se marca legible. El servidor invoca el callback, que hace `read` para drenar el descriptor y luego llama a los observadores registrados.

La emisión se realiza con `broadcast`, que envía `SIGUSR1` a todos los procesos cuyo nombre coincida con `apps/*.lua`, excepto el propio emisor.

**Dependencias**  
`lib.log`, `ffi`.

### API

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `install(srv, cb)` | `srv`, `cb` (callback) | `fd` o `nil` | Instala el mecanismo y registra el callback. Instalaciones sucesivas añaden callbacks al mismo signalfd. |
| `broadcast()` | — | número | Envía `SIGUSR1` a todos los procesos `apps/*.lua` activos excepto el actual. Devuelve el número de procesos señalados. |

### Uso

```lua
local reload = require("lib.reload")

reload.install(srv, function()
    -- Reconstruir la interfaz con la configuración nueva
    rebuild_ui()
end)

-- En el proceso que cambia la configuración:
reload.broadcast()
```

### Anti-patrones

- **No usar `signal()` con handlers en Lua.** LuaJIT no permite reentrar su runtime desde un handler. El proceso muere con `PANIC: unprotected error in call to Lua API`.
- **No enviar la señal a procesos que no la esperan.** Los procesos sin `signalfd` reciben el `SIGUSR1` por defecto, cuya acción es terminar. Restringir el `broadcast` a procesos conocidos.
- **No llamar `install` antes de inicializar el servidor.** El descriptor no puede registrarse sin un servidor activo.

---

## 5.4 `xsessions.lua`

**Propósito**  
Lectura de las sesiones gráficas disponibles en el sistema a partir de los archivos `.desktop` instalados en `/usr/share/xsessions` y en el directorio de usuario.

**Cómo funciona**  
Lee los archivos `.desktop` y extrae los campos `Name`, `Exec` y `Comment`. Descarta las entradas marcadas como `NoDisplay`, `Hidden`, o que no tengan el campo `Exec`. Limpia los sufijos de traducción del nombre (`Nombre (variante)`) y construye un identificador a partir del nombre del archivo.

El directorio del usuario tiene precedencia sobre el directorio del sistema: si existen dos archivos con el mismo identificador, se conserva el del usuario.

**Dependencias**  
`lib.helpers.util`.

### API

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `list()` | — | tabla | Lista de sesiones, cada una con los campos `id`, `name`, `exec`, `comment`. Ordenadas alfabéticamente. |
| `build_command(id)` | `id` (string) | tabla de strings o `nil` | Construye el comando a pasar a `greetd:start_session`. Devuelve `{"startx"}` para las sesiones de `/usr/share/xsessions`. |

### Uso

```lua
local xsessions = require("lib.xsessions")

for _, s in ipairs(xsessions.list()) do
    print(s.id, s.name, s.exec)
end

local cmd = xsessions.build_command("bspwm")
-- cmd = { "startx" }
```

### Anti-patrones

- **No invocar `startx` con un cliente explícito.** Ignora `~/.xinitrc` y puede pisar el VT activo cuando greetd ya ha cambiado de consola.
- **No asumir que todas las sesiones son X11.** La implementación actual devuelve `startx` para todas las entradas, lo que es correcto para sesiones X11 pero no para sesiones Wayland.

---

## 5.5 `wallpaper.lua`

**Propósito**  
Establecimiento del fondo de escritorio de forma nativa, sin invocar programas externos de gestión de escritorio salvo `ffmpeg` para la decodificación.

**Cómo funciona**  
El módulo decodifica la imagen de origen con `ffmpeg` al tamaño y formato requeridos, sube el resultado al servidor X como pixmap, y crea una ventana con `override_redirect` que ocupa el monitor objetivo con el pixmap como fondo.

La decodificación se realiza a formato `BGRA` en bruto, que coincide con el formato `ZPixmap` esperado por `xcb_put_image` en modo little-endian.

El módulo admite los siguientes modos de ajuste:

| Modo | Comportamiento |
|---|---|
| `"cover"` | Escala la imagen para cubrir el monitor por completo, recortando el excedente. |
| `"contain"` | Escala la imagen para caber entera en el monitor, con bandas negras donde no alcanza. |
| `"stretch"` | Estira la imagen sin respetar el aspect ratio. |
| `"center"` | Coloca la imagen centrada a tamaño nativo, con bandas negras o recorte según corresponda. |

El objeto devuelto por `set` expone un método `close` que destruye las ventanas y libera los pixmaps asociados.

**Dependencias**  
`lib.xcb`, `lib.screens`, `lib.log`.

### API

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `set(srv, path, opts)` | `srv`, `path` (string), `opts.mode`, `opts.monitor` | handle o `nil, err` | Aplica el fondo. `opts.mode` por defecto `"cover"`. `opts.monitor` limita la aplicación a un monitor concreto. |
| `handle:close()` | — | — | Destruye las ventanas y libera los pixmaps. |

### Uso

```lua
local wallpaper = require("lib.wallpaper")

local handle, err = wallpaper.set(srv, "/ruta/fondo.png", { mode = "cover" })
if not handle then
    log.error("wallpaper", "fallo: %s", err)
end

-- Para retirar el fondo:
handle:close()
```

### Anti-patrones

- **No llamar `set` desde `on_draw`.** Ejecuta `ffmpeg`, que es bloqueante. Invocarlo desde un callback puntual o desde el arranque.
- **No asumir que `ffmpeg` está disponible.** El módulo devuelve `nil, err` cuando no lo encuentra.
- **No dejar handles sin cerrar.** Cada aplicación de fondo crea ventanas y pixmaps que consumen recursos del servidor X.

---

## 5.6 `thumbs.lua`

**Propósito**  
Generación y cache de miniaturas de imágenes, usando `ffmpeg` para la decodificación y almacenando el resultado como PNG en el directorio de cache del usuario.

**Cómo funciona**  
Cada miniatura se identifica por el hash FNV-1a de 32 bits de la ruta de origen, más el tamaño solicitado. El archivo resultante se almacena en `~/.cache/lane/thumbs/`. Si la miniatura ya existe, se devuelve su ruta sin volver a generarla.

El escalado respeta el aspect ratio original: el lado más largo de la miniatura coincide con el tamaño solicitado. No se añade padding.

**Dependencias**  
`ffmpeg` como comando externo.

### API

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `ensure(src, size?)` | `src` (string), `size` (número) | ruta del PNG o `nil` | Genera la miniatura si no existe. `size` por defecto 128. |
| `path_for(src)` | `src` (string) | string | Ruta que tendría la miniatura. No genera nada. |
| `clear()` | — | — | Borra el directorio de cache completo. |
| `size()` | — | número | Tamaño por defecto. |

### Uso

```lua
local thumbs = require("lib.thumbs")

local thumb = thumbs.ensure("/home/user/foto.jpg", 256)
if thumb then
    -- Cargar la miniatura con cairo.load_png_cached(thumb)
end
```

### Anti-patrones

- **No llamar `ensure` desde `on_draw`.** Ejecuta `ffmpeg` de forma bloqueante. Generar en segundo plano y notificar al widget cuando esté lista.
- **No usar `path_for` como si generara la miniatura.** Solo devuelve la ruta que tendría.

---

## 5.7 `icon_theme.lua`

**Propósito**  
Resolución de iconos por nombre a partir del tema de iconos activo en el sistema, con soporte de herencia entre temas.

**Cómo funciona**  
Detecta el tema activo leyendo la configuración de GTK en este orden:

1. `~/.config/gtk-3.0/settings.ini`
2. `~/.config/gtk-4.0/settings.ini`
3. `~/.gtkrc-2.0`

Si no encuentra ninguno, usa `hicolor`.

A partir del tema activo, construye la cadena de herencia leyendo el campo `Inherits` del archivo `index.theme` de cada tema. La búsqueda se realiza en orden: primero el tema activo, después sus ancestros.

Para cada tema, busca el archivo con las extensiones `.svg` y `.png`, en directorios de tamaño estándar (`scalable` y una lista de tamaños comunes). Los nombres se resuelven en categorías habituales (`mimetypes`, `places`, `actions`, `devices`, `apps`, etc.).

Los resultados se almacenan en cache tanto por ruta como por superficie Cairo resuelta.

**Dependencias**  
`lib.helpers.util`, `lib.svg`, `lib.cairo`.

### API

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `theme()` | — | string | Nombre del tema activo. |
| `parents()` | — | tabla | Cadena de herencia del tema activo. |
| `find_path(name, size?)` | `name`, `size` | ruta o `nil` | Ruta del archivo del icono. `size` por defecto 22. |
| `resolve(name, size?)` | `name`, `size` | surface o `nil` | Superficie Cairo lista para dibujar. Los SVG se renderizan al tamaño solicitado. |
| `clear_cache()` | — | — | Libera los surfaces y vacía los caches de ruta y de superficie. |

### Uso

```lua
local icon_theme = require("lib.icon_theme")

local surface = icon_theme.resolve("folder", 32)
if surface then
    cairo.draw_surface(cr, surface, x, y, 32, 32)
end
```

### Anti-patrones

- **No llamar `resolve` en cada frame.** Consulta el disco. Guardar la superficie resultante en el widget que la utiliza.
- **No llamar `clear_cache` mientras haya widgets en pantalla con superficies resueltas.** La superficie devuelta queda destruida y el widget dibujará con memoria liberada.

---

## 5.8 `icons.lua`

**Propósito**  
Resolución de iconos propios del toolkit, almacenados en los directorios `icons-src` (SVG) e `icons-png` (PNG) del repositorio de LaneTK.

**Cómo funciona**  
Construye un índice de todos los archivos presentes en ambos directorios, registrando cada archivo bajo todos sus sufijos de ruta y con y sin extensión. Un mismo icono queda accesible por múltiples rutas.

Ejemplo: el archivo `icons-src/awesome/tabs/home.svg` se registra bajo las claves `awesome/tabs/home.svg`, `awesome/tabs/home`, `tabs/home.svg`, `tabs/home`, `home.svg` y `home`.

Si un nombre existe en ambos formatos, prevalece el SVG sobre el PNG.

El directorio raíz se toma de la variable de entorno `PWD` o, si no está definida, del directorio actual. La función `set_root` permite indicarlo explícitamente.

**Dependencias**  
`lib.svg`, `lib.cairo`.

### API

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `root()` | — | string | Directorio raíz para la búsqueda. |
| `set_root(path)` | `path` (string) | — | Cambia el directorio raíz. Invalida el índice. |
| `find(name)` | `name` (string) | ruta o `nil` | Ruta del archivo que corresponde al nombre. |
| `surface(name, size?)` | `name`, `size` | surface o `nil` | Superficie Cairo lista para dibujar. Los SVG se renderizan al tamaño indicado. |
| `clear_cache()` | — | — | Vacía el cache de superficies resueltas. |

### Uso

```lua
local icons = require("lib.icons")

local surf = icons.surface("tabs/home", 24)
if surf then
    cairo.draw_surface(cr, surf, x, y, 24, 24)
end
```

### Anti-patrones

- **No llamar `find` ni `surface` desde `on_draw`.** La primera consulta construye el índice recorriendo el árbol de archivos con `find`. Hacerlo en el arranque o tras el primer acceso, no en el bucle de render.
- **No compartir superficies resueltas entre procesos.** El cache es local al proceso.
- **No llamar `clear_cache` mientras haya widgets en pantalla.** Aplica la misma advertencia que en `icon_theme`.
# 06. Helpers

Utilidades de propósito general que no dependen de X11 ni del árbol de widgets. Son ligeras, testeables de forma aislada y reutilizables desde cualquier capa del toolkit o desde scripts externos.

---

## 6.1 `util.lua`

**Propósito**  
Operaciones básicas de sistema, manipulación de cadenas y gestión de archivos de configuración en texto plano.

**Cómo funciona**  
Envuelve las funciones de `io` y `os` en interfaces predecibles. Las funciones de configuración (`read_conf_key`, `write_conf_key`) operan mediante expresiones regulares sobre el texto, sin evaluar el contenido como Lua. Esto permite tratar los archivos de configuración como datos y no como código, evitando la ejecución de contenido no confiable.

### API

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `trim(s)` | `s` (string) | string | Recorta espacios al inicio y al final. Si el argumento no es una cadena, lo devuelve sin modificar. |
| `read_file(path)` | `path` (string) | string o `nil` | Lee el archivo completo. |
| `write_file(path, content)` | `path`, `content` | `bool` | Sobrescribe el archivo. |
| `shell_once(cmd)` | `cmd` (string) | string | **Bloqueante.** Ejecuta el comando y devuelve su salida estándar. |
| `list_files(dir, ext?)` | `dir`, `ext` (por defecto `"lua"`) | tabla | Nombres base de los archivos con la extensión indicada, excluyendo `README`, ordenados alfabéticamente. |
| `read_conf_key(file, key)` | `file`, `key` | string o `nil` | Busca el patrón `key = "valor"` en el archivo. |
| `write_conf_key(file, key, val)` | `file`, `key`, `val` | `bool` | Reescribe el valor. Devuelve `false` si la clave no existe. |
| `home()` | — | string | Directorio del usuario. Devuelve `"/"` si `$HOME` no está definido. |

### Anti-patrones

- **No usar `shell_once` con comandos lentos** (`dmidecode`, `smartctl`, `ping`) desde un callback del bucle de eventos. Bloquea el repintado. Usar `lib.helpers.async`.

---

## 6.2 `format.lua`

**Propósito**  
Formateadores de valores numéricos a cadenas legibles para la interfaz de usuario.

### API

| Función | Parámetros | Retorno | Ejemplo |
|---|---|---|---|
| `mb(kb)` | `kb` (número) | string | `1234567` → `"1.2 GB"` |
| `bytes(b)` | `b` (número) | string | `1536` → `"1.5 KB"` |
| `speed(bps)` | `bps` (número) | string | `1048576` → `"1.0 MB/s"` |
| `uptime(secs)` | `secs` (número) | string | `90000` → `"1d 1h 0m"` |
| `date()` | — | string | `"Domingo, 20 de septiembre de 2026"` |
| `greeting(hour?)` | `hour` (número entre 0 y 23) | string | `"Buenos días,"`, `"Buenas tardes,"` o `"Buenas noches,"` |

### Notas

- `mb` espera kilobytes, que es la unidad que devuelve `/proc/meminfo`. `bytes` espera bytes.
- `date` y `greeting` están escritos en español y no se adaptan al locale del sistema.

---

## 6.3 `async.lua`

**Propósito**  
Ejecución de comandos de shell en segundo plano sin bloquear el bucle de eventos.

**Cómo funciona**  
Crea un script temporal en `/tmp` que redirige la salida estándar y la salida de error a archivos separados, y escribe el código de salida al terminar. El script se lanza en segundo plano. Un timer registrado en el servidor consulta cada 150 milisegundos la existencia del archivo de finalización. Cuando aparece, el módulo lee los resultados, limpia los archivos temporales e invoca el callback.

El mecanismo produce cuatro archivos temporales por invocación: el script, el archivo de salida estándar, el archivo de salida de error y el archivo de código de salida. Todos se eliminan al terminar la ejecución, salvo que el handle se cancele antes.

### API

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `async_shell(srv, cmd, cb)` | `srv` (instancia de `Server`), `cmd` (string), `cb` (función) | handle | El callback recibe `(code, stdout, stderr)`. El handle expone `handle:cancel()`. |

### Uso

```lua
local async = require("lib.helpers.async")

local handle = async.async_shell(srv, "ls -la /tmp", function(code, out, err)
    if code == 0 then
        print(out)
    else
        print("error:", err)
    end
end)

-- Para cancelar antes de que termine:
-- handle:cancel()
```

### Anti-patrones

- **No lanzar múltiples instancias del mismo comando sin coordinar.** Cada invocación crea su propio conjunto de archivos temporales. No hay colisión entre procesos distintos, pero se consume espacio y descriptores.
- **No usar `async_shell` para operaciones instantáneas.** El sondeo cada 150 ms introduce un retardo mínimo mayor que el de `shell_once` para comandos que terminan en menos de 50 ms.

---

## 6.4 `graphics.lua`

**Propósito**  
Primitivas de dibujo Cairo de alto nivel. Se ocupa de formas y colores. El texto se delega a `lib.pango`.

**Cómo funciona**  
Encapsula las operaciones más repetitivas de Cairo: conversión de colores hexadecimales a componentes RGB, barras de progreso, barras apiladas, anillos y gráficos de líneas. Incluye un buffer circular para series temporales.

### API

| Función | Parámetros | Notas |
|---|---|---|
| `hex_to_rgba(hex, alpha?)` | `hex` (`"#RRGGBB"` o `"#RGB"`), `alpha` entre 0 y 1 | Devuelve `r, g, b, a` como cuatro números, no como tabla. |
| `set_color(cr, hex, alpha?)` | Contexto Cairo, cadena hexadecimal, alpha opcional | Aplica el color al contexto. |
| `bar(cr, x, y, w, h, pct, opts)` | `pct` entre 0 y 1. `opts.fg`, `opts.bg`, `opts.radius` | Barra horizontal con relleno proporcional. Ajusta el radio si el relleno es menor que el diámetro. |
| `stacked_bar(cr, x, y, w, h, segs, opts)` | `segs` es una lista de tablas `{ pct, color }` | Barra con segmentos apilados. Aplica un clip redondeado final. |
| `ring(cr, cx, cy, r, pct, opts)` | `opts.thickness`, `opts.fg`, `opts.bg`, `opts.start_angle`, `opts.end_angle` | Anillo de progreso. El ángulo inicial por defecto apunta hacia arriba. |
| `sparkline(cr, x, y, w, h, data, opts)` | `data` es una lista de números | Gráfico de líneas con soporte de animación. |
| `history(size)` | `size` (número) | Buffer circular. Métodos `push(v)`, `get()` y `clear()`. |

### Opciones de `sparkline`

| Opción | Descripción |
|---|---|
| `fg` | Color de la línea. |
| `fill` | Si es `true`, rellena el área bajo la línea. |
| `width` | Grosor de la línea. |
| `alpha` | Multiplicador de opacidad aplicado al conjunto. |
| `min`, `max` | Rango del eje. Si se omiten, se calcula a partir de los datos. |
| `size` | Número de puntos que representa el ancho completo. Evita el reescalado visual cuando el buffer no está lleno. |
| `scroll` | Desplazamiento horizontal entre 0 y 1. |
| `tail` | Trazo progresivo del último segmento entre 0 y 1. |
| `reveal` | Ancho visible entre 0 y 1, con recorte desde la izquierda. |

Las opciones `scroll` y `tail` están diseñadas para ser animadas por `lib.anim` y producir transiciones suaves cuando llegan nuevos datos.

### Anti-patrones

- **No pasar una tabla de color a `set_color`.** Espera argumentos separados o una cadena hexadecimal.
- **No invocar `sparkline` con menos de dos puntos.** La función retorna sin dibujar.

---

## 6.5 `json.lua`

**Propósito**  
Parser y encoder JSON sin dependencias externas.

**Cómo funciona**  
Implementa el análisis y la generación de JSON en Lua puro. El decoder admite los tipos básicos del estándar, incluidos números en notación científica, cadenas con escapes y pares de sustitución Unicode. El encoder serializa tablas, cadenas, números, booleanos y los marcadores explícitos de nulo.

### Convenciones del encoder

- Una tabla vacía se serializa como `{}`.
- Una tabla con claves consecutivas desde 1 se serializa como array.
- Una tabla con claves de tipo cadena se serializa como objeto.
- Una tabla con claves mixtas produce un error.

### Marcadores públicos

| Marcador | Descripción |
|---|---|
| `json.NULL` | Representa el valor `null` del estándar. Se usa cuando es necesario incluir un nulo explícito dentro de un array, ya que el valor `nil` de Lua corta la secuencia. |
| `json.EMPTY_ARRAY` | Fuerza la serialización como `[]` en lugar de `{}` para una tabla vacía. |

### API

| Función | Parámetros | Retorno | Notas |
|---|---|---|---|
| `decode(s)` | `s` (string) | valor o `nil, err` | Devuelve el valor decodificado o un mensaje de error. |
| `encode(v)` | `v` | string o `nil, err` | Devuelve la representación JSON del valor o un mensaje de error. |

### Uso

```lua
local json = require("lib.helpers.json")

local v, err = json.decode('{"a": 1, "b": [true, null]}')
-- v = { a = 1, b = { true, json.NULL } }

local s = json.encode({ a = 1, b = { true, json.NULL } })
-- s = '{"a":1,"b":[true,null]}'
```

### Anti-patrones

- **No usar `nil` dentro de un array para representar un nulo.** En Lua, un `nil` en una tabla no forma parte de la secuencia. Usar `json.NULL`.
- **No usar el módulo para documentos grandes.** Es un parser recursivo sin streaming. Para cargas de varios megabytes conviene usar una biblioteca en C.

---

## 6.6 `init.lua`

**Propósito**  
Reexporta los helpers en una tabla única.

**Uso**

```lua
local helpers = require("lib.helpers")
local u = helpers.util
local f = helpers.format
```

La tabla expone las claves `util` y `format`. Los módulos `async`, `graphics` y `json` no están incluidos y deben requerirse por su ruta completa. Esta decisión evita cargar dependencias pesadas de Cairo o del bucle de eventos cuando solo se necesitan utilidades básicas.
