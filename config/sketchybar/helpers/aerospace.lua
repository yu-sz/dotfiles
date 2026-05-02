local M = {}

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

function M.focused_workspace()
  local f = io.popen("aerospace list-workspaces --focused")
  if not f then
    return "1"
  end
  local out = (f:read("*l") or ""):gsub("%s+", "")
  f:close()
  return out ~= "" and out or "1"
end

function M.apps_by_workspace()
  local cmd =
    [[aerospace list-windows --all --format "%{workspace}%{app-name}" --json | jq -r '.[] | "\(.workspace)\t\(.["app-name"])"']]
  local result = {}
  local seen = {}
  local f = io.popen(cmd)
  if not f then
    return result
  end
  for line in f:lines() do
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
  f:close()
  return result
end

return M
