return {
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    opts = { transparent_mode = true, italic = { strings = true, comments = true } },
    config = function(_, opts)
      require("gruvbox").setup(opts)
      vim.cmd.colorscheme("gruvbox")
    end,
  },
  { "nvim-tree/nvim-web-devicons", opts = {} },
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = { theme = "gruvbox" },
      sections = {
        lualine_c = {
          { "filename", path = 3 },
          function()
            return vim.b.latex_live and "LaTeX LIVE" or ""
          end,
        },
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    version = "*",
    opts = { options = { separator_style = "thick", show_buffer_close_icons = false } },
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      exclude = { filetypes = { "tex", "plaintex", "markdown", "help", "lazy" } },
    },
  },
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gdiffsplit", "Gread", "Gwrite" },
    keys = {
      { "<leader>gs", "<cmd>Git<cr>", desc = "Git status" },
      { "<leader>gc", "<cmd>Git commit<cr>", desc = "Git commit" },
    },
  },
  { "godlygeek/tabular", cmd = "Tabularize" },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Telescope",
    keys = {
      {
        "<leader>ff",
        function()
          require("telescope.builtin").find_files({
            cwd = vim.fs.root(0, ".git") or vim.fn.getcwd(),
          })
        end,
        desc = "Find files",
      },
      {
        "<leader>fg",
        function()
          require("telescope.builtin").live_grep({
            cwd = vim.fs.root(0, ".git") or vim.fn.getcwd(),
          })
        end,
        desc = "Search project",
      },
      {
        "<leader>fb",
        function()
          require("telescope.builtin").buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>fh",
        function()
          require("telescope.builtin").help_tags()
        end,
        desc = "Help",
      },
    },
    opts = {},
  },
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = { check_ts = false } },
  { "windwp/nvim-ts-autotag", ft = { "html", "javascriptreact", "typescriptreact" }, opts = {} },
}
