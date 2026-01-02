return {
  "akinsho/git-conflict.nvim",
  version = "*",
  config = true,
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<CR>", { silent = true, desc = "open git diff" } },
  },
}
