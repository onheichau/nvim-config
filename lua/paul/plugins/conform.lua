return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "Format",
      },
    },
    opts = {
      formatters_by_ft = {
        tex = { "latexindent" },
        plaintex = { "latexindent" },
        bib = { "latexindent" },
        lua = { "stylua" },
        python = { "black" },
        c = { "clang_format" },
        cpp = { "clang_format" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        r = { "styler" },
      },
      format_on_save = function(buf)
        -- Keep prose formatting manual for Markdown.
        if vim.bo[buf].filetype == "markdown" then
          return
        end
        return { timeout_ms = 1000, lsp_format = "never" }
      end,
    },
  },
}
