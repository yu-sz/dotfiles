-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

config.color_scheme = "tokyonight_moon"

------------------------------------------------
-- font settings
------------------------------------------------
config.font = wezterm.font_with_fallback({
	{ family = "PlemolJP Console NF", assume_emoji_presentation = false },
	{ family = "Cica", assume_emoji_presentation = true },
})

config.font_size = 18.0
config.adjust_window_size_when_changing_font_size = false
config.use_ime = true

------------------------------------------------
-- window settings
------------------------------------------------
-- 透明度
config.window_background_opacity = 0.90
-- ぼかし
config.macos_window_background_blur = 20
-- inactiveなpaneは暗めの色味にする
config.inactive_pane_hsb = { hue = 1.0, saturation = 0.90, brightness = 0.50 }
-- タイトルバーを非表示
config.window_decorations = "RESIZE"

------------------------------------------------
-- tab setting
------------------------------------------------
-- タブバーの表示
config.show_tabs_in_tab_bar = true
-- タブが1つだけの場合は非表示
config.hide_tab_bar_if_only_one_tab = true
-- インデックスを表示しない
config.show_tab_index_in_tab_bar = false
-- タブの追加ボタンを非表示
config.show_new_tab_button_in_tab_bar = false

-- タブバーの基本設定
config.window_frame = {
	-- The font used in the tab bar.
	-- Roboto Bold is the default; this font is bundled
	-- with wezterm.
	-- Whatever font is selected here, it will have the
	-- main font setting appended to it to pick up any
	-- fallback fonts you may have used there.
	font = wezterm.font({ family = "Roboto", weight = "Bold" }),

	-- The size of the font in the tab bar.
	-- Default to 10.0 on Windows but 12.0 on other systems
	font_size = 12.0,

	-- The overall background color of the tab bar when
	-- the window is focused
	active_titlebar_bg = "#222436",

	-- The overall background color of the tab bar when
	-- the window is not focused
	inactive_titlebar_bg = "#222436",
}
config.colors = {
	tab_bar = {
		-- The color of the strip that goes along the top of the window
		-- (does not apply when fancy tab bar is in use)
		background = "#222436",

		-- The active tab is the one that has focus in the window
		active_tab = {
			-- The color of the background area for the tab
			bg_color = "#3B6ADB",
			-- The color of the text for the tab
			fg_color = "#ffffff",

			-- Specify whether you want "Half", "Normal" or "Bold" intensity for the
			-- label shown for this tab.
			-- The default is "Normal"
			intensity = "Normal",

			-- Specify whether you want "None", "Single" or "Double" underline for
			-- label shown for this tab.
			-- The default is "None"
			underline = "None",

			-- Specify whether you want the text to be italic (true) or not (false)
			-- for this tab.  The default is false.
			italic = false,

			-- Specify whether you want the text to be rendered with strikethrough (true)
			-- or not for this tab.  The default is false.
			strikethrough = false,
		},

		-- Inactive tabs are the tabs that do not have focus
		inactive_tab = {
			bg_color = "#222436",
			fg_color = "#ffffff",

			-- The same options that were listed under the `active_tab` section above
			-- can also be used for `inactive_tab`.
		},

		-- You can configure some alternate styling when the mouse pointer
		-- moves over inactive tabs
		inactive_tab_hover = {
			bg_color = "#3b3052",
			fg_color = "#909090",
			italic = true,

			-- The same options that were listed under the `active_tab` section above
			-- can also be used for `inactive_tab_hover`.
		},

		inactive_tab_edge = "none",

		-- The new tab button that let you create new tabs
		new_tab = {
			bg_color = "#1b1032",
			fg_color = "#808080",

			-- The same options that were listed under the `active_tab` section above
			-- can also be used for `new_tab`.
		},

		-- You can configure some alternate styling when the mouse pointer
		-- moves over the new tab button
		new_tab_hover = {
			bg_color = "#3b3052",
			fg_color = "#909090",
			italic = true,

			-- The same options that were listed under the `active_tab` section above
			-- can also be used for `new_tab_hover`.
		},
	},
}

wezterm.on("update-right-status", function(window, pane)
	-- demonstrates shelling out to get some external status.
	-- wezterm will parse escape sequences output by the
	-- child process and include them in the status area, too.
	local hostname = " " .. wezterm.hostname() .. " "

	-- However, if all you need is to format the date/time, then:
	local date = wezterm.strftime(" %H:%M  %A  %B %-d ")
	-- Make it italic and underlined
	window:set_right_status(wezterm.format({
		{ Foreground = { Color = "#123A8A" } },
		{ Background = { Color = "#0A204F" } },
		{ Text = "" },
		{ Foreground = { Color = "#ffffff" } },
		{ Background = { Color = "#123A8A" } },
		{ Text = date },
		{ Foreground = { Color = "#1F4CB8" } },
		{ Background = { Color = "#123A8A" } },
		{ Text = "" },
		{ Foreground = { Color = "#ffffff" } },
		{ Background = { Color = "#1F4CB8" } },
		{ Text = hostname },
	}))
end)

local act = wezterm.action
config.keys = {
	-- full screen
	{
		key = "f",
		mods = "SHIFT|META",
		action = act.ToggleFullScreen,
	},
	-- font_size
	{
		key = "+",
		mods = "CMD|SHIFT",
		action = act.IncreaseFontSize,
	},
	-- Tab新規作成
	{
		key = "t",
		mods = "CMD",
		action = act({ SpawnTab = "CurrentPaneDomain" }),
	},
	-- ⌘ w でペインを閉じる（デフォルトではタブが閉じる）
	{
		key = "w",
		mods = "CMD",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},
	-- ⌘ Ctrl ,で下方向にペイン分割
	{
		key = ",",
		mods = "CMD|CTRL",
		action = act({ SplitVertical = { domain = "CurrentPaneDomain" } }),
	},
	-- ⌘ Ctrl .で右方向にペイン分割
	{
		key = ".",
		mods = "CMD|CTRL",
		action = wezterm.action({ SplitHorizontal = { domain = "CurrentPaneDomain" } }),
	},
	-- ⌘ Ctrl oでペインの中身を入れ替える
	{
		key = "o",
		mods = "CMD|CTRL",
		action = wezterm.action.RotatePanes("Clockwise"),
	},
	-- ⌘ Ctrl hjklでペインの移動
	{
		key = "h",
		mods = "CMD",
		action = wezterm.action.ActivatePaneDirection("Left"),
	},
	{
		key = "j",
		mods = "CMD",
		action = wezterm.action.ActivatePaneDirection("Down"),
	},
	{
		key = "k",
		mods = "CMD",
		action = wezterm.action.ActivatePaneDirection("Up"),
	},
	{
		key = "l",
		mods = "CMD",
		action = wezterm.action.ActivatePaneDirection("Right"),
	},
}

-- and finally, return the configuration to wezterm
return config
