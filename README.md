# ⌨️ modalisa 🎨

`modalisa` is a hybrid modal keymap framework for AwesomeWM.
It combines the best of both traditional and modal input modes while also providing a visually appealing interface.

Traditional input modes in tiling window managers often require
complex keymaps that involve pressing multiple modifiers simultaneously
due to limited keyspace. Additionally, users have to rely on their memory or
unpractical cheatsheets as there are no key suggestions while typing.
On the other hand, modal input modes allow for easy entry of key sequences
but can become cumbersome when repeating actions. Users either have to
repeat the entire sequence or specify a count beforehand, making the process
inefficient.

`modalisa` addresses these shortcomings by providing a flexible hybrid approach.
It keeps track of modifier states to provide distinct input modes that can be tailored to the user's needs for each key and at every stage of the sequence individually.
It allows for traditional keybinds for common operations that can be repeated by holding down the modifier,
while also enabling users to tap the modifier (like a leader key) to enter modal mode followed by a key sequence for less common commands.
This flexibility makes it possible to transition into a more modal-esque keymap gradually without having to relearn most of the AwesomeWM controls.

In addition, `modalisa` comes with a preconfigured default keymap that includes improved default AwesomeWM controls (and a lot more) to provide a starting point and to give an overview about the possibilities using this framework.

<table>
  <tr>
    <th>Which Key Hints</th>
    <th>AwesomeWM Controls</th>
    <th>System Controls</th>
  </tr>
  <tr>
    <td>
      <img src="https://user-images.githubusercontent.com/1234183/284088067-73f1d696-c5ed-47fc-a502-776d9ba718f6.gif" />
    </td>
    <td>
      <img src="https://user-images.githubusercontent.com/1234183/284087983-de9dcb2c-9314-4439-bf70-36bfb33c2ddc.gif" />
    </td>
    <td>
      <img src="https://user-images.githubusercontent.com/1234183/284088055-abcc634d-deb9-4315-b22b-1f82706ad089.gif" />
    </td>
  </tr>
  <tr>
    <th>Client Labels</th>
    <th>Mouse Menu</th>
    <th>File Picker</th>
  </tr>
  <tr>
    <td>
      <img src="https://user-images.githubusercontent.com/1234183/284088127-fc91a8b5-40d6-43eb-8d88-3c96a84309ba.gif" />
    </td>
    <td>
      <img src="https://user-images.githubusercontent.com/1234183/284088114-ef598194-7b33-445e-98d8-e5dc14e811aa.gif" />
    </td>
    <td>
      <img src="https://user-images.githubusercontent.com/1234183/284088084-1cd651c7-4a5b-42b3-8c3d-a72bb5930fd0.gif" />
    </td>
  </tr>
</table>

## ✨ Features

- 🪄 Unique input modes
- 💥 Which key hints with mouse support
- 🌳 Keymap trees with property inheritance
- 💄 UI building blocks (prompt, echo, labels)
- 🌐 Define options for every key individually
- 🪟 Preconfigured AwesomeWM and system keymap
- 🧙 Use vim syntax to define key sequences
- ♿ Easy and intuitive configuration
- 📡 Highly extensible and customizable (200+ parameters)

## 💡 Example

```
{
	["t"] = { desc = "tag", opts = { mode = "hybrid", hints = { enabled = true } } },
	-- opts are inherited from predecessor t
	["t<Tab>"] = {
		desc = "view last tag",
		fn = function(opts)
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

## ⚠️ Warning

`modalisa` is in early development and breaking changes might occur.

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
	-- try the auto-generated theme first
	theme = {
		-- fg = "#eceffc",
		-- bg = "#24283B",
		-- grey = "#959cbc",
		-- border = "#444A73",
		-- accent = "#82AAFF",
	},
})
```

### Create Your Own Keymap

1. Copy the default keymap `keys.lua` as `modalisa_keys.lua` into the home AwesomeWM directory:

`cp ~/.config/awesome/modalisa/keys.lua ~/.config/awesome/modalisa_keys.lua`

2. Disable the default keymap by setting `include_default_keys = false` during setup.

3. Edit the copy. Restart AwesomeWM for the changes to take effect.

You can retrieve keynames by running the command

```sh
awesome-client "awesome.emit_signal('modalisa::showkey')"
```

