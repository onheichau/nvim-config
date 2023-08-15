vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "*.*",
	callback = function()
		vim.cmd("silent! normal g;")
	end,
})

vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "*.txt",
	callback = function()
		vim.cmd("set wrap")
		vim.cmd("set linebreak")
	end,
})
