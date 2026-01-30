local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- 1. Linux Performance & Integration
config.front_end = "WebGpu" -- Faster rendering on modern Linux drivers
config.enable_wayland = true
config.warn_about_missing_glyphs = false

-- 2. Visuals: The "Translucent Pro" Look
config.color_scheme = 'Catppuccin Mocha'
config.font = wezterm.font('Monospace', { weight = 'Medium' })
config.font_size = 11.0

-- Background blurring (requires a compositor like Sway, Hyprland, or GNOME with Blur-my-Shell)
config.window_background_opacity = 0.9
config.window_decorations = "TITLE | RESIZE"


-- 4. Keybindings for Linux Power Users
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }
config.keys = {
  -- Quick split: CTRL+A then | or -
  { key = '|', mods = 'LEADER|SHIFT', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-', mods = 'LEADER', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } },
  
  {
    key = 'a', mods = 'LEADER', action = wezterm.action.SendKey { key = 'a', mods = 'CTRL' },
  },

  -- The "Magic" Workspace Switcher (Quickly jump between Local and Cloud)
  { key = 'w', mods = 'LEADER', action = wezterm.action.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },

  -- Copy to system clipboard (Linux specific shortcut)
  { key = 'c', mods = 'CTRL|SHIFT', action = wezterm.action.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CTRL|SHIFT', action = wezterm.action.PasteFrom 'Clipboard' },
}

-- 5. Dynamic Tab Bar (Shows if you're on your Laptop or the Cloud)
config.use_fancy_tab_bar = false
config.status_update_interval = 1000
wezterm.on('update-status', function(window, pane)
  local domain = pane:get_domain_name()
  local color = domain == 'local' and '#fab387' or '#a6e3a1'
  
  window:set_right_status(wezterm.format {
    { Foreground = { Color = color } },
    { Text = ' 🌐 Domain: ' .. domain .. '  ' },
    { Foreground = { Color = '#94e2d5' } },
    { Text = wezterm.strftime('%H:%M ') },
  })
end)

return config