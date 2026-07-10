-- git blame
return {
  {
    "FabijanZulj/blame.nvim",
    cmd = "BlameToggle",
    opts = {},
    keys = {
      { "<leader>gb", ":BlameToggle window<CR>", desc = "Git Blame Toggle (Window)" },
    },
  },
}
