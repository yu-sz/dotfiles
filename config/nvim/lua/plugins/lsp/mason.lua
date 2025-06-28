-- LSP management (automatic installation)
return {
  "williamboman/mason.nvim",
  dependencies = {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  config = function()
    require("mason").setup({
      ui = {
        icons = {
          ui = {
            icons = {
              package_installed = "✓",
              package_pending = "➜",
              package_uninstalled = "✗",
            },
          },
        },
      },
    })

    require("mason-tool-installer").setup({
      ensure_installed = {
        -- lsp
        "lua-language-server",
        -- linter
        "luacheck",
        -- formatter
        "stylua",
        "shfmt",
        "prettier",
        "biome",
      }
    })
  end,
}
