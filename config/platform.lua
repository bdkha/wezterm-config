-- Nhận diện hệ điều hành và vài đường dẫn cơ bản.
-- Mọi chỗ khác trong config hỏi module này thay vì tự đoán.
local wezterm = require("wezterm")

local M = {}

local triple = wezterm.target_triple

M.is_windows = triple:find("windows") ~= nil
M.is_mac = triple:find("darwin") ~= nil
M.is_linux = triple:find("linux") ~= nil

M.home = (os.getenv("HOME") or os.getenv("USERPROFILE") or ""):gsub("\\", "/"):gsub("/+$", "")
M.config_dir = (wezterm.config_dir or ""):gsub("\\", "/"):gsub("/+$", "")

--- File có tồn tại và đọc được không. Dùng để dò shell đã cài chưa.
function M.exists(path)
	local f = io.open(path, "r")
	if f then
		f:close()
		return true
	end
	return false
end

--- Thư mục có tồn tại không. io.open không dùng được cho thư mục nên hỏi glob.
function M.dir_exists(path)
	local ok, matches = pcall(wezterm.glob, path)
	return ok and matches ~= nil and #matches > 0
end

--- Trả về đường dẫn đầu tiên tồn tại trong danh sách, hoặc nil.
function M.first_existing(paths)
	for _, p in ipairs(paths) do
		if M.exists(p) then
			return p
		end
	end
	return nil
end

--- Tạo thư mục, không phụ thuộc hệ điều hành. Chạy nền, không mở cửa sổ console.
function M.mkdir(path)
	if M.is_windows then
		pcall(wezterm.background_child_process, { "cmd", "/c", "mkdir", (path:gsub("/", "\\")) })
	else
		pcall(wezterm.background_child_process, { "mkdir", "-p", path })
	end
end

return M
