local colors = require("colors")

local M = {}

local icons = {
  ["Google Chrome"] = ":google_chrome:",
  ["Safari"] = ":safari:",
  ["Arc"] = ":arc:",
  ["Firefox"] = ":firefox:",
  ["Ghostty"] = ":ghostty:",
  ["WezTerm"] = ":wezterm:",
  ["Terminal"] = ":terminal:",
  ["iTerm2"] = ":iterm:",
  ["Slack"] = ":slack:",
  ["Discord"] = ":discord:",
  ["Code"] = ":code:",
  ["Cursor"] = ":cursor:",
  ["Visual Studio Code"] = ":code:",
  ["Finder"] = ":finder:",
  ["1Password"] = ":one_password:",
  ["Spotify"] = ":spotify:",
  ["Notion"] = ":notion:",
  ["Notes"] = ":notes:",
  ["Mail"] = ":mail:",
  ["Calendar"] = ":calendar:",
  ["System Settings"] = ":gear:",
  ["システム設定"] = ":gear:",
  ["Docker Desktop"] = ":docker:",
  ["DBeaver"] = ":dbeaver:",
  ["Raycast"] = ":raycast:",
  ["Karabiner-Elements"] = ":keyboard:",
  ["zoom.us"] = ":zoom:",
  ["Zoom"] = ":zoom:",
}

local app_colors = {
  ["Google Chrome"] = colors.yellow,
  ["Safari"] = colors.blue,
  ["Arc"] = colors.orange,
  ["Firefox"] = colors.orange,
  ["Ghostty"] = colors.purple,
  ["WezTerm"] = colors.cyan,
  ["Terminal"] = colors.fg,
  ["iTerm2"] = colors.fg,
  ["Slack"] = colors.magenta,
  ["Discord"] = colors.purple,
  ["Code"] = colors.blue,
  ["Cursor"] = colors.cyan,
  ["Visual Studio Code"] = colors.blue,
  ["Finder"] = colors.cyan,
  ["1Password"] = colors.blue,
  ["Spotify"] = colors.green,
  ["Notion"] = colors.fg,
  ["System Settings"] = colors.fg_dark,
  ["システム設定"] = colors.fg_dark,
  ["Docker Desktop"] = colors.blue,
  ["DBeaver"] = colors.orange,
  ["Raycast"] = colors.red,
}

function M.icon(app_name)
  return icons[app_name] or ":default:"
end

function M.color(app_name)
  return app_colors[app_name] or colors.fg
end

return M
