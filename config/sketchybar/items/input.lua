local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local nf = require("helpers.icons").nf

sbar.add("event", "input_change", "com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged")

local function pick_label(id)
  id = (id or ""):lower()
  if id:find("japanese") or id:find("kotoeri") or id:find("atok") or id:find("googlejapanese") then
    return "あ"
  end
  return "EN"
end

return function(position)
  local input = sbar.add("item", "input", {
    position = position,
    icon = {
      string = nf(0xF11C),
      color = colors.blue,
      font = settings.font.icons,
      padding_left = 8,
      padding_right = 4,
    },
    label = {
      string = "--",
      font = settings.font.numbers,
      color = colors.blue,
      padding_right = 6,
    },
    background = { drawing = false },
    updates = true,
  })

  local function fetch_input()
    sbar.exec("/etc/profiles/per-user/$USER/bin/macism", function(out)
      input:set({ label = { string = pick_label(out) } })
    end)
  end

  input:subscribe({ "input_change", "system_woke" }, fetch_input)

  fetch_input()
end
