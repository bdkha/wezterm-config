-- ============================================================================
--  Bảng màu dùng chung cho status bar, tab bar và color_scheme.
--
--  Mặc định là Catppuccin Mocha (tối). Đổi bằng Ctrl+A T — picker liệt kê
--  toàn bộ color scheme có sẵn của WezTerm; lựa chọn được ghi vào theme.txt
--  nên còn nguyên sau khi khởi động lại.
--
--  Mocha và Latte có bảng màu chỉnh tay. Các scheme còn lại được suy ra từ
--  chính scheme đó (nền, chữ, 8 màu ANSI) nên powerline vẫn hợp tông.
-- ============================================================================
local wezterm = require("wezterm")
local platform = require("config.platform")

local M = {}

M.DEFAULT = "Catppuccin Mocha"

----------------------------------------------------------------------
--  BẢNG MÀU CHỈNH TAY
----------------------------------------------------------------------
local curated = {
	["Catppuccin Mocha"] = {
		scheme = "Catppuccin Mocha",
		is_dark = true,
		crust = "#11111b",
		mantle = "#181825",
		base = "#1e1e2e",
		surface = "#313244",
		overlay = "#6c7086",
		subtext = "#a6adc8",
		text = "#cdd6f4",
		accent = "#89b4fa",
		green = "#a6e3a1",
		peach = "#fab387",
		mauve = "#cba6f7",
		red = "#f38ba8",
		yellow = "#f9e2af",
		teal = "#94e2d5",
	},
	["Catppuccin Latte"] = {
		scheme = "Catppuccin Latte",
		is_dark = false,
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
	},
}

-- Giữ lại hai tên cũ cho tương thích.
M.dark = curated["Catppuccin Mocha"]
M.light = curated["Catppuccin Latte"]

--- Vài scheme được đẩy lên đầu picker cho đỡ phải cuộn.
M.favourites = {
	"Catppuccin Mocha",
	"Catppuccin Macchiato",
	"Catppuccin Frappe",
	"Tokyo Night",
	"Tokyo Night Storm",
	"Kanagawa (Gogh)",
	"rose-pine",
	"rose-pine-moon",
	"Gruvbox Dark (Gogh)",
	"Everforest Dark (Gogh)",
	"nord",
	"Dracula (Official)",
	"OneHalfDark",
	"Catppuccin Latte",
	"rose-pine-dawn",
}

----------------------------------------------------------------------
--  SUY BẢNG MÀU TỪ MỘT SCHEME BẤT KỲ
----------------------------------------------------------------------

--- darken(x) nhân độ sáng với (1-x); lighten(x) kéo độ sáng về phía trắng
--- theo tỉ lệ x. Hai hàm dưới đây gói lại theo ý nghĩa "lùi về nền" và
--- "nổi lên khỏi nền", vì hướng đi khác nhau giữa theme sáng và theme tối.
local function derive(name, scheme)
	local bg = wezterm.color.parse(scheme.background)
	local fg = wezterm.color.parse(scheme.foreground)
	local _, _, lightness = bg:hsla()
	local is_dark = lightness < 0.5

	local ansi = scheme.ansi or {}
	local brights = scheme.brights or {}
	-- Theme tối hợp với brights; theme sáng cần màu đậm nên lấy ansi.
	local pick = is_dark and brights or ansi
	local function color(index)
		return tostring(pick[index] or ansi[index] or brights[index] or scheme.foreground)
	end

	local yellow = color(4)

	return {
		scheme = name,
		is_dark = is_dark,

		-- Nền lùi lại luôn tối đi, kể cả ở theme sáng.
		crust = tostring(is_dark and bg:darken(0.45) or bg:darken(0.09)),
		mantle = tostring(is_dark and bg:darken(0.22) or bg:darken(0.04)),
		base = tostring(bg),
		-- Mặt nổi thì tách khỏi nền: sáng lên ở theme tối, tối đi ở theme sáng.
		surface = tostring(is_dark and bg:lighten(0.10) or bg:darken(0.14)),
		overlay = tostring(is_dark and bg:lighten(0.38) or bg:darken(0.35)),

		text = tostring(fg),
		subtext = tostring(is_dark and fg:darken(0.18) or fg:lighten(0.09)),

		accent = color(5), -- blue
		green = color(3),
		yellow = yellow,
		peach = yellow, -- ANSI không có cam riêng
		mauve = color(6), -- magenta
		red = color(2),
		teal = color(7), -- cyan
	}
end

local derived_cache = {}
local builtin_cache = nil

