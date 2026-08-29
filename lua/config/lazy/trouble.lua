return {
	"folke/trouble.nvim",
	opts = {
		mode = "diagnostics",
		auto_preview = true,
		auto_close = true,
		focus = true,
		warn_no_results = false,
		open_no_results = true,
		preview = {
			type = "split",
			relative = "win",
			position = "right",
			size = 0.3,
		},
	}, -- for default options, refer to the configuration section for custom setup.
	cmd = "Trouble",
	keys = {
		{
			"<leader>xx",
			"<cmd>Trouble diagnostics toggle<cr>",
			desc = "Diagnostics (Trouble)",
		},
		{
			"<leader>xf",
			"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
			desc = "Buffer Diagnostics (Trouble)",
		},
		{
			"<leader>xq",
			"<cmd>Trouble qflist toggle<cr>",
			desc = "Quickfix List (Trouble)",
		},
		--{
		--    "<leader>cs",
		--    "<cmd>Trouble symbols toggle focus=false<cr>",
		--    desc = "Symbols (Trouble)",
		--},
		--{
		--    "<leader>cl",
		--    "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
		--    desc = "LSP Definitions / references / ... (Trouble)",
		--},
		--{
		--    "<leader>xl",
		--    "<cmd>Trouble loclist toggle<cr>",
		--    desc = "Location List (Trouble)",
		--},
	},
}
