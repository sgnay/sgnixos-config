local wezterm = require("wezterm")

-- 加载外部 TOML 主题
local function load_toml_theme(name)
	local path = wezterm.config_dir .. "/colors/" .. name .. ".toml"
	local success, colors = pcall(wezterm.parse_config, path)
	if success then
		return colors.colors
	end
	return nil
end

-- 主要配色方案定义
return {
	-- 在这里定义 color_schemes
	color_schemes = {
		-- 经典护眼深色
		["GruvboxDarkMedium"] = {
			foreground = "#ebdbb2",
			background = "#282828",
			cursor_bg = "#ebdbb2",
			cursor_border = "#ebdbb2",
			cursor_fg = "#282828",
			selection_bg = "#665c54",
			selection_fg = "#ebdbb2",

			ansi = {
				"#282828",
				"#cc241d",
				"#98971a",
				"#d79921",
				"#458588",
				"#b16286",
				"#689d6a",
				"#a89984",
			},
			brights = {
				"#928374",
				"#fb4934",
				"#b8bb26",
				"#fabd2f",
				"#83a598",
				"#d3869b",
				"#8ec07c",
				"#ebdbb2",
			},

			tab_bar = {
				background = "#1d2021",
				active_tab = {
					bg_color = "#282828",
					fg_color = "#ebdbb2",
					intensity = "Bold",
				},
				inactive_tab = {
					bg_color = "#1d2021",
					fg_color = "#a89984",
				},
				inactive_tab_hover = {
					bg_color = "#3c3836",
					fg_color = "#ebdbb2",
				},
				new_tab = {
					bg_color = "#1d2021",
					fg_color = "#a89984",
				},
				new_tab_hover = {
					bg_color = "#282828",
					fg_color = "#ebdbb2",
				},
			},
			compose_cursor = "#d3869b",
			split = "#504945",
			visual_bell = "#d65d0e",
			scrollbar_thumb = "#8ec07c",
		},
		-- 专业科学配色
		["SolarizedDark"] = {
			foreground = "#839496",
			background = "#002b36",
			cursor_bg = "#839496",
			cursor_border = "#839496",
			cursor_fg = "#002b36",
			selection_bg = "#073642",
			selection_fg = "#93a1a1",

			ansi = {
				"#073642",
				"#dc322f",
				"#859900",
				"#b58900",
				"#268bd2",
				"#d33682",
				"#2aa198",
				"#eee8d5",
			},
			brights = {
				"#586e75",
				"#cb4b16",
				"#859900",
				"#b58900",
				"#268bd2",
				"#6c71c4",
				"#2aa198",
				"#fdf6e3",
			},

			tab_bar = {
				background = "#073642",
				active_tab = {
					bg_color = "#002b36",
					fg_color = "#839496",
					intensity = "Bold",
				},
				inactive_tab = {
					bg_color = "#073642",
					fg_color = "#586e75",
				},
				inactive_tab_hover = {
					bg_color = "#586e75",
					fg_color = "#fdf6e3",
				},
				new_tab = {
					bg_color = "#073642",
					fg_color = "#586e75",
				},
				new_tab_hover = {
					bg_color = "#002b36",
					fg_color = "#839496",
				},
			},
			compose_cursor = "#d33682",
			split = "#586e75",
			visual_bell = "#cb4b16",
			scrollbar_thumb = "#8ec07c",
		},
		-- 护眼浅色
		["QuietLight"] = {
			foreground = "#4a4a48",
			background = "#f5f5f0",
			cursor_bg = "#54494b",
			cursor_border = "#54494b",
			cursor_fg = "#ffffff",
			selection_bg = "#c4d9b1",
			selection_fg = "#4a4a48",

			ansi = {
				"#4a4a48",
				"#aa3731",
				"#6a9a5b",
				"#9c5d27",
				"#4b69c6",
				"#7a3e9d",
				"#91b3e0",
				"#7a7a78",
			},
			brights = {
				"#aaaaaa",
				"#cc5555",
				"#88bb77",
				"#cc8833",
				"#6699dd",
				"#9966bb",
				"#aabbcc",
				"#555555",
			},

			tab_bar = {
				background = "#eeeeea",
				active_tab = {
					bg_color = "#f5f5f0",
					fg_color = "#4a4a48",
					intensity = "Bold",
				},
				inactive_tab = {
					bg_color = "#eeeeea",
					fg_color = "#8a8a88",
				},
				inactive_tab_hover = {
					bg_color = "#e5e5e0",
					fg_color = "#4a4a48",
				},
				new_tab = {
					bg_color = "#eeeeea",
					fg_color = "#8a8a88",
				},
				new_tab_hover = {
					bg_color = "#f5f5f0",
					fg_color = "#4a4a48",
				},
			},
			compose_cursor = "#7a3e9d",
			split = "#d8d8d5",
			visual_bell = "#9c5d27",
			scrollbar_thumb = "#a8c4a0",
		},
		-- 外部 TOML 主题
		["DankTheme"] = load_toml_theme("dank-theme") or {},
	},

	-- 激活配色方案
	-- 亮色护眼配色 QuietLight
	-- color_scheme = "QuietLight",
	-- 暗色护眼配色 GruvboxDarkMedium
	color_scheme = "GruvboxDarkMedium",
	-- 专业科学配色 SolarizedDark
	-- color_scheme = "SolarizedDark",
	-- 外部主题 DankTheme
	-- color_scheme = "DankTheme",
	-- 透明度
	window_background_opacity = 0.85,
	-- 字体
	font = wezterm.font("JetBrains Mono", { weight = "Regular" }),
	-- 字体大小设为 16
	font_size = 16,
	font = wezterm.font_with_fallback({
		"Fira Code",
		"WenQuanYi Zen Hei",
	}),
	-- 如果后续需要更多字体配置
	-- font_rules = {...},
}
