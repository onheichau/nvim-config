-- import lspconfig plugin safely
local lspconfig_status, lspconfig = pcall(require, "lspconfig")
if not lspconfig_status then
	return
end

-- import cmp-nvim-lsp plugin safely
local cmp_nvim_lsp_status, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not cmp_nvim_lsp_status then
	return
end

local keymap = vim.keymap -- for conciseness

-- enable keybinds only for when lsp server available
local on_attach = function(client, bufnr)
	-- keybind options
	local opts = { noremap = true, silent = true, buffer = bufnr }

	-- set keybinds
	keymap.set("n", "gd", function()
		vim.lsp.buf.definition()
	end, opts)
	keymap.set("n", "gD", "<Cmd>lua vim.lsp.buf.declaration()<CR>", opts) -- got to declaration
	keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts) -- go to implementation
end

-- used to enable autocompletion (assign to every lsp server config)
local capabilities = cmp_nvim_lsp.default_capabilities()

-- Change the Diagnostic symbols in the sign column (gutter)
-- (not in youtube nvim video)
local signs = { Error = " ", Warn = " ", Hint = "ﴞ ", Info = " " }
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- configure emmet language server
-- lspconfig["emmet_ls"].setup({
--   capabilities = capabilities,
--   on_attach = on_attach,
--   filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
-- })

-- configure r
-- lspconfig["r_language_server"].setup({
-- 	capabilities = capabilities,
-- 	on_attach = on_attach,
-- })
--
lspconfig.r_language_server.setup({
	on_attach = on_attach_custom,
	-- Debounce "textDocument/didChange" notifications because they are slowly
	-- processed (seen when going through completion list with `<C-N>`)
	flags = { debounce_text_changes = 150 },
})

-- configure css server
lspconfig["cssls"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- configure javascript server
lspconfig["bashls"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- configure javascript server
lspconfig["tailwindcss"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- configure javascript server
lspconfig["tsserver"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- configure javascript server
lspconfig["pyright"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- configure javascript server
-- lspconfig["eslint"].setup({
-- 	capabilities = capabilities,
-- 	on_attach = on_attach,
-- })

-- clangd
lspconfig["clangd"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
	cmd = { "clangd", "--header-insertion=never" },
})

-- sqlls
lspconfig["vimls"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- configure lua server (with special settings)
lspconfig["lua_ls"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
	settings = { -- custom settings for lua
		Lua = {
			-- make the language server recognize "vim" global
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				-- make language server aware of runtime files
				library = {
					[vim.fn.expand("$VIMRUNTIME/lua")] = true,
					[vim.fn.stdpath("config") .. "/lua"] = true,
				},
			},
		},
	},
})
