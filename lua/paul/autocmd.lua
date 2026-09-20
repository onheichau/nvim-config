vim.api.nvim_create_autocmd("BufReadPost", {
	pattern = "*.*",
	callback = function()
		vim.cmd("silent! normal g;")
		vim.cmd("norm zz")
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "netrw",
	callback = function()
		vim.cmd("set number rnu")
		vim.cmd("cd $PWD")
		vim.cmd("silent! normal g;")
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "text",
	callback = function()
		vim.cmd("set wrap linebreak textwidth=80")
	end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "*.R",
	callback = function()
		vim.cmd("!Rscript -e 'styler::style_file(\"" .. vim.fn.expand("%:p") .. "\")'")
	end,
})
