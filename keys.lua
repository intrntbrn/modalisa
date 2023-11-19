local modalisa = require("modalisa")
local util = require("modalisa.util")

local sys = require("modalisa.presets.sys")
local awm = require("modalisa.presets.awesome")
local c = require("modalisa.presets.client")
local t = require("modalisa.presets.tag")
local sp = require("modalisa.presets.spawn")
local s = require("modalisa.presets.screen")

local M = {}

-- NOTE:
-- presets can be overwritten (deep extended) by using the + operator

local keys = {
	[","] = nil,
	[";"] = nil,
	["y"] = nil,
	["q"] = nil,
	["g"] = nil,
	["v"] = nil,
	["d"] = nil,
	["'"] = nil,

	-- interactive configuration of modalisa
	["i"] = require("modalisa.presets.modalisa").generate() + {
		highlight = { desc = { fg = "#7DCFFF", bold = true, italic = true } },
		opts = { hints = { enabled = true }, mode = "forever" },
	},

	-- spawn menu example
	["x"] = { desc = "execute", group = "menu.execute" },
	["xw"] = sp.spawn("wezterm"),
	["xa"] = sp.spawn("alacritty"),
	["xx"] = sp.spawn("xterm"),
	["xk"] = sp.spawn("kitty"),
	["xt"] = sp.spawn("thunar"),
	["xg"] = sp.spawn_with_shell("chromium || google-chrome-stable") + { desc = "google chrome" },
	["xf"] = sp.spawn("firefox"),
	["xq"] = sp.spawn("qutebrowser"),
	["xb"] = sp.spawn("brave"),
	["xr"] = sp.spawn("arandr"),
	["xp"] = sp.spawn("pavucontrol"),
	["xc"] = sp.spawn("code"),
	["xi"] = sp.spawn("gimp"),
	["xd"] = sp.spawn("discord"),
	["xs"] = sp.spawn("steam"),

	-- root
	["Q"] = c.kill(),
	["h"] = c.focus_dir("left"),
	["j"] = c.focus_dir("down"),
	["k"] = c.focus_dir("up"),
	["l"] = c.focus_dir("right"),
	["H"] = c.move_dir_smart("left"),
	["J"] = c.move_dir_smart("down"),
	["K"] = c.move_dir_smart("up"),
	["L"] = c.move_dir_smart("right"),

	["<C-h>"] = s.focus_direction("left"),
	["<C-j>"] = s.focus_direction("down"),
	["<C-k>"] = s.focus_direction("up"),
	["<C-l>"] = s.focus_direction("right"),

	["<Left>"] = c.resize_smart("left"),
	["<Down>"] = c.resize_smart("down"),
	["<Up>"] = c.resize_smart("up"),
	["<Right>"] = c.resize_smart("right"),
	["<S-Left>"] = c.size_decrease_floating("left"),
	["<S-Down>"] = c.size_decrease_floating("down"),
	["<S-Up>"] = c.size_decrease_floating("up"),
	["<S-Right>"] = c.size_decrease_floating("right"),

	["<"] = t.column_count_decrease() + { continue = true },
	[">"] = t.column_count_increase() + { continue = true },
	["+"] = t.master_count_increase() + { continue = true },
	["-"] = t.master_count_decrease() + { continue = true },
	["]"] = t.master_width_increase() + { continue = true },
	["["] = t.master_width_decrease() + { continue = true },

	["1"] = t.view_only_index(1) + { hidden = false },
	["2"] = t.view_only_index(2) + { hidden = false },
	["3"] = t.view_only_index(3) + { hidden = false },
	["4"] = t.view_only_index(4) + { hidden = false },
	["5"] = t.view_only_index(5) + { hidden = false },
	["6"] = t.view_only_index(6) + { hidden = false },
	["7"] = t.view_only_index(7) + { hidden = false },
	["8"] = t.view_only_index(8) + { hidden = false },
	["9"] = t.view_only_index(9) + { hidden = false },
	["0"] = t.view_only_index(10) + { hidden = false },

	["z"] = s.focus_picker(),
	[" "] = c.select_picker(true) + { opts = { labels = util.labels_qwerty } },
	["w"] = c.swap_picker() + { opts = { labels = util.labels_qwerty } },
	["s"] = c.swap_master_smart() + { opts = { labels = util.labels_qwerty } },
	["f"] = c.toggle_property("fullscreen", nil, true, "client"),
	["m"] = c.toggle_property("maximized", nil, true, "client"),
	["n"] = c.minimize(),
	["u"] = c.unminimize_menu(false)
		+ { opts = { hints = { enabled = true, delay = 0 }, labels = util.labels_qwerty } },
	["<Tab>"] = c.focus_prev(),

	-- apps
	["<Return>"] = sp.terminal(),
	["b"] = sp.browser(),
	["o"] = sp.appmenu(),

	-- awesome
	["a"] = { desc = "awesome", group = "menu.awesome" },
	["aQ"] = awm.quit(),
	["aR"] = awm.restart(),
	["ax"] = awm.execute_lua(),
	["ar"] = awm.run_prompt(),
	["as"] = awm.help_popup(),
	["am"] = awm.menubar(),
	["at"] = awm.toggle_wibox(),
	["aw"] = awm.wallpaper_menu(2),
	["ap"] = awm.screen_padding_menu(),

	-- tag
	["t"] = { desc = "tag", group = "menu.tag" },
	["tD"] = t.delete(),
	["tr"] = t.rename(),
	["tn"] = t.new_tag(),
	["tN"] = t.new_tag_copy(),
	["tp"] = t.tag_toggle_policy(),
	["tg"] = t.set_gap(),
	["tv"] = t.toggle_property("volatile"),
	["tG"] = t.toggle_property("gap_single_client"),
	["tt"] = t.tag_toggle_menu() + { opts = { hints = { enabled = true, delay = 0 } } },
	["ta"] = t.move_all_clients_to_tag_menu() + { opts = { hints = { enabled = true, delay = 0 } } },
	["ts"] = t.move_tag_to_screen_menu(),
	["t<Left>"] = t.view_previous() + { continue = true },
	["t<Right>"] = t.view_next() + { continue = true },
	["t<Tab>"] = t.view_last(),
	["t1"] = t.move_client_to_tag_index(1),
	["t2"] = t.move_client_to_tag_index(2),
	["t3"] = t.move_client_to_tag_index(3),
	["t4"] = t.move_client_to_tag_index(4),
	["t5"] = t.move_client_to_tag_index(5),
	["t6"] = t.move_client_to_tag_index(6),
	["t7"] = t.move_client_to_tag_index(7),
	["t8"] = t.move_client_to_tag_index(8),
	["t9"] = t.move_client_to_tag_index(9),
	["t0"] = t.move_client_to_tag_index(10),
	["tJ"] = t.layout_prev() + { continue = true },
	["tK"] = t.layout_next() + { continue = true },
	["t "] = t.layout_select_menu() + { opts = { labels = util.labels_qwerty } },
	["tk"] = t.master_width_increase() + { continue = true },
	["tj"] = t.master_width_decrease() + { continue = true },
	["tl"] = t.master_count_increase() + { continue = true },
	["th"] = t.master_count_decrease() + { continue = true },
	["tc"] = t.column_count_increase() + { continue = true },
	["tC"] = t.column_count_decrease() + { continue = true },

	-- client
	["c"] = { desc = "client", group = "menu.client" },
	["ct"] = c.toggle_tag_menu(),
	["cn"] = c.minimize(),
	["cf"] = c.toggle_property("fullscreen", nil, true),
	["cm"] = c.toggle_property("maximized", nil, true),
	["ch"] = c.toggle_property("maximized_horizontally", nil, true),
	["cv"] = c.toggle_property("maximized_vertically", nil, true),
	["c "] = c.toggle_property("floating"),
	["co"] = c.toggle_property("ontop"),
	["cy"] = c.toggle_property("sticky"),
	["ca"] = c.toggle_property("above"),
	["cb"] = c.toggle_property("below"),
	["cS"] = c.toggle_property("skip_taskbar"),
	["cU"] = c.toggle_property("urgent"),
	["cT"] = c.toggle_titlebar() + { desc = "titlebar toggle" },
	["cp"] = c.set_property("opacity") + { desc = "opacity" },
	["cw"] = c.set_property("border_width") + { desc = "border_width" },
	["cC"] = c.set_property("border_color") + { desc = "border_color" },
	["cu"] = c.unminimize_menu(false) + { desc = "unminize" },
	["c<Tab>"] = c.focus_prev(),
	["cc"] = c.swap_master_smart(),
	["c<Return>"] = c.move_to_master(),
	["cs"] = c.move_to_screen_menu(),
	["ck"] = c.kill() + { desc = "kill" },
	["cK"] = { desc = "kill signal", group = "client.kill" },
	["cKt"] = c.kill_signal("TERM"),
	["cKk"] = c.kill_signal("KILL"),
	["cKi"] = c.kill_signal("INT"),
	["cKq"] = c.kill_signal("QUIT"),
	["c1"] = t.move_client_to_tag_index(1),
	["c2"] = t.move_client_to_tag_index(2),
	["c3"] = t.move_client_to_tag_index(3),
	["c4"] = t.move_client_to_tag_index(4),
	["c5"] = t.move_client_to_tag_index(5),
	["c6"] = t.move_client_to_tag_index(6),
	["c7"] = t.move_client_to_tag_index(7),
	["c8"] = t.move_client_to_tag_index(8),
	["c9"] = t.move_client_to_tag_index(9),
	["c0"] = t.move_client_to_tag_index(10),

	-- resize floating
	["r"] = c.resize_floating(),
	["rf"] = { desc = "fix manual position" },
	["rfx"] = c.set_property("x") + { desc = "x coordinate" },
	["rfy"] = c.set_property("y") + { desc = "y coordinate" },
	["rfw"] = c.set_property("width") + { desc = "width" },
	["rfh"] = c.set_property("height") + { desc = "height" },
	["r "] = c.placement("no_offscreen"),
	["ro"] = c.placement("no_overlap"),
	["rt"] = { desc = "top placement", group = "placement.top", opts = {} },
	["rtt"] = c.placement("top"),
	["rth"] = c.placement("top_left"),
	["rtl"] = c.placement("top_right"),
	["rb"] = { desc = "bottom placement", group = "placement.bottom", opts = {} },
	["rbb"] = c.placement("bottom"),
	["rbh"] = c.placement("bottom_left"),
	["rbl"] = c.placement("bottom_right"),
	["rh"] = c.placement("left"),
	["rl"] = c.placement("right"),
	["rc"] = c.placement("centered"),
	["ru"] = c.placement("under_mouse"),
	["rm"] = { desc = "maximize placement", group = "placement.maximize", opts = {} },
	["rmm"] = c.placement("maximize"),
	["rmv"] = c.placement("maximize_vertically"),
	["rmh"] = c.placement("maximize_horizontally"),
	["rs"] = { desc = "stretch placement", group = "placement.stretch", opts = {} },
	["rsh"] = c.placement("stretch_left"),
	["rsj"] = c.placement("stretch_down"),
	["rsk"] = c.placement("stretch_up"),
	["rsl"] = c.placement("stretch_right"),
	["rj"] = c.resize_mode_floating() + { opts = { mode = "forever" }, desc = "decrease size" },
	["rjh"] = c.size_decrease_floating("left"),
	["rjj"] = c.size_decrease_floating("down"),
	["rjk"] = c.size_decrease_floating("up"),
	["rjl"] = c.size_decrease_floating("right"),
	["rk"] = c.resize_mode_floating() + { opts = { mode = "forever" }, desc = "increase size" },
	["rkh"] = c.size_decrease_floating("left"),
	["rkj"] = c.size_decrease_floating("down"),
	["rkk"] = c.size_decrease_floating("up"),
	["rkl"] = c.size_decrease_floating("right"),

	-- power menu
	["p"] = { desc = "power", opts = { hints = { enabled = true }, mode = "hybrid" } },
	["ps"] = sys.power_shutdown(),
	["pc"] = sys.power_shutdown_cancel(),
	["pt"] = sys.power_shutdown_timer(),
	["pr"] = sys.power_reboot(),
	["pu"] = sys.power_suspend(),

	-- audio (requires amixer and playerctl)
	["<XF86AudioRaiseVolume>"] = sys.volume_inc(5) + { desc = "volume raise", global = true },
	["<XF86AudioLowerVolume>"] = sys.volume_inc(-5) + { desc = "volume lower", global = true },
	["<XF86AudioMute>"] = sys.volume_mute_toggle() + { desc = "mute toggle", global = true },
	["<XF86AudioNext>"] = sys.audio_next() + { global = true },
	["<XF86AudioPrev>"] = sys.audio_prev() + { global = true },
	["<XF86AudioStop>"] = sys.audio_stop() + { global = true },
	["<XF86AudioPlay>"] = sys.audio_play_pause() + { global = true },

	-- brightness (requires xbacklight)
	["<XF86MonBrightnessUp>"] = sys.brightness_inc(10) + { desc = "brightness increase", global = true },
	["<XF86MonBrightnessDown>"] = sys.brightness_inc(-10) + { desc = "brightness decrease", global = true },
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
