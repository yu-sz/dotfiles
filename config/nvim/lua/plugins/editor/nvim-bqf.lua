-- preview quickfix
return {
  "kevinhwang91/nvim-bqf",
  config = function()
    ---@diagnostic disable-next-line: missing-fields
    require("bqf").setup({
      func_map = {
        openc = "<CR>",
        open = "o",
      },
    })
  end,
}
