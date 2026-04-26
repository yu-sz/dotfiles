local M = {}

function M.list_apps(workspace_id)
  local cmd =
    string.format("aerospace list-windows --workspace %d --json | jq -r '.[].\"app-name\"' | sort -u", workspace_id)
  local f = io.popen(cmd)
  if not f then
    return {}
  end
  local apps = {}
  for line in f:lines() do
    if line ~= "" then
      table.insert(apps, line)
    end
  end
  f:close()
  return apps
end

function M.focused_workspace()
  local f = io.popen("aerospace list-workspaces --focused")
  if not f then
    return 1
  end
  local out = f:read("*l") or ""
  f:close()
  return tonumber(out:match("(%d+)")) or 1
end

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

return M
