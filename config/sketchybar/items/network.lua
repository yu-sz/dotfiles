local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local nf = require("helpers.icons").nf

local network = sbar.add("item", "network", {
  position = "right",
  icon = {
    string = nf(0xF1EB),
    color = colors.cyan,
    font = settings.font.icons,
    padding_left = 10,
    padding_right = 6,
  },
  label = {
    string = "↑0  ↓0",
    font = settings.font.numbers,
    color = colors.fg,
    padding_right = 10,
  },
  background = {
    color = colors.bg_dark,
    border_color = colors.cyan,
    border_width = 2,
    corner_radius = 10,
    height = 32,
  },
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
      network:set({
        label = { string = string.format("↑%s ↓%s", format_bps(dout), format_bps(din)) },
      })
    end
  )
end

network:subscribe({ "routine", "forced", "system_woke" }, update_network)
