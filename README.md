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

## 📋 Requirements

- awesome-git
- nerd-font (optional)

## 📦 Installation

## ⚙️ Configuration

## 📡 API

## 💡 Examples
