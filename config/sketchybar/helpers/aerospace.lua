local sbar = require("sketchybar")

local M = {}

---@return string[] 全 workspace 名のリスト
function M.list_workspaces()
  local f = io.popen("aerospace list-workspaces --all")
  if not f then
    return {}
  end
  local ws = {}
  for line in f:lines() do
    if line ~= "" then
      table.insert(ws, line)
    end
  end
  f:close()
  return ws
end

---@return string フォーカス中の workspace 名（取得失敗時は "1"）
function M.focused_workspace()
  local f = io.popen("aerospace list-workspaces --focused")
  if not f then
    return "1"
  end
  local out = (f:read("*l") or ""):gsub("%s+", "")
  f:close()
  return out ~= "" and out or "1"
end

---@param callback fun(result: table<string, string[]>) workspace 名 → アプリ名リスト
function M.apps_by_workspace(callback)
  local cmd =
    [[aerospace list-windows --all --format "%{workspace}%{app-name}" --json | jq -r '.[] | "\(.workspace)\t\(.["app-name"])"']]
  sbar.exec(cmd, function(out)
    local result = {}
    local seen = {}
    for line in (out or ""):gmatch("[^\r\n]+") do
      local ws, app = line:match("^([^\t]+)\t(.+)$")
      if ws and app then
        seen[ws] = seen[ws] or {}
        if not seen[ws][app] then
          seen[ws][app] = true
          result[ws] = result[ws] or {}
          table.insert(result[ws], app)
        end
      end
    end
    callback(result)
  end)
end

return M
