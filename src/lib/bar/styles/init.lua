local M = {}
M.arrow       = require("lib.bar.styles.arrow")
M.glyph       = require("lib.bar.styles.glyph")
M.glyph_thick = require("lib.bar.styles.glyph_thick")
M.gap         = require("lib.bar.styles.gap")
M.none        = require("lib.bar.styles.none")
M.underline   = require("lib.bar.styles.underline")
M.island      = require("lib.bar.styles.island")
M.dock        = require("lib.bar.styles.dock")
M.minimal     = require("lib.bar.styles.minimal")

function M.get(name)
    return M[name] or M.arrow
end
return M
