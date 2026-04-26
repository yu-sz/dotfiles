local M = {}

function M.nf(codepoint)
  return string.char(
    0xE0 + math.floor(codepoint / 0x1000),
    0x80 + math.floor((codepoint % 0x1000) / 0x40),
    0x80 + (codepoint % 0x40)
  )
end

return M
