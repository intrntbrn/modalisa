local motion = require("motion")
local wm = require("motion.wm")

local M = {}

function M.setup(opts)
	local keys = {
		-- root
		["h"] = wm.client_focus("left"),
		["j"] = wm.client_focus("down"),
		["k"] = wm.client_focus("up"),
		["l"] = wm.client_focus("right"),
		["H"] = wm.client_move_smart("left"),
		["J"] = wm.client_move_smart("down"),
		["K"] = wm.client_move_smart("up"),
		["L"] = wm.client_move_smart("right"),

		["<Left>"] = wm.client_resize_smart("left"),
		["<Down>"] = wm.client_resize_smart("down"),
		["<Up>"] = wm.client_resize_smart("up"),
		["<Right>"] = wm.client_resize_smart("right"),
		["<S-Left>"] = wm.client_floating_size_decrease("left"),
		["<S-Down>"] = wm.client_floating_size_decrease("down"),
		["<S-Up>"] = wm.client_floating_size_decrease("up"),
		["<S-Right>"] = wm.client_floating_size_decrease("right"),

		["<"] = wm.layout_column_count_decrease(),
		[">"] = wm.layout_column_count_increase(),
		["+"] = wm.layout_master_count_increase(),
		["-"] = wm.layout_master_count_decrease(),
		["]"] = wm.layout_master_width_increase(),
		["["] = wm.layout_master_width_decrease(),

		["1"] = wm.tag_view_only(1),
		["2"] = wm.tag_view_only(2),
		["3"] = wm.tag_view_only(3),
		["4"] = wm.tag_view_only(4),
		["5"] = wm.tag_view_only(5),
		["6"] = wm.tag_view_only(6),
		["7"] = wm.tag_view_only(7),
		["8"] = wm.tag_view_only(8),
		["9"] = wm.tag_view_only(9),
		["0"] = wm.tag_view_only(10),

		[" "] = wm.client_select_picker(true),
		["w"] = wm.client_swap_picker(),
		["s"] = wm.client_swap_master_smart(),
		["f"] = wm.client_toggle_fullscreen(),
		["m"] = wm.client_toggle_maximize(),
		["n"] = wm.client_minimize(),
		["u"] = wm.client_unminimize_menu(),
		["<Tab>"] = wm.client_focus_prev(),

		["<Return>"] = wm.spawn_terminal(),
		["b"] = wm.spawn_browser(),
		["o"] = wm.spawn_appmenu(),

		-- awesome
		["a"] = { desc = "awesome", opts = { group = "awesome", mod_release_stop = false } },
		["aQ"] = wm.awesome_quit(),
		["aR"] = wm.awesome_restart(),
		["ax"] = wm.awesome_execute(),
		["ar"] = wm.awesome_run_prompt(),
		["as"] = wm.awesome_help(),
		["ap"] = wm.awesome_menubar(),

		-- tag
		["t"] = { desc = "tag", opts = { group = "tag" } },
		["tD"] = wm.tag_delete(),
		["tr"] = { desc = "rename tag" }, -- TODO
		["tn"] = { desc = "new tag" }, -- TODO
		["tp"] = wm.tag_toggle_policy(),
		["tt"] = wm.tag_toggle_menu(),
		["ta"] = wm.tag_move_all_clients_to_tag_menu(),
		["t<Left>"] = wm.tag_previous(),
		["t<Right>"] = wm.tag_next(),
		["t<Tab>"] = wm.tag_last(),
		["t1"] = wm.tag_move_focused_client_to_tag(1),
		["t2"] = wm.tag_move_focused_client_to_tag(2),
		["t3"] = wm.tag_move_focused_client_to_tag(3),
		["t4"] = wm.tag_move_focused_client_to_tag(4),
		["t5"] = wm.tag_move_focused_client_to_tag(5),
		["t6"] = wm.tag_move_focused_client_to_tag(6),
		["t7"] = wm.tag_move_focused_client_to_tag(7),
		["t8"] = wm.tag_move_focused_client_to_tag(8),
		["t9"] = wm.tag_move_focused_client_to_tag(9),
		["t0"] = wm.tag_move_focused_client_to_tag(10),

		-- layout
		["r"] = { desc = "layout", opts = { group = "layout", labels = "asdfghjklqwertyuiopzxcvbnmqp" } },
		["r "] = wm.layout_select_menu(),
		["r<Left>"] = wm.layout_prev(),
		["r<Right>"] = wm.layout_next(),
		["rk"] = wm.layout_master_width_increase(),
		["rj"] = wm.layout_master_width_decrease(),
		["rl"] = wm.layout_master_count_increase(),
		["rh"] = wm.layout_master_count_decrease(),
		["rL"] = wm.layout_column_count_increase(),
		["rH"] = wm.layout_column_count_decrease(),

		-- client
		["c"] = { desc = "client", opts = { group = "client" } },
		["ct"] = wm.client_toggle_tag_menu(),
		["cf"] = wm.client_toggle_fullscreen(),
		["cm"] = wm.client_toggle_maximize(),
		["cn"] = wm.client_minimize(),
		["ch"] = wm.client_toggle_maximize_horizontally(),
		["cv"] = wm.client_toggle_maximize_vertically(),
		["cC"] = wm.client_kill(),
		["c "] = wm.client_toggle_floating(),
		["co"] = wm.client_toggle_ontop(),
		["cy"] = wm.client_toggle_sticky(),
		["cu"] = wm.client_unminimize_menu(),
		["cp"] = wm.client_focus_prev(),
		["c<Tab>"] = wm.client_swap_master_smart(),
		["c<Return>"] = wm.client_move_to_master(),
	}

	keys["u"].opts.hints_delay = 0
	keys[" "].opts.hints_delay = 0
	keys["tt"].opts.hints_delay = 0
	keys["ta"].opts.hints_delay = 0

	motion.add_keys(keys)
end

return setmetatable(M, {
	__call = function(_, ...)
		return M.setup(...)
	end,
})
