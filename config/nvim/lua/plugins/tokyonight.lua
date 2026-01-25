-- color schema
return {
  "folke/tokyonight.nvim",
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
    })
    vim.cmd([[colorscheme tokyonight-night]])
  end,
}
