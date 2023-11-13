local modalisa = require("modalisa")
local psys = require("modalisa.presets.sys")
local util = require("modalisa.util")
local pawm = require("modalisa.presets.awesome")
local pclient = require("modalisa.presets.client")
local ptag = require("modalisa.presets.tag")
local playout = require("modalisa.presets.layout")
local pspawn = require("modalisa.presets.spawn")
local pscreen = require("modalisa.presets.screen")

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
	["xw"] = pspawn.spawn("wezterm"),
	["xa"] = pspawn.spawn("alacritty"),
	["xx"] = pspawn.spawn("xterm"),
	["xk"] = pspawn.spawn("kitty"),
	["xt"] = pspawn.spawn("thunar"),
	["xg"] = pspawn.spawn_with_shell("chromium || google-chrome-stable") + { desc = "google chrome" },
	["xf"] = pspawn.spawn("firefox"),
	["xq"] = pspawn.spawn("qutebrowser"),
	["xb"] = pspawn.spawn("brave"),
	["xr"] = pspawn.spawn("arandr"),
	["xp"] = pspawn.spawn("pavucontrol"),
	["xc"] = pspawn.spawn("code"),
	["xi"] = pspawn.spawn("gimp"),
	["xd"] = pspawn.spawn("discord"),
	["xs"] = pspawn.spawn("steam"),

	-- root
	["Q"] = pclient.client_kill(),
	["h"] = pclient.client_focus("left"),
	["j"] = pclient.client_focus("down"),
	["k"] = pclient.client_focus("up"),
	["l"] = pclient.client_focus("right"),
	["H"] = pclient.client_move_smart("left"),
	["J"] = pclient.client_move_smart("down"),
	["K"] = pclient.client_move_smart("up"),
	["L"] = pclient.client_move_smart("right"),

	["<C-h>"] = pscreen.focus_direction("left"),
	["<C-j>"] = pscreen.focus_direction("down"),
	["<C-k>"] = pscreen.focus_direction("up"),
	["<C-l>"] = pscreen.focus_direction("right"),

	["<Left>"] = pclient.client_resize_smart("left"),
	["<Down>"] = pclient.client_resize_smart("down"),
	["<Up>"] = pclient.client_resize_smart("up"),
	["<Right>"] = pclient.client_resize_smart("right"),
	["<S-Left>"] = pclient.client_floating_size_decrease("left"),
	["<S-Down>"] = pclient.client_floating_size_decrease("down"),
	["<S-Up>"] = pclient.client_floating_size_decrease("up"),
	["<S-Right>"] = pclient.client_floating_size_decrease("right"),

	["<"] = playout.layout_column_count_decrease() + { continue = true },
	[">"] = playout.layout_column_count_increase() + { continue = true },
	["+"] = playout.layout_master_count_increase() + { continue = true },
	["-"] = playout.layout_master_count_decrease() + { continue = true },
	["]"] = playout.layout_master_width_increase() + { continue = true },
	["["] = playout.layout_master_width_decrease() + { continue = true },

	["1"] = ptag.tag_view_only(1) + { hidden = false },
	["2"] = ptag.tag_view_only(2) + { hidden = false },
	["3"] = ptag.tag_view_only(3) + { hidden = false },
	["4"] = ptag.tag_view_only(4) + { hidden = false },
	["5"] = ptag.tag_view_only(5) + { hidden = false },
	["6"] = ptag.tag_view_only(6) + { hidden = false },
	["7"] = ptag.tag_view_only(7) + { hidden = false },
	["8"] = ptag.tag_view_only(8) + { hidden = false },
	["9"] = ptag.tag_view_only(9) + { hidden = false },
	["0"] = ptag.tag_view_only(10) + { hidden = false },

	[" "] = pclient.client_select_picker(true) + { opts = { labels = util.labels_qwerty } },
	["w"] = pclient.client_swap_picker(),
	["s"] = pclient.client_swap_master_smart() + { opts = { labels = util.labels_qwerty } },
	["f"] = pclient.client_toggle_property("fullscreen", nil, true),
	["m"] = pclient.client_toggle_property("maximized", nil, true),
	["n"] = pclient.client_minimize(),
	["u"] = pclient.client_unminimize_menu(false)
		+ { opts = { hints = { enabled = true, delay = 0 }, labels = util.labels_qwerty } },
	["<Tab>"] = pclient.client_focus_prev(),

	-- apps
	["<Return>"] = pspawn.spawn_terminal(),
	["b"] = pspawn.spawn_browser(),
	["o"] = pspawn.spawn_appmenu(),

	-- awesome
	["a"] = { desc = "awesome", group = "menu.awesome" },
	["aQ"] = pawm.awesome_quit(),
	["aR"] = pawm.awesome_restart(),
	["ax"] = pawm.awesome_execute(),
	["ar"] = pawm.awesome_run_prompt(),
	["as"] = pawm.awesome_help(),
	["ap"] = pawm.awesome_menubar(),
	["at"] = pawm.awesome_toggle_wibox(),
	["aw"] = pawm.awesome_wallpaper_menu(2),

	-- tag
	["t"] = { desc = "tag", group = "menu.tag" },
	["tD"] = ptag.tag_delete(),
	["tr"] = ptag.tag_rename(),
	["tn"] = ptag.tag_new(),
	["tN"] = ptag.tag_new_copy(),
	["tp"] = ptag.tag_toggle_policy(),
	["tv"] = ptag.tag_toggle_volatile(),
	["tg"] = ptag.tag_gap(),
	["tS"] = ptag.tag_toggle_gap_single_client(),
	["tt"] = ptag.tag_toggle_menu() + { opts = { hints = { enabled = true, delay = 0 } } },
	["ta"] = ptag.tag_move_all_clients_to_tag_menu() + { opts = { hints = { enabled = true, delay = 0 } } },
	["ts"] = ptag.move_tag_to_screen_menu(),
	["t<Left>"] = ptag.tag_previous() + { continue = true },
	["t<Right>"] = ptag.tag_next() + { continue = true },
	["t<Tab>"] = ptag.tag_last(),
	["t1"] = ptag.tag_move_focused_client_to_tag(1),
	["t2"] = ptag.tag_move_focused_client_to_tag(2),
	["t3"] = ptag.tag_move_focused_client_to_tag(3),
	["t4"] = ptag.tag_move_focused_client_to_tag(4),
	["t5"] = ptag.tag_move_focused_client_to_tag(5),
	["t6"] = ptag.tag_move_focused_client_to_tag(6),
	["t7"] = ptag.tag_move_focused_client_to_tag(7),
	["t8"] = ptag.tag_move_focused_client_to_tag(8),
	["t9"] = ptag.tag_move_focused_client_to_tag(9),
	["t0"] = ptag.tag_move_focused_client_to_tag(10),
	["t "] = playout.layout_select_menu() + { opts = { labels = util.labels_qwerty } },
	["tk"] = playout.layout_master_width_increase() + { continue = true },
	["tj"] = playout.layout_master_width_decrease() + { continue = true },
	["tl"] = playout.layout_master_count_increase() + { continue = true },
	["th"] = playout.layout_master_count_decrease() + { continue = true },
	["tc"] = playout.layout_column_count_increase() + { continue = true },
	["tC"] = playout.layout_column_count_decrease() + { continue = true },

	-- client
	["c"] = { desc = "client", group = "menu.client" },
	["ct"] = pclient.client_toggle_tag_menu(),
	["cn"] = pclient.client_minimize(),
	["cf"] = pclient.client_toggle_property("fullscreen", nil, true),
	["cm"] = pclient.client_toggle_property("maximized", nil, true),
	["ch"] = pclient.client_toggle_property("maximized_horizontally", nil, true),
	["cv"] = pclient.client_toggle_property("maximized_vertically", nil, true),
	["c "] = pclient.client_toggle_property("floating"),
	["co"] = pclient.client_toggle_property("ontop"),
	["cy"] = pclient.client_toggle_property("sticky"),
	["ca"] = pclient.client_toggle_property("above"),
	["cb"] = pclient.client_toggle_property("below"),
	["cS"] = pclient.client_toggle_property("skip_taskbar"),
	["cU"] = pclient.client_toggle_property("urgent"),
	["cT"] = pclient.client_toggle_titlebar() + { desc = "titlebar toggle" },
	["cp"] = pclient.client_set_property("opacity") + { desc = "opacity" },
	["cw"] = pclient.client_set_property("border_width") + { desc = "border_width" },
	["cC"] = pclient.client_set_property("border_color") + { desc = "border_color" },
	["ck"] = pclient.client_kill() + { desc = "kill" },
	["cu"] = pclient.client_unminimize_menu(false) + { desc = "unminize" },
	["c<Tab>"] = pclient.client_focus_prev(),
	["cc"] = pclient.client_swap_master_smart(),
	["c<Return>"] = pclient.client_move_to_master(),
	["cs"] = pclient.move_to_screen_menu(),

	-- resize floating
	["r"] = pclient.client_resize_floating(),
	["rf"] = { desc = "fix manual position" },
	["rfx"] = pclient.client_set_property("x") + { desc = "x coordinate" },
	["rfy"] = pclient.client_set_property("y") + { desc = "y coordinate" },
	["rfw"] = pclient.client_set_property("width") + { desc = "width" },
	["rfh"] = pclient.client_set_property("height") + { desc = "height" },
	["r "] = pclient.client_placement("no_offscreen"),
	["ro"] = pclient.client_placement("no_overlap"),
	["rt"] = { desc = "top placement", group = "placement.top", opts = {} },
	["rtt"] = pclient.client_placement("top"),
	["rth"] = pclient.client_placement("top_left"),
	["rtl"] = pclient.client_placement("top_right"),
	["rb"] = { desc = "bottom placement", group = "placement.bottom", opts = {} },
	["rbb"] = pclient.client_placement("bottom"),
	["rbh"] = pclient.client_placement("bottom_left"),
	["rbl"] = pclient.client_placement("bottom_right"),
	["rh"] = pclient.client_placement("left"),
	["rl"] = pclient.client_placement("right"),
	["rc"] = pclient.client_placement("centered"),
	["ru"] = pclient.client_placement("under_mouse"),
	["rm"] = { desc = "maximize placement", group = "placement.maximize", opts = {} },
	["rmm"] = pclient.client_placement("maximize"),
	["rmv"] = pclient.client_placement("maximize_vertically"),
	["rmh"] = pclient.client_placement("maximize_horizontally"),
	["rs"] = { desc = "stretch placement", group = "placement.stretch", opts = {} },
	["rsh"] = pclient.client_placement("stretch_left"),
	["rsj"] = pclient.client_placement("stretch_down"),
	["rsk"] = pclient.client_placement("stretch_up"),
	["rsl"] = pclient.client_placement("stretch_right"),
	["rj"] = pclient.client_resize_mode_floating() + { opts = { mode = "forever" }, desc = "decrease size" },
	["rjh"] = pclient.client_floating_size_decrease("left"),
	["rjj"] = pclient.client_floating_size_decrease("down"),
	["rjk"] = pclient.client_floating_size_decrease("up"),
	["rjl"] = pclient.client_floating_size_decrease("right"),
	["rk"] = pclient.client_resize_mode_floating() + { opts = { mode = "forever" }, desc = "increase size" },
	["rkh"] = pclient.client_floating_size_increase("left"),
	["rkj"] = pclient.client_floating_size_increase("down"),
	["rkk"] = pclient.client_floating_size_increase("up"),
	["rkl"] = pclient.client_floating_size_increase("right"),

	-- power menu
	["p"] = { desc = "power", opts = { hints = { enabled = true }, mode = "hybrid" } },
	["ps"] = psys.power_shutdown(),
	["pc"] = psys.power_shutdown_cancel(),
	["pt"] = psys.power_shutdown_timer(),
	["pr"] = psys.power_reboot(),
	["pu"] = psys.power_suspend(),

	-- audio (requires amixer and playerctl)
	["<XF86AudioRaiseVolume>"] = psys.volume_inc(5) + { desc = "volume raise", global = true },
	["<XF86AudioLowerVolume>"] = psys.volume_inc(-5) + { desc = "volume lower", global = true },
	["<XF86AudioMute>"] = psys.volume_mute_toggle() + { desc = "mute toggle", global = true },
	["<XF86AudioNext>"] = psys.audio_next() + { global = true },
	["<XF86AudioPrev>"] = psys.audio_prev() + { global = true },
	["<XF86AudioStop>"] = psys.audio_stop() + { global = true },
	["<XF86AudioPause>"] = psys.audio_play_pause() + { global = true },

	-- brightness (requires xbacklight)
	["<XF86MonBrightnessUp>"] = psys.brightness_inc(10) + { desc = "brightness increase", global = true },
	["<XF86MonBrightnessDown>"] = psys.brightness_inc(-10) + { desc = "brightness decrease", global = true },
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
