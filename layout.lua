-- Spec de la barra. Puro dato, editable sin tocar codigo.
--
-- CAMPOS
--   position   "top" | "bottom" | "left" | "right" | "free"
--   width      <px> | "screen" | "N%" | nil
--              default: "screen" si position es top/bottom,
--              <px> obligatorio si es left/right.
--   height     <px> | "screen" | "N%" | nil
--              default: 24 si position es top/bottom,
--              "screen" si es left/right.
--   margin     { top, right, bottom, left } en px.
--   x, y       solo si position = "free". Acepta
--              <px> | "center" | "start" | "end" | "N%".
--   padding    padding interno del contenido (px).
--   orientation  "horizontal" | "vertical"
--              default: "horizontal" para top/bottom y "vertical"
--              para left/right.
--   separator  "arrow" | "glyph" | "glyph_thick" | "gap" | "none"
--              | "underline" | "island"
--   gap        separacion entre widgets (px).
--   left/center/right  listas de items. Cada item:
--              - "nombre"  un widget del registry
--              - { toggle_group = "grupo", default = "visible" | "hidden",
--                  widgets = { "a", "b", ... } }
--
-- EJEMPLOS
--   Barra clasica arriba:
--     position = "top", width = "screen", height = 24
--   Barra abajo:
--     position = "bottom", width = "screen", height = 24
--   Dock pequeno centrado arriba:
--     position = "free", width = 600, height = 24,
--     x = "center", y = 0
--   Barra vertical a la derecha:
--     position = "right", width = 30, orientation = "vertical"

return {
    position  = "top",
    width     = "screen",
    height    = 24,
    margin    = { 0, 0, 0, 0 },
    padding   = 0,
    separator = "arrow",
    gap       = 12,
    left      = { "taglist", "prompt" },
    center    = {},
    right     = {
        { toggle_group = "telemetry", default = "visible",
          widgets = { "net", "mem", "gpu", "cpu", "temp" } },
        "bright", "vol", "bat", "clock",
    },
}
