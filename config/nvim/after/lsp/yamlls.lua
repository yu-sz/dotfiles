---@type vim.lsp.Config
return {
  settings = {
    yaml = {
      customTags = {
        "!ENV scalar",
        "!ENV sequence",
      },
      schemaStore = {
        enable = true,
      },
    },
  },
}
