-- git blame
return {
  {
    "FabijanZulj/blame.nvim",
    cmd = "BlameToggle",
    config = function()
      require("blame").setup({})
    end,
    keys = {
      { "<leader>gb", ":BlameToggle window<CR>", desc = "Git Blame Toggle (Window)" },
    },
  },
}
