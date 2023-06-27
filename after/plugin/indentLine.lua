vim.opt.list = true
vim.opt.listchars:append "eol:↴"


require("indent_blankline").setup {
  show_end_of_line = false,
  show_first_indent_level = false,
  show_trailing_blankline_indent = false,
}

vim.cmd("highlight IndentBlanklineChar guifg=#808080 gui=nocombine")

vim.cmd([[
  highlight IndentBlanklineChar guifg=#808080 gui=nocombine
  highlight IndentBlanklineContextChar guifg=#808080 gui=nocombine
  highlight IndentBlanklineSpaceChar guifg=#808080 gui=nocombine
  highlight IndentBlanklineSpaceCharBlankline guifg=#808080 gui=nocombine
]])

