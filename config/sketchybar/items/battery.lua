local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")

local battery = sbar.add("item", "battery", {
  position = "right",
  icon = {
    color = colors.fg,
    font = settings.font.icons,
    padding_left = 10,
    padding_right = 6,
  },
  label = {
    font = settings.font.numbers,
    color = colors.fg,
    padding_right = 10,
  },
  update_freq = 60,
  updates = true,
})

local function pick_icon(percent, charging)
  if charging then
    return "􀋦"
  elseif percent <= 20 then
    return "􀛪"
  elseif percent <= 40 then
    return "􀛩"
  elseif percent <= 60 then
    return "􀛨"
  elseif percent <= 80 then
    return "􀺸"
  else
    return "􀛨"
  end
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
