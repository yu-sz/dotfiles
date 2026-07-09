-- Usage:
-- :CopyBufferName — カレントバッファのファイル名をクリップボードへコピー
-- :CopyBufferPath — カレントバッファの絶対パスをクリップボードへコピー

---@param expand_fmt string vim.fn.expand に渡すフォーマット（"%:t" / "%:p" 等）
---@param label string 通知に表示する名前
local function copy_expand(expand_fmt, label)
  local value = vim.fn.expand(expand_fmt)
  vim.fn.setreg("+", value)
  vim.notify(("Copied %s: %s"):format(label, value))
end

vim.api.nvim_create_user_command("CopyBufferName", function()
  copy_expand("%:t", "buffer name")
end, { desc = "Copy current buffer name to clipboard", nargs = 0 })

vim.api.nvim_create_user_command("CopyBufferPath", function()
  copy_expand("%:p", "buffer path")
end, { desc = "Copy current buffer path to clipboard", nargs = 0 })
