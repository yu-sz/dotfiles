-- 独自実装: tmux セッション一覧と Claude の状態を表示。
-- 自作 workspace zsh プラグイン (config/zsh/plugins/workspace) に依存。
-- SLOT_COUNT 個の slot を起動時に確保し、drawing で表示制御する。

local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local nf = require("helpers.icons").nf

local STATE_DIR = (os.getenv("TMPDIR") or "/tmp/"):gsub("/$", "") .. "/ws-state"
local TMUX = "/etc/profiles/per-user/" .. (os.getenv("USER") or "") .. "/bin/tmux"
local NAME_LIMIT = 12
local POLL_INTERVAL = 5
local SLOT_COUNT = 10

local STATE_COLOR = {
  -- waiting への遷移は Claude Code 側の hook fire 遅延あり (anthropics/claude-code#19627, 未修正)
  waiting = colors.yellow,
  idle = colors.blue,
  none = colors.fg_dark,
}

local function list_sessions()
  local f = io.popen(TMUX .. " ls -F '#{session_name}' 2>/dev/null")
  if not f then
    return {}
  end
  local out = {}
  for line in f:lines() do
    if line ~= "" then
      table.insert(out, line)
    end
  end
  f:close()
  return out
end

local function read_state(name)
  local f = io.open(STATE_DIR .. "/claude_" .. name, "r")
  if not f then
    return "none"
  end
  local content = f:read("*l") or ""
  f:close()
  if content:match("^waiting") then
    return "waiting"
  end
  if content:match("^idle") then
    return "idle"
  end
  return "none"
end

return function(position)
  local header = sbar.add("item", "tmux.header", {
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
  local member_ids = { "tmux.header" }

  for i = 1, SLOT_COUNT do
    separators[i] = sbar.add("item", "tmux.sep." .. i, {
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
    slots[i] = sbar.add("item", "tmux.slot." .. i, {
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
    table.insert(member_ids, "tmux.sep." .. i)
    table.insert(member_ids, "tmux.slot." .. i)
  end

  local bracket = sbar.add("bracket", "tmux.bracket", member_ids, {
    background = {
      color = colors.bg_dark,
      border_color = colors.transparent,
      border_width = 0,
      corner_radius = 10,
      height = 32,
    },
  })

  local function reconcile()
    local current = list_sessions()
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
        local name = current[i]
        slots[i]:set({
          label = {
            string = name:sub(1, NAME_LIMIT),
            color = STATE_COLOR[read_state(name)] or STATE_COLOR.none,
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

  reconcile()

  sbar.add("event", "tmux_change")

  local handler = sbar.add("item", "tmux.handler", {
    drawing = false,
    update_freq = POLL_INTERVAL,
    updates = true,
  })
  handler:subscribe({ "routine", "forced", "tmux_change" }, reconcile)
end
