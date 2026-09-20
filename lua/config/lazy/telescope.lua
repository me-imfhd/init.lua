return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	dependencies = {
		{ "nvim-lua/plenary.nvim" },
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release",
		},
	},
	opts = {},
	config = function()
		local add_to_trouble = require("trouble.sources.telescope").add
		require("telescope").setup({
			defaults = {
				mappings = {
					i = { ["<C-t>"] = add_to_trouble },
					n = { ["<C-t>"] = add_to_trouble },
				},
			},
			pickers = {
				find_files = {
					-- include hidden files but ignore files in .git directories
					find_command = {
						"rg",
						"--files",
						"--hidden",
						"-g",
						"!.git",
					},
				},
			},
		})
		local preview_utils = require("telescope.previewers.utils")
		preview_utils.ts_highlighter = function(bufnr, ft)
			local lang = vim.treesitter.language.get_lang(ft) or ft
			if not lang or lang == "" then
				return false
			end
			return pcall(vim.treesitter.start, bufnr, lang)
		end

		local builtin = require("telescope.builtin")
		local make_entry = require("telescope.make_entry")

		-- Skip generated/vendor trees in grep-based searches.
		local extra_rg_args = {
			"--hidden",
			"-g",
			"!.git",
			"-g",
			"!**/target/**",
			"-g",
			"!**/node_modules/**",
			"-g",
			"!**/vendor/**",
			"-g",
			"!**/dist/**",
		}

		-- Lines that are almost always re-exports / imports, not the definition.
		local import_line = vim.regex([=[^\s*\(\(pub\|export\|public\)\s\+\)\?\(use\|import\|using\|from\|require\|extern\s\+crate\|#include\)\|^\s*local\s\+.\+=\s*require]=])

		local function skip_imports_maker(opts)
			local inner = make_entry.gen_from_vimgrep(opts)
			return function(line)
				local entry = inner(line)
				if not entry then
					return nil
				end
				if import_line:match_str(entry.text or "") then
					return nil
				end
				return entry
			end
		end

		local function rg_escape(s)
			return (s:gsub("([%.%[%]%(%)%{%}%+%-%?%^%$%*%|\\])", "\\%1"))
		end

		local function grep_word_no_imports()
			local opts = {
				additional_args = extra_rg_args,
				cwd = vim.uv.cwd(),
			}
			opts.entry_maker = skip_imports_maker(opts)
			builtin.grep_string(opts)
		end

		-- Keyword-based "go to definition" without LSP: fn/struct/trait/class/etc.
		local function grep_definitions()
			local word = vim.fn.expand("<cword>")
			if word == "" then
				return
			end
			local w = rg_escape(word)
			local pattern = table.concat({
				string.format(
					[[\b(fn|func|function|def|struct|class|enum|trait|interface|type|typedef|mod|module|const|macro_rules!|macro|protocol|record|union|namespace)\s+%s\b]],
					w
				),
				string.format([[\bimpl(<[^>]*>)?(\s+[\w:]+(<[^>]*>)?\s+for)?\s+%s\b]], w),
				string.format([[\b%s\s*=\s*(function|class|struct)\b]], w),
			}, "|")
			builtin.grep_string({
				use_regex = true,
				search = pattern,
				prompt_title = "Defs: " .. word,
				additional_args = extra_rg_args,
			})
		end

		-- Visual-select a list of names, optional prefix, open hits in Telescope.
		-- Example prefix: impl QueryHydrator<ScoredPostsQuery> for
		local function grep_visual_list()
			local s = vim.fn.getpos("v")
			local e = vim.fn.getpos(".")
			local start_row, end_row = s[2], e[2]
			if start_row > end_row then
				start_row, end_row = end_row, start_row
			end
			local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)

			local names = {}
			for _, line in ipairs(lines) do
				local name = vim.trim(line)
				if name ~= "" then
					table.insert(names, rg_escape(name))
				end
			end
			if #names == 0 then
				return
			end

			vim.ui.input({ prompt = "Grep prefix (names appended as A|B|C): " }, function(prefix)
				if prefix == nil then
					return
				end
				local group = "(" .. table.concat(names, "|") .. ")"
				local search
				if prefix == "" then
					search = group
				elseif prefix:find("%s", 1, true) then
					search = prefix:gsub("%%s", group, 1)
				else
					if not prefix:match("%s$") then
						prefix = prefix .. " "
					end
					search = prefix .. group
				end
				builtin.grep_string({
					use_regex = true,
					search = search,
					prompt_title = search,
					additional_args = extra_rg_args,
				})
			end)
		end

		vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "[S]earch [H]elp" })
		vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
		vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "[S]earch [F]iles" })
		vim.keymap.set("n", "<leader>fs", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
		vim.keymap.set("n", "<leader>fw", grep_word_no_imports, { desc = "[S]earch current [W]ord (no imports)" })
		vim.keymap.set("n", "<leader>ft", grep_definitions, { desc = "[S]earch [T]ype/function definitions" })
		vim.keymap.set("n", "<leader>fg", function()
			local opts = { additional_args = extra_rg_args, cwd = vim.uv.cwd() }
			opts.entry_maker = skip_imports_maker(opts)
			builtin.live_grep(opts)
		end, { desc = "[S]earch by [G]rep (no imports)" })
		vim.keymap.set("v", "<leader>fg", grep_visual_list, { desc = "Grep visual name list with prefix" })
		vim.keymap.set("n", "<leader>fI", function()
			builtin.live_grep({ additional_args = extra_rg_args })
		end, { desc = "[S]earch by grep [I]ncluding imports" })
		vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
		vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "[S]earch [R]esume" })
		vim.keymap.set("n", "<leader>f.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
		vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })

		vim.keymap.set("n", "<leader>/", function()
			builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
				winblend = 10,
				previewer = false,
			}))
		end, { desc = "[/] Fuzzily search in current buffer" })

		vim.keymap.set("n", "<leader>f/", function()
			builtin.live_grep({
				grep_open_files = true,
				prompt_title = "Live Grep in Open Files",
			})
		end, { desc = "[S]earch [/] in Open Files" })

		vim.keymap.set("n", "<leader>fn", function()
			builtin.find_files({ cwd = vim.fn.stdpath("config") })
		end, { desc = "[S]earch [N]eovim config files" })

		vim.keymap.set("n", "<leader>tg", builtin.git_status, { desc = "[G]it [S]tatus" })
	end,
}
