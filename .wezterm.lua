local wezterm = require 'wezterm'

local config = wezterm.config_builder()

config.font = wezterm.font_with_fallback { 'DejaVuSansMono Nerd Font',  'DejaVuSansM Nerd Font Mono' }
config.font_size = 11.0

config.keys = {
    {
        key = 'r',
        mods = 'CMD|SHIFT',
        action = wezterm.action.ReloadConfiguration,
    },
    {
        key = 'l',
        mods = 'CMD|SHIFT',
        action = wezterm.action.ShowLauncher,
    },
}


return config
