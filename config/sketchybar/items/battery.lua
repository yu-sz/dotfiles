local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local nf = require("helpers.icons").nf

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
    return nf(0xF0E7)
  elseif percent <= 20 then
    return nf(0xF244)
  elseif percent <= 40 then
    return nf(0xF243)
  elseif percent <= 60 then
    return nf(0xF242)
  elseif percent <= 80 then
    return nf(0xF241)
  else
    return nf(0xF240)
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
