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
    })
    vim.cmd([[colorscheme tokyonight-moon]])
  end,
}
