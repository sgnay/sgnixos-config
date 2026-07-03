local wezterm = require("wezterm")

-- 返回窗口的其他配置（你原有的配置可以放在这里）
return {
	-- 启用滚动条
	enable_scroll_bar = true,
	-- 滚动条尺寸为 25 ，其他方向不需要 pad
	window_padding = { left = 0, right = 15, top = 0, bottom = 0 },
	-- 窗口居中
	-- window_decorations = "RESIZE",
	-- initial_cols = 120,
	-- initial_rows = 35,
	-- window_frame = {...},
	-- 背景图
	-- window_background_image = "/home/sgnay/Pictures/Wallpapers/Daily-Lives.jpg",
	-- window_background_image_hsb = { -- 调整图片灰度等
	-- 	brightness = 0.1,
	-- 	hue = 1.0,
	-- 	saturation = 1.0,
	-- },
	-- window_background_gradient = { -- 背景渐变色，纯色
	-- },
	-- 右上角提示内容
	wezterm.on("update-right-status", function(window, pane)
		local date = wezterm.strftime("%Y-%m-%d %H:%M:%S")

		-- Make it italic and underlined
		window:set_right_status(wezterm.format({
			{ Attribute = { Underline = "Single" } },
			{ Attribute = { Italic = true } },
			{ Text = "现在时间 " .. date },
		}))
	end),
}
