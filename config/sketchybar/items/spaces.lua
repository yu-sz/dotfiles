local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")

local space_count = 4
local space_names = {}

for i = 1, space_count do
  local name = "space." .. i
  local space = sbar.add("item", name, {
    icon = {
      string = tostring(i),
      padding_left = 10,
      padding_right = 10,
      color = colors.fg_dark,
      font = settings.font.numbers,
    },
    label = {
      drawing = false,
    },
    background = {
      color = colors.transparent,
      border_width = 0,
      height = 22,
      corner_radius = 6,
    },
    padding_left = 2,
    padding_right = 2,
    click_script = "aerospace workspace " .. i,
  })

  space:subscribe("aerospace_workspace_change", function(env)
    local focused = tonumber(env.FOCUSED)
    if focused == i then
      space:set({
        icon = { color = colors.bg },
        background = { color = colors.blue },
      })
    else
      space:set({
        icon = { color = colors.fg_dark },
        background = { color = colors.transparent },
      })
    end
  end)

  table.insert(space_names, name)
end

sbar.add("bracket", "spaces", space_names, {
  background = {
    color = colors.bg_dark,
    border_color = colors.bg_highlight,
    border_width = 1,
    corner_radius = 9,
    height = 26,
  },
})
