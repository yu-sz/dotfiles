local ensure_installed = {
  "lua",
  "vim",
  "vimdoc",
  "query",
  "javascript",
  "typescript",
  "tsx",
  "html",
  "css",
  "scss",
  "json",
  "jsonc",
  "yaml",
  "markdown",
  "markdown_inline",
  "bash",
  "sql",
  "nix",
  "prisma",
  "terraform",
  "hcl",
  "regex",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    dependencies = {
      { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
    },
    build = ":TSUpdate",
    lazy = false,
    main = "nvim-treesitter",
    opts = {},
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter-start", {}),
        callback = function()
          pcall(vim.treesitter.start)
          pcall(function()
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end)
        end,
      })
    end,
    config = function()
      require("nvim-treesitter").setup({})
      require("nvim-treesitter").install(ensure_installed)
    end,
  },
}
