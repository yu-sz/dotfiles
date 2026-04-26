local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")

local clock = sbar.add("item", "clock", {
  position = "right",
  icon = {
    string = "􀐬",
    color = colors.blue,
    font = settings.font.icons,
    padding_left = 10,
    padding_right = 6,
  },
  label = {
    string = os.date("%H:%M"),
    font = settings.font.numbers,
    color = colors.fg,
    padding_right = 10,
  },
  update_freq = 60,
  updates = true,
})

clock:subscribe("routine", function()
  clock:set({ label = { string = os.date("%H:%M") } })
end)
