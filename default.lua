local motion = require("motion")
local presets = require("motion.presets.awesome")
local util = require("motion.util")

local M = {}

function M.setup(opts)
	local keys = {
		-- root
		["h"] = presets.client_focus("left"),
		["j"] = presets.client_focus("down"),
		["k"] = presets.client_focus("up"),
		["l"] = presets.client_focus("right"),
		["H"] = presets.client_move_smart("left"),
		["J"] = presets.client_move_smart("down"),
		["K"] = presets.client_move_smart("up"),
		["L"] = presets.client_move_smart("right"),

		["<Left>"] = presets.client_resize_smart("left"),
		["<Down>"] = presets.client_resize_smart("down"),
		["<Up>"] = presets.client_resize_smart("up"),
		["<Right>"] = presets.client_resize_smart("right"),
		["<S-Left>"] = presets.client_floating_size_decrease("left"),
		["<S-Down>"] = presets.client_floating_size_decrease("down"),
		["<S-Up>"] = presets.client_floating_size_decrease("up"),
		["<S-Right>"] = presets.client_floating_size_decrease("right"),

		["<"] = presets.layout_column_count_decrease() + { opts = { continue = true } },
		[">"] = presets.layout_column_count_increase() + { opts = { continue = true } },
		["+"] = presets.layout_master_count_increase() + { opts = { continue = true } },
		["-"] = presets.layout_master_count_decrease() + { opts = { continue = true } },
		["]"] = presets.layout_master_width_increase() + { opts = { continue = true } },
		["["] = presets.layout_master_width_decrease() + { opts = { continue = true } },

		["1"] = presets.tag_view_only(1),
		["2"] = presets.tag_view_only(2),
		["3"] = presets.tag_view_only(3),
		["4"] = presets.tag_view_only(4),
		["5"] = presets.tag_view_only(5),
		["6"] = presets.tag_view_only(6),
		["7"] = presets.tag_view_only(7),
		["8"] = presets.tag_view_only(8),
		["9"] = presets.tag_view_only(9),
		["0"] = presets.tag_view_only(10),

		[" "] = presets.client_select_picker(true) + { opts = { hints_delay = 0 } },
		["w"] = presets.client_swap_picker(),
		["s"] = presets.client_swap_master_smart(),
		["f"] = presets.client_toggle_fullscreen(),
		["m"] = presets.client_toggle_maximize(),
		["n"] = presets.client_minimize(),
		["u"] = presets.client_unminimize_menu() + { opts = { hints_delay = 0 } },
		["<Tab>"] = presets.client_focus_prev(),

		["<Return>"] = presets.spawn_terminal(),
		["b"] = presets.spawn_browser(),
		["o"] = presets.spawn_appmenu(),

		-- awesome
		["a"] = { desc = "awesome", opts = { group = "awesome" } },
		["aQ"] = presets.awesome_quit(),
		["aR"] = presets.awesome_restart(),
		["ax"] = presets.awesome_execute(),
		["ar"] = presets.awesome_run_prompt(),
		["as"] = presets.awesome_help(),
		["ap"] = presets.awesome_menubar(),

		-- tag
		["t"] = { desc = "tag", opts = { group = "tag" } },
		["tD"] = presets.tag_delete(),
		["tr"] = { desc = "rename tag" }, -- TODO
		["tn"] = { desc = "new tag" }, -- TODO
		["tp"] = presets.tag_toggle_policy(),
		["tt"] = presets.tag_toggle_menu() + { hints_delay = 0 },
		["ta"] = presets.tag_move_all_clients_to_tag_menu() + { opts = { hints_delay = 0 } },
		["t<Left>"] = presets.tag_previous(),
		["t<Right>"] = presets.tag_next(),
		["t<Tab>"] = presets.tag_last(),
		["t1"] = presets.tag_move_focused_client_to_tag(1),
		["t2"] = presets.tag_move_focused_client_to_tag(2),
		["t3"] = presets.tag_move_focused_client_to_tag(3),
		["t4"] = presets.tag_move_focused_client_to_tag(4),
		["t5"] = presets.tag_move_focused_client_to_tag(5),
		["t6"] = presets.tag_move_focused_client_to_tag(6),
		["t7"] = presets.tag_move_focused_client_to_tag(7),
		["t8"] = presets.tag_move_focused_client_to_tag(8),
		["t9"] = presets.tag_move_focused_client_to_tag(9),
		["t0"] = presets.tag_move_focused_client_to_tag(10),

		-- layout
		["r"] = { desc = "layout", opts = { group = "layout" } },
		["r "] = presets.layout_select_menu() + { opts = { labels = util.labels_qwerty } },
		["r<Left>"] = presets.layout_prev(),
		["r<Right>"] = presets.layout_next(),
		["rk"] = presets.layout_master_width_increase(),
		["rj"] = presets.layout_master_width_decrease(),
		["rl"] = presets.layout_master_count_increase(),
		["rh"] = presets.layout_master_count_decrease(),
		["rL"] = presets.layout_column_count_increase(),
		["rH"] = presets.layout_column_count_decrease(),

		-- client
		["c"] = { desc = "client", opts = { group = "client" } },
		["ct"] = presets.client_toggle_tag_menu(),
		["cf"] = presets.client_toggle_fullscreen(),
		["cm"] = presets.client_toggle_maximize(),
		["cn"] = presets.client_minimize(),
		["ch"] = presets.client_toggle_maximize_horizontally(),
		["cv"] = presets.client_toggle_maximize_vertically(),
		["cC"] = presets.client_kill(),
		["c "] = presets.client_toggle_floating(),
		["co"] = presets.client_toggle_ontop(),
		["cy"] = presets.client_toggle_sticky(),
		["cu"] = presets.client_unminimize_menu(),
		["cp"] = presets.client_focus_prev(),
		["c<Tab>"] = presets.client_swap_master_smart(),
		["c<Return>"] = presets.client_move_to_master(),
	}

	motion.add_keys(keys)
end

return setmetatable(M, {
	__call = function(_, ...)
		return M.setup(...)
	end,
})
