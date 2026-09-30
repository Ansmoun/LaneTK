-- data/disk: particiones (df + lsblk) sincrono y SMART via
-- archivo /tmp/lanetk-smart.tsv actualizado en background.

local U = require("lib.helpers.util")

local M = {}

local SMART_TSV = "/tmp/lanetk-smart.tsv"

-- Procesa el output de df + lsblk. Devuelve array de tablas.
function M.partitions()
    local list = {}
    local out = U.shell_once("LC_ALL=C df -hP 2>/dev/null")
    for line in out:gmatch("[^\n]+") do
        local fs, size, used, avail, pct, mount =
            line:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%d+)%%%s+(%S+)$")
        if fs and mount and mount:sub(1, 1) == "/" then
            local skip = false
            for _, v in ipairs({ "tmpfs", "devtmpfs", "udev",
                                 "squashfs", "efivarfs" }) do
                if fs:find(v, 1, true) then skip = true; break end
            end
            for _, p in ipairs({ "/run", "/sys", "/proc", "/dev", "/media" }) do
                if mount == p or mount:sub(1, #p + 1) == p .. "/" then
                    skip = true; break
                end
            end
            if not skip then
                list[#list + 1] = {
                    dev = fs, size = size, used = used, avail = avail,
                    pct = tonumber(pct) or 0, mount = mount,
                }
            end
        end
    end
    table.sort(list, function(a, b) return a.mount < b.mount end)

    -- Enriquecer con label/fs desde lsblk
    local p = io.popen("lsblk -P -o NAME,LABEL,FSTYPE,MOUNTPOINT 2>/dev/null")
    if p then
        for line in p:lines() do
            local name   = line:match('NAME="([^"]*)"')
            local label  = line:match('LABEL="([^"]*)"')
            local fstype = line:match('FSTYPE="([^"]*)"')
            local mnt    = line:match('MOUNTPOINT="([^"]*)"')
            if mnt and mnt ~= "" and name and name ~= "" then
                for _, d in ipairs(list) do
                    if d.mount == mnt then
                        if fstype and fstype ~= "" then d.fs_type = fstype end
                        d.label = label or ""
                        d.dev = "/dev/" .. name
                        break
                    end
                end
            end
        end
        p:close()
    end

    return list
end

-- Lee el TSV de SMART si existe. Devuelve tabla o nil.
function M.smart_read()
    local content = U.read_file(SMART_TSV)
    if not content or content == "" then return nil end

    local first_line = content:match("^([^\n]+)")
    if not first_line then return nil end

    local f = {}
    for v in (first_line .. "\t"):gmatch("([^\t]*)\t") do
        f[#f + 1] = v
    end

    return {
        passed      = (f[1] == "true"),
        temp        = tonumber(f[2])  or 0,
        hours       = tonumber(f[3])  or 0,
        cycles      = tonumber(f[4])  or 0,
        realloc     = tonumber(f[5])  or 0,
        pending     = tonumber(f[6])  or 0,
        offline     = tonumber(f[7])  or 0,
        crc         = tonumber(f[8])  or 0,
        load_cycles = tonumber(f[9])  or 0,
        lba_written = tonumber(f[10]) or 0,
        lba_read    = tonumber(f[11]) or 0,
        model_family= f[12] or "?",
        model_name  = f[13] or "?",
        serial      = f[14] or "?",
        firmware    = f[15] or "?",
        cap_bytes   = tonumber(f[16]) or 0,
        rotation    = tonumber(f[17]) or 0,
        form_factor = f[18] or "?",
        sec_logical = tonumber(f[19]) or 0,
        sec_physical= tonumber(f[20]) or 0,
        sata_version= f[21] or "?",
        sata_link   = f[22] or "?",
    }
end

-- Lanza smartctl en background, escribiendo el TSV a SMART_TSV.
-- El comando corre en segundo plano (&) y vuelve inmediatamente.
function M.smart_trigger(device)
    device = device or "/dev/sda"

    local jq = [[
[
  .smart_status.passed,
  (.temperature.current // 0),
  (.power_on_time.hours // 0),
  (.power_cycle_count // 0),
  ((.ata_smart_attributes.table[] | select(.id==5)   | .raw.value) // 0),
  ((.ata_smart_attributes.table[] | select(.id==197) | .raw.value) // 0),
  ((.ata_smart_attributes.table[] | select(.id==198) | .raw.value) // 0),
  ((.ata_smart_attributes.table[] | select(.id==199) | .raw.value) // 0),
  ((.ata_smart_attributes.table[] | select(.id==193) | .raw.value) // 0),
  ((.ata_smart_attributes.table[] | select(.id==241) | .raw.value) // 0),
  ((.ata_smart_attributes.table[] | select(.id==242) | .raw.value) // 0),
  (.model_family    // "?"),
  (.model_name      // "?"),
  (.serial_number   // "?"),
  (.firmware_version// "?"),
  (.user_capacity.bytes // 0),
  (.rotation_rate   // 0),
  (.form_factor.name // "?"),
  (.sector_size.logical  // 0),
  (.sector_size.physical // 0),
  (.sata_version.string  // "?"),
  (.interface_speed.current.string // "?")
] | @tsv
]]
    local escaped = jq:gsub("'", "'\\''")
    local tmp = SMART_TSV .. ".tmp"

    local cmd = string.format(
        "(sudo -n /usr/bin/smartctl -j -a %s 2>/dev/null " ..
        "| jq -r '%s' > %s 2>/dev/null && mv %s %s) &",
        device, escaped, tmp, tmp, SMART_TSV)
    os.execute(cmd)
end

return M
