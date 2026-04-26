local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")

local volume = sbar.add("item", "volume", {
  position = "right",
  icon = {
    color = colors.cyan,
    font = settings.font.icons,
    padding_left = 10,
    padding_right = 6,
  },
  label = {
    font = settings.font.numbers,
    color = colors.fg,
    padding_right = 10,
  },
  updates = true,
})

local function pick_icon(percent)
  if percent == 0 then
    return "􀊠"
  elseif percent <= 33 then
    return "􀊡"
  elseif percent <= 66 then
    return "􀊢"
  else
    return "􀊣"
  end
end

volume:subscribe("volume_change", function(env)
  local percent = tonumber(env.INFO) or 0
  volume:set({
    icon = { string = pick_icon(percent) },
    label = { string = percent .. "%" },
  })
end)
