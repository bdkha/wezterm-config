-- Bảng màu dùng chung cho status bar, tab bar và color_scheme.
-- Tự đổi sáng/tối theo theme của Windows.
local wezterm = require("wezterm")
local platform = require("config.platform")

local M = {}

M.dark = {
	scheme = "Catppuccin Mocha",
	crust = "#11111b",
	mantle = "#181825",
	base = "#1e1e2e",
	surface = "#313244",
	overlay = "#6c7086",
	subtext = "#a6adc8",
	text = "#cdd6f4",
	accent = "#89b4fa", -- blue
	green = "#a6e3a1",
	peach = "#fab387",
	mauve = "#cba6f7",
	red = "#f38ba8",
	yellow = "#f9e2af",
	teal = "#94e2d5",
}

M.light = {
	scheme = "Catppuccin Latte",
	crust = "#dce0e8",
	mantle = "#e6e9ef",
	base = "#eff1f5",
	surface = "#ccd0da",
	overlay = "#7c7f93",
	subtext = "#5c5f77",
	text = "#4c4f69",
	accent = "#1e66f5",
	green = "#40a02b",
	peach = "#fe640b",
	mauve = "#8839ef",
	red = "#d20f39",
	yellow = "#df8e1d",
	teal = "#179299",
}

-- "auto" | "dark" | "light". Đặt qua opts.theme trong wezterm.lua / local.lua.
local mode = "auto"

function M.set_mode(value)
	if value == "dark" or value == "light" then
		mode = value
	else
		mode = "auto"
	end
end

--- Đọc thẳng thiết lập của Windows.
---
--- wezterm.gui.get_appearance() trên Windows trả về "Light" khi chưa có cửa sổ
--- nào tồn tại, kể cả lúc hệ thống đang ở chế độ tối. Điều đó xảy ra đúng lúc
--- mux.spawn_window tạo cửa sổ mới — ví dụ khi khôi phục session — nên cả cửa
--- sổ loé lên nền sáng. Hỏi registry thì luôn đúng.
local function windows_appearance()
	local ok, success, stdout = pcall(wezterm.run_child_process, {
		"reg",
		"query",
		[[HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize]],
		"/v",
		"AppsUseLightTheme",
	})
	if ok and success and stdout then
		local hex = stdout:match("AppsUseLightTheme%s+REG_DWORD%s+0x(%x+)")
		if hex then
			return tonumber(hex, 16) == 0 and "Dark" or "Light"
		end
	end
	return nil
end

function M.appearance()
	if mode == "dark" then
		return "Dark"
	elseif mode == "light" then
		return "Light"
	end

	if platform.is_windows then
		local detected = windows_appearance()
		if detected then
			return detected
		end
	end

	-- macOS và Linux: get_appearance() đáng tin.
	-- wezterm.gui chỉ tồn tại trong tiến trình GUI (không có ở mux server).
	if wezterm.gui then
		return wezterm.gui.get_appearance()
	end
	return "Dark"
end

function M.current()
	if M.appearance():find("Dark") then
		return M.dark
	end
	return M.light
end

return M
