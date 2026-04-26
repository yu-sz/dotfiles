local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")

local function add_separator(name, position)
  sbar.add("item", name, {
    position = position,
    icon = {
      string = "│",
      color = colors.bg_highlight,
      font = settings.font.icons,
      padding_left = 4,
      padding_right = 4,
    },
    label = { drawing = false },
    background = { drawing = false },
  })
end

add_separator("separator.left", "left")
add_separator("separator.right", "right")
