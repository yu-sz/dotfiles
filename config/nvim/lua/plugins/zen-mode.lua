return {
  "folke/zen-mode.nvim",
  keys = {
    {
      "<leader><CR>",
      mode = "n",
      function()
        require("zen-mode").toggle({
          window = {
            width = 0.60,
          },
        })
      end,
      desc = "Toggle zen mode",
    },
  },
  opts = {},
}
