-- linter settings
return {
  "mfussenegger/nvim-lint",
  event = "VeryLazy",
  config = function()
    local lint = require("lint")
    lint.linters_by_ft = {
      lua = { "luacheck" },
      javascript = { "biomejs", "eslint" },
      typescript = { "biomejs", "eslint" },
      typescriptreact = { "biomejs", "eslint" },
    }

    local augroup = vim.api.nvim_create_augroup("NvimLintAutocmds", { clear = true })

    -- open file
    vim.api.nvim_create_autocmd({ "BufReadPost" }, {
      group = augroup,
      callback = function()
        require("lint").try_lint(nil, { ignore_errors = true })
      end,
    })

    -- format on save
    vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
      group = augroup,
      callback = function()
        require("lint").try_lint(nil, { ignore_errors = true })
      end,
    })
  end,
}
