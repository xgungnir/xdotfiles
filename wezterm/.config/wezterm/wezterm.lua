-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
-- config.color_scheme = 'AdventureTime'

-- Font
-- config.font = wezterm.font("Sarasa Mono SC Nerd Font", { weight = "Medium" })
config.font = wezterm.font("Sarasa Mono SC Nerd Font", { weight = "DemiBold" })
config.freetype_load_flags = 'NO_HINTING'
config.font_size = 16

-- and finally, return the configuration to wezterm
return config
