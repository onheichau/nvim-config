require("mason").setup() 
require("mason-lspconfig").setup({ 

  ensure_installed = {"sumneko_lua"} 

})

require("lspconfig").sumneko_lua.setup{}
require("lspconfig").clangd.setup{}

--require("lspconfig").sompack.setup{}
--require("lspconfig").sompack.setup{}
--require("lspconfig").sompack.setup{}
--require("lspconfig").sompack.setup{}
--require("lspconfig").sompack.setup{}
--require("lspconfig").sompack.setup{}
--require("lspconfig").sompack.setup{}
--require("lspconfig").sompack.setup{}
--require("lspconfig").sompack.setup{}



