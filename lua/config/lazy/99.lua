return {
	"ThePrimeagen/99",
	config = function()
		local _99 = require("99")
		local cwd = vim.uv.cwd()
		local basename = vim.fs.basename(cwd)

		-- Permanent defaults. Live picker (<leader>9p / 9m) only lasts this session.
		-- tmp_dir MUST be inside the project: OpenCode refuses to write outside cwd.
		_99.setup({
			provider = _99.Providers.OpenCodeProvider,
			model = "xai/grok-4.20-0309-non-reasoning",
			-- opencode run auto-rejects writes unless --auto is set
			provider_extra_args = { "--auto" },
			tmp_dir = "./tmp",
			display_errors = true,
			logger = {
				type = "file",
				level = _99.DEBUG,
				path = "/tmp/" .. basename .. ".99.debug",
				print_on_error = true,
			},
			md_files = {
				"AGENT.md",
			},
			completion = {
				source = "cmp",
				custom_rules = {},
			},
		})

		local function pick_model()
			local ok, err = pcall(function()
				require("99.extensions.telescope").select_model()
			end)
			if not ok then
				vim.notify("99 model picker: " .. tostring(err), vim.log.levels.ERROR)
			end
		end

		local function pick_provider()
			local ok, err = pcall(function()
				require("99.extensions.telescope").select_provider()
			end)
			if not ok then
				vim.notify("99 provider picker: " .. tostring(err), vim.log.levels.ERROR)
			end
		end

		vim.keymap.set("v", "<leader>9v", function()
			_99.visual({})
		end, { desc = "99 visual edit" })

		vim.keymap.set("n", "<leader>9s", function()
			_99.search({})
		end, { desc = "99 search" })

		vim.keymap.set("n", "<leader>9x", function()
			_99.stop_all_requests()
		end, { desc = "99 stop requests" })

		vim.keymap.set("n", "<leader>9o", function()
			_99.open()
		end, { desc = "99 open last" })

		vim.keymap.set("n", "<leader>9m", pick_model, { desc = "99 select model" })
		vim.keymap.set("n", "<leader>9p", pick_provider, { desc = "99 select provider" })

		vim.api.nvim_create_user_command("NineSearch", function()
			_99.search({})
		end, { desc = "99 search" })
		vim.api.nvim_create_user_command("NineStop", function()
			_99.stop_all_requests()
		end, { desc = "99 stop requests" })
		vim.api.nvim_create_user_command("NineOpen", function()
			_99.open()
		end, { desc = "99 open last" })
		vim.api.nvim_create_user_command("NineModel", pick_model, { desc = "99 select model" })
		vim.api.nvim_create_user_command("NineProvider", pick_provider, { desc = "99 select provider" })
	end,
}
