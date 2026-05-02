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

local function workspace_index(ws_id)
  local n = tonumber(ws_id)
  if n then
    return n
  end
  return string.byte(ws_id:sub(1, 1):upper()) - string.byte("A") + 10
end

local function accent_for(ws_id)
  local idx = workspace_index(ws_id)
  return color_palette[((idx - 1) % #color_palette) + 1]
end

local spaces = {}
local current_focused = aerospace.focused_workspace()

local function ensure_space_item(ws_id)
  if spaces[ws_id] then
    return
  end
  local accent = accent_for(ws_id)
  spaces[ws_id] = sbar.add("item", "space." .. ws_id, {
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
end

local function update_space(ws_id, apps)
  local item = spaces[ws_id]
  if not item then
    return
  end
  apps = apps or {}
  local parts = {}
  for _, app in ipairs(apps) do
    table.insert(parts, icon_map.icon(app))
  end
  local has_apps = #apps > 0
  local is_focused = (ws_id == current_focused)
  local accent = accent_for(ws_id)
  item:set({
    label = { string = table.concat(parts, ""), highlight = is_focused },
    icon = { highlight = is_focused },
    background = {
      color = is_focused and accent or colors.bg_dark,
      border_color = accent,
    },
    drawing = has_apps or is_focused,
  })
end

local function reconcile()
  local workspaces = aerospace.list_workspaces()
  local apps_map = aerospace.apps_by_workspace()

  local current_set = {}
  for _, ws_id in ipairs(workspaces) do
    current_set[ws_id] = true
    ensure_space_item(ws_id)
  end
  if current_focused and not current_set[current_focused] then
    current_set[current_focused] = true
    ensure_space_item(current_focused)
  end

  for ws_id, item in pairs(spaces) do
    if current_set[ws_id] then
      update_space(ws_id, apps_map[ws_id])
    else
      item:set({ drawing = false })
    end
  end
end

reconcile()

sbar.add("event", "aerospace_workspace_change")

local handler = sbar.add("item", "spaces.handler", {
  drawing = false,
  updates = true,
})
handler:subscribe("aerospace_workspace_change", function(env)
  current_focused = env.FOCUSED or current_focused
  reconcile()
end)
handler:subscribe("front_app_switched", reconcile)
