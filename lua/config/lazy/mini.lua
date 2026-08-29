return {
	"nvim-mini/mini.nvim",
	config = function()
		require("mini.ai").setup()
		require("mini.surround").setup()
		require("mini.comment").setup()
		require("mini.pairs").setup()

		require("mini.pick").setup()

		require("mini.statusline").setup()
		require("mini.icons").setup()
	end,
}
