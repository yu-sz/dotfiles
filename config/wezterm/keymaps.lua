---@type Wezterm
local wezterm = require("wezterm")
local act = wezterm.action

local prefix = { key = "g", mods = "CTRL", timeout_milliseconds = 1000 }
local keys = {
	-- full screen
	{ key = "f", mods = "LEADER", action = act.ToggleFullScreen },

	{ key = "b", mods = "LEADER", action = act.EmitEvent("toggle-blur") },
	{ key = "o", mods = "LEADER", action = act.EmitEvent("toggle-opacity") },

	-- font size
	{ key = "+", mods = "LEADER", action = act.IncreaseFontSize },
	{ key = "-", mods = "LEADER", action = act.DecreaseFontSize },

	-- create Tab
	{ key = "t", mods = "LEADER", action = act({ SpawnTab = "CurrentPaneDomain" }) },
	-- close Tab
	{ key = "w", mods = "LEADER", action = act.CloseCurrentTab({ confirm = true }) },
	-- move Tab
	{ key = "]", mods = "LEADER", action = act.MoveTabRelative(1) },
	{ key = "[", mods = "LEADER", action = act.MoveTabRelative(-1) },

	-- create Pane
	{ key = "w", mods = "LEADER", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
	-- 下方向にPane分割
	{ key = ",", mods = "LEADER", action = act({ SplitVertical = { domain = "CurrentPaneDomain" } }) },
	-- 右方向にPane分割
	{ key = ".", mods = "LEADER", action = wezterm.action({ SplitHorizontal = { domain = "CurrentPaneDomain" } }) },
	-- 中身を入れ替える
	{ key = "g", mods = "LEADER", action = wezterm.action.RotatePanes("Clockwise") },
	-- move on pane
	{ key = "h", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Right") },

	-- Shift + Enter で改行を送信（for Claude Code）
	{ key = "Enter", mods = "SHIFT", action = act.SendString("\n") },

	-- workspace一覧
	{
		key = "s",
		mods = "LEADER",
		action = wezterm.action_callback(function(win, pane)
			local workspaces = {}
			for i, name in ipairs(wezterm.mux.get_workspace_names()) do
				table.insert(workspaces, {
					id = name,
					label = string.format("%d. %s", i, name),
				})
			end

			-- local current = wezterm.mux.get_active_workspace()
			win:perform_action(
				act.InputSelector({
					action = wezterm.action_callback(function(_, _, id, label)
						if not id and not label then
							wezterm.log_info("Workspace selection canceled")
						else
							win:perform_action(act.SwitchToWorkspace({ name = id }), pane) -- workspace を移動
						end
					end),
					title = "Select workspace",
					choices = workspaces,
					fuzzy = true,
					-- fuzzy_description = string.format("Select workspace: %s -> ", current), -- requires nightly build
				}),
				pane
			)
		end),
	},
	-- 現在のワークスペースに名前を追加
	{
		key = "$",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "(wezterm) Set workspace title:",
			action = wezterm.action_callback(function(_win, _pane, line)
				if line and line ~= "" then
					wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
				end
			end),
		}),
	},
	-- 名前を指定して新しいworkspaceを作成
	{
		key = "S",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "(wezterm) Set workspace title:",
			action = wezterm.action_callback(function(win, pane, line)
				if line and line ~= "" then
					win:perform_action(
						act.SwitchToWorkspace({
							name = line,
						}),
						pane
					)
				end
			end),
		}),
	},
}

-- 番号のタブに移動する
for i = 1, 9 do
	table.insert(keys, {
		key = tostring(i),
		mods = "LEADER",
		action = act.ActivateTab(i - 1),
	})
end

--- @type Config
return {
	leader = prefix,
	keys = keys,
}
