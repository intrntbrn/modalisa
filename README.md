# ⌨️ modalisa 🎨

`modalisa` is a hybrid modal keymap framework for awesomewm.
It comes with a preconfigured keymap that includes all default awesomewm
controls (and a lot more), but can also be used for all kinds of applications.
It is designed to combine best of both traditional and modal input modes while
also looking pretty.

Traditional input modes, such as default awesomewm, often require
complex keymaps that involve pressing multiple modifiers simultaneously
due to limited keyspace. Additionally, users have to rely on their memory or
unpractical cheatsheets as there are no key suggestions while typing.
On the other hand, modal input modes allow for easy entry of key sequences
but can become cumbersome when repeating actions. Users either have to
repeat the entire sequence or specify a count beforehand, making the process
inefficient.

`modalisa` addresses these shortcomings by keeping track of modifier states to
provide a set of distinct input modes that can be tailored exactly to the user's
needs for each key and at every stage of the sequence individually.
It allows for traditional keybinds for common operations that can be repeated by holding
down the modifier, while also enabling users to tap the modifier (like a
leader key) to enter modal mode followed by a key sequence for less common
commands. This flexibility makes it possible to transition into a more modal-esque
keymap gradually without having to relearn most of the awesomewm controls.

## ✨ Features

- 🪄 input modes: modal, hold, hybrid, forever
- 💥 which key hints (clickable)
- 🌳 keymap trees with property inheritance
- 🌐 define options for every key individually
- 💄 ui building blocks (prompt, echo, labels)
- 🪟 preconfigured awesomewm and system controls
- 🧙 define keys with vim syntax
- ♿ easy and intuitive configuration
- 📡 highly extensible

## 💡 Example

```
{
	["t"] = { desc = "tag", opts = { mode = "hybrid", hints = { enabled = true } } },
	-- opts are inherited from predecessor t
	["t<Tab>"] = {
		desc = "view last tag",
		function(opts)
			awful.tag.history.restore()
		end,
	},
	["tD"] = {
		desc = "delete current tag",
		opts = { hints = { placement = "centered" } },
		cond = function()
			return awful.screen.focused().selected_tag.index > 1
		end,
		fn = function(opts)
			local dynamic_menu = {
				y = {
					desc = function()
						return "yes, delete tag " .. awful.screen.focused().selected_tag.index
					end,
					highlight = { bg = "#FF0000", desc = { bold = true } },
					function(opts)
						awful.screen.focused().selected_tag:delete()
					end,
				},
				n = { desc = "no, cancel delete" },
			}
			return dynamic_menu
		end,
	},
}
```

## 📋 Requirements

- awesome-git
- nerd-font (optional)

## 📦 Installation

1. Clone the repo:

`git clone https://github.com/intrntbrn/modalisa ~/.config/awesome/modalisa`

2. Import and configure the module in `rc.lua`:

```lua
-- NOTE:
-- modalisa is designed to be used in conjunction with a modifier as the leader
-- key (e.g. Super_L), but this prevents all current keybinds utilizing
-- that modifier from functioning.
require("modalisa").setup({
	-- root_keys = { "<M-a>" }, -- "Mod4" + "a"
	root_keys = { "<Super_L>" }, -- or "<Alt_L>"
	back_keys = { "<BackSpace>" },
	stop_keys = { "<Escape>" },
	mode = "hybrid",
	include_default_keys = true,
})
```

### Create your own keymap

1. Copy the default keymap `keys.lua` as `modalisa_keys.lua` into the home awesomewm directory:

`cp ~/.config/awesome/modalisa/keys.lua ~/.config/awesome/modalisa_keys.lua`

2. Disable the default keymap by setting `include_default_keys = false`

3. Edit the copy. The keymap will be imported automatically.

## ⚙️ Configuration

