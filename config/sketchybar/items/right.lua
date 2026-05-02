local sbar = require("sketchybar")
local colors = require("colors")

local section_background = {
  color = colors.bg_dark,
  border_color = colors.blue,
  border_width = 1,
  corner_radius = 10,
  height = 32,
}

sbar.add("bracket", "metrics.bracket", {
  "cpu.padding",
  "cpu.graph",
  "cpu",
  "memory.padding",
  "memory.graph",
  "memory",
  "network.padding",
  "network",
  "network.up",
  "network.up.graph",
  "network.down",
  "network.down.graph",
}, {
  background = section_background,
})

sbar.add("bracket", "status.bracket", {
  "input",
  "volume",
  "battery",
}, {
  background = section_background,
})
