vim.g.mapleader = " "
vim.keymap.set("n", "<leader> ", vim.cmd.Ex)
vim.keymap.set("n", "<Tab>", "<C-w><C-w>")
vim.keymap.set("n", "<leader>s", "yiw:%s/<C-r>\"//g<Left><Left>", {noremap = true})
vim.keymap.set("n", "<leader>=", "=ap", {noremap = true})
vim.keymap.set("n", "<leader><Tab>", ":vsplit<Enter><C-w><C-w>", {noremap = true})
vim.keymap.set("n", "<leader>t", vim.cmd.NvimTreeToggle)

vim.cmd('inoremap <C-l> <C-o>l')
vim.cmd('inoremap <C-h> <C-o>h')

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

-- Files
--
