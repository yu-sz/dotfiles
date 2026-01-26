-- extend Neovim notifications and LSP progress messages.
return {
  "j-hui/fidget.nvim",
  event = "LspAttach",
  opts = {},
}
