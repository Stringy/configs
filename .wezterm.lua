local wezterm = require 'wezterm'

local config = wezterm.config_builder()

config.font = wezterm.font 'DejaVuSansMono Nerd Font'

config.keys = {
    {
        key = 'r',
        mods = 'CMD|SHIFT',
        action = wezterm.action.ReloadConfiguration,
    },
}

return config
