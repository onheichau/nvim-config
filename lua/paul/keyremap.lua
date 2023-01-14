vim.g.mapleader = " "
vim.keymap.set("n", "<leader> ", ":w<Enter>:Ex<Enter>")
vim.keymap.set("n", "<Tab>", "<C-w><C-w>")
vim.keymap.set("i", "<C-j>", "<ESC>", {noremap = true})
vim.keymap.set("n", "<leader>s", "yiw:%s/<C-r>\"//g<Left><Left>", {noremap = true})
vim.keymap.set("n", "<leader>=", "=ap", {noremap = true})
vim.keymap.set("n", "<leader><Tab>", ":vsplit<Enter><C-w><C-w>", {noremap = true})
vim.keymap.set("n", "<leader>t", vim.cmd.NvimTreeToggle)
vim.keymap.set("n", "v", "V", {noremap = true})
vim.keymap.set("n", "V", "v", {noremap = true})
