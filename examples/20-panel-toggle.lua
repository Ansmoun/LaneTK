-- Prueba del PanelApp con toggle por archivo.
--
-- Uso:
--   1. Lanzar este ejemplo.
--   2. Desde otra terminal:
--        echo toggle > /tmp/lanetk-panel.cmd   (abre/cierra)
--        echo show   > /tmp/lanetk-panel.cmd   (solo abrir)
--        echo hide   > /tmp/lanetk-panel.cmd   (solo cerrar)
--        echo quit   > /tmp/lanetk-panel.cmd   (termina el proceso)
--   3. Tambien puedes cerrar el panel con 'q' o Mod4+Shift+Q.
--      El proceso NO termina, sigue esperando trigger.

local PanelApp = require("lib.panelapp")
local W        = require("lib.widgets")
local cairo    = require("lib.cairo")

-- Un tab de prueba
local function make_test_tab()
    local kv = W.KV.new {
        key_width = 120, row_height = 20, row_spacing = 8,
        rows = {
            { id = "time",  label = "Hora" },
            { id = "count", label = "Aperturas" },
        }
    }
    local card = W.Card.new {
        title = "Test",
        content = kv,
        padding = 16,
        bg = {0.14, 0.14, 0.18},
        border = {0.28, 0.28, 0.34},
    }
    return { widget = card }
end

local app = PanelApp.new {
    trigger_path = "/tmp/lanetk-panel.cmd",
    panel_opts = {
        title = "Panel toggle test",
        width = "60%",
        height = "60%",
        x = "center", y = "center",
        tabs = {
            { id = "test", label = "Test", factory = make_test_tab },
        },
    },
}

print("PanelApp arrancado. En otra terminal:")
print("  echo toggle > /tmp/lanetk-panel.cmd   (abre/cierra)")
print("  echo show   > /tmp/lanetk-panel.cmd   (abrir)")
print("  echo hide   > /tmp/lanetk-panel.cmd   (cerrar)")
print("  echo quit   > /tmp/lanetk-panel.cmd   (terminar proceso)")
print("")
print("Cerrar el panel con 'q' NO termina el proceso.")
print("Terminarlo con Ctrl+C o con: echo quit > /tmp/lanetk-panel.cmd")
print("")

-- Arrancar con el panel visible
app:show()

app:run()
print("Proceso terminado.")
