-- formatter settings
return {
  "stevearc/conform.nvim",
  event = "VeryLazy",
  opts = function()
    ---@param bufnr integer
    ---@return string[]
    local web_formatter_config = function(bufnr)
      if vim.fs.root(bufnr, { "biome.json", "biome.jsonc" }) then
        return { "biome-check" }
      end
      return { "biome-check", "prettier", stop_after_first = true }
    end

    return {
      format_on_save = {
        timeout_ms = 1500,
        lsp_format = "fallback",
      },
      formatters_by_ft = {
        lua = { "stylua" },
        nix = { "nixfmt" },
        bash = { "shfmt" },
        typescript = web_formatter_config,
        javascript = web_formatter_config,
        typescriptreact = web_formatter_config,
        javascriptreact = web_formatter_config,
        html = web_formatter_config,
        css = web_formatter_config,
        scss = web_formatter_config,
        less = web_formatter_config,
        json = web_formatter_config,
        jsonc = web_formatter_config,
        yaml = { "prettier" },
        markdown = { "prettier" },
      },
      formatters = {
        stylua = {
          command = "stylua",
        },
        shfmt = {
          command = "shfmt",
        },
        prettier = {
          prepend_args = { "--ignore-path", "/dev/null" },
        },
      },
    }
  end,
  config = function(_, opts)
    local conform = require("conform")
    conform.setup(opts)
    vim.keymap.set({ "n", "v" }, "<leader>lF", function()
      conform.format({
        lsp_format = "fallback",
        async = false,
        timeout_ms = 500,
      })
    end, { desc = "Format file or range (in visual mode)" })
  end,
}
