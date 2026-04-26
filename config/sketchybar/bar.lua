local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")

sbar.bar({
  height = settings.bar_height,
  color = colors.transparent,
  border_color = colors.transparent,
  border_width = 0,
  shadow = false,
  sticky = true,
  topmost = "window",
  position = "top",
  margin = 0,
  y_offset = 0,
  blur_radius = 0,
  padding_left = 8,
  padding_right = 8,
  notch_width = 0,
})
