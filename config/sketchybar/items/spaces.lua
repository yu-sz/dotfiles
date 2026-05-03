local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local aerospace = require("helpers.aerospace")
local icon_map = require("helpers.icon_map")

local focus_color = colors.blue

local spaces = {}
local current_focused = aerospace.focused_workspace()

local function ensure_space_item(ws_id)
  if spaces[ws_id] then
    return
  end
  spaces[ws_id] = sbar.add("item", "space." .. ws_id, {
    position = "left",
    icon = {
      string = ws_id,
      color = colors.blue,
      highlight_color = colors.bg_dark,
      font = settings.font.numbers,
      padding_left = 6,
      padding_right = 4,
    },
    label = {
      string = "",
      font = settings.font.app,
      color = colors.blue,
      highlight_color = colors.bg_dark,
      padding_right = 6,
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
  item:set({
    label = { string = table.concat(parts, ""), highlight = is_focused },
    icon = { highlight = is_focused },
    background = {
      color = is_focused and focus_color or colors.transparent,
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

local space_ids = { "aerospace.mode" }
for _, ws_id in ipairs(aerospace.list_workspaces()) do
  ensure_space_item(ws_id)
  table.insert(space_ids, "space." .. ws_id)
end

sbar.add("bracket", "spaces.bracket", space_ids, {
  background = {
    color = colors.bg_dark,
    border_color = colors.blue,
    border_width = 1,
    corner_radius = 10,
    height = 32,
  },
})

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
