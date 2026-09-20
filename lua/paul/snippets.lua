local ls = require("luasnip")
local s, t, i, f = ls.s, ls.text_node, ls.insert_node, ls.function_node
local rep = require("luasnip.extras").rep

local function get_filename_without_ext()
  local filename = vim.fn.expand("%:t:r") -- Get filename without extension.
  if filename == "" then
    return "ComponentName" -- Default name in case it's an unnamed buffer.
  end
  return filename.upper(filename.sub(filename, 1, 1)) .. filename.sub(filename, 2)
end

ls.add_snippets("all", {

  s("ncomp", {
    -- jsx ComponentName
    t("export default function "),
    f(get_filename_without_ext, {}),
    t({ "({}) {", "\treturn (", "\t\t <div>" }),
    i(0),
    t({
      "</div>",
      "\t)",
      "}",
    }),
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
    -- bullet point
    trig = "bullet",
  }, {
    t("• "),
  }),
  s({
    trig = "\\frac",
  }, {
    t("\\frac{"),
    i(1),
    t("}{"),
    i(0),
    t("}"),
  }),
  s({
    trig = "keymap",
  }, {
    t('vim.keymap.set("", "", "")'),
  }),
  s({
    trig = "\\array",
  }, {
    t({ "$$", "\\begin{array}{lcl}", "" }),
    i(0),
    t(" \\\\"),
    t({ "", "\\end{array}", "$$" }),
  }),
  s({
    trig = "\\cases",
  }, {
    t({ "$$", "\\begin{cases}", "" }),
    i(0),
    t(" \\\\"),
    t({ "", "\\end{cases}", "$$" }),
  }),
  s({
    trig = "\\text",
  }, {
    t("\\text{"),
    i(1),
    t("} "),
    i(0),
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
    trig = "dummy_request",
  }, {
    t({ 'std::string request = "GET / HTTP/1.1\\r\\n"' }),
    t({ "", '"Host: example.com\\r\\n"' }),
    t({ "", '"Connection: close\\r\\n\\r\\n";' }),
  }),
  s({
    trig = "#safeguard",
  }, {
    -- compilation safeguard
    t("#ifndef "),
    i(1, { string.upper(get_filename_without_ext()) .. "_H__" }),
    t({ "", "#define " }),
    rep(1),
    t({ "", "", "namespace {", "\t" }),
    i(0),
    t({ "", "}", "", "" }),
    t("#endif //!"),
    rep(1),
  }),
  -- s({trig = "class"}, {
  --   t({"class"}),
  --   i()
  -- }),
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
