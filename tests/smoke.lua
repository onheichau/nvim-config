-- Run against a disposable copy of examples/assignment; never your homework.
local function check(value, message)
  assert(value, message)
end
local function read(path)
  return table.concat(vim.fn.readfile(path), "\n")
end
local function wait_for(fn, message)
  check(vim.wait(30000, fn, 100), message)
end
local function run()
  check(vim.v.errmsg == "", "startup error: " .. vim.v.errmsg)
  for _, path in ipairs(vim.api.nvim_list_runtime_paths()) do
    check(not path:find("/pack/packer/", 1, true), "old Packer plugins still loaded")
  end
  check(vim.fn.exists(":PackerSync") == 0, "Packer still active")
  check(vim.fn.exists(":CalcPdfWidth") == 2, "personal commands lost")
  check(vim.fn.maparg("a", "n") == "A", "personal mappings lost")
  require("lazy").load({
    plugins = {
      "nvim-cmp",
      "telescope.nvim",
      "conform.nvim",
      "nvim-autopairs",
      "nvim-ts-autotag",
      "vim-fugitive",
      "tabular",
    },
  })
  check(pcall(require, "telescope.builtin"), "Telescope failed to load")
  local regexp_ok, regexp = pcall(require, "luasnip.util.jsregexp")
  check(regexp_ok and regexp, "LuaSnip regexp support missing")
  check(vim.lsp.config.texlab.settings.texlab.build.onSave == false, "duplicate Texlab builds")
  check(require("conform").get_formatter_info("styler") ~= nil, "R formatter missing")
  -- Disable GUI launching for the repeatable headless test only.
  vim.g.vimtex_view_enabled = 0
  vim.g.latex_live_delay = 60
  local project =
    assert(vim.env.NVIM_TEST_PROJECT, "NVIM_TEST_PROJECT must point to a disposable assignment copy")
  local latex = require("paul.latex")
  local fresh_project = vim.fn.tempname()
  vim.fn.mkdir(fresh_project, "p")
  local fresh_source = fresh_project .. "/main.tex"
  vim.fn.writefile({}, fresh_source)
  vim.cmd.edit(vim.fn.fnameescape(fresh_source))
  latex.toggle()
  check(vim.b.latex_live, "live mode did not start for a new empty file")
  check(read(fresh_source):find("\\documentclass", 1, true), "starter document was not created")
  wait_for(function()
    return vim.fn.filereadable(fresh_project .. "/main.pdf") == 1
  end, "starter document PDF was not generated")
  latex.stop()
  vim.cmd.VimtexStop()
  local source = project .. "/sections/problem1.tex"
  vim.cmd.edit(vim.fn.fnameescape(source))
  local buf = vim.api.nvim_get_current_buf()
  check(vim.bo.filetype == "tex", "wrong filetype")
  check(vim.b.vimtex.tex == project .. "/main.tex", "child file did not resolve main.tex")
  check(
    vim.fn.maparg(" ll", "n") == "<Cmd>LatexLive<CR>"
      or vim.fn.maparg(" ll", "n"):lower() == "<cmd>latexlive<cr>",
    "LaTeX keymap missing"
  )
  check(vim.bo.omnifunc == "vimtex#complete#omnifunc", "VimTeX completion missing")
  check(vim.wo.spell and vim.wo.wrap, "prose settings missing")
  check(vim.treesitter.highlighter.active[buf] == nil, "Tree-sitter overrides VimTeX syntax")
  wait_for(function()
    return #vim.lsp.get_clients({ bufnr = buf, name = "texlab" }) == 1
  end, "Texlab did not attach")
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "% compile-on-write test" })
  vim.cmd.update()
  wait_for(function()
    return vim.fn.eval("b:vimtex.compiler.is_running() ? 1 : 0") == 1
  end, "writing a LaTeX file did not start the compiler")
  check(not vim.b.latex_live, "compile-on-write unexpectedly enabled live auto-save")
  vim.cmd.VimtexStop()
  latex.toggle()
  check(vim.b.latex_live, "live mode did not start")
  wait_for(function()
    return vim.fn.filereadable(project .. "/main.pdf") == 1
      and vim.fn.filereadable(project .. "/main.synctex.gz") == 1
      and vim.fn.filereadable(project .. "/main.bbl") == 1
  end, "initial PDF/SyncTeX/bibliography was not generated")
  local first_pdf = vim.uv.fs_stat(project .. "/main.pdf").mtime
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "Live preview integration test." })
  vim.api.nvim_exec_autocmds("TextChangedI", { buffer = buf })
  wait_for(function()
    return not vim.bo[buf].modified
  end, "insert-mode edit was not auto-saved")
  check(read(source):find("Live preview integration test.", 1, true), "wrong buffer was saved")
  wait_for(function()
    local stat = vim.uv.fs_stat(project .. "/main.pdf")
    return stat and (stat.mtime.sec ~= first_pdf.sec or stat.mtime.nsec ~= first_pdf.nsec)
  end, "PDF did not rebuild after live edit")
  -- Live mode must not overwrite a modification made by another program.
  vim.fn.writefile({ "% external edit" }, source, "a")
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "% unsaved local edit" })
  latex.save(buf)
  check(not vim.b.latex_live, "live mode did not pause on external edit")
  check(not read(source):find("unsaved local edit", 1, true), "external changes overwritten")
  vim.cmd("edit!")
  latex.toggle()
  check(vim.b.latex_live, "live mode did not restart")
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "% read-only edit" })
  vim.bo.readonly = true
  latex.save(buf)
  check(not read(source):find("read-only edit", 1, true), "read-only buffer was saved")
  vim.bo.readonly = false
  latex.schedule(buf)
  latex.stop(buf)
  vim.wait(150, function()
    return false
  end)
  check(vim.bo.modified, "pending save survived stop")
  check(not read(source):find("read-only edit", 1, true), "disabled live mode saved")
  vim.cmd.VimtexStopAll()
  check(vim.fn.eval("b:vimtex.compiler.is_running() ? 1 : 0") == 0, "compiler did not stop")
  vim.cmd("edit!")
  -- Personal snippets use the real engine, respect math context, and enter
  -- their first useful input field.
  vim.cmd.enew()
  vim.bo.filetype = "tex"
  local ls = require("luasnip")
  local snippets = dofile(vim.fn.stdpath("config") .. "/snippets/tex.lua")
  local function find_snippet(list, trigger)
    for _, snippet in ipairs(list) do
      if snippet.trigger == trigger then
        return snippet
      end
    end
    error("missing snippet: " .. trigger)
  end

  -- The trailing space lets a headless normal-mode cursor sit immediately
  -- after the trigger, matching insert-mode behavior.
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "start " })
  vim.api.nvim_win_set_cursor(0, { 1, 5 })
  check(ls.expand(), "article starter trigger did not expand")
  -- LuaSnip probes optional vim-repeat with :silent!, which may set v:errmsg
  -- when vim-repeat is absent even though expansion succeeds.
  vim.v.errmsg = ""
  local expanded = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  check(expanded:find("\\setlength{\\parindent}{0pt}", 1, true), "article starter paragraph style missing")
  check(expanded:find("\\setlength{\\parskip}{0.6em}", 1, true), "article starter spacing missing")
  check(
    expanded:find("\\section*{insert here}\n\n\\end{document}", 1, true),
    "article starter section or blank body line missing"
  )
  check(not expanded:find("\\title", 1, true), "obsolete course title remains in article starter")
  local current = ls.session.current_nodes[vim.api.nvim_get_current_buf()]
  check(current and current.pos == 1, "article starter did not select the section title")
  check(ls.jumpable(1), "article starter body field is unreachable")
  ls.jump(1)
  current = ls.session.current_nodes[vim.api.nvim_get_current_buf()]
  check(current and current.pos == 2, "article starter did not jump to the document body")
  ls.unlink_current()

  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "mm " })
  vim.api.nvim_win_set_cursor(0, { 1, 2 })
  ls.expand_auto()
  vim.wait(50)
  expanded = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  check(expanded:find("\\[\n  \n\\]", 1, true), "display-math snippet malformed")
  current = ls.session.current_nodes[vim.api.nvim_get_current_buf()]
  check(current and current.pos == 1, "display-math snippet cursor misplaced")
  ls.unlink_current()

  local prefix = "\\( "
  for _, case in ipairs({
    { "st", "\\sqrt{}", true },
    { "frac", "\\frac{}{}", true },
    { "cur", "\\{\\}", true },
    { "ve", "\\vec{}", true },
    { "BB", "\\mathbb{}", true },
    { "lim", "\\displaystyle \\lim_{ \\to }", true },
    { "RR", "\\mathbb{R}" },
    { "ZZ", "\\mathbb{Z}" },
    { "QQ", "\\mathbb{Q}" },
    { "NN", "\\mathbb{N}" },
    { "CC", "\\mathbb{C}" },
    { "not", "\\neg" },
    { "and", "\\land" },
    { "or", "\\lor" },
    { "implies", "\\implies" },
    { "iff", "\\iff" },
    { "<->", "\\leftrightarrow" },
    { "->", "\\rightarrow" },
    { "forall", "\\forall" },
    { "exists", "\\exists" },
    { "uni", "\\cup" },
    { "inter", "\\cap" },
    { "ep", "\\varepsilon" },
    { "ff", "f(x)" },
    { "gg", "g(x)" },
    { "hh", "h(x)" },
  }) do
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { prefix .. case[1] .. "  \\)" })
    vim.api.nvim_win_set_cursor(0, { 1, #prefix + #case[1] })
    ls.expand_auto()
    vim.wait(50)
    check(vim.api.nvim_get_current_line():find(case[2], 1, true), case[1] .. " snippet malformed")
    current = ls.session.current_nodes[vim.api.nvim_get_current_buf()]
    check(current and current.pos == (case[3] and 1 or 0), case[1] .. " snippet cursor misplaced")
    ls.unlink_current()
  end

  for _, case in ipairs({
    { "a0", "a_{0}" },
    { "z9", "z_{9}" },
    { "A1", "A_{1}" },
    { "Z8", "Z_{8}" },
  }) do
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { prefix .. case[1] .. "  \\)" })
    vim.api.nvim_win_set_cursor(0, { 1, #prefix + #case[1] })
    ls.expand_auto()
    vim.wait(50)
    check(vim.api.nvim_get_current_line():find(case[2], 1, true), case[1] .. " auto-subscript malformed")
    current = ls.session.current_nodes[vim.api.nvim_get_current_buf()]
    check(current and current.pos == 0, case[1] .. " auto-subscript cursor misplaced")
    ls.unlink_current()
  end

  for _, kind in ipairs({ "ag", "arr" }) do
    for _, size in ipairs({ 1, 2, 3 }) do
      local trigger = kind .. size
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { prefix .. trigger .. "  \\)" })
      vim.api.nvim_win_set_cursor(0, { 1, #prefix + #trigger })
      ls.expand_auto()
      vim.wait(50)
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local columns = kind == "ag" and (string.rep("r", size - 1) .. "|r") or string.rep("r", size)
      check(lines[1]:find("\\left[", 1, true), trigger .. " did not open the bracket")
      check(
        lines[2]:find("\\begin{array}{" .. columns .. "}", 1, true),
        trigger .. " has the wrong column layout"
      )
      check(#lines == size + 4, trigger .. " generated the wrong row count")
      check(lines[size + 3]:find("\\end{array}", 1, true), trigger .. " did not close the array")
      check(lines[size + 4]:find("\\right]", 1, true), trigger .. " did not close the bracket")
      for row = 1, size do
        local _, separators = lines[row + 2]:gsub(" & ", "")
        check(separators == size - 1, trigger .. " generated the wrong column count")
        if row < size then
          check(lines[row + 2]:sub(-2) == "\\\\", trigger .. " row separator is missing")
        end
      end
      current = ls.session.current_nodes[vim.api.nvim_get_current_buf()]
      check(current and current.pos == 1, trigger .. " did not select the first cell")
      for cell = 2, size * size do
        check(ls.jumpable(1), trigger .. " has an unreachable cell")
        ls.jump(1)
        current = ls.session.current_nodes[vim.api.nvim_get_current_buf()]
        check(current and current.pos == cell, trigger .. " cells are out of order")
      end
      check(ls.jumpable(1), trigger .. " has no exit field")
      ls.jump(1)
      current = ls.session.current_nodes[vim.api.nvim_get_current_buf()]
      check(current and current.pos == 0, trigger .. " did not exit after the last cell")
      ls.unlink_current()
    end
  end

  local original_input = vim.fn.input
  local answers = { "2", "3" }
  vim.fn.input = function()
    check(#answers > 0, "ARR requested more than two dimensions")
    return table.remove(answers, 1)
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { prefix .. "ARR  \\)" })
  vim.api.nvim_win_set_cursor(0, { 1, #prefix + 3 })
  local rectangular_ok, rectangular_error = pcall(ls.expand)
  vim.fn.input = original_input
  check(rectangular_ok and rectangular_error, "ARR did not expand: " .. tostring(rectangular_error))
  local rectangular = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  check(rectangular[2]:find("\\begin{array}{rrr}", 1, true), "ARR did not create three right-aligned columns")
  check(#rectangular == 6, "ARR did not create two rows")
  for row = 1, 2 do
    local _, separators = rectangular[row + 2]:gsub(" & ", "")
    check(separators == 2, "ARR created the wrong number of cells")
  end
  for cell = 2, 6 do
    check(ls.jumpable(1), "ARR has an unreachable cell")
    ls.jump(1)
    current = ls.session.current_nodes[vim.api.nvim_get_current_buf()]
    check(current and current.pos == cell, "ARR cells are out of order")
  end
  ls.unlink_current()

  vim.fn.input = function()
    return "0"
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { prefix .. "ARR  \\)" })
  vim.api.nvim_win_set_cursor(0, { 1, #prefix + 3 })
  local cancelled_ok, cancelled_error = pcall(ls.expand)
  vim.fn.input = original_input
  check(cancelled_ok and cancelled_error, "ARR cancellation failed: " .. tostring(cancelled_error))
  check(vim.api.nvim_get_current_line():find("ARR", 1, true), "invalid ARR dimensions removed the trigger")
  ls.unlink_current()

  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "ARR " })
  vim.api.nvim_win_set_cursor(0, { 1, 3 })
  check(not ls.expand(), "ARR expanded outside math mode")

  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "frac " })
  vim.api.nvim_win_set_cursor(0, { 1, 4 })
  ls.expand_auto()
  vim.wait(50)
  check(vim.api.nvim_get_current_line() == "frac ", "math snippet expanded in prose")

  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "x1 " })
  vim.api.nvim_win_set_cursor(0, { 1, 2 })
  ls.expand_auto()
  vim.wait(50)
  check(vim.api.nvim_get_current_line() == "x1 ", "auto-subscript expanded in prose")

  vim.api.nvim_buf_set_lines(0, 0, -1, false, { prefix .. "x->  \\)" })
  vim.api.nvim_win_set_cursor(0, { 1, #prefix + 3 })
  ls.expand_auto()
  vim.wait(50)
  check(
    vim.api.nvim_get_current_line():find("x\\rightarrow ", 1, true),
    "right arrow did not expand after a variable"
  )
  current = ls.session.current_nodes[vim.api.nvim_get_current_buf()]
  check(current and current.pos == 0, "right arrow cursor misplaced")
  ls.unlink_current()

  vim.api.nvim_buf_set_lines(0, 0, -1, false, { prefix .. "x<->  \\)" })
  vim.api.nvim_win_set_cursor(0, { 1, #prefix + 4 })
  ls.expand_auto()
  vim.wait(50)
  check(
    vim.api.nvim_get_current_line():find("x\\leftrightarrow ", 1, true),
    "left-right arrow did not expand after a variable"
  )
  current = ls.session.current_nodes[vim.api.nvim_get_current_buf()]
  check(current and current.pos == 0, "left-right arrow cursor misplaced")
  ls.unlink_current()

  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "x-> " })
  vim.api.nvim_win_set_cursor(0, { 1, 3 })
  ls.expand_auto()
  vim.wait(50)
  check(vim.api.nvim_get_current_line() == "x-> ", "right arrow expanded in prose")

  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "x<-> " })
  vim.api.nvim_win_set_cursor(0, { 1, 4 })
  ls.expand_auto()
  vim.wait(50)
  check(vim.api.nvim_get_current_line() == "x<-> ", "left-right arrow expanded in prose")

  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "arr3 " })
  vim.api.nvim_win_set_cursor(0, { 1, 5 })
  ls.expand_auto()
  vim.wait(50)
  check(vim.api.nvim_get_current_line() == "arr3 ", "array snippet expanded in prose")

  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "ag2 " })
  vim.api.nvim_win_set_cursor(0, { 1, 3 })
  ls.expand_auto()
  vim.wait(50)
  check(vim.api.nvim_get_current_line() == "ag2 ", "augmented array snippet expanded in prose")

  vim.api.nvim_buf_set_lines(0, 0, -1, false, { prefix .. "mm  \\)" })
  vim.api.nvim_win_set_cursor(0, { 1, #prefix + 2 })
  ls.expand_auto()
  vim.wait(50)
  check(vim.api.nvim_get_current_line() == prefix .. "mm  \\)", "display-math snippet expanded inside math")

  vim.cmd.enew()
  vim.bo.filetype = "tex"
  ls.snip_expand(find_snippet(snippets, "eq"))
  expanded = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  check(
    expanded:find("\\begin{equation}", 1, true) and expanded:find("\\end{equation}", 1, true),
    "environment snippet malformed"
  )
  -- Each expansion may repeat LuaSnip's harmless optional vim-repeat probe.
  vim.v.errmsg = ""
  check(vim.v.errmsg == "", "Neovim error during integration test: " .. vim.v.errmsg)
  print(
    "PASS: startup, plugins, personal mappings, Texlab, multi-file root, compile on write, PDF + bibliography + SyncTeX, live rebuild, external edits, read-only protection, timer cancellation, snippets"
  )
end
local ok, err = xpcall(run, debug.traceback)
if not ok then
  if vim.b.vimtex and vim.b.vimtex.compiler then
    local compiler = vim.b.vimtex.compiler
    io.stderr:write("Compiler command: " .. tostring(compiler.cmd) .. "\n")
    if compiler.output and vim.fn.filereadable(compiler.output) == 1 then
      io.stderr:write(table.concat(vim.fn.readfile(compiler.output), "\n") .. "\n")
    end
  end
  pcall(vim.cmd, "VimtexStopAll")
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
