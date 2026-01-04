-- treesitter
return {
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "yioneko/nvim-yati",
    },
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    main = "nvim-treesitter.configs",
    config = function()
      ---@type TSConfig
      ---@diagnostic disable-next-line: missing-fields
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua",
          "vim",
          "vimdoc",
          "query",
          "javascript",
          "typescript",
          "tsx",
          "html",
          "sql",
          "prisma",
          "regex",
        },
        sync_install = false,
        auto_install = true,
        ignore_install = {},
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = false,
        },
        autopairs = {
          enable = true,
        },
        -- fix indentation
        yati = {
          enable = true,
          disable = {},
          default_lazy = true,
          default_fallback = "auto",
        },
      })
    end,
  },
}
