local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local nf = require("helpers.icons").nf

return function(position)
  sbar.add("item", "cpu.padding", {
    position = position,
    width = 4,
    background = { drawing = false },
    icon = { drawing = false, padding_left = 0, padding_right = 0 },
    label = { drawing = false, padding_left = 0, padding_right = 0 },
  })

  local cpu_graph = sbar.add("graph", "cpu.graph", 40, {
    position = position,
    graph = {
      color = colors.purple,
      fill_color = colors.with_alpha(colors.purple, 0.6),
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

  local cpu = sbar.add("item", "cpu", {
    position = position,
    icon = {
      string = nf(0xF4BC),
      color = colors.purple,
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
end
