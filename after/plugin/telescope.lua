local builtin = require("telescope.builtin")
local telescope = require("telescope")
--local telescopeConfig = require("telescope.config")

telescope.setup()

local function is_git_repo()
	vim.fn.system("git rev-parse --is-inside-work-tree")

	return vim.v.shell_error == 0
end

local function get_git_root()
	local dot_git_path = vim.fn.finddir(".git", ".;")
	return vim.fn.fnamemodify(dot_git_path, ":h")
end

vim.keymap.set("n", "<leader>ff", function()
	local opts = {}

	if is_git_repo() then
		opts = {
			cwd = get_git_root(),
		}
	end

	builtin.find_files(opts)
end)

vim.keymap.set("n", "<leader>fg", function()
	local opts = {}

	if is_git_repo() then
		opts = {
			cwd = get_git_root(),
		}
	end

	builtin.live_grep(opts)
end)

vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
