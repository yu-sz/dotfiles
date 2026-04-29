local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local nf = require("helpers.icons").nf

sbar.add("item", "cpu.padding", {
  position = "right",
  width = 4,
  background = { drawing = false },
  icon = { drawing = false, padding_left = 0, padding_right = 0 },
  label = { drawing = false, padding_left = 0, padding_right = 0 },
})

local cpu_graph = sbar.add("graph", "cpu.graph", 40, {
  position = "right",
  graph = {
    color = colors.red,
    fill_color = colors.with_alpha(colors.red, 0.7),
    line_width = 1.0,
  },
  background = {
    drawing = true,
    color = colors.transparent,
    border_color = colors.transparent,
    border_width = 0,
    height = 22,
  },
  padding_left = -10,
})

local cpu = sbar.add("item", "cpu", {
  position = "right",
  icon = {
    string = nf(0xF4BC),
    color = colors.red,
    font = settings.font.icons,
    padding_left = 8,
    padding_right = 4,
  },
  label = {
    string = "--%",
    font = settings.font.numbers,
    color = colors.fg,
    padding_right = 6,
  },
  background = { drawing = false },
  update_freq = 2,
  updates = true,
})

sbar.add("bracket", "cpu.bracket", { cpu.name, cpu_graph.name }, {
  background = {
    color = colors.bg_dark,
    border_color = colors.red,
    border_width = 2,
    corner_radius = 10,
    height = 32,
  },
})

local function update_cpu()
  sbar.exec("top -l 1 -n 0 | awk '/CPU usage/ {print $3+$5}'", function(out)
    local percent = tonumber((out or ""):match("([%d%.]+)")) or 0
    cpu_graph:push({ percent / 100 })
    cpu:set({
      label = { string = string.format("%d%%", math.floor(percent + 0.5)) },
    })
  end)
end

cpu:subscribe({ "routine", "forced" }, update_cpu)
