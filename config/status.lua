-- Tab bar powerline + status bar (workspace / git branch / cwd / giờ).
local wezterm = require("wezterm")
local theme = require("config.theme")
local util = require("config.util")

local M = {}

-- Nerd Font powerline glyphs
local LEFT_ROUND = "" -- U+E0B6
local RIGHT_ROUND = "" -- U+E0B4
local LEFT_ARROW = "" -- U+E0B2

----------------------------------------------------------------------
-- TAB TITLE
----------------------------------------------------------------------
local function tab_label(tab)
	local pane = tab.active_pane
	-- 1) tiêu đề do user đặt (Ctrl+A ,)
	local explicit = tab.tab_title
	if explicit and #explicit > 0 then
		return explicit
	end
	-- 2) tên thư mục hiện tại
	local cwd = util.cwd(pane)
	if cwd then
		local base = cwd:match("([^/]+)/?$")
		if base and base ~= "" then
			return base
		end
	end
	-- 3) tên tiến trình
	return util.proc_name(pane.foreground_process_name) or "shell"
end

wezterm.on("format-tab-title", function(tab, _tabs, _panes, _config, _hover, max_width)
	local p = theme.current()

	local bg = tab.is_active and p.accent or p.surface
	local fg = tab.is_active and p.crust or p.subtext
	if tab.active_pane and tab.active_pane.has_unseen_output and not tab.is_active then
		bg = p.peach
		fg = p.crust
	end

	local icon = util.proc_icon(tab.active_pane and tab.active_pane.foreground_process_name)
	local title = tab_label(tab)

	local prefix = string.format(" %d %s ", tab.tab_index + 1, icon)
	local budget = math.max(6, max_width - #prefix - 3)
	if #title > budget then
		title = title:sub(1, budget - 1) .. "…"
	end

	return {
		{ Background = { Color = p.mantle } },
		{ Foreground = { Color = bg } },
		{ Text = LEFT_ROUND },
		{ Background = { Color = bg } },
		{ Foreground = { Color = fg } },
		{ Attribute = { Intensity = tab.is_active and "Bold" or "Normal" } },
		{ Text = prefix .. title .. " " },
		{ Background = { Color = p.mantle } },
		{ Foreground = { Color = bg } },
		{ Text = RIGHT_ROUND },
	}
end)

----------------------------------------------------------------------
-- STATUS BAR
----------------------------------------------------------------------
wezterm.on("update-status", function(window, pane)
	local p = theme.current()

	------------------------------------------------------------------
	-- TRÁI: báo LEADER đang bật + key table đang active
	------------------------------------------------------------------
	local left = {}
	local kt = window:active_key_table()
	if kt then
		table.insert(left, { Background = { Color = p.red } })
		table.insert(left, { Foreground = { Color = p.crust } })
		table.insert(left, { Attribute = { Intensity = "Bold" } })
		table.insert(left, { Text = "  " .. kt:upper() .. " " })
	elseif window:leader_is_active() then
		table.insert(left, { Background = { Color = p.yellow } })
		table.insert(left, { Foreground = { Color = p.crust } })
		table.insert(left, { Attribute = { Intensity = "Bold" } })
		table.insert(left, { Text = " 󰘴 LEADER " })
	end
	table.insert(left, { Background = { Color = p.mantle } })
	table.insert(left, { Foreground = { Color = p.mantle } })
	table.insert(left, { Text = " " })
	window:set_left_status(wezterm.format(left))

	------------------------------------------------------------------
	-- PHẢI: workspace  branch  cwd
	------------------------------------------------------------------
	local cells = {}
	local function push(text, fg, bg)
		table.insert(cells, { text = text, fg = fg, bg = bg })
	end

	local ws = window:active_workspace()
	push("  " .. ws .. " ", p.crust, p.mauve)

	local cwd = util.cwd(pane)
	local branch = util.git_branch(cwd)
	if branch then
		push("  " .. branch .. " ", p.crust, p.green)
	end

	if cwd then
		push("  " .. (util.shorten(cwd, 2) or cwd) .. " ", p.text, p.surface)
	end

	local elements = {}
	local prev_bg = p.mantle
	for _, c in ipairs(cells) do
		table.insert(elements, { Background = { Color = prev_bg } })
		table.insert(elements, { Foreground = { Color = c.bg } })
		table.insert(elements, { Text = LEFT_ARROW })
		table.insert(elements, { Background = { Color = c.bg } })
		table.insert(elements, { Foreground = { Color = c.fg } })
		table.insert(elements, { Text = c.text })
		prev_bg = c.bg
	end
	window:set_right_status(wezterm.format(elements))
end)

----------------------------------------------------------------------
-- Đổi màu ngay khi Windows đổi theme sáng/tối
----------------------------------------------------------------------
wezterm.on("window-config-reloaded", function(window)
	local p = theme.current()
	local overrides = window:get_config_overrides() or {}
	if overrides.color_scheme ~= p.scheme then
		overrides.color_scheme = p.scheme
		window:set_config_overrides(overrides)
	end
end)

return M
