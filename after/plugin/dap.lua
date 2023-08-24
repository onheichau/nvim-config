local dap = require("dap")
dap.adapters.lldb = {
	type = "executable",
	command = "/opt/homebrew/opt/llvm/bin/lldb-vscode", -- adjust as needed, must be absolute path
	name = "lldb",
}

dap.configurations.cpp = {
	{
		name = "mac db",
		type = "lldb",
		request = "launch",
		--program = function()
		--  return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
		--end,
		program = "a.out",
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
		args = { "" },
		-- args = {"input.txt", "encoded.dat.txt", "K"},
	},
}

-- If you want to use this for Rust and C, add something like this:

dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp

vim.keymap.set("n", "<F5>", function()
	dap.continue()
end)
vim.keymap.set("n", "<F10>", function()
	dap.step_over()
	vim.cmd("normal! zz")
end)
vim.keymap.set("n", "<F11>", function()
	dap.step_into()
	vim.cmd("normal! zz")
end)
vim.keymap.set("n", "<F12>", function()
	dap.step_out()
	vim.cmd("normal! zz")
end)
vim.keymap.set("n", "<Leader>r", function()
	dap.step_back()
	vim.cmd("normal! zz")
end)
vim.keymap.set("n", "<Leader>b", function()
	dap.toggle_breakpoint()
end)
vim.keymap.set("n", "<F1>", function()
	dap.down()
	dap.focus_frame()
end)
vim.keymap.set("n", "<F2>", function()
	dap.up()
	dap.focus_frame()
end)

local dapui = require("dapui")

dapui.setup()

dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
end

require("nvim-dap-virtual-text").setup({
	commented = false,
})
