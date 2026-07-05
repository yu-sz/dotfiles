local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local aerospace = require("helpers.aerospace")
local icon_map = require("helpers.icon_map")

return function(position)
  local focus_color = colors.blue

  local spaces = {}
  local rendered = {}
  local current_focused = aerospace.focused_workspace()

  local function ensure_space_item(ws_id)
    if spaces[ws_id] then
      return
    end
    spaces[ws_id] = sbar.add("item", "space." .. ws_id, {
      position = position,
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
    local label = table.concat(parts, "")
    local is_focused = (ws_id == current_focused)
    local drawing = #apps > 0 or is_focused

    local prev = rendered[ws_id]
    if prev and prev.label == label and prev.focused == is_focused and prev.drawing == drawing then
      return
    end
    rendered[ws_id] = { label = label, focused = is_focused, drawing = drawing }

    item:set({
      label = { string = label, highlight = is_focused },
      icon = { highlight = is_focused },
      background = {
        color = is_focused and focus_color or colors.transparent,
      },
      drawing = drawing,
    })
  end

  local in_flight, dirty = false, false

  local function do_reconcile()
    in_flight = true
    aerospace.apps_by_workspace(function(apps_map)
      for ws_id in pairs(spaces) do
        update_space(ws_id, apps_map[ws_id])
      end
      in_flight = false
      if dirty then
        dirty = false
        do_reconcile()
      end
    end)
  end

  local function reconcile()
    if in_flight then
      dirty = true
      return
    end
    do_reconcile()
  end

  local space_ids = { "aerospace.mode" }
  for _, ws_id in ipairs(aerospace.list_workspaces()) do
    ensure_space_item(ws_id)
    table.insert(space_ids, "space." .. ws_id)
  end
  if current_focused and not spaces[current_focused] then
    ensure_space_item(current_focused)
    table.insert(space_ids, "space." .. current_focused)
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
end
