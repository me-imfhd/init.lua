return {
	"manojmallick/sigmap.nvim",
	config = function()
		require("sigmap").setup({
			auto_run = false,
			float_query = true,
		})
	end,
}
