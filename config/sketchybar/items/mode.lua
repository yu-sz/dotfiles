local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local nf = require("helpers.icons").nf

local mode_style = {
  main = { color = colors.blue, icon = nf(0xF24D), label = "main" },
  resize = { color = colors.orange, icon = nf(0xF065), label = "resize" },
  service = { color = colors.magenta, icon = nf(0xF013), label = "service" },
}

local function fetch_current_mode()
  local f = io.popen("aerospace list-modes --current")
  if not f then
    return "main"
  end
  local out = (f:read("*l") or ""):gsub("%s+", "")
  f:close()
  return out ~= "" and out or "main"
end

return function(position)
  local mode = sbar.add("item", "aerospace.mode", {
    position = position,
    icon = {
      string = mode_style.main.icon,
      color = mode_style.main.color,
      font = settings.font.icons,
      padding_left = 8,
      padding_right = 4,
    },
    label = {
      string = mode_style.main.label,
      font = settings.font.numbers,
      color = mode_style.main.color,
      padding_right = 4,
    },
    background = {
      color = colors.transparent,
      border_color = colors.transparent,
      border_width = 0,
      corner_radius = 8,
      height = 26,
    },
    padding_left = 2,
    padding_right = 2,
    update_freq = 1,
    updates = true,
  })

  local last_mode

  local function update_mode(name)
    if name == last_mode then
      return
    end
    last_mode = name
    local style = mode_style[name] or mode_style.main
    mode:set({
      icon = { string = style.icon, color = style.color },
      label = { string = style.label, color = style.color },
    })
  end

  local function refresh()
    update_mode(fetch_current_mode())
  end

  sbar.add("event", "aerospace_mode_change")

  mode:subscribe({ "routine", "forced", "aerospace_mode_change" }, refresh)

  refresh()
end
