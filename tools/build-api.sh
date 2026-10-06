#!/bin/sh
# build-api.sh: une los fragmentos de docs/ en api.md
cd "$(dirname "$0")/../docs" || exit 1

cat indice.md \
    core.md \
    infra.md \
    widgets.md \
    data.md \
    integracion.md \
    helpers.md > api.md

echo "api.md regenerado ($(wc -l < api.md) líneas)"
