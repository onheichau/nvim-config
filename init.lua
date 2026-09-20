-- Current VimTeX requires Neovim 0.12.4 or newer.
if vim.fn.has("nvim-0.12.4") == 0 then
  error("This config requires Neovim 0.12.4+ (tested on 0.12.5).")
end
vim.g.mapleader = " "
vim.g.maplocalleader = ","
require("paul")