--- Bảng scheme dựng sẵn của WezTerm. Hơn 1000 cái nên chỉ lấy một lần.
function M.builtin_schemes()
	if not builtin_cache then
		builtin_cache = wezterm.color.get_builtin_schemes()
	end
	return builtin_cache
end

--- Bảng màu cho một scheme. Trả về nil nếu WezTerm không biết tên đó.
function M.for_scheme(name)
	if curated[name] then
		return curated[name]
	end
	if derived_cache[name] then
		return derived_cache[name]
	end
	local scheme = M.builtin_schemes()[name]
	if not scheme then
		return nil
	end
	local palette = derive(name, scheme)
	derived_cache[name] = palette
	return palette
end

--- Khối config.colors ứng với một bảng màu. appearance.lua dùng lúc nạp config,
--- picker dùng lại y hệt khi preview, để hai đường không lệch nhau.
function M.colors_for(palette)
	return {
		cursor_bg = palette.accent,
		cursor_border = palette.accent,
		cursor_fg = palette.crust,
		selection_bg = palette.surface,
		selection_fg = palette.text,
		split = palette.overlay,
		tab_bar = {
			background = palette.mantle,
			inactive_tab_edge = palette.mantle,
		},
	}
end

--- Bảng màu ứng với config hiệu lực của một cửa sổ. Nhờ hàm này mà tab bar
--- và status bar đi theo cả scheme đang preview, không chỉ scheme đã lưu.
function M.for_config(cfg)
	if cfg and cfg.color_scheme then
		local palette = M.for_scheme(cfg.color_scheme)
		if palette then
			return palette
		end
	end
	return M.current()
end

--- Toàn bộ tên scheme: ưa dùng trước, còn lại xếp theo bảng chữ cái.
function M.list_all()
	local schemes = M.builtin_schemes()
	local seen, ordered = {}, {}
	for _, name in ipairs(M.favourites) do
		if schemes[name] and not seen[name] then
			seen[name] = true
			table.insert(ordered, name)
		end
	end
	local rest = {}
	for name in pairs(schemes) do
		if not seen[name] then
			table.insert(rest, name)
		end
	end
	table.sort(rest, function(a, b)
		return a:lower() < b:lower()
	end)
	for _, name in ipairs(rest) do
		table.insert(ordered, name)
	end
	return ordered
end

----------------------------------------------------------------------
--  CHỌN THEME
----------------------------------------------------------------------
local SAVE_FILE = platform.config_dir .. "/theme.txt"

local configured = M.DEFAULT -- từ opts.theme trong wezterm.lua / local.lua
local resolved = nil -- cache trong một lần nạp config

function M.set_mode(value)
	configured = (type(value) == "string" and #value > 0) and value or M.DEFAULT
	resolved = nil
end

function M.save_file()
	return SAVE_FILE
end

--- Tên scheme người dùng đã chọn qua picker, nếu có.
function M.saved_choice()
	local file = io.open(SAVE_FILE, "r")
	if not file then
		return nil
	end
	local line = file:read("*l")
	file:close()
	if line then
		line = line:gsub("^%s+", ""):gsub("%s+$", "")
	end
	if line and #line > 0 then
		return line
	end
	return nil
end

function M.write_choice(name)
	local file = io.open(SAVE_FILE, "w")
	if not file then
		platform.mkdir(platform.config_dir)
		return false
	end
	file:write(name .. "\n")
	file:close()
	return true
end

function M.clear_choice()
	os.remove(SAVE_FILE)
	resolved = nil
end

--- Chỉ dùng khi theme được đặt thành "auto".
---
--- wezterm.gui.get_appearance() trên Windows trả về "Light" khi chưa có cửa sổ
--- nào tồn tại, kể cả lúc hệ thống đang ở chế độ tối — đúng vào lúc
--- mux.spawn_window dựng cửa sổ mới khi khôi phục session. Hỏi registry mới đúng.
local function system_appearance()
	if platform.is_windows then
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
	end
	if wezterm.gui then
		return wezterm.gui.get_appearance()
	end
	return "Dark"
end

M.appearance = system_appearance

--- Thứ tự ưu tiên: theme.txt (picker) > opts.theme > mặc định.
function M.current()
	if resolved then
		return resolved
	end

	local name = M.saved_choice() or configured

	if name == "auto" then
		name = system_appearance():find("Dark") and "Catppuccin Mocha" or "Catppuccin Latte"
	end

	resolved = M.for_scheme(name) or curated[M.DEFAULT]
	return resolved
end

--- Tên scheme đang dùng, để picker đánh dấu.
function M.current_name()
	return M.current().scheme
end

return M
