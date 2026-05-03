local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local nf = require("helpers.icons").nf

sbar.add("item", "apple", {
  position = "left",
  icon = {
    string = nf(0xF179),
    color = colors.bg_dark,
    font = settings.font.apple_icon,
    padding_left = 10,
    padding_right = 10,
    y_offset = 2,
  },
  label = { drawing = false },
  background = {
    color = colors.blue,
    border_color = colors.blue,
    border_width = 1,
    corner_radius = 10,
    height = 32,
  },
  padding_left = 4,
  padding_right = 4,
  click_script = "open -a 'System Settings'",
})
