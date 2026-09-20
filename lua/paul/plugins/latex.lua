return {
  "lervag/vimtex",
  lazy = false,
  init = function()
    vim.g.tex_flavor = "latex"
    vim.g.vimtex_view_method = vim.fn.has("mac") == 1 and "skim" or "zathura"
    vim.g.vimtex_view_skim_activate = 0
    vim.g.vimtex_view_skim_sync = 0
    vim.g.vimtex_compiler_method = "latexmk"
    vim.g.vimtex_compiler_latexmk = {
      continuous = 1,
      options = { "-verbose", "-file-line-error", "-synctex=1", "-interaction=nonstopmode" },
    }
    vim.g.vimtex_quickfix_mode = 0
    vim.g.vimtex_mappings_disable = { n = { "K" } }
    vim.g.vimtex_syntax_conceal_disable = 1
  end,
  config = function()
    require("paul.latex").setup()
  end,
}
