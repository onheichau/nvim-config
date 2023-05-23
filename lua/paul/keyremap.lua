vim.g.mapleader = " "
vim.keymap.set("n", "<leader> ", ":w<CR>:Ex<CR>")
vim.keymap.set("n", "<Tab>", "<C-w><C-w>")
vim.keymap.set("n", "<leader>s", "yiw:%s/<C-r>\"//g<Left><Left>", {noremap = true})
vim.keymap.set("n", "<leader>=", "=ap", {noremap = true})
vim.keymap.set("n", "<leader><Tab>", ":vsplit<Enter><C-w><C-w>", {noremap = true})

vim.keymap.set("i", "<ESC>", "<ESC>l")
vim.keymap.set("i", "<C-j>", "<ESC>l")
vim.keymap.set("n", "<leader>n", ":w<CR>:bnext<CR>")


vim.keymap.set("i", "<C-l>", "<right>")
vim.keymap.set("i", "<C-h>", "<left>")

vim.keymap.set("n", "a", "A", {noremap = true})
vim.keymap.set("n", "A", "a", {noremap = true})

vim.keymap.set("n", "v", "V", {noremap = true})
vim.keymap.set("n", "V", "v", {noremap = true})

vim.keymap.set("n", "v", "V", {noremap = true})
vim.keymap.set("n", "V", "v", {noremap = true})

vim.keymap.set("n", "S", "s", {noremap = true})
vim.keymap.set("n", "s", "S", {noremap = true})

-- Navgation
vim.keymap.set("n", "<C-j>", "<C-d>zz10<C-e>", {noremap = true})
vim.keymap.set("n", "<C-k>", "<C-u>zz10", {noremap = true})
vim.cmd('vnoremap <C-j> 15jzz')
vim.cmd('vnoremap <C-k> 15kzz')

-- Editiing
vim.keymap.set("n", "<leader>d", "d$a", {noremap = true})
vim.keymap.set("n", "<leader><BS>", "d0i	", {noremap = true})

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- command sugar
