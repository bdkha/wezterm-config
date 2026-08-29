-- Shell mặc định + menu launcher (Ctrl+Shift+P), chọn theo hệ điều hành.
local wezterm = require("wezterm")
local platform = require("config.platform")

local M = {}

----------------------------------------------------------------------
--  WINDOWS
----------------------------------------------------------------------
local function windows(config, opts)
	local pwsh = platform.first_existing({
		"C:/Program Files/PowerShell/7/pwsh.exe",
		"C:/Program Files/PowerShell/6/pwsh.exe",
	})
	local winps = "C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
	local gitbash = platform.first_existing({
		"C:/Program Files/Git/bin/bash.exe",
		"C:/Program Files (x86)/Git/bin/bash.exe",
	})

	-- Ưu tiên PowerShell 7; máy chưa cài thì rơi về bản đi kèm Windows.
	config.default_prog = pwsh and { pwsh, "-NoLogo" } or { winps, "-NoLogo" }

	local menu = {}
	if pwsh then
		table.insert(menu, { label = "PowerShell 7", args = { pwsh, "-NoLogo" } })
		table.insert(menu, {
			label = "PowerShell 7 (no profile, khởi động nhanh)",
			args = { pwsh, "-NoLogo", "-NoProfile" },
		})
	end
	if gitbash then
		table.insert(menu, { label = "Git Bash", args = { gitbash, "-i", "-l" } })
	end
	table.insert(menu, { label = "Command Prompt", args = { "cmd.exe" } })
	table.insert(menu, { label = "Windows PowerShell 5.1", args = { winps, "-NoLogo" } })
	config.launch_menu = menu

	-- Tự nhận các distro WSL đã cài, nếu có.
	local ok, domains = pcall(wezterm.default_wsl_domains)
	if ok and domains then
		config.wsl_domains = domains
	end

	_ = opts
end

----------------------------------------------------------------------
--  macOS / LINUX
----------------------------------------------------------------------
local function unix(config, opts)
	-- Không ép shell: để WezTerm dùng login shell trong /etc/passwd,
	-- nhờ vậy chezmoi/nix/homebrew đặt shell gì thì theo cái đó.
	config.default_prog = nil

	local menu = {}
	local candidates = {
		{ label = "zsh", paths = { "/bin/zsh", "/usr/bin/zsh" } },
		{ label = "bash", paths = { "/bin/bash", "/usr/bin/bash", "/opt/homebrew/bin/bash" } },
		{ label = "fish", paths = { "/usr/bin/fish", "/usr/local/bin/fish", "/opt/homebrew/bin/fish" } },
		{ label = "nushell", paths = { "/usr/bin/nu", "/usr/local/bin/nu", "/opt/homebrew/bin/nu" } },
	}
	for _, shell in ipairs(candidates) do
		local found = platform.first_existing(shell.paths)
		if found then
			table.insert(menu, { label = shell.label, args = { found, "-l" } })
		end
	end
	config.launch_menu = menu

	_ = opts
end

----------------------------------------------------------------------
function M.apply(config, opts)
	if platform.is_windows then
		windows(config, opts)
	else
		unix(config, opts)
	end

	-- Chỉ giữ những thư mục code thật sự có trên máy này.
	local roots = {}
	for _, root in ipairs(opts.project_roots or {}) do
		if platform.dir_exists(root) then
			table.insert(roots, root)
		end
	end

	-- Tab mới mở ở thư mục code đầu tiên, nếu shell chưa báo cwd.
	if roots[1] then
		config.default_cwd = roots[1]
	end

	-- Mở nhanh từng thư mục code từ launcher.
	for _, root in ipairs(roots) do
		table.insert(config.launch_menu, { label = root, cwd = root })
	end
end

return M
