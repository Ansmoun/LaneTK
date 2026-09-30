#!/bin/sh
# Convierte SVGs a PNG en varios tamanos.
# Uso:
#   ./tools/convert-icons.sh <directorio-de-svg> [prefijo]

SRC="$1"
PREFIX="${2:-}"

if [ -z "$SRC" ] || [ ! -d "$SRC" ]; then
    echo "uso: $0 <directorio-de-svg> [prefijo]"
    exit 1
fi

OUT_BASE="$HOME/proyectos/lanetk/icons-png"
SIZES="16 24 32 48"

for size in $SIZES; do
    mkdir -p "$OUT_BASE/$size"
done

n=0
for svg in $(find "$SRC" -type f -name '*.svg'); do
    rel="${svg#$SRC/}"
    name="${rel%.svg}"
    name=$(echo "$name" | tr '/' '_')

    for size in $SIZES; do
        rsvg-convert -w "$size" -h "$size" \
            -o "$OUT_BASE/$size/${PREFIX}${name}.png" \
            "$svg" 2>/dev/null
    done

    n=$((n + 1))
done

echo "Convertidos $n SVG a $OUT_BASE/{16,24,32,48}/"
