return {
  "folke/zen-mode.nvim",
  keys = {
    {
      "<leader><CR>",
      mode = "n",
      function()
        require("zen-mode").toggle({
          -- @lua
          window = {
            width = 0.60,
          },
        })
      end,
    },
  },
  opts = {},
}
