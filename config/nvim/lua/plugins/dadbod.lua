return {
  {
    "tpope/vim-dadbod",
    cmd = { "DB", "DBUI", "DBUIToggle", "DBUIFindBuffer", "DBUIRenameBuffer" },
    dependencies = {
      "kristijanhusak/vim-dadbod-ui",
      "kristijanhusak/vim-dadbod-completion",
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_execute_on_save = 0
    end,
    -- catalog の読み込みは yq の同期実行を伴うため、起動時ではなく初回使用時に行う
    config = function()
      require("db.catalog").load()
    end,
    keys = {
      {
        "<leader>db",
        function()
          require("db.picker").pick()
        end,
        desc = "DB: pick",
      },
      { "<leader>du", "<cmd>DBUIToggle<cr>", desc = "DB: UI toggle" },
      { "<leader>dd", "<cmd>DBUIFindBuffer<cr>", desc = "DB: find buffer" },
    },
  },
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      sources = {
        per_filetype = { sql = { "snippets", "dadbod", "buffer" } },
        providers = {
          dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
        },
      },
    },
  },
  {
    "nanotee/sqls.nvim",
    ft = "sql",
  },
}
