local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")

sbar.default({
  updates = "when_shown",
  icon = {
    font = settings.font.icons,
    color = colors.fg,
    padding_left = settings.paddings,
    padding_right = settings.paddings,
  },
  label = {
    font = settings.font.text,
    color = colors.fg,
    padding_left = settings.paddings,
    padding_right = settings.paddings,
  },
  background = {
    color = colors.bg_dark,
    height = 34,
    corner_radius = 10,
    border_width = 2,
    border_color = colors.bg_highlight,
  },
  popup = {
    background = {
      border_width = 1,
      corner_radius = 8,
      border_color = colors.popup.border,
      color = colors.popup.bg,
    },
    blur_radius = 50,
  },
  padding_left = math.floor(settings.paddings / 2),
  padding_right = math.floor(settings.paddings / 2),
})
