-- color schema
return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    ---@diagnostic disable-next-line: missing-fields
    require("tokyonight").setup({
      transparent = true,
      styles = {
        -- Background styles. Can be "dark", "transparent" or "normal"
        sidebars = "transparent",
        floats = "transparent",
      },
      on_colors = function(colors)
        colors.bg_statusline = colors.none
      end,
      on_highlights = function(hl, c)
        hl["@markup.quote.markdown"] = { italic = true }
        -- render-markdown はこのグループの bg 色でコードブロックの罫線を描く
        hl.RenderMarkdownCodeBorder = { bg = c.blue0 }
      end,
    })
    vim.cmd([[colorscheme tokyonight-night]])
  end,
}
