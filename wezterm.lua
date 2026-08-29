-- ============================================================================
--  WezTerm config — chạy được trên Windows, macOS và Linux
--
--  File này là điểm vào. Cấu hình thật nằm trong ./config/*.lua
--
--    config/platform.lua    nhận diện hệ điều hành
--    config/theme.lua       bảng màu, tự đổi sáng/tối theo hệ thống
--    config/util.lua        helper: cwd, git branch, icon tiến trình
--    config/appearance.lua  font, màu, cửa sổ, hiệu năng render
--    config/launch.lua      shell mặc định + launch menu theo OS
--    config/status.lua      tab bar powerline + status bar
--    config/workspaces.lua  quét project, fuzzy switcher
--    config/sessions.lua    lưu / khôi phục bố cục pane
--    config/keys.lua        phím tắt + chuột
--
--  Ctrl+Shift+R để nạp lại sau khi sửa. Không cần khởi động lại WezTerm.
-- ============================================================================

local wezterm = require("wezterm")
local config = wezterm.config_builder()
local platform = require("config.platform")

-- ============================================================================
--  MẶC ĐỊNH
--  Đừng sửa trực tiếp ở đây nếu bạn dùng chung repo này trên nhiều máy —
--  tạo file local.lua (đã được gitignore) để ghi đè. Xem local.lua.example.
-- ============================================================================
local opts = {
	font_size = 12.0,

	-- Theme mặc định. Nhận tên bất kỳ color scheme nào WezTerm có sẵn,
	-- hoặc "auto" để theo hệ điều hành.
	-- Ctrl+A T mở picker và ghi lựa chọn vào theme.txt, ghi đè dòng này.
	theme = "Catppuccin Mocha",

	-- 1.0 = nền đục hoàn toàn. Hạ xuống ~0.92 để nền trong,
	-- hiệu ứng mờ sẽ tự bật theo hệ điều hành.
	opacity = 1.0,

	-- Windows: "Acrylic" | "Mica" | "Tabbed" | "Auto"
	backdrop = "Acrylic",
	-- macOS: độ mờ hậu cảnh, 0–100
	blur = 30,

	-- "WebGpu" nhanh hơn. Máy nào dựng hình lỗi thì đổi thành "OpenGL".
	front_end = "WebGpu",
	max_fps = 120,

	-- Thư mục chứa code, dùng cho Ctrl+A W và launcher.
	-- Thư mục nào không tồn tại trên máy này sẽ tự bị bỏ qua.
	project_roots = {
		platform.home .. "/Code",
		platform.home .. "/code",
		platform.home .. "/Projects",
		platform.home .. "/projects",
		platform.home .. "/dev",
		platform.home .. "/src",
		platform.home .. "/work",
	},
}

-- Ghi đè theo từng máy. local.lua trả về một bảng, ví dụ:
--   return { font_size = 13.5, project_roots = { "D:/Code", "D:/Product" } }
local ok, overrides = pcall(require, "local")
if ok and type(overrides) == "table" then
	for key, value in pairs(overrides) do
		opts[key] = value
	end
end

require("config.theme").set_mode(opts.theme)
require("config.appearance").apply(config, opts)
require("config.launch").apply(config, opts)
require("config.workspaces").set_roots(opts.project_roots)
require("config.keys").apply(config)
require("config.status") -- chỉ đăng ký event, không cần apply

return config
