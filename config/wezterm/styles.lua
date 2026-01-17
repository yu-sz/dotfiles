local wezterm = require("wezterm")

--- @type Config
return {
	color_scheme = "tokyonight_night",
	font = wezterm.font_with_fallback({
		{ family = "PlemolJP Console NF", assume_emoji_presentation = false },
		{ family = "Cica", assume_emoji_presentation = true },
	}),

	-- window styles
	window_background_opacity = 1.0,
	macos_window_background_blur = 30,
	inactive_pane_hsb = { hue = 1.0, saturation = 0.90, brightness = 0.50 },
	window_decorations = "RESIZE",
	window_background_gradient = {
		colors = { "#000000" },
	},

	-- font styles
	font_size = 18.0,
	adjust_window_size_when_changing_font_size = false,
	use_ime = true,

	-- notification style
	audible_bell = "SystemBeep",
}
