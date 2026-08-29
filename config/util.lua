-- Helper dùng chung: lấy cwd của pane, đọc git branch (đọc file, KHÔNG spawn git),
-- rút gọn đường dẫn cho status bar.
local wezterm = require("wezterm")
local platform = require("config.platform")

local M = {}

local HOME = platform.home

--- Chuẩn hoá path: backslash -> slash, bỏ slash cuối.
function M.normalize(p)
	if not p then
		return nil
	end
	p = p:gsub("\\", "/")
	if #p > 3 then
		p = p:gsub("/+$", "")
	end
	return p
end

--- Lấy cwd của một pane (hoặc của bảng tab.active_pane).
--- Trả về nil nếu shell chưa báo cwd qua OSC 7.
function M.cwd(pane_or_info)
	local ok, cwd = pcall(function()
		if type(pane_or_info) == "table" then
			return pane_or_info.current_working_dir
		end
		return pane_or_info:get_current_working_dir()
	end)
	if not ok or not cwd then
		return nil
	end
	if type(cwd) == "string" then
		-- bản cũ trả về chuỗi file://host/C:/path
		cwd = cwd:gsub("^file://[^/]*", "")
		cwd = cwd:gsub("^/([A-Za-z]:)", "%1")
		return M.normalize(cwd)
	end
	return M.normalize(cwd.file_path)
end

--- Rút gọn: thay HOME bằng ~, chỉ giữ `keep` segment cuối.
function M.shorten(path, keep)
	if not path then
		return nil
	end
	keep = keep or 2
	local p = path
	if HOME ~= "" and p:sub(1, #HOME) == HOME then
		p = "~" .. p:sub(#HOME + 1)
	end
	local parts = {}
	for seg in p:gmatch("[^/]+") do
		table.insert(parts, seg)
	end
	if #parts <= keep then
		return p
	end
	local tail = {}
	for i = #parts - keep + 1, #parts do
		table.insert(tail, parts[i])
	end
	return "…/" .. table.concat(tail, "/")
end

local function head_to_branch(line)
	if not line then
		return nil
	end
	local ref = line:match("^ref: refs/heads/(.+)$")
	if ref then
		return ref
	end
	-- detached HEAD -> hiện short sha
	local sha = line:match("^(%x+)$")
	if sha then
		return sha:sub(1, 7)
	end
	return nil
end

local function read_head(dir)
	-- repo thường: <dir>/.git/HEAD
	local f = io.open(dir .. "/.git/HEAD", "r")
	if f then
		local line = f:read("*l")
		f:close()
		return head_to_branch(line)
	end
	-- worktree / submodule: <dir>/.git là FILE chứa "gitdir: <path>"
	local gf = io.open(dir .. "/.git", "r")
	if gf then
		local line = gf:read("*l")
		gf:close()
		local gitdir = line and line:match("^gitdir:%s*(.+)$")
		if gitdir then
			gitdir = M.normalize(gitdir)
			if not gitdir:match("^%a:") and not gitdir:match("^/") then
				gitdir = dir .. "/" .. gitdir
			end
			local hf = io.open(gitdir .. "/HEAD", "r")
			if hf then
				local hline = hf:read("*l")
				hf:close()
				return head_to_branch(hline)
			end
		end
	end
	return nil
end

local cache = {}
local TTL = 3 -- giây

--- Tìm branch bằng cách đi ngược lên cây thư mục. Có cache 3s để status bar không tốn IO.
function M.git_branch(dir)
	if not dir then
		return nil
	end
	local now = os.time()
	local hit = cache[dir]
	if hit and (now - hit.at) < TTL then
		return hit.value or nil
	end

	local value = nil
	local d = dir
	for _ = 1, 24 do
		value = read_head(d)
		if value then
			break
		end
		local parent = d:match("^(.*)/[^/]+$")
		if not parent or parent == d or parent == "" then
			break
		end
		d = parent
	end

	cache[dir] = { at = now, value = value or false }
	return value
end

--- Icon theo tiến trình đang chạy trong pane.
--- Khoá không kèm đuôi .exe để dùng chung cho Windows, macOS và Linux.
local PROC_ICONS = {
	pwsh = "",
	powershell = "",
	cmd = "",
	bash = "",
	sh = "",
	zsh = "",
	fish = "",
	nu = "",
	wsl = "",
	node = "",
	deno = "",
	bun = "",
	npm = "",
	pnpm = "",
	yarn = "",
	python = "",
	python3 = "",
	git = "",
	lazygit = "",
	nvim = "",
	vim = "",
	docker = "",
	kubectl = "󱃾",
	ssh = "",
	cargo = "",
	rustc = "",
	go = "",
	gradlew = "",
	gradle = "",
	java = "",
	adb = "",
	claude = "",
	top = "",
	htop = "",
	btop = "",
	make = "",
}

local function basename_no_ext(proc_path)
	local name = proc_path:gsub("\\", "/"):match("([^/]+)$") or proc_path
	return (name:gsub("%.exe$", ""):gsub("%.cmd$", ""):gsub("%.bat$", "")):lower()
end

function M.proc_icon(proc_path)
	if not proc_path or proc_path == "" then
		return ""
	end
	return PROC_ICONS[basename_no_ext(proc_path)] or ""
end

function M.proc_name(proc_path)
	if not proc_path or proc_path == "" then
		return nil
	end
	return basename_no_ext(proc_path)
end

return M
