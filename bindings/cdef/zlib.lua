-- cdef minimo para libz.so.1. Solo crc32, que necesitamos para
-- escribir chunks PNG correctamente (el CRC de cada chunk es
-- obligatorio; sin el, la imagen queda corrupta para cualquier
-- decoder estricto).

local ffi = require("ffi")

ffi.cdef[[
typedef unsigned int  uInt;
typedef unsigned long uLong;
typedef unsigned char Bytef;

uLong crc32(uLong crc, const Bytef *buf, uInt len);
]]

return ffi
