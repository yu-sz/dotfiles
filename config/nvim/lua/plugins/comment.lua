-- commenting
return {
  "numToStr/Comment.nvim",
  event = "VeryLazy",
  opts = {
    toggler = {
      line = "<leader>/",
    },
    opleader = {
      line = "<leader>/",
    },
    extra = {
      above = "<leader>l/",
      below = "<leader>j/",
    },
    pre_hook = function(ctx)
     return require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook()(ctx)
    end,
  },
}
