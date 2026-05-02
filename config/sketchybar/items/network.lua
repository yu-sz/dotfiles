local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local nf = require("helpers.icons").nf

local LOG_REFERENCE_BPS = 25 * 1024 * 1024
local LOG_REF_DENOM = math.log(LOG_REFERENCE_BPS + 1)

local function normalize_log(bps)
  return math.min(1.0, math.log(bps + 1) / LOG_REF_DENOM)
end

sbar.add("item", "network.padding", {
  position = "right",
  width = 4,
  background = { drawing = false },
  icon = { drawing = false, padding_left = 0, padding_right = 0 },
  label = { drawing = false, padding_left = 0, padding_right = 0 },
})

local down_graph = sbar.add("graph", "network.down.graph", 48, {
  position = "right",
  graph = {
    color = colors.cyan,
    fill_color = colors.with_alpha(colors.cyan, 0.6),
    line_width = 0.7,
  },
  background = {
    drawing = true,
    color = colors.transparent,
    border_color = colors.transparent,
    border_width = 0,
    height = 20,
  },
  padding_left = -54,
})

local down = sbar.add("item", "network.down", {
  position = "right",
  icon = { drawing = false },
  label = {
    string = "↓0B",
    font = settings.font.numbers,
    color = colors.blue,
    padding_left = 0,
    padding_right = 6,
    width = 48,
    align = "left",
  },
  background = { drawing = false },
})

local up_graph = sbar.add("graph", "network.up.graph", 48, {
  position = "right",
  graph = {
    color = colors.red,
    fill_color = colors.with_alpha(colors.red, 0.6),
    line_width = 0.7,
  },
  background = {
    drawing = true,
    color = colors.transparent,
    border_color = colors.transparent,
    border_width = 0,
    height = 20,
  },
  padding_left = -52,
})

local up = sbar.add("item", "network.up", {
  position = "right",
  icon = { drawing = false },
  label = {
    string = "↑0B",
    font = settings.font.numbers,
    color = colors.blue,
    padding_left = 0,
    padding_right = 4,
    width = 48,
    align = "left",
  },
  background = { drawing = false },
})

local network = sbar.add("item", "network", {
  position = "right",
  icon = {
    string = nf(0xF1EB),
    color = colors.cyan,
    font = settings.font.icons,
    padding_left = 8,
    padding_right = 4,
  },
  label = { drawing = false },
  background = { drawing = false },
  update_freq = 2,
  updates = true,
})

local last_in, last_out = 0, 0

local function format_bps(bytes_per_sec)
  if bytes_per_sec < 1024 then
    return string.format("%dB", bytes_per_sec)
  elseif bytes_per_sec < 1024 * 1024 then
    return string.format("%dK", math.floor(bytes_per_sec / 1024))
  else
    return string.format("%.1fM", bytes_per_sec / (1024 * 1024))
  end
end

local function update_network()
  sbar.exec(
    "netstat -ibn | awk '/en0/ && !/Link/ {ibytes=$7; obytes=$10; exit} END {print ibytes, obytes}'",
    function(out)
      local in_b, out_b = (out or ""):match("(%d+)%s+(%d+)")
      in_b = tonumber(in_b) or 0
      out_b = tonumber(out_b) or 0
      if last_in == 0 then
        last_in, last_out = in_b, out_b
        return
      end
      local din = math.max(0, (in_b - last_in)) / 2
      local dout = math.max(0, (out_b - last_out)) / 2
      last_in, last_out = in_b, out_b
      up:set({ label = { string = "↑" .. format_bps(dout) } })
      down:set({ label = { string = "↓" .. format_bps(din) } })
      up_graph:push({ normalize_log(dout) })
      down_graph:push({ normalize_log(din) })
    end
  )
end

network:subscribe({ "routine", "forced", "system_woke" }, update_network)
