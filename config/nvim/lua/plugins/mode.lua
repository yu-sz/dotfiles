-- prismatic line decorations
local colors = {
  bg = "#f5f5f5",
  copy = "#FFFD75",
  delete = "#FF4C4C",
  insert = "#66B3FF",
  visual = "#FFAAFF",
}

return {
  "mvllow/modes.nvim",
  tag = "v0.2.1",
  opts = {
    colors = colors,
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
