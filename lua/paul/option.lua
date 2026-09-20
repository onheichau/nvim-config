vim.opt.guicursor = ""
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.wrap = false
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.opt.signcolumn = "yes"
vim.opt.clipboard:append("unnamedplus")
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.iskeyword:append("-")
vim.opt.undofile = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.spelllang = "en_us"
-- Stable cwd keeps multi-file LaTeX projects, LSP roots and search consistent.
vim.opt.autochdir = false
-- Discover a compact TinyTeX install or BasicTeX/MacTeX in GUI terminals too.
for _, path in ipairs({ vim.fn.expand("~/Library/TinyTeX/bin/universal-darwin"), "/Library/TeX/texbin" }) do
  if vim.fn.isdirectory(path) == 1 then
    vim.env.PATH = path .. ":" .. vim.env.PATH
  end
end
