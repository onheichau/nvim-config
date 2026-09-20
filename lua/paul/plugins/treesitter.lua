return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    -- Packer's start plugins may have cached the legacy top-level module before
    -- Lazy resets runtime paths during this migration. Reload it from Lazy's
    -- pinned main-branch checkout.
    package.loaded["nvim-treesitter"] = nil
    local ts = require("nvim-treesitter")
    ts.setup({})
    if vim.fn.executable("tree-sitter") == 1 then
      ts.install({
        "lua",
        "vim",
        "vimdoc",
        "query",
        "bash",
        "python",
        "c",
        "cpp",
        "sql",
        "html",
        "javascript",
        "typescript",
        "tsx",
        "css",
        "json",
        "markdown",
        "markdown_inline",
        "yaml",
      })
    end
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("PaulTreesitter", { clear = true }),
      callback = function(event)
        -- VimTeX needs its own syntax engine for math zones and text objects.
        if not vim.tbl_contains({ "tex", "plaintex", "bib" }, vim.bo[event.buf].filetype) then
          pcall(vim.treesitter.start, event.buf)
        end
      end,
    })
  end,
}
