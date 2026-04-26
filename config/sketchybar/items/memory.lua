local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local nf = require("helpers.icons").nf

local memory = sbar.add("item", "memory", {
  position = "right",
  icon = {
    string = nf(0xF0E4),
    color = colors.green,
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
    border_color = colors.green,
    border_width = 2,
    corner_radius = 10,
    height = 32,
  },
  update_freq = 10,
  updates = true,
})

local function update_memory()
  sbar.exec("memory_pressure | awk '/System-wide memory free percentage/ {print 100 - $5}'", function(out)
    local percent = tonumber((out or ""):match("([%d%.]+)"))
    if percent then
      memory:set({ label = { string = string.format("%d%%", math.floor(percent + 0.5)) } })
    end
  end)
end

memory:subscribe({ "routine", "forced" }, update_memory)
