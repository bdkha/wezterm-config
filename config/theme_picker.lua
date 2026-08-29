-- ============================================================================
--  Chọn theme có xem trước (Ctrl+A T)
--
--  Ctrl+A T mở chế độ duyệt: mũi tên hoặc j/k để đi, màu cả cửa sổ đổi ngay
--  theo scheme đang trỏ tới. Enter giữ lại, Esc trả về như cũ.
--
--  InputSelector của WezTerm không báo khi con trỏ di chuyển, chỉ báo lúc
--  Enter — nên không xem trước trong đó được. Vì vậy duyệt bằng key table
--  riêng, còn fuzzy search vẫn dùng InputSelector, mở bằng phím "/".
--
--  Xem trước = set_config_overrides trên đúng cửa sổ đó, nên các cửa sổ khác
--  không bị đổi màu theo. Chốt lại thì ghi theme.txt rồi nạp lại config, lúc
--  đó mọi cửa sổ mới đồng loạt đổi.
-- ============================================================================
local wezterm = require("wezterm")
local act = wezterm.action
local theme = require("config.theme")

local M = {}

M.KEY_TABLE = "theme_browse"

-- window_id -> { list, index, original_overrides }
local sessions = {}

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
	local overrides = window:get_config_overrides() or {}
	overrides.color_scheme = name
	overrides.colors = theme.colors_for(palette)
	window:set_config_overrides(overrides)
end

local function state(window)
	return sessions[window:window_id()]
end

--- Scheme đang xem trước ở cửa sổ này, hoặc nil nếu không duyệt.
function M.preview_scheme(window_id)
	local session = sessions[window_id]
	return session and session.list[session.index] or nil
end

--- Nhãn hiện trên thanh tab trong lúc duyệt. status.lua gọi hàm này.
function M.browsing_label(window_id)
	local session = sessions[window_id]
	if not session then
		return nil
	end
	return string.format("%s  %d/%d", session.list[session.index], session.index, #session.list)
end

local function activate_table(window, pane)
	window:perform_action(
		act.ActivateKeyTable({
			name = M.KEY_TABLE,
			one_shot = false,
			prevent_fallback = true,
		}),
		pane
	)
end

local function step(delta)
	return wezterm.action_callback(function(window, pane)
		local session = state(window)
		if not session then
			return
		end
		local count = #session.list
		session.index = ((session.index - 1 + delta) % count) + 1
		preview(window, session.list[session.index])
		_ = pane
	end)
end

----------------------------------------------------------------------
--  VÀO / RA
----------------------------------------------------------------------
M.enter = wezterm.action_callback(function(window, pane)
	local list = theme.list_all()
	sessions[window:window_id()] = {
		list = list,
		index = index_of(list, theme.current_name()),
		original_overrides = window:get_config_overrides() or {},
	}
	preview(window, list[sessions[window:window_id()].index])
	activate_table(window, pane)
end)

M.next = step(1)
M.prev = step(-1)
M.next_page = step(20)
M.prev_page = step(-20)

M.commit = wezterm.action_callback(function(window, pane)
	local session = state(window)
	window:perform_action(act.PopKeyTable, pane)
	if not session then
		return
	end
	local name = session.list[session.index]
	sessions[window:window_id()] = nil

	if not theme.write_choice(name) then
		window:toast_notification("WezTerm", "Không ghi được theme.txt", nil, 4000)
		return
	end
	-- Bỏ override xem trước rồi nạp lại: base config sẽ tự lấy theme.txt,
	-- nên mọi cửa sổ đang mở đều đổi theo.
	window:set_config_overrides(session.original_overrides)
	window:toast_notification("WezTerm", "Theme: " .. name, nil, 3000)
	wezterm.reload_configuration()
end)

M.cancel = wezterm.action_callback(function(window, pane)
	local session = state(window)
	window:perform_action(act.PopKeyTable, pane)
	if not session then
		return
	end
	sessions[window:window_id()] = nil
	window:set_config_overrides(session.original_overrides)
end)

M.reset = wezterm.action_callback(function(window, pane)
	local session = state(window)
	window:perform_action(act.PopKeyTable, pane)
	sessions[window:window_id()] = nil
	if session then
		window:set_config_overrides(session.original_overrides)
	end
	theme.clear_choice()
	window:toast_notification("WezTerm", "Đã về theme mặc định: " .. theme.DEFAULT, nil, 3000)
	wezterm.reload_configuration()
end)

----------------------------------------------------------------------
--  FUZZY SEARCH (phím "/")
--  Nhảy con trỏ tới scheme đã chọn rồi quay lại chế độ duyệt, nên vẫn
--  xem trước được và vẫn Esc về như cũ.
----------------------------------------------------------------------
M.search = wezterm.action_callback(function(window, pane)
	local session = state(window)
	if not session then
		return
	end
	local current = session.list[session.index]
	local choices = {}
	for _, name in ipairs(session.list) do
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
				local current_session = state(win)
				if current_session and id then
					current_session.index = index_of(current_session.list, id)
					preview(win, id)
				end
				-- InputSelector đã nuốt mất key table, bật lại để duyệt tiếp
				if current_session then
					activate_table(win, p)
				end
			end),
		}),
		pane
	)
end)

return M
