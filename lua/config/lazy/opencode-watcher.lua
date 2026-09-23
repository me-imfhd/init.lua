return {
	dir = "/home/meimfhd/dev/opencode-watcher",
	name = "opencode-watcher",
	lazy = false,
	priority = 100,
	config = function()
		require("opencode-watcher").setup({
			-- auto: git root else cwd; or set basename like "opencode-watcher.nvim" or full path
			dir = nil,
			position = "top-right", -- or "bottom-right"
			width = 50,
			height = 12,
			border = "rounded",
			-- hide noisy perms, keep loop/msg/file visible; customize as needed
			exclude = "MSG,SYNC,LLM,PERM:bash,read,edit",
			lines = 0, -- 0 = live only
			auto_refresh = true,
			hide_delay = 2500,
		})
	end,
}
