local api = vim.api

-- Disable auto-commenting on new lines
api.nvim_create_autocmd("FileType", {
  pattern = "*",
  group = vim.api.nvim_create_augroup("disable_comment", { clear = true }),
  callback = function()
    if vim.bo.filetype == "markdown" then
      return
    end
    vim.opt_local.formatoptions:remove({ "r", "o" })
    vim.opt_local.formatoptions:append({ "M", "j" })
  end,
})

-- Reload file if changed externally
api.nvim_create_autocmd({ "WinEnter", "FocusGained", "BufEnter" }, {
  pattern = "*",
  command = "checktime",
})

-- Highlight extra-whitespace
api.nvim_create_augroup("extra-whitespace", {})
api.nvim_create_autocmd({ "VimEnter", "WinEnter" }, {
  group = "extra-whitespace",
  pattern = { "*" },
  command = [[call matchadd('ExtraWhitespace', '[\u200B\u3000]')]],
})
api.nvim_create_autocmd({ "ColorScheme" }, {
  group = "extra-whitespace",
  pattern = { "*" },
  command = [[highlight default ExtraWhitespace ctermbg=202 ctermfg=202 guibg=salmon]],
})
