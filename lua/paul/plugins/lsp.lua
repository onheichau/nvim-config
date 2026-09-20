return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { "mason-org/mason.nvim", "mason-org/mason-lspconfig.nvim", "hrsh7th/cmp-nvim-lsp" },
    config = function()
      require("mason").setup()
      vim.lsp.config("*", { capabilities = require("cmp_nvim_lsp").default_capabilities() })
      vim.lsp.config(
        "lua_ls",
        {
          settings = {
            Lua = {
              runtime = { version = "LuaJIT" },
              diagnostics = { globals = { "vim" } },
              workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
            },
          },
        }
      )
      vim.lsp.config("clangd", {
        cmd = { "clangd", "--header-insertion=never" },
        filetypes = { "c", "cpp", "proto" },
      })
      vim.lsp.config("tailwindcss", {
        filetypes = {
          "css",
          "html",
          "javascript",
          "javascriptreact",
          "scss",
          "svelte",
          "typescript",
          "typescriptreact",
          "vue",
        },
      })
      vim.lsp.config("texlab", {
        settings = {
          texlab = {
            -- VimTeX owns compilation and PDF navigation; avoid duplicate builds.
            build = { onSave = false },
            chktex = { onEdit = false, onOpenAndSave = false },
          },
        },
      })
      local servers = {
        "lua_ls",
        "clangd",
        "bashls",
        "cssls",
        "tailwindcss",
        "pyright",
        "ts_ls",
        "vimls",
        "eslint",
        "texlab",
      }
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "texlab" },
        automatic_enable = servers,
      })
      -- Also support existing system installations, including R's languageserver.
      for _, server in ipairs(vim.list_extend(vim.deepcopy(servers), { "r_language_server" })) do
        local config = vim.lsp.config[server]
        if config and type(config.cmd) == "table" and vim.fn.executable(config.cmd[1]) == 1 then
          vim.lsp.enable(server)
        end
      end
      vim.diagnostic.config({
        severity_sort = true,
        underline = true,
        update_in_insert = false,
        virtual_text = { spacing = 2, source = "if_many" },
        float = { border = "rounded" },
      })
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("PaulLsp", { clear = true }),
        callback = function(event)
          local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = event.buf, desc = desc })
          end
          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("gi", vim.lsp.buf.implementation, "Go to implementation")
          map("gr", vim.lsp.buf.references, "References")
          map("K", vim.lsp.buf.hover, "Documentation")
          map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
        end,
      })
    end,
  },
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
        -- Don't reflow prose, equations or snippets on every live-preview save.
        if vim.tbl_contains({ "tex", "plaintex", "bib", "markdown" }, vim.bo[buf].filetype) then
          return
        end
        return { timeout_ms = 1000, lsp_format = "never" }
      end,
    },
  },
}
