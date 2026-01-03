return {
  "folke/todo-comments.nvim",
  version = "*",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = { "BufNewFile", "BufRead" },
  opts = {
    sign_priority = 1,
  },
}
