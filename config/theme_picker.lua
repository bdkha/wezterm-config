-- ============================================================================
--  Chọn theme có xem trước (Ctrl+A T)
--
--  Ctrl+A T mở chế độ duyệt: mũi tên hoặc j/k để đi, màu cả cửa sổ đổi ngay
--  theo scheme đang trỏ tới. Enter giữ lại, Esc trả về như cũ.
--
--  Hai chỗ phải né:
--
--  1. InputSelector chỉ gọi action lúc bấm Enter, không báo khi con trỏ di
--     chuyển — nên không xem trước bên trong nó được. Việc duyệt vì vậy dùng
--     key table riêng, còn fuzzy search vẫn là InputSelector, mở bằng "/".
--
--  2. set_config_overrides bắt WezTerm tính lại config cho cửa sổ, và việc đó
--     xoá key table đang active. Bật lại ngay trong callback vẫn hụt, vì lần
--     tính lại xảy ra sau đó. Nên bật lại từ chính sự kiện
--     window-config-reloaded, tức là sau khi tính xong.
--
--  Kéo theo một điều kiện: không giữ state nào trong Lua. Vị trí đang duyệt
--  đọc thẳng từ color_scheme trong overrides của cửa sổ, nên config có được
--  tính lại bao nhiêu lần thì vẫn tìm lại đúng chỗ cũ.
-- ============================================================================
local wezterm = require("wezterm")
local act = wezterm.action
local theme = require("config.theme")

local M = {}

M.KEY_TABLE = "theme_browse"

----------------------------------------------------------------------
--  TRẠNG THÁI ĐỌC TỪ OVERRIDES
----------------------------------------------------------------------

--- Scheme đang xem trước, hoặc nil nếu cửa sổ không ở chế độ duyệt.
--- Chỉ chế độ duyệt mới đặt color_scheme vào overrides, và cả commit lẫn
--- cancel đều xoá sạch overrides khi thoát — nên đây là dấu hiệu đáng tin.
local function browsing_scheme(window)
	local overrides = window:get_config_overrides()
	return overrides and overrides.color_scheme or nil
end

local function index_of(list, name)
	for i, value in ipairs(list) do
		if value == name then
			return i
		end
	end
	return 1
end

local function preview(window, name)
	local palette = theme.for_scheme(name)
	if not palette then
		return
	end
	window:set_config_overrides({
		color_scheme = name,
		colors = theme.colors_for(palette),
	})
end

local function activate_table(window, pane)
	window:perform_action(
		act.ActivateKeyTable({
			name = M.KEY_TABLE,
			one_shot = false,
			prevent_fallback = true,
			replace_current = true,
		}),
		pane
	)
end

local function leave(window, pane)
	window:perform_action(act.PopKeyTable, pane)
	window:set_config_overrides({})
end

----------------------------------------------------------------------
--  CHO STATUS BAR
----------------------------------------------------------------------

--- Scheme đang xem trước ở cửa sổ này, hoặc nil nếu không duyệt.
function M.preview_scheme(window)
	return browsing_scheme(window)
end

--- Nhãn hiện ở góc trái thanh tab trong lúc duyệt.
function M.browsing_label(window)
	local name = browsing_scheme(window)
	if not name then
		return nil
	end
	local list = theme.list_all()
	return string.format("%s  %d/%d", name, index_of(list, name), #list)
end

----------------------------------------------------------------------
--  VÀO / DI CHUYỂN / RA
----------------------------------------------------------------------
M.enter = wezterm.action_callback(function(window, pane)
	preview(window, browsing_scheme(window) or theme.current_name())
	activate_table(window, pane)
end)

local function step(delta)
	return wezterm.action_callback(function(window, pane)
		local list = theme.list_all()
		local index = index_of(list, browsing_scheme(window) or theme.current_name())
		index = ((index - 1 + delta) % #list) + 1
		preview(window, list[index])
		activate_table(window, pane)
	end)
end

M.next = step(1)
M.prev = step(-1)
M.next_page = step(20)
M.prev_page = step(-20)

M.commit = wezterm.action_callback(function(window, pane)
	local name = browsing_scheme(window)
	leave(window, pane)
	if not name then
		return
	end
	if not theme.write_choice(name) then
		window:toast_notification("WezTerm", "Không ghi được theme.txt", nil, 4000)
		return
	end
	-- Overrides đã xoá ở leave(); nạp lại để base config lấy theme.txt,
	-- nhờ vậy mọi cửa sổ đang mở cùng đổi.
	window:toast_notification("WezTerm", "Theme: " .. name, nil, 3000)
	wezterm.reload_configuration()
end)

M.cancel = wezterm.action_callback(function(window, pane)
	leave(window, pane)
end)

M.reset = wezterm.action_callback(function(window, pane)
	leave(window, pane)
	theme.clear_choice()
	window:toast_notification("WezTerm", "Đã về theme mặc định: " .. theme.DEFAULT, nil, 3000)
	wezterm.reload_configuration()
end)

----------------------------------------------------------------------
--  FUZZY SEARCH (phím "/")
--  Nhảy con trỏ tới scheme đã chọn rồi quay lại chế độ duyệt, nên vẫn xem
--  trước tiếp được và vẫn Esc để trả lại màu cũ.
----------------------------------------------------------------------
M.search = wezterm.action_callback(function(window, pane)
	local current = browsing_scheme(window) or theme.current_name()
	local choices = {}
	for _, name in ipairs(theme.list_all()) do
		table.insert(choices, {
			id = name,
			label = (name == current and " > " or "   ") .. name,
		})
	end

	window:perform_action(
		act.InputSelector({
			title = "Tìm theme",
			description = "Gõ để lọc, Enter để xem trước, Esc để quay lại",
			fuzzy = true,
			choices = choices,
			action = wezterm.action_callback(function(win, p, id)
				if id then
					preview(win, id)
				end
				activate_table(win, p)
			end),
		}),
		pane
	)
end)

--- Lưới an toàn: status.lua gọi mỗi giây. Nếu đang duyệt mà bảng phím không
--- còn active thì bật lại, phòng khi window-config-reloaded không kịp bắn.
function M.rearm_if_needed(window, pane)
	if browsing_scheme(window) and window:active_key_table() ~= M.KEY_TABLE then
		activate_table(window, pane)
	end
end

----------------------------------------------------------------------
--  BẬT LẠI KEY TABLE SAU MỖI LẦN TÍNH LẠI CONFIG
--
--  Đây là chỗ giữ cho việc duyệt không đứt sau bước đầu tiên: mỗi lần xem
--  trước kéo theo một lần tính lại config, mà lần đó xoá key table.
----------------------------------------------------------------------
wezterm.on("window-config-reloaded", function(window, pane)
	if browsing_scheme(window) then
		activate_table(window, pane)
	end
end)

return M
