-- prismatic line decorations
local COLORSCHEME = "dark"

local color_scheme = {
  tokyonight = {
    bg = "#f5f5f5",
    copy = "#FFFD75",
    delete = "#FF4C4C",
    insert = "#66B3FF",
    visual = "#FFAAFF",
  },
  dark = {
    bg = "#f5f5f5",
    copy = "#FFFD75",
    delete = "#FF4C4C",
    insert = "#66B3FF",
    visual = "#FFAAFF",
  },
}

return {
  "mvllow/modes.nvim",
  tag = "v0.2.1",
  opts = {
    colors = color_scheme[COLORSCHEME],
    line_opacity = {
      bg = 0.10,
      copy = 0.30,
      delete = 0.30,
      insert = 0.30,
      visual = 0.30,
    },
    set_cursor = true,
    set_cursorline = true,
    set_number = true,
    ignore_filetypes = { "NvimTree" },
  },
}
