-- Parser comun de filas para los widgets que aceptan
--   { id, label, ... }  (tabla con keys)
--   { "id", "label" }   (array posicional, estilo del proyecto original)
--
-- Devuelve los valores en orden: id, label, extra.
-- `keys` es una lista de claves para el formato con tabla, en el
-- orden en que se quieren devolver. Si la fila no las tiene, se
-- cae al formato posicional.

local M = {}

function M.parse(row, keys)
    keys = keys or { "id", "label" }

    -- Formato tabla: si tiene la primera key, es tabla con keys
    if row[keys[1]] ~= nil then
        local out = {}
        for i, k in ipairs(keys) do
            out[i] = row[k]
        end
        return unpack(out, 1, #keys)
    end

    -- Formato posicional
    local out = {}
    for i = 1, #keys do
        out[i] = row[i]
    end
    return unpack(out, 1, #keys)
end

return M
