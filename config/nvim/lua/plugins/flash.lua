-- fast and smart cursor movement/selection
return {
  "folke/flash.nvim",
  evenh = "VeryLazy",
  ---@type Flash.Config
  opts = {},
  keys = {
    {
      "<leader>s",
      mode = { "n", "x", "o" },
      function()
        require("flash").jump()
      end,
      desc = "Flash Jump",
    },
    {
      "S",
      mode = { "n", "x", "o" },
      function()
        require("flash").treesitter()
      end,
      desc = "Flash Treesitter (visual)",
    },
    {
      "r",
      mode = "o",
      function()
        require("flash").remote()
      end,
      desc = "Remote Flash",
    },
  },
}
