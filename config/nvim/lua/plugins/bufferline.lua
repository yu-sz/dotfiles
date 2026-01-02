-- bufferline
return {
  "akinsho/bufferline.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    options = {
      mode = "tabs",
      show_buffer_close_icons = true,
      show_close_icon = true,
      -- separator_style = "slant",
      separator_style = "thin",
      show_tab_indicators = true,
      indicator = {
        style = "underline",
      },
    },
  },
}
