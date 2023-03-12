vim.g.mapleader = " "
vim.keymap.set("n", "<leader> ", vim.cmd(Ex))
vim.keymap.set("n", "<Tab>", "<C-w><C-w>")
vim.keymap.set("n", "<leader>s", "yiw:%s/<C-r>\"//g<Left><Left>", {noremap = true})
vim.keymap.set("n", "<leader>=", "=ap", {noremap = true})
vim.keymap.set("n", "<leader><Tab>", ":vsplit<Enter><C-w><C-w>", {noremap = true})
vim.keymap.set("n", "<leader>t", vim.cmd.NvimTreeToggle)

vim.keymap.set("n", "v", "V", {noremap = true})
vim.keymap.set("n", "V", "v", {noremap = true})

vim.keymap.set("n", "S", "s", {noremap = true})
vim.keymap.set("n", "s", "S", {noremap = true})

-- Navgation
vim.keymap.set("n", "<C-j>", "<C-d>zz", {noremap = true})
vim.keymap.set("n", "<C-k>", "<C-u>zz", {noremap = true})

-- Editiing
vim.keymap.set("n", "<leader>d", "d$a", {noremap = true})
vim.keymap.set("n", "<leader><BS>", "d0i	", {noremap = true})

-- Files
--
