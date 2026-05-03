local sbar = require("sketchybar")

local M = {}

function M.add(name, position)
  sbar.add("item", name, {
    position = position,
    width = 8,
    background = { drawing = false },
    icon = { drawing = false, padding_left = 0, padding_right = 0 },
    label = { drawing = false, padding_left = 0, padding_right = 0 },
  })
end

return M
