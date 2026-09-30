#!/bin/sh
# Uso: lanetk-trigger.sh <app-name> <trigger-file>
# Arranca el daemon si no esta corriendo y escribe el trigger.
APP="$1"
TRIGGER="$2"
LANETK_DIR="$HOME/proyectos/lanetk"

if [ -z "$APP" ] || [ -z "$TRIGGER" ]; then
    echo "uso: $0 <app-name> <trigger-file>" >&2
    exit 1
fi

if ! pgrep -f "apps/$APP.lua" > /dev/null; then
    cd "$LANETK_DIR"
    nohup ./run "apps/$APP.lua" > "/tmp/lanetk-$APP.log" 2>&1 &
    sleep 0.6
fi

echo toggle > "$TRIGGER"
