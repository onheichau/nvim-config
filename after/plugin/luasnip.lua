if not pcall(require, "luasnip") then
	return
end

local ls = require("luasnip")
local types = require("luasnip.util.types")

ls.config.set_config({
	-- This tells LuaSnip to remember to keep around the last snippet.
	-- You can jump back into it even if you move outside of the selection
	history = true,

	-- This one is cool cause if you have dynamic snippets, it updates as you type!
	updateevents = "TextChanged,TextChangedI",

	-- Autosnippets:
	enable_autosnippets = false,

	-- Crazy highlights!!
	-- #vid3
	-- ext_opts = nil,
	ext_opts = {
		[types.choiceNode] = {
			active = {
				virt_text = { { " « ", "NonTest" } },
			},
		},
	},
})

-- s(context, nodes, condition, ...)
local s = ls.s

local fmt = require("luasnip.extras.fmt").fmt

--  Useful for dynamic nodes and choice nodes
local snippet_from_nodes = ls.sn

-- This is the simplest node.
--  Creates a new text node. Places cursor after node by default.
--  t { "this will be inserted" }
--
--  Multiple lines are by passing a table of strings.
--  t { "line 1", "line 2" }
local t = ls.text_node

-- Insert Node
--  Creates a location for the cursor to jump to.
--      Possible options to jump to are 1 - N
--      If you use 0, that's the final place to jump to.
--
--  To create placeholder text, pass it as the second argument
--      i(2, "this is placeholder text")
local i = ls.insert_node

-- Function Node
--  Takes a function that returns text
local f = ls.function_node

-- This a choice snippet. You can move through with <c-l> (in my config)
--   c(1, { t {"hello"}, t {"world"}, }),
--
-- The first argument is the jump position
-- The second argument is a table of possible nodes.
--  Note, one thing that's nice is you don't have to include
--  the jump position for nodes that normally require one (can be nil)
local c = ls.choice_node

local d = ls.dynamic_node

local snippets = {}

-- TODO: Document what I've learned about lambda
local l = require("luasnip.extras").lambda

local events = require("luasnip.util.events")

local same = function(index)
	return f(function(args)
		return args[1]
	end, { index })
end

local toexpand_count = 0

local js_attr_split = function(args)
	local val = args[1][1]
	local split = vim.split(val, ".", { plain = true })

	local choices = {}
	local thus_far = {}
	for index = 0, #split - 1 do
		table.insert(thus_far, 1, split[#split - index])
		table.insert(choices, t({ table.concat(thus_far, ".") }))
	end

	return snippet_from_nodes(nil, c(1, choices))
end

local fill_line = function(char)
	return function()
		local row = vim.api.nvim_win_get_cursor(0)[1]
		local lines = vim.api.nvim_buf_get_lines(0, row - 2, row, false)
		return string.rep(char, #lines[1])
	end
end

for _, ft_path in ipairs(vim.api.nvim_get_runtime_file("lua/tj/snips/ft/*.lua", true)) do
	loadfile(ft_path)()
end

vim.keymap.set({ "i", "s" }, "<c-j>", function()
	if ls.expand_or_jumpable() then
		ls.expand_or_jump()
	end
end, { silent = true })

vim.keymap.set({ "i", "s" }, "<c-k>", function()
	if ls.jumpable(-1) then
		ls.jump(-1)
	end
end, { silent = true })

--vim.keymap.set("i", "<c-l>", function()
--  if ls.choice_active() then
--    ls.change_choice(1)
--  end
--end)

vim.keymap.set("i", "<c-u>", require("luasnip.extras.select_choice"))

vim.keymap.set("n", "<leader><leader>s", "<cmd>source ~/.config/nvim/after/plugin/luasnip.lua<CR>")

local function get_filename_without_ext()
	local filename = vim.fn.expand("%:t:r") -- Get filename without extension.
	if filename == "" then
		return "ComponentName" -- Default name in case it's an unnamed buffer.
	end
	return filename
end

ls.add_snippets("all", {

	s("ncomp", {
		-- Using the function_node to dynamically insert the filename.
		t("const "),
		f(get_filename_without_ext, {}),
		t({
			" = props => {",
			"\treturn (",
			"\t\t<div>",
			"\t\t\t",
		}),
		i(0), -- This is the final cursor position, between the <div> tags.
		t({
			"",
			"\t\t</div>",
			"\t);",
			"};",
			"",
			"export default ",
		}),
		-- Using the function_node again to dynamically insert the filename at the end.
		f(get_filename_without_ext, {}),
	}),
	s("arrow", {
		t("const "),
		i(1),
		t("  = "),
		t("("),
		i(2),
		t(")"),
		t({ " => {", "\t" }),
		i(0),
		t({ "", "}" }),
	}),
	-- s("safeguard", {
	--
	-- }),
	-- s(), next snippet goes here
	-- s(), next snippet goes here
	-- s(), next snippet goes here
}) -- end of add_snippets
