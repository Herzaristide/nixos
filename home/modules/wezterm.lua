local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()
-- default_domain 'WSL:NixOS' only exists on Windows; on Linux use local (default)
-- config.default_domain = 'WSL:NixOS'

-- Appearance
config.color_scheme = 'Gruvbox Dark (Gogh)'
config.font = wezterm.font('JetBrains Mono', { weight = 'Regular' })
config.font_size = 10.0

-- Transparent background
config.window_background_opacity = 0.90
config.win32_system_backdrop = 'Acrylic'

-- Remove title bar for a cleaner look (optional)
config.window_decorations = 'NONE'

-- Padding
config.window_padding = {
  left = 16,
  right = 16,
  top = 16,
  bottom = 16,
}

-- Tab bar
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = true
config.tab_max_width = 25

-- Tab bar frame: drives bar height and font weight
config.window_frame = {
  font                 = wezterm.font('JetBrains Mono', { weight = 'Bold' }),
  font_size            = 10.0,
  active_titlebar_bg   = '#0f0f0f',
  inactive_titlebar_bg = '#0f0f0f',
}

-- Flat, modern Gruvbox palette
config.colors = {
  tab_bar = {
    background = '#0f0f0f',   -- very dark bar strip

    active_tab = {
      bg_color  = '#1d2021',  -- slightly lifted surface
      fg_color  = '#d79921',  -- Gruvbox gold accent
      intensity = 'Bold',
    },

    inactive_tab = {
      bg_color = '#0f0f0f',   -- blends into bar
      fg_color = '#504945',   -- very muted
    },

    inactive_tab_hover = {
      bg_color = '#1d2021',
      fg_color = '#a89984',
    },

    new_tab = {
      bg_color = '#0f0f0f',
      fg_color = '#3c3836',
    },

    new_tab_hover = {
      bg_color = '#1d2021',
      fg_color = '#ebdbb2',
    },
  },
}

-- Modern flat tab titles — fixed width
wezterm.on('format-tab-title', function(tab, tabs, panes, cfg, hover, max_width)
  -- Resolve title
  local title = tab.active_pane.title
  if tab.tab_title and #tab.tab_title > 0 then
    title = tab.tab_title
  end
  -- Strip leading path, keep only the process/file name
  title = title:gsub('.*[/\\]', '')

  -- Fixed width: pad or truncate to exactly 20 characters for the title portion
  local fixed_title_width = 20
  local title_width = wezterm.column_width(title)
  if title_width > fixed_title_width then
    title = wezterm.truncate_right(title, fixed_title_width - 1) .. '…'
  else
    -- Pad with spaces to fixed width
    local padding = string.rep(' ', fixed_title_width - title_width)
    title = title .. padding
  end

  -- Fixed tab content: "  ● title(20 chars)  " = 25 chars total
  local tab_content = '  ● ' .. title .. '  '

  if tab.is_active then
    return {
      { Background = { Color = '#1d2021' } },
      { Foreground = { Color = '#d79921' } },
      { Attribute = { Intensity = 'Bold'   } },
      { Text = tab_content },
    }
  elseif hover then
    return {
      { Background = { Color = '#1d2021' } },
      { Foreground = { Color = '#a89984' } },
      { Attribute = { Intensity = 'Normal' } },
      { Text = '  · ' .. title .. '  ' },
    }
  else
    return {
      { Background = { Color = '#0f0f0f' } },
      { Foreground = { Color = '#504945' } },
      { Attribute = { Intensity = 'Normal' } },
      { Text = '  · ' .. title .. '  ' },
    }
  end
end)

-- Cursor
config.cursor_blink_rate = 500
config.default_cursor_style = 'BlinkingBar'

-- Scrollback
config.scrollback_lines = 5000

-- Key bindings to spawn WSL and PowerShell
config.keys = {
  -- Alt+W: Open WSL in a new tab
  {
    key = 'w',
    mods = 'ALT',
    action = wezterm.action.SpawnCommandInNewTab {
      args = { 'wsl.exe' },
    },
  },
  -- Alt+P: Open PowerShell in a new tab
  {
    key = 'p',
    mods = 'ALT',
    action = wezterm.action.SpawnCommandInNewTab {
      args = { 'powershell.exe' },
    },
  },
  { key = 'e', mods = 'ALT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'd', mods = 'ALT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- Navigate between panes
  { key = 'LeftArrow',  mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow',    mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow',  mods = 'ALT', action = act.ActivatePaneDirection 'Down' },

  -- Close current pane
  { key = 'q', mods = 'ALT', action = act.CloseCurrentPane { confirm = false } },
}

return config
