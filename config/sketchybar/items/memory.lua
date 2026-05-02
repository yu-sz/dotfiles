local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local nf = require("helpers.icons").nf

sbar.add("item", "memory.padding", {
  position = "right",
  width = 4,
  background = { drawing = false },
  icon = { drawing = false, padding_left = 0, padding_right = 0 },
  label = { drawing = false, padding_left = 0, padding_right = 0 },
})

local memory_graph = sbar.add("graph", "memory.graph", 40, {
  position = "right",
  graph = {
    color = colors.green,
    fill_color = colors.with_alpha(colors.green, 0.6),
    line_width = 0.7,
  },
  background = {
    drawing = true,
    color = colors.transparent,
    border_color = colors.transparent,
    border_width = 0,
    height = 20,
  },
  padding_left = -46,
})

local memory = sbar.add("item", "memory", {
  position = "right",
  icon = {
    string = nf(0xF0E4),
    color = colors.green,
    font = settings.font.icons,
    padding_left = 8,
    padding_right = 4,
  },
  label = {
    string = "--%",
    font = settings.font.numbers,
    color = colors.blue,
    width = 40,
    align = "left",
    padding_right = 6,
  },
  background = { drawing = false },
  update_freq = 2,
  updates = true,
})

local function update_memory()
  sbar.exec("memory_pressure | awk '/System-wide memory free percentage/ {print 100 - $5}'", function(out)
    local percent = tonumber((out or ""):match("([%d%.]+)"))
    if percent then
      memory_graph:push({ percent / 100 })
      memory:set({ label = { string = string.format("%d%%", math.floor(percent + 0.5)) } })
    end
  end)
end

memory:subscribe({ "routine", "forced" }, update_memory)
