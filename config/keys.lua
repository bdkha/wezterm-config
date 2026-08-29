-- Phím tắt: Ctrl+Shift cho thao tác hay dùng + LEADER (Ctrl+A) kiểu tmux cho nâng cao.
local wezterm = require("wezterm")
local act = wezterm.action
local ws = require("config.workspaces")
local sessions = require("config.sessions")
local theme_picker = require("config.theme_picker")

local M = {}

-- Ctrl+C: có bôi đen thì copy, không thì gửi Ctrl+C (SIGINT) như bình thường.
local smart_copy = wezterm.action_callback(function(window, pane)
	local sel = window:get_selection_text_for_pane(pane)
	if sel and #sel > 0 then
		window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
		window:perform_action(act.ClearSelection, pane)
	else
		window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
	end
end)

function M.apply(config)
	config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1500 }
	config.disable_default_key_bindings = false

	config.keys = {
		------------------------------------------------------------------
		-- TAB
		------------------------------------------------------------------
		{ key = "t", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
		{ key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
		{ key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
		{ key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },
		{ key = "PageUp", mods = "CTRL|SHIFT", action = act.MoveTabRelative(-1) },
		{ key = "PageDown", mods = "CTRL|SHIFT", action = act.MoveTabRelative(1) },

		------------------------------------------------------------------
		-- PANE
		------------------------------------------------------------------
		{ key = "d", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "e", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "z", mods = "CTRL|SHIFT", action = act.TogglePaneZoomState },
		{ key = "q", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = true }) },
		{ key = "LeftArrow", mods = "ALT", action = act.ActivatePaneDirection("Left") },
		{ key = "RightArrow", mods = "ALT", action = act.ActivatePaneDirection("Right") },
		{ key = "UpArrow", mods = "ALT", action = act.ActivatePaneDirection("Up") },
		{ key = "DownArrow", mods = "ALT", action = act.ActivatePaneDirection("Down") },
		{ key = "h", mods = "ALT", action = act.ActivatePaneDirection("Left") },
		{ key = "l", mods = "ALT", action = act.ActivatePaneDirection("Right") },
		{ key = "k", mods = "ALT", action = act.ActivatePaneDirection("Up") },
		{ key = "j", mods = "ALT", action = act.ActivatePaneDirection("Down") },

		------------------------------------------------------------------
		-- COPY / PASTE / SEARCH
		------------------------------------------------------------------
		{ key = "c", mods = "CTRL", action = smart_copy },
		{ key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
		{ key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
		{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
		{ key = "f", mods = "CTRL|SHIFT", action = act.Search({ CaseInSensitiveString = "" }) },
		{ key = "x", mods = "CTRL|SHIFT", action = act.ActivateCopyMode },
		{ key = "k", mods = "CTRL|SHIFT", action = act.ClearScrollback("ScrollbackAndViewport") },

		------------------------------------------------------------------
		-- CỬA SỔ / FONT / CONFIG
		------------------------------------------------------------------
		{ key = "n", mods = "CTRL|SHIFT", action = act.SpawnWindow },
		{
			key = "p",
			mods = "CTRL|SHIFT",
			action = act.ShowLauncherArgs({ flags = "FUZZY|LAUNCH_MENU_ITEMS|DOMAINS|WORKSPACES" }),
		},
		{ key = "r", mods = "CTRL|SHIFT", action = act.ReloadConfiguration },
		{ key = "Enter", mods = "ALT", action = act.ToggleFullScreen },
		{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },
		{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
		{ key = "0", mods = "CTRL", action = act.ResetFontSize },
		{ key = "PageUp", mods = "SHIFT", action = act.ScrollByPage(-1) },
		{ key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1) },

		------------------------------------------------------------------
		-- Alt+1..9 nhảy tab (Alt+9 = tab cuối)
		------------------------------------------------------------------
		{ key = "1", mods = "ALT", action = act.ActivateTab(0) },
		{ key = "2", mods = "ALT", action = act.ActivateTab(1) },
		{ key = "3", mods = "ALT", action = act.ActivateTab(2) },
		{ key = "4", mods = "ALT", action = act.ActivateTab(3) },
		{ key = "5", mods = "ALT", action = act.ActivateTab(4) },
		{ key = "6", mods = "ALT", action = act.ActivateTab(5) },
		{ key = "7", mods = "ALT", action = act.ActivateTab(6) },
		{ key = "8", mods = "ALT", action = act.ActivateTab(7) },
		{ key = "9", mods = "ALT", action = act.ActivateTab(-1) },

		------------------------------------------------------------------
		-- LEADER (Ctrl+A)
		------------------------------------------------------------------
		-- Ctrl+A A gửi Ctrl+A thật xuống shell (PSReadLine: về đầu dòng)
		{ key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },
		{ key = "a", mods = "LEADER", action = act.SendKey({ key = "a", mods = "CTRL" }) },

		-- workspace
		{ key = "w", mods = "LEADER", action = ws.switcher },
		{ key = "W", mods = "LEADER|SHIFT", action = ws.create },
		{ key = "]", mods = "LEADER", action = act.SwitchWorkspaceRelative(1) },
		{ key = "[", mods = "LEADER", action = act.SwitchWorkspaceRelative(-1) },

		-- session: lưu / khôi phục / xoá (thủ công, không tự động lưu)
		{ key = "S", mods = "LEADER|SHIFT", action = sessions.save },
		{ key = "R", mods = "LEADER|SHIFT", action = sessions.restore },
		{ key = "D", mods = "LEADER|SHIFT", action = sessions.delete },

		-- pane
		{ key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "|", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "\\", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "o", mods = "LEADER", action = act.RotatePanes("Clockwise") },
		{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
		{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
		{ key = "p", mods = "LEADER", action = act.PaneSelect({ alphabet = "asdfghjkl" }) },
		{ key = "s", mods = "LEADER", action = act.PaneSelect({ mode = "SwapWithActive", alphabet = "asdfghjkl" }) },

		-- tab / tiện ích
		{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
		{ key = ",", mods = "LEADER", action = ws.rename_tab },
		{ key = "f", mods = "LEADER", action = act.Search({ CaseInSensitiveString = "" }) },
		{ key = "k", mods = "LEADER", action = act.ActivateCommandPalette },
		{
			key = "l",
			mods = "LEADER",
			action = act.ShowLauncherArgs({ flags = "FUZZY|LAUNCH_MENU_ITEMS|DOMAINS|WORKSPACES" }),
		},
		{ key = "u", mods = "LEADER", action = act.CharSelect({ copy_on_select = true }) },
		{ key = "t", mods = "LEADER", action = theme_picker.pick },

		-- vào chế độ resize
		{
			key = "r",
			mods = "LEADER",
			action = act.ActivateKeyTable({ name = "resize", one_shot = false, timeout_milliseconds = 4000 }),
		},
	}

	------------------------------------------------------------------
	-- KEY TABLE: resize (Ctrl+A r rồi hjkl / mũi tên, Esc để thoát)
	------------------------------------------------------------------
	config.key_tables = {
		resize = {
			{ key = "h", action = act.AdjustPaneSize({ "Left", 3 }) },
			{ key = "l", action = act.AdjustPaneSize({ "Right", 3 }) },
			{ key = "k", action = act.AdjustPaneSize({ "Up", 2 }) },
			{ key = "j", action = act.AdjustPaneSize({ "Down", 2 }) },
			{ key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 3 }) },
			{ key = "RightArrow", action = act.AdjustPaneSize({ "Right", 3 }) },
			{ key = "UpArrow", action = act.AdjustPaneSize({ "Up", 2 }) },
			{ key = "DownArrow", action = act.AdjustPaneSize({ "Down", 2 }) },
			{ key = "Escape", action = act.PopKeyTable },
			{ key = "Enter", action = act.PopKeyTable },
			{ key = "q", action = act.PopKeyTable },
		},
	}

	------------------------------------------------------------------
	-- CHUỘT
	------------------------------------------------------------------
	config.mouse_bindings = {
		-- Ctrl+Click mở link
		{
			event = { Up = { streak = 1, button = "Left" } },
			mods = "CTRL",
			action = act.OpenLinkAtMouseCursor,
		},
		-- không gửi click xuống chương trình khi đang Ctrl+Click
		{
			event = { Down = { streak = 1, button = "Left" } },
			mods = "CTRL",
			action = act.Nop,
		},
		-- Chuột phải = paste
		{
			event = { Down = { streak = 1, button = "Right" } },
			mods = "NONE",
			action = act.PasteFrom("Clipboard"),
		},
	}
end

return M
