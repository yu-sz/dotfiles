-- lsp config (for auto default setting)
return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
}
