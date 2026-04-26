local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")

local date = sbar.add("item", "date", {
  position = "right",
  icon = {
    drawing = false,
  },
  label = {
    string = os.date("%b %d %a %H:%M"),
    font = settings.font.numbers,
    color = colors.fg,
    padding_left = 10,
    padding_right = 10,
  },
  background = {
    color = colors.bg_dark,
    border_color = colors.fg_dark,
    border_width = 2,
    corner_radius = 10,
    height = 32,
  },
  update_freq = 30,
  updates = true,
})

date:subscribe("routine", function()
  date:set({ label = { string = os.date("%b %d %a %H:%M") } })
end)
