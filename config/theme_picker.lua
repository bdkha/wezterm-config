-- Picker chọn theme (Ctrl+A T).
--
-- Liệt kê toàn bộ color scheme có sẵn của WezTerm, vài cái hay dùng lên đầu.
-- Chọn xong ghi tên vào theme.txt rồi nạp lại config, nên mọi cửa sổ đang mở
-- đổi màu ngay và lựa chọn còn nguyên sau khi khởi động lại.
local wezterm = require("wezterm")
local act = wezterm.action
local theme = require("config.theme")

local M = {}

local RESET = "\0reset"

M.pick = wezterm.action_callback(function(window, pane)
	local current = theme.current_name()
	local schemes = wezterm.color.get_builtin_schemes()

	local seen = {}
	local choices = {
		{ id = RESET, label = "   Về mặc định — " .. theme.DEFAULT },
	}

	local function add(name)
		if seen[name] or not schemes[name] then
			return
		end
		seen[name] = true
		table.insert(choices, {
			id = name,
			label = (name == current and " > " or "   ") .. name,
		})
	end

	-- Ưa dùng trước
	for _, name in ipairs(theme.favourites) do
		add(name)
	end

	-- Rồi tới tất cả các scheme còn lại, xếp theo bảng chữ cái
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
		add(name)
	end

	window:perform_action(
		act.InputSelector({
			title = "Chọn theme",
			description = "Gõ để lọc, Enter để áp dụng cho mọi cửa sổ, Esc để huỷ",
			fuzzy = true,
			choices = choices,
			action = wezterm.action_callback(function(win, _p, id)
				if not id then
					return
				end
				if id == RESET then
					theme.clear_choice()
					win:toast_notification("WezTerm", "Đã về theme mặc định: " .. theme.DEFAULT, nil, 3000)
				elseif theme.write_choice(id) then
					win:toast_notification("WezTerm", "Theme: " .. id, nil, 3000)
				else
					win:toast_notification("WezTerm", "Không ghi được theme.txt", nil, 4000)
					return
				end
				wezterm.reload_configuration()
			end),
		}),
		pane
	)
end)

return M
