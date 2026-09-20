return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local harpoon = require("harpoon")

		harpoon:setup()

		-- Last harpoon file you were in, not the one currently on screen.
		-- Numbered slots stay in mark order; only the menu cursor follows recency.
		local curr_harpoon ---@type string|nil
		local prev_harpoon ---@type string|nil

		local function abspath(path)
			if not path or path == "" then
				return nil
			end
			return vim.fn.fnamemodify(path, ":p")
		end

		local function same_file(a, b)
			a, b = abspath(a), abspath(b)
			return a ~= nil and b ~= nil and a == b
		end

		local function is_harpoon_file(path)
			local list = harpoon:list()
			for i = 1, list:length() do
				local item = list:get(i)
				if item and item.value and same_file(item.value, path) then
					return true
				end
			end
			return false
		end

		vim.api.nvim_create_autocmd("BufEnter", {
			callback = function()
				if vim.bo.filetype == "harpoon" then
					return
				end
				local name = vim.api.nvim_buf_get_name(0)
				if name == "" or not is_harpoon_file(name) then
					return
				end
				if curr_harpoon and not same_file(curr_harpoon, name) then
					prev_harpoon = curr_harpoon
				end
				curr_harpoon = name
			end,
		})

		harpoon:extend({
			UI_CREATE = function(cx)
				local current = cx.current_file
				local want
				if curr_harpoon and not same_file(curr_harpoon, current) then
					want = curr_harpoon
				else
					want = prev_harpoon
				end

				local line
				if want then
					for i, file in ipairs(cx.contents) do
						if file ~= "" and same_file(file, want) then
							line = i
							break
						end
					end
				end
				if not line then
					for i, file in ipairs(cx.contents) do
						if file ~= "" and not same_file(file, current) then
							line = i
							break
						end
					end
				end
				if not line then
					return
				end
				vim.schedule(function()
					if vim.api.nvim_win_is_valid(cx.win_id) then
						vim.api.nvim_win_set_cursor(cx.win_id, { line, 0 })
					end
				end)
			end,
		})

		vim.keymap.set("n", "<leader>a", function()
			harpoon:list():add()
		end, { desc = "Harpoon add file" })

		vim.keymap.set("n", "<C-e>", function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end, { desc = "Harpoon menu" })

		vim.keymap.set("n", "<leader>1", function()
			harpoon:list():select(1)
		end, { desc = "Harpoon file 1" })
		vim.keymap.set("n", "<leader>2", function()
			harpoon:list():select(2)
		end, { desc = "Harpoon file 2" })
		vim.keymap.set("n", "<leader>3", function()
			harpoon:list():select(3)
		end, { desc = "Harpoon file 3" })
		vim.keymap.set("n", "<leader>4", function()
			harpoon:list():select(4)
		end, { desc = "Harpoon file 4" })

		vim.keymap.set("n", "<C-S-P>", function()
			harpoon:list():prev()
		end, { desc = "Harpoon prev" })
		vim.keymap.set("n", "<C-S-N>", function()
			harpoon:list():next()
		end, { desc = "Harpoon next" })
	end,
}
