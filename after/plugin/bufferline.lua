vim.opt.termguicolors = true

require("bufferline").setup({
  options = {
    separator_style = 'thick',
    always_show_bufferline = true,
    show_buffer_close_icons = false,
    color_icons = true
  },
  highlights = {
    buffer_selected = {
      fg = '#FFFFFF',  -- Foreground color white
      bg = '#035ea3',  -- Background color yellow
      bold = true,
    },
  },
})