```
{
	-- keys
	root_keys = { "<M-a>" },
	back_keys = { "<BackSpace>" },
	stop_keys = { "<Escape>" },
	include_default_keys = true,

	-- core
	mode = "hybrid", -- "modal" | "hold" | "hybrid" | "forever"
	smart_modifiers = true,
	stop_on_unknown_key = false,
	ignore_shift_state_for_special_characters = true,
	timeout = 0, -- ms
	labels = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!\"#$%&'()*+,-./:;<=>?@\\^_`{|}~",

	theme = {
		fg = beautiful.fg_focus or "#eceffc",
		bg = beautiful.bg_focus or "#24283B",
		grey = beautiful.fg_normal or "#959cbc",
		border = beautiful.border_color_normal or "#444A73",
		accent = "#82AAFF",
	},

	-- hints
	hints = {
		enabled = true,
		delay = 0, -- ms
		show_header = false,
		show_disabled_keys = true,
		sort = "group", -- group | id | key | none
		mouse_button_select = 1, -- left click
		mouse_button_select_continue = 3, -- right click
		mouse_button_stop = 2, -- middle click
		mouse_button_back = 8, -- back click
		color_border = nil,
		color_odd_bg = -8, -- color or luminosity
		color_hover_bg = 15, -- color or luminosity
		color_disabled_fg = nil,
		font_header = "Monospace 12",
		color_header_fg = nil,
		color_header_bg = nil,
		highlight = {
			bg = nil,
			key = {
				font = "Monospace 12",
			},
			desc = {
				font = "Monospace 12",
				italic = true,
			},
			separator = {
				font = "Monospace 12",
			},
		},
		menu_highlight = {
			desc = {
				bold = true,
			},
		},
		group_highlights = {
			-- ["^awesome"] = {
			-- 	desc = {
			-- 		underline = true,
			-- 	},
			-- },
		},
		separator = " ➜ ",
		entry_key_width = 5, -- chars
		min_entry_width = 25, -- chars
		max_entry_width = 30, -- chars
		entry_padding = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0,
		},
		padding = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0,
		},
		margin = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0,
		},
		width = 0.75, -- fraction or abs pixel count
		height = 0.35, -- fraction or abs pixel count
		stretch_vertical = false, -- use all available height
		stretch_horizontal = false, -- use all available width
		flow_horizontal = false, -- fill from left to right
		expand_horizontal = true, -- use all available columns first
		placement = function(h) -- function, placement (e.g. "centered") or false (last position)
			awful.placement.bottom(h, { honor_workarea = true })
		end,
		border_width = beautiful.border_width or dpi(1),
		opacity = 1,
		shape = nil,
		odd_style = "row", -- row  | column | checkered | none
		key_aliases = {
			[" "] = "space",
			Left = "←",
			Right = "→",
			["^Up"] = "↑",
			["[%-]Up"] = "↑",
			["^Down"] = "↓",
			["[%-]Down"] = "↓",
			XF86MonBrightnessUp = "󰃝 +",
			XF86MonBrightnessDown = "󰃝 -",
			XF86AudioRaiseVolume = "󰝝",
			XF86AudioLowerVolume = "󰝞",
			XF86AudioMute = "󰝟",
			XF86AudioPlay = "󰐊",
			XF86AudioPrev = "󰒮",
			XF86AudioNext = "󰒭",
			XF86AudioStop = "󰓛",
		},
	},

	echo = {
		enabled = true,
		show_percentage_as_progressbar = false,
		placement = "centered",
		timeout = 1000, -- ms
		vertical_layout = true,
		entry_width = 20, -- chars
		entry_width_strategy = "exact", -- min | max | exact
		padding = {
			top = dpi(5),
			bottom = dpi(5),
			left = dpi(5),
			right = dpi(5),
		},
		spacing = 0,
		font = "Monospace 20",
		font_header = nil,
		border_width = beautiful.border_width or dpi(1),
		odd = 0, -- luminosity or color
		shape = nil,
		opacity = 1,
		color_border = nil,
		color_bg = nil,
		color_fg = nil,
		color_header_fg = nil,

		progressbar = {
			shape = gears.shape.rounded_rect,
			bar_shape = gears.shape.rounded_rect,
			border_width = dpi(2),
			bar_border_width = dpi(2),
			color = nil,
			background_color = nil,
			border_color = nil,
			bar_border_color = nil,
			margin = {
				left = dpi(5),
				right = dpi(5),
				top = dpi(5),
				bottom = dpi(5),
			},
			paddings = {
				left = 0,
				right = 0,
				top = 0,
				bottom = 0,
			},
			opacity = 1,
		},
	},

	prompt = {
		placement = "centered",
		vertical_layout = true,
		width = 20, -- chars
		padding = {
			top = dpi(5),
			bottom = dpi(5),
			left = dpi(5),
			right = dpi(5),
		},
		spacing = 0,
		font = "Monospace 20",
		font_header = nil,
		border_width = beautiful.border_width or dpi(1),
		shape = nil,
		opacity = 1,
		color_border = nil,
		color_bg = nil,
		color_fg = nil,
		color_header_fg = nil,
		color_cursor_fg = nil,
		color_cursor_bg = nil,
	},

	label = {
		font = "Monospace 40",
		shape = gears.shape.rounded_rect,
		border_width = beautiful.border_width or dpi(1),
		color_bg = nil,
		color_fg = nil,
		color_border = nil,
		width = dpi(100),
		height = dpi(100),
		opacity = 1,
	},

	-- awesome
	awesome = {
		auto_select_the_only_choice = false,
		resize_delta = dpi(32),
		resize_factor = 0.025,
		browser = "firefox || chromium || google-chrome-stable || qutebrowser",
		terminal = terminal or "alacritty || kitty || wezterm || st || urxvt || xterm",
		app_menu = "rofi -show drun || dmenu_run",
	},
}
```

## 📖 Documentation

### Key definition

| Property    | Type             | Description                                                                                                                                                  |
| ----------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| (`seq`)     | string           | The sequence of keys to be pressed.                                                                                                                          |
| (`fn`)      | function(opts)   | The function to be executed when the key sequence has been entered. If the key has successors it will only be executed if a timeout occurs (similar to vim). |
| `desc`      | string, function | Provides a brief description of the key.                                                                                                                     |
| `opts`      | table            | Specifies custom options for the key that will be merged with options from predecessors.                                                                     |
| `cond`      | function(opts)   | A condition that determines whether the key is active (nil means it is always active)                                                                        |
| `group`     | string           | Assigns the key to a group, used for sorting purposes purposes.                                                                                              |
| `global`    | string, boolean  | Creates a global keybinding in awesomewm to run the key's function (e.g. "\<M-a\>"). If set to true, the key sequence will be used as the global keybinding. |
| `continue`  | boolean          | Forces continuation after executing the key's function regardless of the current input mode.                                                                 |
| `hidden`    | boolean          | Hides the key in hints.                                                                                                                                      |
| `is_menu`   | boolean          | Marks the key explicitly as a menu, even if it has no successsors (purely cosmetic, used for dynamic menus).                                                 |
| `temp`      | boolean          | Marks the key as temporary, indicating that it is dynamically created and only available for a single use.                                                   |
| `highlight` | table            | Custom attributes to display the key in hints (font, fg, bg, bold, italic, underline, strikethrough)                                                         |
| `on_enter`  | function(opts)   | The function to be executed before the main function (init).                                                                                                 |
| `on_leave`  | function(opts)   | The function to be executed after the main function (cleanup).                                                                                               |
| `result`    | table            | Specifies the results or notifications to be shown after executing the key's function (e.g. { volume = 0.5 }).                                               |

## 📡 API
