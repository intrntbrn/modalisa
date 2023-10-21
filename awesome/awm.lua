local awful = require("awful")

local M = {}

function M.awesome_help()
	local hotkeys_popup = require("awful.hotkeys_popup")
	if hotkeys_popup then
		hotkeys_popup.show_help()
	end
end

function M.awesome_menubar()
	require("menubar").show()
end

function M.awesome_quit()
	awesome.quit()
end

function M.awesome_restart()
	awesome.restart()
end

function M.awesome_lua_prompt()
	if awful.screen.focused().mypromptbox then
		awful.prompt.run({
			prompt = "Run Lua code: ",
			textbox = awful.screen.focused().mypromptbox.widget,
			exe_callback = awful.util.eval,
			history_path = awful.util.get_cache_dir() .. "/history_eval",
		})
	end
end

function M.awesome_run_prompt()
	if awful.screen.focused().mypromptbox then
		awful.screen.focused().mypromptbox:run()
	end
end

return M
