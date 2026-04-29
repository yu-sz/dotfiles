local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local nf = require("helpers.icons").nf

local battery = sbar.add("item", "battery", {
  position = "right",
  icon = {
    color = colors.fg,
    font = settings.font.icons,
    padding_left = 8,
    padding_right = 4,
  },
  label = {
    font = settings.font.numbers,
    color = colors.fg,
    padding_right = 6,
  },
  update_freq = 60,
  updates = true,
})

local function pick_icon(percent, charging)
  if charging then
    return nf(0xF0084)
  end
  if percent >= 100 then
    return nf(0xF0079)
  end
  local level = math.max(1, math.floor(percent / 10))
  return nf(0xF0079 + level)
end

local function pick_color(percent, charging)
  if charging then
    return colors.green
  elseif percent <= 20 then
    return colors.red
  elseif percent <= 40 then
    return colors.yellow
  else
    return colors.green
  end
end

local function update_battery()
  sbar.exec("pmset -g batt", function(out)
    out = out or ""
    local percent = tonumber(out:match("(%d+)%%")) or 0
    local charging = out:find("AC Power", 1, true) ~= nil
    local color = pick_color(percent, charging)
    battery:set({
      icon = { string = pick_icon(percent, charging), color = color },
      label = { string = percent .. "%" },
    })
  end)
end

battery:subscribe({ "routine", "power_source_change", "system_woke" }, update_battery)
