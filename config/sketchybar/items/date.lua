local sbar = require("sketchybar")
local colors = require("colors")

return function(position)
  local accent_outer = {
    color = colors.blue,
    border_color = colors.transparent,
    border_width = 0,
    height = 30,
    corner_radius = 1,
  }

  local accent_inner = {
    color = colors.blue,
    border_color = colors.transparent,
    border_width = 0,
    height = 30,
    corner_radius = 0,
  }

  sbar.add("item", "date.accent.right_outer", {
    position = position,
    width = 2,
    padding_left = 0,
    padding_right = 0,
    background = accent_outer,
    icon = { drawing = false, padding_left = 0, padding_right = 0 },
    label = { drawing = false, padding_left = 0, padding_right = 0 },
  })

  sbar.add("item", "date.accent.right_inner", {
    position = position,
    width = 1,
    padding_left = 0,
    padding_right = 2,
    background = accent_inner,
    icon = { drawing = false, padding_left = 0, padding_right = 0 },
    label = { drawing = false, padding_left = 0, padding_right = 0 },
  })

  local date = sbar.add("item", "date", {
    position = position,
    icon = {
      string = os.date("%H:%M"),
      font = "Moralerspace Xenon HW:Bold:14.0",
      color = colors.fg,
      y_offset = 7,
      padding_left = 6,
      padding_right = 4,
    },
    label = {
      string = os.date("%b %d %a"),
      font = "Moralerspace Xenon HW:Regular:12.0",
      color = colors.blue,
      y_offset = -7,
      padding_left = -40,
      padding_right = 6,
    },
    background = { drawing = false },
    update_freq = 30,
    updates = true,
  })

  sbar.add("item", "date.accent.left_inner", {
    position = position,
    width = 1,
    padding_left = 0,
    padding_right = 0,
    background = accent_inner,
    icon = { drawing = false, padding_left = 0, padding_right = 0 },
    label = { drawing = false, padding_left = 0, padding_right = 0 },
  })

  sbar.add("item", "date.accent.left_outer", {
    position = position,
    width = 2,
    padding_right = 2,
    background = accent_outer,
    icon = { drawing = false, padding_left = 0, padding_right = 0 },
    label = { drawing = false, padding_left = 0, padding_right = 0 },
  })

  date:subscribe("routine", function()
    date:set({
      icon = { string = os.date("%H:%M") },
      label = { string = os.date("%b %d %a") },
    })
  end)
end
