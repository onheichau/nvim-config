vim.opt.list = true

require("indent_blankline").setup({
	show_end_of_line = false,
	show_first_indent_level = false,
	show_trailing_blankline_indent = false,
})

vim.cmd("highlight IndentBlanklineChar guifg=#808080 gui=nocombine")

vim.cmd([[
  highlight IndentBlanklineChar guifg=#808080 gui=nocombine
  highlight IndentBlanklineContextChar guifg=#808080 gui=nocombine
  highlight IndentBlanklineSpaceChar guifg=#808080 gui=nocombine
  highlight IndentBlanklineSpaceCharBlankline guifg=#808080 gui=nocombine
  highlight SignColumn guibg=NONE ctermbg=NONE
  highlight NormalFloat guibg=NONE ctermbg=NONE
  highlight CursorLineNr guibg=NONE ctermbg=NONE
]])
