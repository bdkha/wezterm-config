-- ============================================================================
--  Lưu / khôi phục session theo tên (thủ công, KHÔNG tự động lưu).
--
--  Lưu lại: danh sách tab, tiêu đề tab, tab đang active, và cây chia pane
--  của từng tab kèm cwd của từng pane.
--
--  Cách hoạt động:
--    - Lưu:     đọc toạ độ (left/top/width/height) của mọi pane trong tab,
--               suy ngược ra cây split nhị phân (guillotine), ghi ra JSON.
--    - Khôi phục: tạo workspace mới rồi split đệ quy lại đúng cây đó,
--               mỗi pane spawn thẳng vào cwd đã lưu.
--
--  File lưu ở: <config_dir>/sessions/<tên>.json  — cứ mở ra sửa tay được.
-- ============================================================================
local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux
local util = require("config.util")
local platform = require("config.platform")

local M = {}

local DIR = util.normalize(wezterm.config_dir) .. "/sessions"

local function sanitize(name)
	return (name:gsub("[^%w%-%._ ]", "_"):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function path_for(name)
	return DIR .. "/" .. sanitize(name) .. ".json"
end

local function notify(window, title, body)
	window:toast_notification(title, body, nil, 4000)
end

----------------------------------------------------------------------
--  SUY NGƯỢC CÂY SPLIT TỪ TOẠ ĐỘ PANE
----------------------------------------------------------------------

--- Thử cắt `panes` thành 2 nhóm bằng một đường thẳng.
--- axis = "x" (cắt dọc -> hai pane nằm cạnh nhau) hoặc "y" (cắt ngang).
local function try_cut(panes, bbox, axis)
	local pos_key = axis == "x" and "left" or "top"
	local len_key = axis == "x" and "width" or "height"

	local candidates = {}
	for _, p in ipairs(panes) do
		if p[pos_key] > bbox[pos_key] then
			candidates[p[pos_key]] = true
		end
	end
	local sorted = {}
	for c in pairs(candidates) do
		table.insert(sorted, c)
	end
	table.sort(sorted)

	for _, cut in ipairs(sorted) do
		local before, after, clean = {}, {}, true
		for _, p in ipairs(panes) do
			if p[pos_key] + p[len_key] <= cut then
				table.insert(before, p)
			elseif p[pos_key] >= cut then
				table.insert(after, p)
			else
				clean = false -- pane này vắt qua đường cắt -> không cắt được ở đây
				break
			end
		end
		if clean and #before > 0 and #after > 0 then
			return cut, before, after
		end
	end
	return nil
end

local build_tree -- forward declare

local function sub_bbox(bbox, axis, cut, side)
	local pos_key = axis == "x" and "left" or "top"
	local len_key = axis == "x" and "width" or "height"
	local out = { left = bbox.left, top = bbox.top, width = bbox.width, height = bbox.height }
	if side == "before" then
		out[len_key] = cut - 1 - bbox[pos_key] -- trừ 1 cột/dòng cho đường phân cách
	else
		out[pos_key] = cut
		out[len_key] = bbox[pos_key] + bbox[len_key] - cut
	end
	return out
end

--- Trả về node: { leaf = true, cwd = ... }
---           hoặc { dir = "Horizontal"|"Vertical", size = <tỉ lệ của nhánh b>, a = node, b = node }
build_tree = function(panes, bbox)
	if #panes == 1 then
		return { leaf = true, cwd = panes[1].cwd, zoomed = panes[1].zoomed }
	end

	-- ưu tiên cắt dọc (pane nằm cạnh nhau) rồi mới cắt ngang
	for _, axis in ipairs({ "x", "y" }) do
		local cut, before, after = try_cut(panes, bbox, axis)
		if cut then
			local bb_a = sub_bbox(bbox, axis, cut, "before")
			local bb_b = sub_bbox(bbox, axis, cut, "after")
			local len_key = axis == "x" and "width" or "height"
			return {
				dir = axis == "x" and "Horizontal" or "Vertical",
				size = bb_b[len_key] / math.max(1, bbox[len_key]),
				a = build_tree(before, bb_a),
				b = build_tree(after, bb_b),
			}
		end
	end

	-- layout lạ không cắt được -> xếp chồng tuần tự cho khỏi mất pane
	local first = table.remove(panes, 1)
	return {
		dir = "Vertical",
		size = 1 - (1 / (#panes + 1)),
		a = { leaf = true, cwd = first.cwd },
		b = build_tree(panes, bbox),
	}
end

local function capture_tab(tab)
	local infos = tab:panes_with_info()
	if #infos == 0 then
		return nil
	end

	local panes, bbox = {}, nil
	for _, info in ipairs(infos) do
		table.insert(panes, {
			left = info.left,
			top = info.top,
			width = info.width,
			height = info.height,
			zoomed = info.is_zoomed or false,
			cwd = util.cwd(info.pane),
		})
		if bbox == nil then
			bbox = { left = info.left, top = info.top, right = info.left + info.width, bottom = info.top + info.height }
		else
			bbox.left = math.min(bbox.left, info.left)
			bbox.top = math.min(bbox.top, info.top)
			bbox.right = math.max(bbox.right, info.left + info.width)
			bbox.bottom = math.max(bbox.bottom, info.top + info.height)
		end
	end

	return {
		title = tab:get_title(),
		tree = build_tree(panes, {
			left = bbox.left,
			top = bbox.top,
			width = bbox.right - bbox.left,
			height = bbox.bottom - bbox.top,
		}),
	}
end

----------------------------------------------------------------------
--  LƯU
----------------------------------------------------------------------
local function write_session(window, name)
	local mux_win = window:mux_window()
	local session = {
		name = name,
		workspace = mux_win:get_workspace(),
		saved_at = wezterm.strftime("%Y-%m-%d %H:%M"),
		active_tab = 1,
		tabs = {},
	}

	for idx, tab in ipairs(mux_win:tabs()) do
		local captured = capture_tab(tab)
		if captured then
			table.insert(session.tabs, captured)
			if tab:tab_id() == mux_win:active_tab():tab_id() then
				session.active_tab = #session.tabs
			end
		end
		_ = idx
	end

	if #session.tabs == 0 then
		notify(window, "WezTerm", "Không có tab nào để lưu.")
		return
	end

	local file = io.open(path_for(name), "w")
	if not file then
		-- thư mục sessions/ chưa tồn tại -> tạo rồi báo bấm lại
		platform.mkdir(DIR)
		notify(window, "WezTerm", "Chưa có thư mục sessions/, vừa tạo xong. Bấm lưu lại lần nữa.")
		return
	end
	file:write(wezterm.json_encode(session))
	file:close()

	local n = 0
	for _, t in ipairs(session.tabs) do
		local function count(node)
			if node.leaf then
				n = n + 1
			else
				count(node.a)
				count(node.b)
			end
		end
		count(t.tree)
	end
	notify(window, "Đã lưu session", string.format("%s — %d tab, %d pane", name, #session.tabs, n))
end

M.save = act.PromptInputLine({
	description = wezterm.format({
		{ Attribute = { Intensity = "Bold" } },
		{ Text = "Lưu session với tên:" },
	}),
	action = wezterm.action_callback(function(window, _pane, line)
		if line and #line > 0 then
			write_session(window, line)
		end
	end),
})

----------------------------------------------------------------------
--  KHÔI PHỤC
----------------------------------------------------------------------
local function list_sessions()
	local out = {}
	local ok, files = pcall(wezterm.glob, DIR .. "/*.json")
	if not ok or not files then
		return out
	end
	for _, f in ipairs(files) do
		local p = f:gsub("\\", "/")
		table.insert(out, { path = p, name = (p:match("([^/]+)%.json$") or p) })
	end
	table.sort(out, function(a, b)
		return a.name:lower() < b.name:lower()
	end)
	return out
end

local function read_session(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end
	local raw = file:read("*a")
	file:close()
	local ok, data = pcall(wezterm.json_parse, raw)
	if ok and type(data) == "table" and data.tabs then
		return data
	end
	return nil
end

--- Chuẩn hoá lúc đọc, để các file session lưu từ bản cũ (có "/D:/..." sai)
--- vẫn khôi phục đúng chỗ mà không cần sửa tay.
local function first_cwd(node)
	if node.leaf then
		return util.normalize(node.cwd)
	end
	return first_cwd(node.a)
end

--- Split đệ quy: cắt nhánh b ra trước, rồi mới đi sâu vào nhánh a
--- (lúc đó `pane` đúng bằng vùng của a).
local function realize(pane, node)
	if node.leaf then
		return
	end
	local direction = node.dir == "Horizontal" and "Right" or "Bottom"
	local size = node.size
	if type(size) ~= "number" or size <= 0.05 or size >= 0.95 then
		size = 0.5
	end
	local ok, new_pane = pcall(function()
		return pane:split({ direction = direction, size = size, cwd = first_cwd(node.b) })
	end)
	if not ok or not new_pane then
		return -- pane quá nhỏ để chia tiếp, bỏ qua nhánh này
	end
	realize(pane, node.a)
	realize(new_pane, node.b)
end

local function restore_session(window, pane, path)
	local data = read_session(path)
	if not data then
		notify(window, "WezTerm", "Không đọc được file session.")
		return
	end

	local ws = data.name or data.workspace or "restored"

	-- workspace đã mở rồi thì chỉ chuyển sang, không dựng lại
	for _, existing in ipairs(mux.get_workspace_names()) do
		if existing == ws then
			window:perform_action(act.SwitchToWorkspace({ name = ws }), pane)
			notify(window, "WezTerm", string.format('Workspace "%s" đang mở sẵn — đã chuyển sang.', ws))
			return
		end
	end

	local first = data.tabs[1]
	local first_tab, first_pane, mux_win = mux.spawn_window({
		workspace = ws,
		cwd = first_cwd(first.tree),
	})
	realize(first_pane, first.tree)
	if first.title and #first.title > 0 then
		first_tab:set_title(first.title)
	end

	for i = 2, #data.tabs do
		local t = data.tabs[i]
		local ok, new_tab, new_pane = pcall(function()
			return mux_win:spawn_tab({ cwd = first_cwd(t.tree) })
		end)
		if ok and new_pane then
			realize(new_pane, t.tree)
			if t.title and #t.title > 0 then
				new_tab:set_title(t.title)
			end
		end
	end

	local target = data.active_tab or 1
	local tabs = mux_win:tabs()
	if tabs[target] then
		tabs[target]:activate()
	end

	mux.set_active_workspace(ws)
	notify(window, "Đã khôi phục session", string.format("%s — %d tab", ws, #data.tabs))
end

local function pick(window, pane, title, on_choose)
	local sessions = list_sessions()
	if #sessions == 0 then
		notify(window, "WezTerm", "Chưa có session nào được lưu (Ctrl+A S để lưu).")
		return
	end
	local choices = {}
	for _, s in ipairs(sessions) do
		local data = read_session(s.path)
		local meta = data and data.saved_at or ""
		local ntabs = data and #data.tabs or 0
		table.insert(choices, {
			id = s.path,
			label = string.format("  %s   %d tab   %s", s.name, ntabs, meta),
		})
	end
	window:perform_action(
		act.InputSelector({
			title = title,
			description = "Gõ để lọc, Enter để chọn, Esc để huỷ",
			fuzzy = true,
			choices = choices,
			action = wezterm.action_callback(function(win, p, id)
				if id then
					on_choose(win, p, id)
				end
			end),
		}),
		pane
	)
end

M.restore = wezterm.action_callback(function(window, pane)
	pick(window, pane, "Khôi phục session", restore_session)
end)

M.delete = wezterm.action_callback(function(window, pane)
	pick(window, pane, "Xoá session đã lưu", function(win, _p, path)
		local okr = os.remove(path)
		notify(win, "WezTerm", okr and ("Đã xoá " .. path:match("([^/]+)%.json$")) or "Xoá thất bại.")
	end)
end)

-- expose cho test logic dựng lại layout (xem scratchpad/session_test.lua)
M._build_tree = build_tree

return M
