local M = {}

-- Unicode codepoint を UTF-8 バイト列へ変換（Nerd Font アイコン用）
---@param codepoint integer
---@return string
function M.nf(codepoint)
  if codepoint < 0x10000 then
    return string.char(
      0xE0 + math.floor(codepoint / 0x1000),
      0x80 + math.floor((codepoint % 0x1000) / 0x40),
      0x80 + (codepoint % 0x40)
    )
  end
  return string.char(
    0xF0 + math.floor(codepoint / 0x40000),
    0x80 + math.floor((codepoint % 0x40000) / 0x1000),
    0x80 + math.floor((codepoint % 0x1000) / 0x40),
    0x80 + (codepoint % 0x40)
  )
end

return M
