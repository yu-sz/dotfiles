local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local nf = require("helpers.icons").nf

local cpu = sbar.add("item", "cpu", {
  position = "right",
  icon = {
    string = nf(0xF4BC),
    color = colors.purple,
    font = settings.font.icons,
    padding_left = 10,
    padding_right = 6,
  },
  label = {
    string = "--%",
    font = settings.font.numbers,
    color = colors.fg,
    padding_right = 10,
  },
  background = {
    color = colors.bg_dark,
    border_color = colors.purple,
    border_width = 2,
    corner_radius = 10,
    height = 32,
  },
  update_freq = 5,
  updates = true,
})

local function update_cpu()
  sbar.exec("top -l 1 -n 0 | awk '/CPU usage/ {print $3+$5}'", function(out)
    local percent = tonumber((out or ""):match("([%d%.]+)")) or 0
    cpu:set({
      label = { string = string.format("%d%%", math.floor(percent + 0.5)) },
    })
  end)
end

cpu:subscribe({ "routine", "forced" }, update_cpu)
