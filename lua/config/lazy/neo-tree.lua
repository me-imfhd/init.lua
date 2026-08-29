return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	keys = {
		{ "<leader>e", "<cmd>Neotree toggle<CR>", desc = "Toggle file explorer" },
	},
	config = function()
		require("neo-tree").setup({
			close__if_last_window = true,
			source_selector = {
				winbar = false,
			},
			window = {
				position = "left",
				width = 30,
				mappings = {
					["l"] = function(state)
						local node = state.tree:get_node()
						local tree_win = vim.api.nvim_get_current_win()
						state.commands.open(state)
						if vim.api.nvim_win_is_valid(tree_win) then
							vim.api.nvim_set_current_win(tree_win)
						end
					end,
					["L"] = "open",
					["h"] = "close_node",
					["H"] = function(state)
						state.filtered_items.hide_gitignored = not state.filtered_items.hide_gitignored
						state.commands.refresh(state)
					end,
					["<CR>"] = "open",
				},
			},
			filesystem = {
				filtered_items = {
					visible = false,
					show_hidden_count = true,
					hide_dotfiles = false,
					hide_gitignored = true,
				},
				follow_current_file = {
					enabled = true,
				},
				use_libuv_file_watcher = true,
			},
			git_status = {
				window = {
					mappings = {
						["l"] = function(state)
							local node = state.tree:get_node()
							local tree_win = vim.api.nvim_get_current_win()
							state.commands.open(state)
							if vim.api.nvim_win_is_valid(tree_win) then
								vim.api.nvim_set_current_win(tree_win)
							end
						end,
						["L"] = "open",
						["h"] = "close_node",
						["H"] = function(state)
							state.filtered_items.hide_gitignored = not state.filtered_items.hide_gitignored
							state.commands.refresh(state)
						end,
					},
				},
			},
			default_component_configs = {
				icon = {
					folder_closed = " ",
					folder_open = " ",
					folder_empty = " ",
				},
				git_status = {
					symbols = {
						added = "+",
						modified = "~",
						deleted = "_",
						renamed = "r",
						untracked = "?",
						ignored = "i",
						unstaged = "",
						conflicted = "!",
						staged = "",
					},
				},
			},
		})
	end,
}
