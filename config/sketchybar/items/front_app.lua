local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")

local app_icon_map = {
  ["Google Chrome"] = ":google_chrome:",
  ["Safari"] = ":safari:",
  ["Ghostty"] = ":ghostty:",
  ["Slack"] = ":slack:",
  ["Code"] = ":code:",
  ["Cursor"] = ":cursor:",
  ["Finder"] = ":finder:",
  ["Discord"] = ":discord:",
  ["Spotify"] = ":spotify:",
  ["1Password"] = ":1password:",
  ["Terminal"] = ":terminal:",
}

local app_icon_color = {
  ["Google Chrome"] = colors.yellow,
  ["Safari"] = colors.blue,
  ["Ghostty"] = colors.purple,
  ["Slack"] = colors.magenta,
  ["Code"] = colors.blue,
  ["Cursor"] = colors.cyan,
  ["Finder"] = colors.cyan,
  ["Discord"] = colors.purple,
  ["Spotify"] = colors.green,
  ["1Password"] = colors.blue,
  ["Terminal"] = colors.fg,
}

local front_app = sbar.add("item", "front_app", {
  position = "left",
  icon = {
    font = settings.font.app,
    padding_left = 10,
    padding_right = 6,
    color = colors.fg,
  },
  label = {
    font = "Moralerspace Xenon HW:Bold:13.0",
    color = colors.fg,
    padding_right = 10,
  },
  updates = true,
})

front_app:subscribe("front_app_switched", function(env)
  local app = env.INFO or ""
  local icon = app_icon_map[app] or ":default:"
  local color = app_icon_color[app] or colors.fg
  front_app:set({
    icon = { string = icon, color = color },
    label = { string = app },
  })
end)
