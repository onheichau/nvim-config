vim.g.mapleader = " "
vim.keymap.set("n", "<leader>e", ":Ex<CR>")
vim.keymap.set("n", "<", ":bp<CR>")
vim.keymap.set("n", ">", ":bn<CR>")
--vim.keymap.set("n", "<Tab>", "2<C-w>", { noremap = true })
vim.keymap.set("n", "<leader>s", 'yiw:%s/<C-r>"//g<Left><Left>', { noremap = true })
vim.keymap.set("n", "<leader>=", "=ap", { noremap = true })
vim.keymap.set("n", "<leader>g", ":DiffviewOpen<CR>", { noremap = true })
vim.keymap.set("n", "<leader>G", ":DiffviewClose<CR>", { noremap = true })
vim.keymap.set("n", "<leader>n", "<cmd>noh<CR>")
--
vim.keymap.set("i", "<ESC>", "<ESC>l")
vim.keymap.set("n", "<leader>n", ":w<CR>:bnext<CR>")

vim.keymap.set("i", "<C-l>", "<right>")
vim.keymap.set("i", "<C-h>", "<left>")
--
vim.keymap.set("n", "<C-o>", "<C-o>zz", { noremap = true })

vim.keymap.set("n", "G", "Gzz", { noremap = true })

vim.keymap.set("n", "a", "A", { noremap = true })
vim.keymap.set("n", "A", "a", { noremap = true })

vim.keymap.set("n", "n", "nzz", { noremap = true })
vim.keymap.set("n", "N", "Nzz", { noremap = true })

vim.keymap.set("n", "v", "V", { noremap = true })
vim.keymap.set("n", "V", "v", { noremap = true })

vim.keymap.set("n", "v", "V", { noremap = true })
vim.keymap.set("n", "V", "v", { noremap = true })

vim.keymap.set("n", "S", "s", { noremap = true })
vim.keymap.set("n", "s", "S", { noremap = true })

-- Navgation
vim.keymap.set("n", "<C-j>", "<C-d>zz10<C-e>", { noremap = true })
vim.keymap.set("n", "<C-k>", "<C-u>zz10", { noremap = true })
vim.cmd("vnoremap <C-j> 15jzz")
vim.cmd("vnoremap <C-k> 15kzz")

-- Editiing
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- command line mode keymap sugar
vim.keymap.set("v", "q:", "q:a")
vim.keymap.set("n", "q:", "q:a")

-- class name inserter
vim.keymap.set(
	"x",
	"S",
	[[:s/\v(((^\s*).*\S\s)(\w+.*\s?[(].*[)].*);)/\2\4 {\r\r\3}\r<left><left><left><left><left><left><left><left><left><left><left><left><left>]],
	{ noremap = true }
)

-- default compile and execute
vim.keymap.set("n", "<leader>c", function()
	vim.cmd("!g++ -std=c++17 -Wall -g -fdiagnostics-color=always *.cpp")
	vim.cmd("! ./a.out")
end)

vim.keymap.set("n", "<leader>j", function()
	vim.cmd("ju")
end)
