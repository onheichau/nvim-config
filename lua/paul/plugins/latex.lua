return {
  "lervag/vimtex",
  lazy = false,
  init = function()
    vim.g.tex_flavor = "latex"
    if vim.fn.has("mac") == 1 then
      vim.g.vimtex_view_method = "general"
      vim.g.vimtex_view_general_viewer = "open"
      vim.g.vimtex_view_general_options = "-g -a Preview @pdf"
      vim.g.vimtex_view_automatic = 0
    else
      vim.g.vimtex_view_method = "zathura"
    end
    vim.g.vimtex_compiler_method = "latexmk"
    vim.g.vimtex_compiler_latexmk = {
      callback = 1,
      continuous = 1,
      options = { "-verbose", "-file-line-error", "-synctex=1", "-interaction=nonstopmode" },
    }
    vim.g.vimtex_quickfix_mode = 0
    vim.g.vimtex_mappings_disable = { n = { "K" } }
    vim.g.vimtex_syntax_conceal_disable = 1
  end,
  config = function()
    require("paul.latex").setup()
    if vim.fn.has("mac") == 1 then
      require("paul.preview").setup()
    end
  end,
}
