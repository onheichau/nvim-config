
local dap = require('dap')
dap.adapters.lldb = {
  type = 'executable',
  command = '/opt/homebrew/opt/llvm/bin/lldb-vscode', -- adjust as needed, must be absolute path
  name = 'lldb'
}

dap.defaults.fallback.external_terminal = {
  command = '/usr/bin/zsh',
  args = {'-e'};
}

dap.configurations.cpp = {
  {
    name = 'Launch',
    type = 'lldb',
    request = 'launch',
    program = 'a.out',
    --program = function()
    --  return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    --end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    --args = {},
    args = {"Stations1.txt", "Stations2.txt", "CustomerOrders.txt"},
  },
}

-- If you want to use this for Rust and C, add something like this:

dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp


vim.keymap.set('n', '<F5>', function() dap.continue()  end)
vim.keymap.set('n', '<F10>', function() dap.step_over() vim.cmd('normal! zz') end)
vim.keymap.set('n', '<F11>', function() dap.step_into() vim.cmd('normal! zz') end)
vim.keymap.set('n', '<F12>', function() dap.step_out() vim.cmd('normal! zz') end)
vim.keymap.set('n', '<Leader>r', function() dap.step_back() vim.cmd('normal! zz') end)
vim.keymap.set('n', '<Leader>b', function() dap.toggle_breakpoint() end)
vim.keymap.set('n', '<F2>', function() dap.up() end)
vim.keymap.set('n', '<F1>', function() dap.down() end)

local dapui = require("dapui")

dapui.setup();

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
