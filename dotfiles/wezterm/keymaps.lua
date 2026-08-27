local wezterm = require("wezterm")
local act = wezterm.action

return {
	keys = {
		-- 禁用 Alt+Enter（默认全屏），全屏已在 niri 中管理
		{ key = "Enter", mods = "ALT", action = wezterm.action.DisableDefaultAssignment },
		-- 全屏快捷键
		{ key = "F11", mods = "SUPER", action = wezterm.action.ToggleFullScreen },
		-- 打开启动菜单
		{ key = "z", mods = "SUPER|ALT", action = wezterm.action.ShowLauncher },
		-- 垂直分屏快捷键（分为上下）
		{ key = "v", mods = "SUPER|ALT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
		-- 水平分屏快捷键（分为左右）
		{ key = "h", mods = "SUPER|ALT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		-- 最大化/还原切换快捷键
		{
			key = "F11",
			mods = "",
			action = wezterm.action_callback(function(window, pane)
				-- 获取窗口当前状态和原始配置
				local overrides = window:get_config_overrides() or {}

				-- 判断当前是否已最大化
				if overrides.is_maximized then
					-- 还原：清除最大化标记，恢复初始尺寸
					overrides.is_maximized = nil
					window:restore()
				else
					-- 最大化：保存当前尺寸作为原始尺寸，然后最大化
					overrides.is_maximized = true
					window:maximize()
				end

				window:set_config_overrides(overrides)
			end),
		},
		-- 切换 tab，默认 CTRL + Tab 也可使用
		-- { key = 'LeftArrow', mods = 'CTRL', action = act.ActivateTabRelative(-1) },
		-- { key = 'RightArrow', mods = 'CTRL', action = act.ActivateTabRelative(1) },
		-- 移动 tab 顺序
		{ key = "UpArrow", mods = "CTRL", action = act.MoveTabRelative(-1) },
		{ key = "DownArrow", mods = "CTRL", action = act.MoveTabRelative(1) },
		-- 向左移动标签页（例如 Ctrl+Shift+Left）
		{ key = "LeftArrow", mods = "CTRL|SHIFT", action = act.MoveTabRelative(-1) },
		-- 向右移动标签页（例如 Ctrl+Shift+Right）
		{ key = "RightArrow", mods = "CTRL|SHIFT", action = act.MoveTabRelative(1) },
	},
	mouse_bindings = {
		-- 鼠标选择复制到 Clipboard（剪切板）和 Primary Selection（主缓冲区/选中即复制）
		{
			event = { Up = { streak = 1, button = "Left" } },
			mods = "NONE",
			action = wezterm.action.CompleteSelection("ClipboardAndPrimarySelection"),
		},
		-- 右键粘贴
		{
			event = { Down = { streak = 1, button = "Right" } },
			mods = "NONE",
			action = wezterm.action({ PasteFrom = "Clipboard" }),
		},
		-- CTRL 鼠标点击打开超链接 http://127.0.0.1:631
		{ event = { Up = { streak = 1, button = "Left" } }, mods = "CTRL", action = "OpenLinkAtMouseCursor" },
	},
}
