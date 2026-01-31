local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- wezterm.on("gui-startup", function()
--     local schemes = wezterm.color.get_builtin_schemes()
--     print("Available color schemes:")
--     for name, _ in pairs(schemes) do
--         print("- " .. name)
--     end
-- end)

local scheme = wezterm.get_builtin_color_schemes()["Material"]
local gpus = wezterm.gui.enumerate_gpus()
local utils = require("utils")

---------------------------------------------------------------
--- Merge the Config
---------------------------------------------------------------
local function create_ssh_domain_from_ssh_config(ssh_domains)
	if ssh_domains == nil then
		ssh_domains = {}
	end
	for host, config in pairs(wezterm.enumerate_ssh_hosts()) do
		table.insert(ssh_domains, {
			name = host,
			remote_address = config.hostname .. ":" .. config.port,
			username = config.user,
			multiplexing = "None",
			assume_shell = "Posix",
		})
	end
	return { ssh_domains = ssh_domains }
end



-- 1. Linux Performance & Integration
config.front_end = "WebGpu" -- Faster rendering on modern Linux drivers
config.enable_wayland = true
config.warn_about_missing_glyphs = false
config.webgpu_preferred_adapter = gpus[1]
config.prefer_egl = true
config.check_for_updates = false
config.use_ime = true

-- 2. Visuals: The "Translucent Pro" Look
config.color_scheme = 'Catppuccin Mocha'
config.font = wezterm.font('Monospace', { weight = 'Medium' })
config.font_size = 11.0
config.animation_fps = 1
cursor_blink_ease_in = "Constant"
cursor_blink_ease_out = "Constant"
use_fancy_tab_bar = false
notification_handling = "SuppressFromFocusedTab"

-- Background blurring (requires a compositor like Sway, Hyprland, or GNOME with Blur-my-Shell)
config.window_background_opacity = 0.9
config.window_decorations = "TITLE | RESIZE"

-- Window positioning and size
config.initial_cols = 140  -- Width in columns (characters)
config.initial_rows = 60   -- Height in rows (lines)
config.window_padding = {
  left = 2,
  right = 2,
  top = 0,
  bottom = 0,
}

-- Centered Window on Startup
wezterm.on("gui-startup", function(cmd)
  local screen            = wezterm.gui.screens().active
  local ratio             = 0.7
  local width, height     = screen.width * ratio, screen.height * ratio
  local tab, pane, window = wezterm.mux.spawn_window {
    position = {
      x = (screen.width - width) / 2,
      y = (screen.height - height) / 2,
      origin = 'ActiveScreen' }
  }
  -- window:gui_window():maximize()
  window:gui_window():set_inner_size(width, height)
end)


-- 4. Keybindings for Linux Power Users
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }
config.keys = {
  -- Quick split: CTRL+A then | or -
  { key = '|', mods = 'LEADER|SHIFT', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-', mods = 'LEADER', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } },
  
  -- The Fix: Send "CTRL-A" to the terminal when pressing CTRL-A, CTRL-A
  {
    key = 'a',
    mods = 'LEADER|CTRL',
    action = wezterm.action.SendKey { key = 'a', mods = 'CTRL' },
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

config.hyperlink_rules = {
	-- Matches: a URL in parens: (URL)
	{
		regex = "\\((\\w+://\\S+)\\)",
		format = "$1",
		highlight = 1,
	},
	-- Matches: a URL in brackets: [URL]
	{
		regex = "\\[(\\w+://\\S+)\\]",
		format = "$1",
		highlight = 1,
	},
	-- Matches: a URL in curly braces: {URL}
	{
		regex = "\\{(\\w+://\\S+)\\}",
		format = "$1",
		highlight = 1,
	},
	-- Matches: a URL in angle brackets: <URL>
	{
		regex = "<(\\w+://\\S+)>",
		format = "$1",
		highlight = 1,
	},
	-- Then handle URLs not wrapped in brackets
	{
		-- Before
		--regex = '\\b\\w+://\\S+[)/a-zA-Z0-9-]+',
		--format = '$0',
		-- After
		regex = "[^(]\\b(\\w+://\\S+[)/a-zA-Z0-9-]+)",
		format = "$1",
		highlight = 1,
	},
	-- implicit mailto link
	{
		regex = "\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b",
		format = "mailto:$0",
	},
}

table.insert(config.hyperlink_rules, {
	regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
	format = "https://github.com/$1/$3",
})

---@diagnostic disable-next-line: unused-local
local function create_tab_title(tab, tabs, panes, config, hover, max_width)
	local user_title = tab.active_pane.user_vars.panetitle
	if user_title ~= nil and #user_title > 0 then
		return tab.tab_index + 1 .. ":" .. user_title
	end
	-- pane:get_foreground_process_info().status

	local title = wezterm.truncate_right(utils.basename(tab.active_pane.foreground_process_name), max_width)
	if title == "" then
		local dir = string.gsub(tab.active_pane.title, "(.*[: ])(.*)]", "%2")
		dir = utils.convert_useful_path(dir)
		title = wezterm.truncate_right(dir, max_width)
	end

	local copy_mode, n = string.gsub(tab.active_pane.title, "(.+) mode: .*", "%1", 1)
	if copy_mode == nil or n == 0 then
		copy_mode = ""
	else
		copy_mode = copy_mode .. ": "
	end
	return copy_mode .. tab.tab_index + 1 .. ":" .. title
end




---------------------------------------------------------------
--- wezterm on
---------------------------------------------------------------
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local title = create_tab_title(tab, tabs, panes, config, hover, max_width)

	-- selene: allow(undefined_variable)
	local solid_left_arrow = utf8.char(0x2590)
	-- selene: allow(undefined_variable)
	local solid_right_arrow = utf8.char(0x258c)
	-- https://github.com/wez/wezterm/issues/807
	-- local edge_background = scheme.background
	-- https://github.com/wez/wezterm/blob/61f01f6ed75a04d40af9ea49aa0afe91f08cb6bd/config/src/color.rs#L245
	local edge_background = "#2e3440"
	local background = scheme.ansi[1]
	local foreground = scheme.ansi[5]

	if tab.is_active then
		background = scheme.brights[1]
		foreground = scheme.brights[8]
	elseif hover then
		background = scheme.cursor_bg
		foreground = scheme.cursor_fg
	end
	local edge_foreground = background

	return {
		{ Attribute = { Intensity = "Bold" } },
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = solid_left_arrow },
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Text = title },
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = solid_right_arrow },
		{ Attribute = { Intensity = "Normal" } },
	}
end)

return config