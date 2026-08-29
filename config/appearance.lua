-- Font, màu, cửa sổ, hiệu năng render.
local wezterm = require("wezterm")
local theme = require("config.theme")
local platform = require("config.platform")

local M = {}

function M.apply(config, opts)
	local p = theme.current()

	----------------------------------------------------------------------
	-- FONT
	-- Cài JetBrainsMono Nerd Font bằng install.sh --font / install.ps1 -Font.
	-- Các font dự phòng bên dưới có sẵn theo từng hệ điều hành.
	----------------------------------------------------------------------
	config.font = wezterm.font_with_fallback({
		{ family = "JetBrainsMono Nerd Font", weight = "Regular" },
		{ family = "JetBrains Mono" },
		{ family = "Consolas" }, -- Windows
		{ family = "Menlo" }, -- macOS
		{ family = "DejaVu Sans Mono" }, -- Linux
		{ family = "Segoe UI Emoji" },
		{ family = "Apple Color Emoji" },
		{ family = "Noto Color Emoji" },
	})
	config.font_size = opts.font_size
	config.line_height = 1.05
	config.cell_width = 1.0

	-- In đậm/nghiêng dùng đúng weight của JetBrains Mono
	config.font_rules = {
		{
			intensity = "Bold",
			font = wezterm.font({ family = "JetBrainsMono Nerd Font", weight = "Bold" }),
		},
		{
			italic = true,
			font = wezterm.font({ family = "JetBrainsMono Nerd Font", style = "Italic" }),
		},
		{
			intensity = "Bold",
			italic = true,
			font = wezterm.font({ family = "JetBrainsMono Nerd Font", weight = "Bold", style = "Italic" }),
		},
	}

	-- Ligature (=> != >=). Bỏ comment dòng dưới nếu bạn KHÔNG thích ligature.
	-- config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

	-- Chữ sắc nét trên màn hình subpixel. macOS tự lo phần này nên bỏ qua.
	if not platform.is_mac then
		config.freetype_load_target = "Light"
		config.freetype_render_target = "HorizontalLcd"
	end

	----------------------------------------------------------------------
	-- MÀU
	----------------------------------------------------------------------
	config.color_scheme = p.scheme
	config.colors = theme.colors_for(p)
	config.inactive_pane_hsb = { saturation = 0.9, brightness = 0.75 }

	----------------------------------------------------------------------
	-- CỬA SỔ
	----------------------------------------------------------------------
	if platform.is_mac then
		-- Giữ nút đèn giao thông của macOS.
		config.window_decorations = "TITLE|RESIZE"
	else
		config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
	end
	config.window_padding = { left = 10, right = 10, top = 6, bottom = 4 }
	config.initial_cols = 130
	config.initial_rows = 34
	config.adjust_window_size_when_changing_font_size = false
	config.window_close_confirmation = "AlwaysPrompt"
	config.skip_close_confirmation_for_processes_named = {
		"bash", "sh", "zsh", "fish", "nu", "cmd.exe", "pwsh.exe", "powershell.exe",
	}

	-- Nền đục mặc định. Muốn trong suốt: đặt opacity < 1.0 trong wezterm.lua
	-- (hoặc local.lua), hiệu ứng nền sẽ tự bật theo hệ điều hành.
	config.window_background_opacity = opts.opacity
	if opts.opacity < 1.0 then
		if platform.is_windows then
			-- "Acrylic" mờ mạnh, "Mica" nhẹ hơn, "Tabbed" gần như phẳng.
			pcall(function()
				config.win32_system_backdrop = opts.backdrop
			end)
		elseif platform.is_mac then
			pcall(function()
				config.macos_window_background_blur = opts.blur
			end)
		end
	end

	----------------------------------------------------------------------
	-- TAB BAR (retro + powerline tự vẽ trong config/status.lua)
	----------------------------------------------------------------------
	config.use_fancy_tab_bar = false
	config.tab_bar_at_bottom = false
	config.hide_tab_bar_if_only_one_tab = false
	config.show_new_tab_button_in_tab_bar = false
	config.tab_max_width = 32
	config.status_update_interval = 1000

	----------------------------------------------------------------------
	-- CON TRỎ & CUỘN
	----------------------------------------------------------------------
	config.default_cursor_style = "BlinkingBar"
	config.cursor_blink_rate = 550
	config.cursor_blink_ease_in = "Constant"
	config.cursor_blink_ease_out = "Constant"
	config.scrollback_lines = 25000
	config.enable_scroll_bar = true
	config.min_scroll_bar_height = "2cell"

	----------------------------------------------------------------------
	-- HIỆU NĂNG
	-- Máy nào WebGpu dựng hình lỗi thì đổi front_end thành "OpenGL".
	----------------------------------------------------------------------
	config.front_end = opts.front_end
	config.webgpu_power_preference = "HighPerformance"
	config.max_fps = opts.max_fps
	config.animation_fps = 60

	----------------------------------------------------------------------
	-- LINH TINH
	----------------------------------------------------------------------
	config.audible_bell = "Disabled"
	config.visual_bell = {
		fade_in_duration_ms = 60,
		fade_out_duration_ms = 60,
		target = "CursorColor",
	}
	config.check_for_updates = false
	config.term = "xterm-256color"
	config.hyperlink_rules = wezterm.default_hyperlink_rules()
	if platform.is_windows then
		config.quote_dropped_files = "WindowsAlwaysQuoted"
	else
		config.quote_dropped_files = "Posix"
	end
end

return M
