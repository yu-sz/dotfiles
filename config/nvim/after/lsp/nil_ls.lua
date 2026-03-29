---@type vim.lsp.Config
return {
  settings = {
    ["nil"] = {
      formatting = {
        command = { "nixfmt" },
      },
      nix = {
        flake = {
          autoArchive = true,
        },
      },
    },
  },
}
