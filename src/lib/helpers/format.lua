-- Formateadores de valores. Devuelven strings listos para mostrar.

local M = {}

-- KB (como viene de /proc/meminfo) a string legible.
-- 1.2 GB, 45 MB, 0 MB.
function M.mb(kb)
    if not kb or kb < 0 then return "0 MB" end
    if kb >= 1024 * 1024 then
        return string.format("%.1f GB", kb / (1024 * 1024))
    elseif kb >= 1024 then
        return string.format("%d MB", math.floor(kb / 1024))
    else
        return string.format("%d MB", 0)
    end
end

-- Bytes a string legible: "512 B", "1.5 KB", "1.2 MB", "2.30 GB".
function M.bytes(b)
    if not b or b < 0 then return "0 B" end
    if b < 1024 then
        return string.format("%d B", math.floor(b))
    elseif b < 1024 * 1024 then
        return string.format("%.1f KB", b / 1024)
    elseif b < 1024 * 1024 * 1024 then
        return string.format("%.1f MB", b / (1024 * 1024))
    else
        return string.format("%.2f GB", b / (1024 * 1024 * 1024))
    end
end

-- Bytes por segundo: "1.5 MB/s", "0 B/s".
function M.speed(bps)
    if not bps or bps < 0 then return "0 B/s" end
    return M.bytes(bps) .. "/s"
end

-- Segundos a "3d 4h 12m" | "4h 12m" | "45m".
function M.uptime(secs)
    if not secs or secs < 0 then secs = 0 end
    local days    = math.floor(secs / 86400)
    local hours   = math.floor((secs % 86400) / 3600)
    local minutes = math.floor((secs % 3600) / 60)

    if days > 0 then
        return string.format("%dd %dh %dm", days, hours, minutes)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    else
        return string.format("%dm", minutes)
    end
end

-- Fecha actual en espanol: "Domingo, 20 de septiembre de 2026".
local DIAS = {
    "Domingo", "Lunes", "Martes", "Miercoles", "Jueves",
    "Viernes", "Sabado"
}
local MESES = {
    "enero", "febrero", "marzo", "abril", "mayo", "junio",
    "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"
}

function M.date()
    local t = os.date("*t")
    -- os.date devuelve wday 1=domingo, 2=lunes, ...
    local dia = DIAS[t.wday] or ""
    local mes = MESES[t.month] or ""
    return string.format("%s, %d de %s de %d",
        dia, t.day, mes, t.year)
end

-- Saludo segun la hora.
function M.greeting(hour)
    if hour == nil then hour = tonumber(os.date("%H")) or 12 end
    if hour >= 6 and hour < 12 then
        return "Buenos dias,"
    elseif hour >= 12 and hour < 20 then
        return "Buenas tardes,"
    else
        return "Buenas noches,"
    end
end

return M
