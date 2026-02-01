return {
  "stevearc/oil.nvim",
  -- Optional dependencies
  dependencies = { { "nvim-mini/mini.icons", opts = {} } },
  keys = {
    { "<leader>o", ":Oil<CR>", silent = true },
  },
  cmd = "Oil",
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    view_options = {
      show_hidden = true,
    },
  },
  -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
  -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
  lazy = false,
}
