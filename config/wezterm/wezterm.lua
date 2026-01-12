local wezterm = require("wezterm")

---@type WeztermMyUtils
local utils = require("my_utils")

local config = wezterm.config_builder()
config = utils.merge_tables(config, require("styles"))
config = utils.merge_tables(config, require("tab_bar"))
config = utils.merge_tables(config, require("keymaps"))

return config
