return {
  "sindrets/diffview.nvim",
  keys = {
    {
      "<leader>df",
      function()
        if next(require("diffview.lib").views) == nil then
          vim.cmd("DiffviewOpen")
        else
          vim.cmd("DiffviewClose")
        end
      end,
      silent = true,
      mode = "n",
      desc = "Toggle Diff View",
    },
    {
      "<leader>hf",
      function()
        if next(require("diffview.lib").views) == nil then
          vim.cmd("DiffviewFileHistory")
        else
          vim.cmd("DiffviewClose")
        end
      end,
      silent = true,
      mode = "n",
      desc = "Toggle Git File History",
    },
    {
      "<leader>hc",
    },
  },
  opts = {
    keymaps = {
      view = {
        ["<tab>"] = false,
        ["<setab>"] = false,
      },
      file_panel = {
        ["<tab>"] = false,
        ["<setab>"] = false,
        ["s"] = false,
      },
    },
  },
}
