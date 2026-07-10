-- expand commenting (for jsx, tsx)
return {
  "JoosepAlviste/nvim-ts-context-commentstring",
  dependencies = "nvim-treesitter/nvim-treesitter",
  -- Comment.nvim の pre_hook からの require で読み込まれる
  lazy = true,
  main = "ts_context_commentstring",
  opts = {
    enable_autocmd = false,
  },
}
