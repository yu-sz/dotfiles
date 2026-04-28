local sbar = require("sketchybar")
local colors = require("colors")

sbar.add("bracket", "right", { "cpu", "memory", "network", "volume", "input", "battery", "date" }, {
  background = {
    color = colors.transparent,
    border_color = colors.transparent,
    border_width = 0,
  },
})
