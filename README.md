# LaneTK

**Toolkit gráfico en LuaJIT y FFI para interfaces de escritorio sobre X11.**

LaneTK proporciona el motor de renderizado, el sistema de widgets, el bucle de eventos y la infraestructura de animación necesarios para construir barras, paneles, lanzadores y aplicaciones de escritorio completas. Está escrito íntegramente en LuaJIT sobre bindings FFI directos a las bibliotecas nativas del sistema, sin puentes en C ni capas intermedias.

---

## Motivación

El desarrollo de escritorios personalizados sobre Linux suele enfrentar una disyuntiva entre estética y consumo de recursos. Los toolkits tradicionales ofrecen capacidades gráficas completas a costa de un consumo elevado de memoria y CPU. Las alternativas ligeras suelen limitar la expresividad visual o exigir un compositor externo para funciones básicas como las animaciones.

LaneTK se propone romper esa disyuntiva ofreciendo una API de widgets de alto nivel sobre una base de recursos mínimos. Está pensado para equipos de bajos recursos, sistemas embebidos y entornos de escritorio minimalistas.

El proyecto toma como referencia conceptual la organización de widgets de Wibox, pero reconstruye el motor sobre XCB para garantizar compatibilidad con cualquier gestor de ventanas. Las aplicaciones construidas sobre LaneTK pueden delegar la gestión de ventanas al WM o asumirla por completo según convenga.

---

## Características

### Motor gráfico

- Bindings FFI directos sobre `libxcb`, `cairo`, `pango`, `libxkbcommon` y `resvg`, sin envoltorios en C.
- Renderizado sobre superficies XCB nativas, sin copias intermedias.
- Doble buffer con seguimiento selectivo de daños: solo se redibujan las regiones que cambiaron.
- Soporte de XShape para máscaras de recorte no rectangulares.
- Carga de PNG y SVG con caché en memoria.

### Sistema de widgets

- Clase base `Area` con contrato uniforme de medición, disposición y dibujo.
- Más de treinta widgets incluidos: contenedores, campos de entrada, visualizadores, gráficos y botones especializados.
- Layout flexible con pesos, hijos rígidos y flexibles.
- Composición mediante `Group`, `Stack`, `Card` y `TabbedPanel`.
- Sistema de foco de teclado y enrutamiento de eventos de ratón al árbol de widgets.

### Animación

- Motor de animaciones con pool y timer bajo demanda, sin coste en reposo.
- Funciones de easing lineales, cuadráticas, cúbicas, exponenciales, elásticas y de rebote.
- Animaciones basadas en física de muelle.
- Secuencias, retardos, loops y entrada progresiva por escalonado.
- Crossfade entre contenidos mediante overlays sobre la ventana.

### Infraestructura

- Bucle de eventos basado en `poll(2)` con soporte de descriptores externos.
- Sistema de timers monótonos con precisión de milisegundos.
- Observación de archivos trigger para comunicación entre procesos.
- Hot reload entre procesos mediante `signalfd` y `SIGUSR1`.
- Cliente del protocolo greetd.
- Lectura y escritura de propiedades EWMH.
- Fondo de escritorio nativo con decodificación vía `ffmpeg`.
- Resolución de iconos con soporte de temas GTK y herencia entre temas.

### Samplers del sistema

Módulos independientes para lectura de CPU, RAM, GPU, discos, red, batería, brillo, volumen, temperatura, procesos, usuarios y dispositivos de red. Todos siguen un contrato común y son utilizables fuera del toolkit.

---

## Requisitos

### Runtime

| Componente | Paquete en Void Linux |
| :--- | :--- |
| LuaJIT | `luajit` |

### Bibliotecas nativas

| Biblioteca | Paquete en Void Linux |
| :--- | :--- |
| libxcb y utilidades | `libxcb`, `libxcb-util`, `xcb-util-wm` |
| Cairo | `cairo` |
| Pango | `pango` |
| Fontconfig | `fontconfig` |
| xkbcommon | `libxkbcommon` |
| resvg | `libresvg` |

### Herramientas del sistema

Requeridas por samplers y aplicaciones auxiliares. Su ausencia deshabilita funcionalidad específica pero no impide el uso del toolkit.

| Herramienta | Uso |
| :--- | :--- |
| `ffmpeg` | Decodificación para fondo de escritorio y miniaturas |
| `xrandr` | Detección de monitores |
| `xclip` | Integración con el portapapeles |
| `xdotool` | Manipulación de ventanas externas |
| `fd` | Búsqueda de archivos |
| `pactl`, `wpctl` o `amixer` | Control de volumen |
| `light` o `brightnessctl` | Control de brillo |

En otras distribuciones los nombres de paquete varían. El script de instalación incluye una tabla orientativa para Void Linux, y los paquetes equivalentes en otras distribuciones pueden localizarse a partir de los nombres de biblioteca.

---

## Instalación

```bash
git clone https://github.com/Ansmoun/lanetk.git
cd lanetk
sudo tools/install.sh
```

El script copia el toolkit a `/opt/lanetk`, verifica las dependencias del sistema y comprueba que los módulos se cargan correctamente.

Opciones disponibles:

| Opción | Descripción |
| :--- | :--- |
| `-y`, `--yes` | No pedir confirmación antes de reemplazar el directorio de destino. |
| `--install-deps` | Instalar automáticamente las dependencias faltantes en Void Linux. |
| `--prefix DIR` | Directorio de instalación. Por defecto `/opt/lanetk`. |

En modo desarrollo, el wrapper `run` permite ejecutar scripts desde el propio repositorio sin instalación previa:

```bash
./run examples/01-window.lua
```

---

## Ejemplos

El directorio [`examples/`](examples/) contiene una colección de programas ejecutables que cubren progresivamente cada subsistema del toolkit, desde la apertura de una ventana hasta la construcción de una barra completa con cambio de geometría en caliente. Cada archivo está numerado y es autocontenido.

Entre los ejemplos se incluye [`examples/34-bar.lua`](examples/34-bar.lua), que demuestra la API en su forma más compleja: construye una barra superior a partir de una especificación declarativa, utiliza el motor de separadores, registra un constructor de widget en tiempo de ejecución y permite alternar entre tres disposiciones distintas sin reiniciar el proceso.

---

## Documentación

La referencia técnica de la API pública, con la descripción de cada módulo, sus funciones, parámetros y valores de retorno, está disponible en [`docs/api.md`](docs/api.md).

---

## Ecosistema

LaneTK es la base técnica de los siguientes proyectos:

| Proyecto | Descripción |
| :--- | :--- |
| [**Lane**](https://github.com/Ansmoun/Lane) | Entorno de escritorio modular. Incluye barra superior, gestor de fondo de escritorio, lanzador, panel de sistema, captura de pantalla y menú de cierre de sesión. |
| [**Lefty**](https://github.com/Ansmoun/Lefty) | Greeter integrado con greetd. Ofrece selección de usuario, layout configurable y elección de gestor de ventanas al iniciar sesión. |

Ambos proyectos consumen LaneTK como dependencia externa y siguen su propia cadencia de versiones.

---

## Licencia

Distribuido bajo los términos de la **GNU General Public License, versión 3**. Ver [`LICENSE`](LICENSE) para el texto completo.

---

<sub>Construido para demostrar que un entorno de escritorio visualmente rico no requiere un consumo de recursos elevado.</sub>
