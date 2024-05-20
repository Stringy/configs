local wezterm = require 'wezterm'

local config = wezterm.config_builder()

local dark_theme = 'Gruvbox Dark'
local light_theme = 'Gruvbox Light'

config.font = wezterm.font_with_fallback { 'DejaVuSansMono Nerd Font', 'DejaVuSansM Nerd Font Mono' }
config.font_size = 11.0
config.color_scheme = light_theme

wezterm.on('toggle-colorscheme', function(window, pane)
    local overrides = window:get_config_overrides() or {}
    if (not overrides.color_scheme) then
        overrides.color_scheme = dark_theme
    elseif (overrides.color_scheme == dark_theme) then
        overrides.color_scheme = light_theme
    else
        overrides.color_scheme = dark_theme
    end
    window:set_config_overrides(overrides)
end)

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
    {
        key = 'd',
        mods = 'CMD|SHIFT',
        action = wezterm.action.EmitEvent 'toggle-colorscheme',
    }
}

return config
