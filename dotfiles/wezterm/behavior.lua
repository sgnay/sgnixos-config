local wezterm = require("wezterm")

return {
	-- 默认 shell
	default_prog = { "fish" },
	-- 保留历史行
	scrollback_lines = 5000,
	alternate_buffer_wheel_scroll_speed = 3,
	-- 其他行为配置可以放在这里
	-- check_for_updates = false,
	-- exit_behavior = "Close",
	-- GPU 加速
	front_end = "OpenGL",
}
