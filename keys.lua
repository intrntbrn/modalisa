local modalisa = require("modalisa")
local ps = require("modalisa.presets.awesome")
local pss = require("modalisa.presets.sys")
local util = require("modalisa.util")

local M = {}

-- NOTE:
-- presets can be overwritten by using the + operator

local keys = {
	["."] = nil,
	[","] = nil,
	[";"] = nil,
	["y"] = nil,
	["q"] = nil,
	["g"] = nil,
	["v"] = nil,
	["d"] = nil,
	["z"] = nil,
	["'"] = nil,

	-- interactive configuration of modalisa
	["i"] = require("modalisa.presets.modalisa").generate() + {
		highlight = { desc = { fg = "#7DCFFF", bold = true, italic = true } },
		opts = { hints = { enabled = true }, mode = "forever" },
	},

	-- spawn menu example
	["x"] = { desc = "execute", group = "menu.execute" },
	["xw"] = ps.spawn("wezterm"),
	["xa"] = ps.spawn("alacritty"),
	["xx"] = ps.spawn("xterm"),
	["xk"] = ps.spawn("kitty"),
	["xt"] = ps.spawn("thunar"),
	["xg"] = ps.spawn_with_shell("chromium || google-chrome-stable") + { desc = "google chrome" },
	["xf"] = ps.spawn("firefox"),
	["xq"] = ps.spawn("qutebrowser"),
	["xb"] = ps.spawn("brave"),
	["xr"] = ps.spawn("arandr"),
	["xp"] = ps.spawn("pavucontrol"),
	["xc"] = ps.spawn("code"),
	["xi"] = ps.spawn("gimp"),
	["xd"] = ps.spawn("discord"),
	["xs"] = ps.spawn("steam"),

	-- root
	["h"] = ps.client_focus("left"),
	["j"] = ps.client_focus("down"),
	["k"] = ps.client_focus("up"),
	["l"] = ps.client_focus("right"),
	["H"] = ps.client_move_smart("left"),
	["J"] = ps.client_move_smart("down"),
	["K"] = ps.client_move_smart("up"),
	["L"] = ps.client_move_smart("right"),

	["<Left>"] = ps.client_resize_smart("left"),
	["<Down>"] = ps.client_resize_smart("down"),
	["<Up>"] = ps.client_resize_smart("up"),
	["<Right>"] = ps.client_resize_smart("right"),
	["<S-Left>"] = ps.client_floating_size_decrease("left"),
	["<S-Down>"] = ps.client_floating_size_decrease("down"),
	["<S-Up>"] = ps.client_floating_size_decrease("up"),
	["<S-Right>"] = ps.client_floating_size_decrease("right"),

	["<"] = ps.layout_column_count_decrease() + { continue = true },
	[">"] = ps.layout_column_count_increase() + { continue = true },
	["+"] = ps.layout_master_count_increase() + { continue = true },
	["-"] = ps.layout_master_count_decrease() + { continue = true },
	["]"] = ps.layout_master_width_increase() + { continue = true },
	["["] = ps.layout_master_width_decrease() + { continue = true },

	["1"] = ps.tag_view_only(1) + { hidden = false },
	["2"] = ps.tag_view_only(2) + { hidden = false },
	["3"] = ps.tag_view_only(3) + { hidden = false },
	["4"] = ps.tag_view_only(4) + { hidden = false },
	["5"] = ps.tag_view_only(5) + { hidden = false },
	["6"] = ps.tag_view_only(6) + { hidden = false },
	["7"] = ps.tag_view_only(7) + { hidden = false },
	["8"] = ps.tag_view_only(8) + { hidden = false },
	["9"] = ps.tag_view_only(9) + { hidden = false },
	["0"] = ps.tag_view_only(10) + { hidden = false },

	[" "] = ps.client_select_picker(true) + { opts = { labels = util.labels_qwerty } },
	["w"] = ps.client_swap_picker(),
	["s"] = ps.client_swap_master_smart() + { opts = { labels = util.labels_qwerty } },
	["f"] = ps.client_focus_toggle_fullscreen(),
	["m"] = ps.client_focus_toggle_maximize(),
	["n"] = ps.client_focus_minimize(),
	["u"] = ps.client_unminimize_menu(false) + { opts = { hints = { delay = 0 }, labels = util.labels_qwerty } },
	["<Tab>"] = ps.client_focus_prev(),

	-- apps
	["<Return>"] = ps.spawn_terminal(),
	["b"] = ps.spawn_browser(),
	["o"] = ps.spawn_appmenu(),

	-- awesome
	["a"] = { desc = "awesome", group = "menu.awesome" },
	["aQ"] = ps.awesome_quit(),
	["aR"] = ps.awesome_restart(),
	["ax"] = ps.awesome_execute(),
	["ar"] = ps.awesome_run_prompt(),
	["as"] = ps.awesome_help(),
	["ap"] = ps.awesome_menubar(),

	-- tag
	["t"] = { desc = "tag", group = "menu.tag" },
	["tD"] = ps.tag_delete(),
	["tr"] = ps.tag_rename(),
	["tn"] = ps.tag_new(),
	["tN"] = ps.tag_new_copy(),
	["tp"] = ps.tag_toggle_policy(),
	["tv"] = ps.tag_toggle_volatile(),
	["tg"] = ps.tag_gap(),
	["ts"] = ps.tag_toggle_gap_single_client(),
	["tt"] = ps.tag_toggle_menu() + { opts = { hints = { enabled = true, delay = 0 } } },
	["ta"] = ps.tag_move_all_clients_to_tag_menu() + { opts = { hints = { enabled = true, delay = 0 } } },
	["t<Left>"] = ps.tag_previous() + { continue = true },
	["t<Right>"] = ps.tag_next() + { continue = true },
	["t<Tab>"] = ps.tag_last(),
	["t1"] = ps.tag_move_focused_client_to_tag(1),
	["t2"] = ps.tag_move_focused_client_to_tag(2),
	["t3"] = ps.tag_move_focused_client_to_tag(3),
	["t4"] = ps.tag_move_focused_client_to_tag(4),
	["t5"] = ps.tag_move_focused_client_to_tag(5),
	["t6"] = ps.tag_move_focused_client_to_tag(6),
	["t7"] = ps.tag_move_focused_client_to_tag(7),
	["t8"] = ps.tag_move_focused_client_to_tag(8),
	["t9"] = ps.tag_move_focused_client_to_tag(9),
	["t0"] = ps.tag_move_focused_client_to_tag(10),
	["t "] = ps.layout_select_menu() + { opts = { labels = util.labels_qwerty } },
	["tk"] = ps.layout_master_width_increase() + { continue = true },
	["tj"] = ps.layout_master_width_decrease() + { continue = true },
	["tl"] = ps.layout_master_count_increase() + { continue = true },
	["th"] = ps.layout_master_count_decrease() + { continue = true },
	["tc"] = ps.layout_column_count_increase() + { continue = true },
	["tC"] = ps.layout_column_count_decrease() + { continue = true },

	-- client
	["c"] = { desc = "client", group = "menu.client" },
	["ct"] = ps.client_toggle_tag_menu(),
	["cf"] = ps.client_focus_toggle_fullscreen(),
	["cm"] = ps.client_focus_toggle_maximize(),
	["cn"] = ps.client_focus_minimize(),
	["ch"] = ps.client_focus_toggle_maximize_horizontally(),
	["cv"] = ps.client_focus_toggle_maximize_vertically(),
	["cC"] = ps.client_focus_kill(),
	["c "] = ps.client_focus_toggle_floating(),
	["co"] = ps.client_focus_toggle_ontop(),
	["cy"] = ps.client_focus_toggle_sticky(),
	["cu"] = ps.client_unminimize_menu(false),
	["cp"] = ps.client_focus_prev(),
	["c<Tab>"] = ps.client_swap_master_smart(),
	["c<Return>"] = ps.client_move_to_master(),

	-- resize floating
	["r"] = ps.client_resize_floating(),
	["r "] = ps.client_placement("no_offscreen"),
	["ro"] = ps.client_placement("no_overlap"),
	["rt"] = { desc = "top placement", group = "placement.top", opts = {} },
	["rtt"] = ps.client_placement("top"),
	["rth"] = ps.client_placement("top_left"),
	["rtl"] = ps.client_placement("top_right"),
	["rb"] = { desc = "bottom placement", group = "placement.bottom", opts = {} },
	["rbb"] = ps.client_placement("bottom"),
	["rbh"] = ps.client_placement("bottom_left"),
	["rbl"] = ps.client_placement("bottom_right"),
	["rh"] = ps.client_placement("left"),
	["rl"] = ps.client_placement("right"),
	["rc"] = ps.client_placement("centered"),
	["ru"] = ps.client_placement("under_mouse"),
	["rm"] = { desc = "maximize placement", group = "placement.maximize", opts = {} },
	["rmm"] = ps.client_placement("maximize"),
	["rmv"] = ps.client_placement("maximize_vertically"),
	["rmh"] = ps.client_placement("maximize_horizontally"),
	["rs"] = { desc = "stretch placement", group = "placement.stretch", opts = {} },
	["rsh"] = ps.client_placement("stretch_left"),
	["rsj"] = ps.client_placement("stretch_down"),
	["rsk"] = ps.client_placement("stretch_up"),
	["rsl"] = ps.client_placement("stretch_right"),
	["rj"] = ps.client_resize_mode_floating() + { opts = { mode = "forever" }, desc = "decrease size" },
	["rjh"] = ps.client_floating_size_decrease("left"),
	["rjj"] = ps.client_floating_size_decrease("down"),
	["rjk"] = ps.client_floating_size_decrease("up"),
	["rjl"] = ps.client_floating_size_decrease("right"),
	["rk"] = ps.client_resize_mode_floating() + { opts = { mode = "forever" }, desc = "increase size" },
	["rkh"] = ps.client_floating_size_increase("left"),
	["rkj"] = ps.client_floating_size_increase("down"),
	["rkk"] = ps.client_floating_size_increase("up"),
	["rkl"] = ps.client_floating_size_increase("right"),

	-- power menu
	["p"] = { desc = "power", opts = { hints = { enabled = true }, mode = "hybrid" } },
	["ps"] = pss.power_shutdown(),
	["pc"] = pss.power_shutdown_cancel(),
	["pt"] = pss.power_shutdown_timer(),
	["pr"] = pss.power_reboot(),
	["pu"] = pss.power_suspend(),

	-- audio (requires amixer and playerctl)
	["<XF86AudioRaiseVolume>"] = pss.volume_inc(5) + { desc = "volume raise", global = true },
	["<XF86AudioLowerVolume>"] = pss.volume_inc(-5) + { desc = "volume lower", global = true },
	["<XF86AudioMute>"] = pss.volume_mute_toggle() + { desc = "mute toggle", global = true },
	["<XF86AudioNext>"] = pss.audio_next() + { global = true },
	["<XF86AudioPrev>"] = pss.audio_prev() + { global = true },
	["<XF86AudioStop>"] = pss.audio_stop() + { global = true },
	["<XF86AudioPause>"] = pss.audio_play_pause() + { global = true },

	-- brightness (requires xbacklight)
	["<XF86MonBrightnessUp>"] = pss.brightness_inc(10) + { desc = "brightness increase", global = true },
	["<XF86MonBrightnessDown>"] = pss.brightness_inc(-10) + { desc = "brightness decrease", global = true },
}

function M.get_keys()
	return keys
end

function M.setup(_)
	modalisa.add_keys(keys)
end

return setmetatable(M, {
	__call = function(_, ...)
		return M.setup(...)
	end,
	__index = function(_, k)
		return keys[k]
	end,
})
