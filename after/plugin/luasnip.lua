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

local rep = require("luasnip.extras").rep -- for mirroring input

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
		-- jsx ComponentName
		t("const "),
		f(get_filename_without_ext, {}),
		t({
			" = ({}) => {",
			"\treturn (",
			"\t\t<",
		}),
		i(1, { "div" }),
		t({ ">", "\t\t\t" }),
		i(0, { "<p>hello</p>" }),
		t({ "" }),
		t({
			"",
			"\t\t</",
		}),
		rep(1),
		t({
			">",
			"\t);",
			"};",
			"",
			"export default ",
		}),
		f(get_filename_without_ext, {}),
	}),
	s({
		trig = "arrow",
	}, {
		-- arrow function
		t("const "),
		i(1),
		t(" = "),
		t("("),
		i(2),
		t(")"),
		t({ " => {", "\t" }),
		i(0),
		t({ "", "}" }),
	}),
	s({
		trig = "reducer",
	}, {
		-- useReducer
		t({
			"const ACTIONS = {",
			"\tplaceholder: 'placeholder'",
			"};",
			"",
			"const reducer = (state, action) => {",
			"\tswitch(action.type) {",
			"\t\tcase 1:",
			"\t\t\treturn {",
			"\t\t\t\t...state,",
			"\t\t\t\t//more...",
			"\t\t\t};",
			"\t\tdefault:",
			"\t\t\tthrow new Error('unhandled actions!');",
			"\t}",
			"};",
			"",
			"const [state, dispatch] = useReducer(reducer, {init: 0})",
		}),
	}),
	s({
		trig = "lambda",
	}, {
		-- compilation safeguard
		t("[](){"),
		i(0),
		t(";}"),
	}),
	s({
		trig = "#safeguard",
	}, {
		-- compilation safeguard
		t("#ifndef "),
		i(1, { get_filename_without_ext() .. "_H__" }),
		t({ "", "#define " }),
		rep(1),
		t({ "", "", "namespace {", "\t" }),
		i(0),
		t({ "", "}", "", "" }),
		t("#endif //!"),
		rep(1),
	}),
	s({
		trig = "dbms",
		filetype = "sql",
	}, { t("DBMS_OUTPUT.PUT_LINE("), i(0), t(");") }),
	s("create", {
		t("CREATE OR REPLACE PROCEDURE "),
		i(1, { "procedure name" }),
		t({ " AS", "BEGIN", "\t" }),
		i(0, "Your context"),
		t({ "", "END;", "/" }),
	}),
	s({
		trig = "begin",
		filetype = "sql",
	}, {
		t({ "BEGIN", "\t" }),
		i(0, "Your context"),
		t({ "", "END;", "/" }),
	}),
	s({
		trig = "if",
		filetype = "sql",
	}, {
		t("IF "),
		i(1, { "condition" }),
		t({ " THEN", "\t" }),
		i(0, { "execution" }),
		t({ "", "END IF;" }),
	}),
	s({
		trig = "for",
		filetype = "sql",
	}, {
		t("FOR "),
		i(1, { "it" }),
		t({ " IN " }),
		i(2, { "1..n" }),
		t({ "", "\tLOOP", "\t\t" }),
		i(0, { "execution" }),
		t({ "", "\tEND LOOP;" }),
	}),
	s({
		trig = "exception",
		filetype = "sql",
	}, {
		t("EXCEPTION WHEN OTHERS THEN", "\t"),
	}),
	s("rlchar", {
		t("normal $R"),
		i(0, { "replacing_text_goes_here" }),
	}),
	-- s(), next snippet goes here
	-- s(), next snippet goes here
}) -- end of add_snippets
