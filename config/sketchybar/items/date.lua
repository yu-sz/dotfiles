local sbar = require("sketchybar")
local colors = require("colors")

local bracket_font = "Hiragino Sans:W3:28.0"

sbar.add("item", "date.rbracket", {
  position = "right",
  icon = {
    string = "〕",
    font = bracket_font,
    color = colors.blue,
    width = 14,
    align = "left",
    padding_left = 0,
    padding_right = 0,
  },
  label = { drawing = false },
  background = { drawing = false },
})

local date = sbar.add("item", "date", {
  position = "right",
  icon = {
    string = os.date("%H:%M"),
    font = "Moralerspace Xenon HW:Bold:14.0",
    color = colors.fg,
    y_offset = 7,
    padding_left = 4,
    padding_right = 4,
  },
  label = {
    string = os.date("%b %d %a"),
    font = "Moralerspace Xenon HW:Regular:12.0",
    color = colors.fg_dark,
    y_offset = -7,
    padding_left = -40,
    padding_right = 4,
  },
  background = { drawing = false },
  update_freq = 30,
  updates = true,
})

sbar.add("item", "date.lbracket", {
  position = "right",
  icon = {
    string = "〔",
    font = bracket_font,
    color = colors.blue,
    width = 14,
    align = "left",
    padding_left = -12,
    padding_right = 0,
  },
  label = { drawing = false },
  background = { drawing = false },
})

date:subscribe("routine", function()
  date:set({
    icon = { string = os.date("%H:%M") },
    label = { string = os.date("%b %d %a") },
  })
end)
