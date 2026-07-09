--- @class WeztermMyUtils
local M = {}

-- update-status の高頻度発火で毎回 git を起動しないための cwd 単位キャッシュ
-- 値が false のときは「リポジトリ外」を表す
---@type table<string, string|false>
local repo_cache = {}

---@param pane any wezterm の Pane オブジェクト
---@return string|nil
local function get_cwd_path(pane)
  local wezterm = require("wezterm")
  local cwd_uri = pane:get_current_working_dir()

  if not cwd_uri then
    return nil
  end

  local cwd_uri_string = wezterm.to_string(cwd_uri)
  if not cwd_uri_string then
    return nil
  end

  local cwd = cwd_uri_string:gsub("^file://", "")
  return cwd
end

-- 現在のディレクトリ名を取得
---@param pane any wezterm の Pane オブジェクト
---@return string|nil
function M.get_current_dir(pane)
  local cwd = get_cwd_path(pane)
  if not cwd then
    return nil
  end

  local current_dir = cwd:match("^.*/(.*)$") or cwd
  return current_dir
end

---@param cwd string
---@return string|nil
local function resolve_git_repository(cwd)
  local wezterm = require("wezterm")

  -- まずリモートURLからリポジトリ名を取得
  local success, stdout = wezterm.run_child_process({
    "git",
    "-C",
    cwd,
    "config",
    "--get",
    "remote.origin.url",
  })

  if success then
    local url = stdout:gsub("%s+", "")
    if url ~= "" then
      -- URLからリポジトリ名を抽出
      -- 例: https://github.com/user/dotfiles.git → dotfiles
      -- 例: git@github.com:user/dotfiles.git → dotfiles
      local repo_name = url:match("/([^/]+)%.git$")
        or url:match("/([^/]+)$")
        or url:match(":([^:]+)%.git$")
        or url:match(":([^:]+)$")
      if repo_name then
        return repo_name
      end
    end
  end

  -- フォールバック: Gitルートディレクトリ名を使用
  success, stdout = wezterm.run_child_process({
    "git",
    "-C",
    cwd,
    "rev-parse",
    "--show-toplevel",
  })

  if success then
    local toplevel = stdout:gsub("%s+", "")
    if toplevel ~= "" then
      return toplevel:match("^.*/(.*)$") or toplevel
    end
  end

  return nil
end

-- gitリポジトリ名を取得
---@param pane any wezterm の Pane オブジェクト
---@return string|nil
function M.get_git_repository(pane)
  local cwd = get_cwd_path(pane)
  if not cwd then
    return nil
  end

  if repo_cache[cwd] == nil then
    repo_cache[cwd] = resolve_git_repository(cwd) or false
  end
  return repo_cache[cwd] or nil
end

-- merge tables
---@param t1 table マージ先（破壊的に更新される）
---@param t2 table マージ元
---@return table
function M.merge_tables(t1, t2)
  for k, v in pairs(t2) do
    if (type(v) == "table") and (type(t1[k] or false) == "table") then
      M.merge_tables(t1[k], t2[k])
    else
      t1[k] = v
    end
  end
  return t1
end

return M
