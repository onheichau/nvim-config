local ls = require("luasnip")
local s, i = ls.snippet, ls.insert_node
local fmta = require("luasnip.extras.fmt").fmta
return {
  s("eq", fmta("\\begin{equation}\n  <>\n  \\label{eq:<>}\n\\end{equation}\n<>", { i(1), i(2), i(0) })),
  s("item", fmta("\\item <>", { i(0) })),
  s("sec", fmta("\\section{<>}\n\\label{sec:<>}\n<>", { i(1), i(2), i(0) })),
}
