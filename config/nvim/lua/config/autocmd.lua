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
  callback = function()
    -- WinEnter \u306E\u305F\u3073\u306B\u540C\u4E00\u30A6\u30A3\u30F3\u30C9\u30A6\u3078 match \u304C\u7D2F\u7A4D\u3057\u306A\u3044\u3088\u3046\u4E00\u5EA6\u3060\u3051\u767B\u9332
    if vim.w.extra_whitespace_match then
      return
    end
    vim.w.extra_whitespace_match = vim.fn.matchadd("ExtraWhitespace", "[\\u200B\\u3000]")
  end,
})
api.nvim_create_autocmd({ "ColorScheme" }, {
  group = "extra-whitespace",
  pattern = { "*" },
  command = [[highlight default ExtraWhitespace ctermbg=202 ctermfg=202 guibg=salmon]],
})
