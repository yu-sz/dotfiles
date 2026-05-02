local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local aerospace = require("helpers.aerospace")
local icon_map = require("helpers.icon_map")

local color_palette = {
  colors.red,
  colors.orange,
  colors.yellow,
  colors.green,
  colors.cyan,
  colors.blue,
  colors.purple,
  colors.magenta,
}

local function accent_for(idx)
  return color_palette[((idx - 1) % #color_palette) + 1]
end

local workspace_ids = aerospace.list_workspaces()
local accents = {}
local spaces = {}

for idx, ws_id in ipairs(workspace_ids) do
  local accent = accent_for(idx)
  accents[ws_id] = accent
  local space = sbar.add("item", "space." .. ws_id, {
    position = "left",
    icon = {
      string = ws_id,
      color = accent,
      highlight_color = colors.bg,
      font = settings.font.numbers,
      padding_left = 8,
      padding_right = 4,
    },
    label = {
      string = "",
      font = settings.font.app,
      color = accent,
      highlight_color = colors.bg,
      padding_right = 8,
    },
    background = {
      color = colors.bg_dark,
      border_color = accent,
      border_width = 1,
      corner_radius = 10,
      height = 34,
    },
    padding_left = 4,
    padding_right = 4,
    click_script = "aerospace workspace " .. ws_id,
  })
  spaces[ws_id] = space
end

local function refresh_apps(ws_id)
  local apps = aerospace.list_apps(ws_id)
  local parts = {}
  for _, app_name in ipairs(apps) do
    table.insert(parts, icon_map.icon(app_name))
  end
  if spaces[ws_id] then
    spaces[ws_id]:set({ label = { string = table.concat(parts, "") } })
  end
end

local function update_focus(focused)
  for _, ws_id in ipairs(workspace_ids) do
    local is_focused = (ws_id == focused)
    local accent = accents[ws_id] or colors.fg
    spaces[ws_id]:set({
      icon = { highlight = is_focused },
      label = { highlight = is_focused },
      background = {
        color = is_focused and accent or colors.bg_dark,
        border_color = accent,
      },
    })
  end
end

local function refresh_all()
  for _, ws_id in ipairs(workspace_ids) do
    refresh_apps(ws_id)
  end
end

refresh_all()
update_focus(tostring(aerospace.focused_workspace()))

sbar.add("event", "aerospace_workspace_change")

local handler = sbar.add("item", "spaces.handler", {
  drawing = false,
  updates = true,
})
handler:subscribe("aerospace_workspace_change", function(env)
  local focused = env.FOCUSED or "1"
  update_focus(focused)
  refresh_all()
end)
handler:subscribe("front_app_switched", refresh_all)
