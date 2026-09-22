return {
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
    dependencies = {
      "rafamadriz/friendly-snippets",
      "iurimateus/luasnip-latex-snippets.nvim",
    },
    config = function()
      local ls = require("luasnip")
      ls.config.setup({
        history = true,
        update_events = "TextChanged,TextChangedI",
        enable_autosnippets = true,
      })
      require("luasnip-latex-snippets").setup({
        use_treesitter = false,
        allow_on_markdown = false,
      })
      require("luasnip.loaders.from_vscode").lazy_load()
      require("luasnip.loaders.from_lua").lazy_load({ paths = { vim.fn.stdpath("config") .. "/snippets" } })
      require("paul.snippets")
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
      "micangl/cmp-vimtex",
      "L3MON4D3/LuaSnip",
    },
    config = function()
      local cmp, ls = require("cmp"), require("luasnip")
      cmp.setup({
        snippet = {
          expand = function(args)
            ls.lsp_expand(args.body)
          end,
        },
        preselect = cmp.PreselectMode.None,
        mapping = cmp.mapping.preset.insert({
          ["<C-j>"] = cmp.mapping.select_next_item(),
          ["<C-k>"] = cmp.mapping.select_prev_item(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if ls.expand_or_locally_jumpable() then
              ls.expand_or_jump()
            elseif cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if ls.locally_jumpable(-1) then
              ls.jump(-1)
            elseif cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
        }, { { name = "buffer" } }),
      })
      cmp.setup.filetype("tex", {
        sources = cmp.config.sources({
          { name = "vimtex" },
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
        }, { { name = "buffer" } }),
      })
      vim.keymap.set({ "i", "s" }, "<C-u>", function()
        if ls.choice_active() then
          ls.change_choice(1)
        end
      end, { desc = "Next snippet choice" })
    end,
  },
}
