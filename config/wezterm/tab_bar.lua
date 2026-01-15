---@type Wezterm
local wezterm = require("wezterm")
---@type WeztermMyUtils
local utils = require("my_utils")

local title_cache = {}

-- set cache
wezterm.on("update-status", function(_win, pane)
	local dir = utils.get_current_dir(pane)
	local repo = utils.get_git_repository(pane)

	local title
	if repo and dir then
		title = dir .. "[" .. repo .. "]"
	elseif dir then
		title = dir
	end

	local pane_id = pane:pane_id()
	title_cache[pane_id] = title
end)
-- cleenup cache
wezterm.on("pane-destroyed", function(pane, _win)
	title_cache[pane:pane_id()] = nil
end)

-- タブのタイトルを設定
wezterm.on("format-tab-title", function(tab, _tabs, _panes, _config, _hover, _max_width)
	local pane = tab.active_pane
	local pane_id = pane.pane_id
	local tab_number = tab.tab_index + 1

	local base_title
	if title_cache[pane_id] then
		base_title = title_cache[pane_id]
	else
		base_title = tab.active_pane.title
	end

	return string.format(" %d:%s ", tab_number, base_title)
end)

-- tab bar右のstatus lineを設定
wezterm.on("update-right-status", function(win, _pane)
	local date = wezterm.strftime(" %H:%M  %A  %B %-d ")
	local workspace = win:active_workspace()

	win:set_right_status(wezterm.format({
		{ Foreground = { Color = "#123A8A" } },
		{ Background = { Color = "#212332" } },
		{ Text = "" },
		{ Foreground = { Color = "#ffffff" } },
		{ Background = { Color = "#123A8A" } },
		{ Text = date },
		{ Foreground = { Color = "#1F4CB8" } },
		{ Background = { Color = "#123A8A" } },
		{ Text = "" },
		{ Foreground = { Color = "#ffffff" } },
		{ Background = { Color = "#1F4CB8" } },
		{ Text = " " .. workspace .. " " },
	}))
end)

---@type Config
return {
	use_fancy_tab_bar = false,

	tab_max_width = 40,
	tab_bar_at_bottom = false,
	hide_tab_bar_if_only_one_tab = true,
	show_new_tab_button_in_tab_bar = false,

	colors = {
		tab_bar = {
			background = "none",
			inactive_tab_edge = "none",

			active_tab = {
				bg_color = "#444b71",
				fg_color = "#c6c8d1",
				intensity = "Normal",
				underline = "None",
				italic = false,
				strikethrough = false,
			},

			inactive_tab = {
				bg_color = "#282d3e",
				fg_color = "#c6c8d1",
				intensity = "Normal",
				underline = "None",
				italic = false,
				strikethrough = false,
			},

			inactive_tab_hover = {
				bg_color = "#1b1f2f",
				fg_color = "#c6c8d1",
				intensity = "Normal",
				underline = "None",
				italic = true,
				strikethrough = false,
			},
		},
	},
	window_background_gradient = {
		colors = { "#212332" },
	},
}