from the terminal.
Press any key combination to show the respective keyname.

## ⚙️ Configuration

Most configuration options can be explored interactively by pressing `i` on the
default keymap.

<details><summary>Default Settings</summary>

<!-- config:start -->

<!-- config:end -->

</details>

## 📖 Documentation

### 🌲Tree

Keymaps are organized and represented using hierarchical tree structures.
Each key is stored as a node in the tree.
When a character is input, the tree is traversed to find the corresponding key.
If a node has been found and there are no possible successors (leaf), the key's function is executed.
Users can also use a specific key (by default, `BackSpace`) to go back a level in the tree.

The tree structure implements property inheritance, which means that options (`opts`) defined at a higher level in the tree will be inherited by the successor keys, unless overridden.
This provides a convenient way to define common options for groups of keys without repeating them for each individual key.

By default, the keymap is stored in the root tree, which is accessed by pressing the keybind defined in `root_keys` during setup.
However, it is possible to create additional trees if needed.

### ✨ Modes

| Mode      | Description                                                                                  |
| --------- | -------------------------------------------------------------------------------------------- |
| `hold`    | Run until the (last remaining) modifier has been released.                                   |
| `modal`   | Run until a command has been executed (by entering a valid key sequence).                    |
| `hybrid`  | Run until a command has been executed _and_ the (last remaining) modifier has been released. |
| `forever` | Run indefinitely until explicitly stopped (by pressing a stop key).                          |

Please note that the exact behaviour is also dependent on other config parameters.
When `stop_on_unknown_key` is active and an unknown key has
been input, operation will stop regardless of the current mode.
Operation will also always stop when a `timeout` (no valid input within
a timeframe) occurs.
The keys itself can also override the behaviour by explicitly setting a `continue` flag.

### 🔑 Key

Keys can be configured by using the following properties:

| Property    | Type                 | Description                                                                                                                                                                                                                                                              |
| ----------- | -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| (`seq`)     | string               | The sequence of keys to be pressed.                                                                                                                                                                                                                                      |
| (`fn`)      | function(opts, tree) | The function to be executed when the key sequence has been entered. If the key has successors (is a menu) it will only be executed if a timeout occurs (similar to vim). Successor keys can get dynamically created by returning a table containing the key definitions. |
| `desc`      | string or function   | Provides a brief description of the key.                                                                                                                                                                                                                                 |
| `opts`      | table                | Specifies custom options for the key that will be merged with options from predecessors.                                                                                                                                                                                 |
| `cond`      | function(opts)       | A condition that determines whether the key is active (nil means it is always active)                                                                                                                                                                                    |
| `group`     | string               | Assigns the key to a group, used for sorting purposes.                                                                                                                                                                                                                   |
| `global`    | string or boolean    | Creates a global keybinding in AwesomeWM to run the key's function (e.g. "\<M-a\>"). If set to true, the key sequence will be used as the global keybinding.                                                                                                             |
| `continue`  | boolean              | Forces continuation after executing the key's function regardless of the current input mode.                                                                                                                                                                             |
| `hidden`    | boolean              | Hides the key in hints.                                                                                                                                                                                                                                                  |
| `highlight` | table                | Custom attributes to display the key in hints (font, fg, bg, bold, italic, underline, strikethrough, etc.)                                                                                                                                                               |
| `is_menu`   | boolean              | Marks the key explicitly as a menu, even if it has no successsors (purely cosmetic, used for dynamic menus).                                                                                                                                                             |
| `temp`      | boolean              | Marks the key as temporary, indicating that it is dynamically created and only available for a single use.                                                                                                                                                               |
| `pre`       | function(opts, tree) | The function to be executed before the main function.                                                                                                                                                                                                                    |
| `post`      | function(opts, tree) | The function to be executed after the main function.                                                                                                                                                                                                                     |
| `on_enter`  | function(opts, tree) | The function to be executed when entering menu (non-leaf node).                                                                                                                                                                                                          |
| `on_leave`  | function(opts, tree) | The function to be executed when leaving a menu (non-leaf node).                                                                                                                                                                                                         |
| `result`    | table                | Specifies the results or notifications to be shown using `echo` after executing the key's function (e.g. { volume = 0.5 }).                                                                                                                                              |

### 📢 Signals

## 📡 API
