local ls = require("luasnip")
local s, i = ls.snippet, ls.insert_node
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep
return {
  s("beg", fmta("\\begin{<>}\n  <>\n\\end{<>}", { i(1, "equation"), i(0), rep(1) })),
  s("mk", fmta("$<>$<>", { i(1), i(0) })),
  s("dm", fmta("\\[\n  <>\n\\]\n<>", { i(1), i(0) })),
  s("ff", fmta("\\frac{<>}{<>}<>", { i(1), i(2), i(0) })),
  s("eq", fmta("\\begin{equation}\n  <>\n  \\label{eq:<>}\n\\end{equation}\n<>", { i(1), i(2), i(0) })),
  s("ali", fmta("\\begin{align*}\n  <>\n\\end{align*}\n<>", { i(1), i(0) })),
  s("item", fmta("\\item <>", { i(0) })),
  s("sec", fmta("\\section{<>}\n\\label{sec:<>}\n<>", { i(1), i(2), i(0) })),
}
