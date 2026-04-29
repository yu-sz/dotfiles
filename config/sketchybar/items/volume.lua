local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local nf = require("helpers.icons").nf

local volume = sbar.add("item", "volume", {
  position = "right",
  icon = {
    string = nf(0xF028),
    color = colors.orange,
    font = settings.font.icons,
    padding_left = 8,
    padding_right = 4,
  },
  label = {
    string = "--",
    font = settings.font.numbers,
    color = colors.fg,
    padding_right = 6,
  },
  updates = true,
})

local function pick_icon(percent)
  if percent == 0 then
    return nf(0xF026)
  elseif percent <= 33 then
    return nf(0xF027)
  elseif percent <= 66 then
    return nf(0xF027)
  else
    return nf(0xF028)
  end
end

volume:subscribe("volume_change", function(env)
  local percent = tonumber(env.INFO) or 0
  volume:set({
    icon = { string = pick_icon(percent) },
    label = { string = percent .. "%" },
  })
end)
