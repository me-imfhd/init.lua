-- KEYBINDS
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.del("n", "grr")
vim.keymap.del("n", "grx")
vim.keymap.del("n", "gra")
vim.keymap.del("n", "gri")
vim.keymap.del("n", "grn")
vim.keymap.del("n", "grt")

vim.keymap.set("n", "<C-q>", "<cmd>bdelete<CR>", { desc = "Close buffer" })
vim.keymap.set("n", "<C-h>", "<C-w><C-h>")
vim.keymap.set("n", "<C-j>", "<C-w><C-j>")
vim.keymap.set("n", "<C-k>", "<C-w><C-k>")
vim.keymap.set("n", "<C-l>", "<C-w><C-l>")

vim.keymap.set("n", "W", "<cmd>write<CR>", { desc = "Save file" })
vim.keymap.set("n", "WW", "<cmd>wall<CR>", { desc = "Save all buffers" })

vim.keymap.set("n", "<leader>cd", vim.cmd.Ex)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv") -- Alt Up/Down in vscode
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z") -- Remap joining lines
vim.keymap.set("n", "<C-d>", "<C-d>zz") -- Keep cursor in place while moving up/down page
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv") -- center screen when looping search results
vim.keymap.set("n", "N", "Nzzzv")

-- paste and don't replace clipboard over deleted text
vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- sometimes in insert mode, control-c doesn't exactly work like escape
vim.keymap.set("i", "<C-c>", "<Esc>")

-- add binds for Control J/K to scroll thru quickfix list
--vim.keymap.set("n", "<C-j>", "<cmd>cnext<CR>zz")
--vim.keymap.set("n", "<C-k>", "<cmd>cprev<CR>zz")
--vim.keymap.set("n", "<leader>j", "<cmd>lnext<CR>zz")
--vim.keymap.set("n", "<leader>k", "<cmd>lprev<cr>zz")

-- What the heck is Ex mode?
vim.keymap.set("n", "Q", "<nop>")

-- lint / format php files for LC
vim.keymap.set("n", "<leader>cc", "<cmd>!php-cs-fixer fix % --using-cache=no<cr>")

-- Replace all instances of whatever is under cursor (on line)
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- make file executable
vim.keymap.set("n", "<leader>ex", "<cmd>!chmod +x %<CR>", { silent = true })

-- yank into clipboard even if on ssh
vim.keymap.set("n", "<leader>y", "<Plug>OSCYankOperator")
vim.keymap.set("v", "<leader>y", "<Plug>OSCYankVisual")

-- reload without exiting vim
vim.keymap.set("n", "<leader>sn", "<cmd>source ~/.config/nvim/init.lua<cr>")

vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)

-- Quickfix list stuff
-- vim.keymap.set("n", "<leader>li", ":checkhealth vim.lsp<CR>", { desc = "LSP Info" })

-- run make in current working directory
vim.keymap.set("n", "<leader>mm", "<cmd>make<CR>")

-- source file
vim.keymap.set("n", "<leader><leader>", function()
	vim.cmd("so")
end)

vim.keymap.set("n", "*", "*``", { desc = "Highlight word under cursor without jumping" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("i", "jk", "<Esc>", { silent = true })
vim.keymap.set("i", "kj", "<Esc>", { silent = true })

vim.api.nvim_create_autocmd("User", {
	pattern = "TelescopePreviewerLoaded",
	callback = function()
		vim.wo.number = true
	end,
})

vim.o.autoread = true

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
	pattern = "*",
	command = "checktime",
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
	pattern = "*",
	callback = function()
		print("File reloaded from disk")
	end,
})
