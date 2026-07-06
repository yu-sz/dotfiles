-- 独自実装: herdr workspace 一覧と agent 状態を表示。
-- herdr plugin (config/herdr/plugins/sketchybar-sync) が発火する herdr_update
-- イベント駆動で再描画する (ポーリングなし)。
-- SLOT_COUNT 個の slot を起動時に確保し、drawing で表示制御する。

local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local nf = require("helpers.icons").nf

local SNAPSHOT = (os.getenv("HOME") or "") .. "/.config/sketchybar/helpers/herdr-ws-snapshot"
local NAME_LIMIT = 12
local SLOT_COUNT = 10

-- herdr の agent_status は 5 値。done を落とすと完了エージェントが
-- unknown 色になるため必ず含める。
local STATE_COLOR = {
  blocked = colors.red,
  working = colors.yellow,
  done = colors.green,
  idle = colors.blue,
  unknown = colors.fg_dark,
}

return function(position)
  local header = sbar.add("item", "herdr.header", {
    position = position,
    icon = {
      string = nf(0xF120),
      color = colors.fg_dark,
      font = settings.font.icons,
      padding_left = 8,
      padding_right = 4,
    },
    label = { drawing = false },
    background = { drawing = false },
    padding_left = 0,
    padding_right = 0,
    drawing = false,
  })

  local slots = {}
  local separators = {}
  local member_ids = { "herdr.header" }

  for i = 1, SLOT_COUNT do
    separators[i] = sbar.add("item", "herdr.sep." .. i, {
      position = position,
      icon = { drawing = false, padding_left = 0, padding_right = 0 },
      label = {
        string = "|",
        font = settings.font.numbers,
        color = colors.comment,
        padding_left = 0,
        padding_right = 0,
      },
      background = { drawing = false },
      padding_left = 0,
      padding_right = 0,
      drawing = false,
    })
    slots[i] = sbar.add("item", "herdr.slot." .. i, {
      position = position,
      icon = { drawing = false, padding_left = 0, padding_right = 0 },
      label = {
        string = "",
        font = settings.font.numbers,
        color = colors.fg_dark,
        padding_left = 6,
        padding_right = 6,
      },
      background = { drawing = false },
      padding_left = 0,
      padding_right = 0,
      drawing = false,
    })
    table.insert(member_ids, "herdr.sep." .. i)
    table.insert(member_ids, "herdr.slot." .. i)
  end

  local bracket = sbar.add("bracket", "herdr.bracket", member_ids, {
    background = {
      color = colors.bg_dark,
      border_color = colors.transparent,
      border_width = 0,
      corner_radius = 10,
      height = 32,
    },
  })

  -- pane.agent_status_changed は working↔idle で頻発しうるため、
  -- 実行中の再入は dirty フラグで合流させ 1 回の再取得へ debounce する。
  local in_flight, dirty = false, false

  local function render(current)
    local count = math.min(#current, SLOT_COUNT)

    if count == 0 then
      header:set({ drawing = false })
      bracket:set({ drawing = false })
      for i = 1, SLOT_COUNT do
        slots[i]:set({ drawing = false })
        separators[i]:set({ drawing = false })
      end
      return
    end

    header:set({ drawing = true })
    bracket:set({ drawing = true })

    for i = 1, SLOT_COUNT do
      if i <= count then
        local ws = current[i]
        slots[i]:set({
          label = {
            string = ws.label:sub(1, NAME_LIMIT),
            color = STATE_COLOR[ws.status] or STATE_COLOR.unknown,
          },
          drawing = true,
        })
        separators[i]:set({ drawing = i > 1 })
      else
        slots[i]:set({ drawing = false })
        separators[i]:set({ drawing = false })
      end
    end
  end

  local function reconcile()
    if in_flight then
      dirty = true
      return
    end
    in_flight = true
    sbar.exec(SNAPSHOT, function(out)
      local current = {}
      for line in (out or ""):gmatch("[^\r\n]+") do
        local label, status = line:match("^([^\t]+)\t(%S+)$")
        if label then
          table.insert(current, { label = label, status = status })
        end
      end
      render(current)
      in_flight = false
      if dirty then
        dirty = false
        reconcile()
      end
    end)
  end

  reconcile()

  sbar.add("event", "herdr_update")

  local handler = sbar.add("item", "herdr.handler", {
    drawing = false,
    updates = true,
  })
  handler:subscribe({ "forced", "herdr_update" }, reconcile)
end
