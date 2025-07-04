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
        "vtsls",                       -- typescript/javascript
        "lua-language-server",         -- lua
        "bash-language-server",        -- bash
        "html-lsp",                    -- html
        "css-lsp",                     -- css
        "tailwindcss-language-server", -- tailwindcss
        "json-lsp",                    -- json
        "yaml-language-server",        -- yaml
        "eslint-lsp",                  -- for javascript/typescript
        "biome",                       -- for javascript/typescript
        -- linter
        "luacheck",                    -- for lua
        "shellcheck",                  -- for shell
        -- formatter
        "stylua",                      -- for lua
        "shfmt",                       -- for shell
        "prettier",                    -- for javascript/typescript
      }
    })
  end,
}
