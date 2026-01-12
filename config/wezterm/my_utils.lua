--- @class WeztermMyUtils
local M = {}

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
function M.get_current_dir(pane)
	local cwd = get_cwd_path(pane)
	if not cwd then
		return nil
	end

	local current_dir = cwd:match("^.*/(.*)$") or cwd
	return current_dir
end

-- gitブランチ名を取得
-- gitリポジトリ名を取得
function M.get_git_repository(pane)
	local wezterm = require("wezterm")
	local cwd = get_cwd_path(pane)
	if not cwd then
		return nil
	end

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
			local repo_name = toplevel:match("^.*/(.*)$") or toplevel
			return repo_name
		end
	end

	return nil
end

-- merge tables
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
