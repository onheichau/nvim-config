local ls = require("luasnip")
local s, i = ls.snippet, ls.insert_node
local fmta = require("luasnip.extras.fmt").fmta
local manual = {
  s(
    {
      trig = "starter",
      name = "Course assignment starter",
      condition = function()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        return #lines == 1 and lines[1]:match("^%s*starter%s*$") ~= nil
      end,
    },
    fmta(
      [[
\documentclass[11pt]{article}
\usepackage[T1]{fontenc}
\usepackage{amsmath,amssymb}
\usepackage[margin=1in]{geometry}
\usepackage[hidelinks]{hyperref}

\title{<>\\<>}
\author{<>\\Student ID: <>}
\date{\today}

\begin{document}
\maketitle

\section*{Problem 1}
<>

\end{document}
]],
      {
        i(1, "Course code"),
        i(2, "Assignment 1"),
        i(3, "Your name"),
        i(4, "Your student ID"),
        i(0),
      }
    )
  ),
  s("eq", fmta("\\begin{equation}\n  <>\n  \\label{eq:<>}\n\\end{equation}\n<>", { i(1), i(2), i(0) })),
  s("item", fmta("\\item <>", { i(0) })),
  s("sec", fmta("\\section{<>}\n\\label{sec:<>}\n<>", { i(1), i(2), i(0) })),
}

local function in_math()
  local ok, result = pcall(vim.fn["vimtex#syntax#in_mathzone"])
  return ok and result == 1
end

local function not_in_math()
  return not in_math()
end

local function math_snippet(trigger, name, expansion)
  return s({
    trig = trigger,
    name = name,
    condition = in_math,
    show_condition = in_math,
  }, expansion)
end

local function math_operator(trigger, name, command)
  return s({
    trig = trigger,
    name = name,
    wordTrig = false,
    condition = in_math,
    show_condition = in_math,
  }, fmta(command .. " <>", { i(0) }))
end

local automatic = {
  s({
    trig = "mm",
    name = "Display math",
    condition = not_in_math,
    show_condition = not_in_math,
  }, fmta("\\[\n  <>\n\\]<>", { i(1), i(0) })),
  math_snippet("st", "Square root", fmta("\\sqrt{<>}<>", { i(1), i(0) })),
  math_snippet("frac", "Fraction", fmta("\\frac{<>}{<>}<>", { i(1), i(2), i(0) })),
  s({
    trig = "pwo",
    name = "Power",
    wordTrig = false,
    condition = in_math,
    show_condition = in_math,
  }, fmta("^{<>}<>", { i(1), i(0) })),
  math_snippet("cur", "Curly braces", fmta("\\{<>\\}<>", { i(1), i(0) })),
  math_snippet("abs", "Absolute value", fmta("\\lvert <> \\rvert<>", { i(1), i(0) })),
  math_snippet("norm", "Norm", fmta("\\lVert <> \\rVert<>", { i(1), i(0) })),
  math_snippet("mbf", "Math bold", fmta("\\mathbf{<>}<>", { i(1), i(0) })),
  math_snippet("lim", "Limit", fmta("\\lim_{<> \\to <>} <>", { i(1), i(2), i(0) })),
  math_operator(">=", "Greater than or equal", "\\ge"),
  math_operator("<=", "Less than or equal", "\\le"),
}

for _, set in ipairs({
  { "RR", "R", "Real numbers" },
  { "ZZ", "Z", "Integers" },
  { "QQ", "Q", "Rational numbers" },
  { "NN", "N", "Natural numbers" },
  { "CC", "C", "Complex numbers" },
}) do
  automatic[#automatic + 1] =
    math_snippet(set[1], set[3], fmta("\\mathbb{<>}<>", { ls.text_node(set[2]), i(0) }))
end

for _, logic in ipairs({
  { "not", "\\neg", "Logical negation" },
  { "and", "\\land", "Logical conjunction" },
  { "or", "\\lor", "Logical disjunction" },
  { "implies", "\\implies", "Logical implication" },
  { "iff", "\\iff", "Logical equivalence" },
  { "forall", "\\forall", "Universal quantifier" },
  { "exists", "\\exists", "Existential quantifier" },
  { "in", "\\in", "Set membership" },
  { "mid", "\\mid", "Set-builder separator" },
  { "cdot", "\\cdot", "Dot product" },
}) do
  automatic[#automatic + 1] = math_snippet(logic[1], logic[3], fmta(logic[2] .. " <>", { i(0) }))
end

return manual, automatic
