local wezterm = require 'wezterm'


local config = wezterm.config_builder()

local light_theme = 'Gruvbox Light'

config.font = wezterm.font_with_fallback { 'DejaVuSansM Nerd Font', 'DejaVuSansM Nerd Font Mono' }
config.font_size = 9.0
config.color_scheme = light_theme;
config.default_prog = { '/usr/bin/tmux', '-l' }

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

config.window_frame = {
    font = config.font,
    font_size = config.font_size,
}

return config
