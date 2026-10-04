#!/bin/sh
# install.sh: instala LaneTK en /opt/lanetk/.
#
# Uso:
#   cd ~/proyectos/lanetk
#   sudo tools/install.sh [-y] [--install-deps] [--prefix /opt/lanetk]
#
# -y, --yes            no pedir confirmación
#     --install-deps   instalar dependencias faltantes (solo Void Linux)
#     --prefix DIR     directorio de instalación (default: /opt/lanetk)

set -e

AUTO_YES=0
INSTALL_DEPS=0
PREFIX="/opt/lanetk"

while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes)          AUTO_YES=1 ;;
        --install-deps)    INSTALL_DEPS=1 ;;
        --prefix)          PREFIX="$2"; shift ;;
        -h|--help)         sed -n '2,12p' "$0"; exit 0 ;;
        *)                 echo "Argumento desconocido: $1" >&2; exit 1 ;;
    esac
    shift
done

if [ -n "${SUDO_USER:-}" ]; then
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_HOME="$HOME"
fi

SRC="${REAL_HOME}/proyectos/lanetk"

if [ "$(id -u)" -ne 0 ]; then
    echo "install.sh: necesita root. Correlo con sudo." >&2
    exit 1
fi

if [ ! -d "$SRC/src/lib" ]; then
    echo "install.sh: no existe $SRC/src/lib" >&2
    exit 1
fi

# --- Helpers de verificacion ---

# Void Linux?
is_void() {
    [ -f /etc/os-release ] && grep -q '^ID="\?void"\?$' /etc/os-release
}

# Comando en PATH? Devuelve 0/1.
has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# Libreria presente? Intenta primero ldconfig; si no, busca el
# archivo directo en las rutas tipicas. libresvg en Void no
# registra symlink en ldconfig, por eso el fallback.
has_lib() {
    if ldconfig -p 2>/dev/null | grep -q "/$1\b"; then
        return 0
    fi
    for dir in /usr/lib /usr/lib64 /lib /lib64 /usr/local/lib; do
        [ -e "$dir/$1" ] && return 0
    done
    return 1
}

MISSING_CMDS=""
MISSING_LIBS=""

need_cmd() {
    if has_cmd "$1"; then
        echo "    OK      $1"
    else
        echo "    FALTA   $1"
        MISSING_CMDS="$MISSING_CMDS $1"
    fi
}

need_lib() {
    if has_lib "$1"; then
        echo "    OK      $1"
    else
        echo "    FALTA   $1"
        MISSING_LIBS="$MISSING_LIBS $1"
    fi
}

# Al menos una de las alternativas debe estar presente.
need_one_of() {
    local present=""
    for c in "$@"; do
        if has_cmd "$c"; then present="$c"; break; fi
    done
    if [ -n "$present" ]; then
        echo "    OK      $present (alternativas: $*)"
    else
        echo "    FALTA   una de: $*"
        MISSING_CMDS="$MISSING_CMDS $1"
    fi
}

echo "==> LaneTK — instalación en $PREFIX"
echo "    Origen: $SRC"
echo

echo "==> Verificando dependencias"
echo
echo "  Runtime:"
need_cmd luajit
echo
echo "  Librerias (FFI):"
need_lib libxcb.so
need_lib libxcb-util.so.1
need_lib libxcb-icccm.so.4
need_lib libcairo.so.2
need_lib libpango-1.0.so.0
need_lib libpangocairo-1.0.so.0
need_lib libgobject-2.0.so.0
need_lib libfontconfig.so.1
need_lib libxkbcommon.so.0
need_lib libresvg.so.0.48
echo
echo "  Herramientas del sistema (samplers):"
need_cmd ffmpeg
need_cmd xrandr
need_cmd xclip
need_cmd xdotool
need_cmd fd
need_one_of pactl wpctl amixer
need_one_of light brightnessctl
echo

if [ -n "$MISSING_CMDS$MISSING_LIBS" ]; then
    echo "==> Faltan dependencias."
    echo "    Comandos:     $MISSING_CMDS"
    echo "    Librerias:    $MISSING_LIBS"
    echo
    if is_void; then
        echo "    Paquetes sugeridos para Void:"
        echo "      xbps-install -S luajit libxcb libxcb-util xcb-util-wm \\"
        echo "                     cairo pango fontconfig libxkbcommon \\"
        echo "                     libresvg ffmpeg xrandr xclip xdotool fd \\"
        echo "                     pulseaudio-utils (o wireplumber)"
        echo
        if [ "$INSTALL_DEPS" -eq 1 ]; then
            echo "==> Instalando dependencias (--install-deps activo)"
            xbps-install -Sy \
                luajit libxcb libxcb-util xcb-util-wm \
                cairo pango fontconfig libxkbcommon \
                libresvg ffmpeg xrandr xclip xdotool fd \
                || { echo "Instalación de paquetes falló" >&2; exit 1; }
        else
            echo "    Volvé a correr con --install-deps para instalarlas,"
            echo "    o instalalas a mano y repetí el script."
            exit 1
        fi
    else
        echo "    Distro no reconocida como Void; instalalas a mano"
        echo "    segun tu gestor de paquetes y repetí el script."
        exit 1
    fi
else
    echo "==> Todas las dependencias presentes."
fi
echo

if [ -d "$PREFIX" ] && [ "$AUTO_YES" -eq 0 ]; then
    printf "==> Se va a reemplazar $PREFIX. Continuar? [y/N] "
    read -r ans
    case "$ans" in
        y|Y|yes|YES) ;;
        *) echo "Cancelado."; exit 0 ;;
    esac
fi

echo "==> Copiando LaneTK"
rm -rf "$PREFIX"
mkdir -p "$PREFIX"
tar -C "$SRC" \
    --exclude='./.git' \
    --exclude='./.backups' \
    --exclude='./docs' \
    --exclude='./examples' \
    --exclude='./tests' \
    --exclude='./tools' \
    --exclude='*.bak' --exclude='*.bak-*' --exclude='*.bak.*' \
    --exclude='*.orig' --exclude='*.swp' --exclude='.DS_Store' \
    -cf - . | tar -C "$PREFIX" -xf -

echo "==> Ajustando permisos"
chmod -R a+rX,go-w "$PREFIX"
[ -f "$PREFIX/run" ] && chmod +x "$PREFIX/run"

echo "==> Verificando carga desde $PREFIX"
cd "$PREFIX"
if ./run -e '
    require("lib.server")
    require("lib.greetd")
    require("lib.xshape_anim")
    require("lib.widgets")
    print("requires OK")
' 2>&1; then
    echo "    OK"
else
    echo "    FALLO: revisar LUA_PATH de $PREFIX/run" >&2
    exit 1
fi

echo
echo "==> Instalación completa."
echo "    LaneTK en $PREFIX"
