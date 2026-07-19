return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  ft = "markdown",
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    anti_conceal = { enabled = false },
    heading = {
      -- 空文字 + inline で '#' をマーカーなしで conceal する
      sign = false,
      position = "inline",
      icons = { "" },
    },
    indent = {
      enabled = true,
    },
    bullet = {
      icons = { "•", "◦", "▪" },
    },
    code = {
      width = "block",
      min_width = 60,
      border = "thin",
      -- 罫線素片によるヘアライン(セル上下中央に引かれる)
      language_border = "─",
      above = "─",
      below = "─",
    },
  },
}
