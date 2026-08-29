-- Workspace theo project: quét git repo trong các thư mục code, mở fuzzy switcher.
local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- Thư mục gốc chứa code. wezterm.lua gọi set_roots() để nạp danh sách này,
-- lấy từ opts.project_roots (mặc định) hoặc local.lua (theo từng máy).
M.roots = {}

function M.set_roots(roots)
	M.roots = roots or {}
end

-- Quét .git ở độ sâu 1 và 2 dưới mỗi root; nếu repo cha đã khớp thì bỏ qua repo con
-- (ví dụ steplock/android, steplock/ios sẽ không hiện riêng).
local function scan_projects()
	local seen, ordered = {}, {}
	for _, root in ipairs(M.roots) do
		for _, pattern in ipairs({ "/*/.git", "/*/*/.git" }) do
			local ok, matches = pcall(wezterm.glob, root .. pattern)
			if ok and matches then
				for _, hit in ipairs(matches) do
					local dir = hit:gsub("\\", "/"):gsub("/%.git$", "")
					local nested = false
					for _, parent in ipairs(ordered) do
						if dir:sub(1, #parent + 1) == parent .. "/" then
							nested = true
							break
						end
					end
					if not nested and not seen[dir] then
						seen[dir] = true
						table.insert(ordered, dir)
					end
				end
			end
		end
	end
	return ordered
end

local function basename(path)
	return path:match("([^/]+)/?$") or path
end

--- Fuzzy switcher: workspace đang mở + tất cả project tìm được.
M.switcher = wezterm.action_callback(function(window, pane)
	local choices = {}
	local listed = {}

	-- workspace đang mở lên đầu
	for _, name in ipairs(wezterm.mux.get_workspace_names()) do
		listed[name] = true
		table.insert(choices, { id = "ws:" .. name, label = "  " .. name })
	end

	for _, dir in ipairs(scan_projects()) do
		local name = basename(dir)
		if not listed[name] then
			local parent = dir:match("([^/]+)/[^/]+/?$") or ""
			table.insert(choices, { id = "dir:" .. dir, label = string.format("  %s   %s", name, parent) })
		end
	end

	window:perform_action(
		act.InputSelector({
			title = "Chuyển / mở project",
			description = "Gõ để lọc, Enter để mở, Esc để huỷ",
			fuzzy = true,
			choices = choices,
			action = wezterm.action_callback(function(win, p, id, _label)
				if not id then
					return
				end
				local kind, value = id:match("^(%a+):(.*)$")
				if kind == "ws" then
					win:perform_action(act.SwitchToWorkspace({ name = value }), p)
				else
					win:perform_action(
						act.SwitchToWorkspace({ name = basename(value), spawn = { cwd = value } }),
						p
					)
				end
			end),
		}),
		pane
	)
end)

--- Tạo workspace mới với tên tự nhập.
M.create = act.PromptInputLine({
	description = wezterm.format({
		{ Attribute = { Intensity = "Bold" } },
		{ Text = "Tên workspace mới:" },
	}),
	action = wezterm.action_callback(function(window, pane, line)
		if line and #line > 0 then
			window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
		end
	end),
})

--- Đổi tên tab hiện tại.
M.rename_tab = act.PromptInputLine({
	description = wezterm.format({
		{ Attribute = { Intensity = "Bold" } },
		{ Text = "Tên tab:" },
	}),
	action = wezterm.action_callback(function(window, _pane, line)
		if line then
			window:active_tab():set_title(line)
		end
	end),
})

return M
