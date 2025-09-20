local lsp_name = {
  "lua_ls",
  "vtsls",
  "bashls",
  "html",
  "cssls",
  "tailwindcss",
  "eslint",
  "biome",
  "jsonls",
  "yamlls",
}

vim.lsp.enable(lsp_name)
require("lsp.lsp-settings")
