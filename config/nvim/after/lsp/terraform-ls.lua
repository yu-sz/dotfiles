---@type vim.lsp.Config
return {
  cmd = { "terraform-ls", "serve" },
  filetypes = { "terraform", "terraform-vars" },
  root_markers = { ".terraform", ".git" },
  settings = {
    ["terraform-ls"] = {
      -- Enable experimental features if needed
      -- experimentalFeatures = {
      --   validateOnSave = true,
      -- },
    },
  },
}
