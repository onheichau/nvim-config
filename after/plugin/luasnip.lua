if not pcall(require, "luasnip") then
  return
end

local ls = require "luasnip"
local types = require "luasnip.util.types"

ls.config.set_config {
  -- This tells LuaSnip to remember to keep around the last snippet.
  -- You can jump back into it even if you move outside of the selection
  history = false,

  -- This one is cool cause if you have dynamic snippets, it updates as you type!
  updateevents = "TextChanged,TextChangedI",

  -- Autosnippets:
  enable_autosnippets = true,

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
}

local snippet = ls.s

local snippet_from_nodes = ls.sn

local t = ls.text_node

local i = ls.insert_node

local f = ls.function_node

local c = ls.choice_node

local d = ls.dynamic_node

local l = require("luasnip.extras").lambda

local events = require "luasnip.util.events"


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
    table.insert(choices, t { table.concat(thus_far, ".") })
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

vim.keymap.set("i", "<c-u>", require "luasnip.extras.select_choice")

vim.keymap.set("n", "<leader><leader>s", "<cmd>source ~/.config/nvim/after/plugin/luasnip.lua<CR>")
