-- Bảng màu dùng chung cho status bar, tab bar và color_scheme.
-- Tự đổi sáng/tối theo theme của Windows.
local wezterm = require("wezterm")

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

-- wezterm.gui chỉ tồn tại trong tiến trình GUI (không có ở mux server).
function M.appearance()
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
