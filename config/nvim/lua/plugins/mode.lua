-- prismatic line decorations
return {
  "mvllow/modes.nvim",
  tag = "v0.2.1",
  opts = {
    colors = {
      bg = "#f5f5f5",
      copy = "#FFFD75",
      delete = "#FF4C4C",
      insert = "#66B3FF",
      visual = "#FFAAFF",
    },
    line_opacity = 0.20,
    set_cursor = true,
    set_cursorline = true,
    set_number = true,
    ignore_filetypes = { "NvimTree", "TelescopePrompt" },
  },
}
