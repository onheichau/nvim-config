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
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "starter " })
  vim.api.nvim_win_set_cursor(0, { 1, 7 })
  check(ls.expand(), "course starter trigger did not expand")
  -- LuaSnip probes optional vim-repeat with :silent!, which may set v:errmsg
  -- when vim-repeat is absent even though expansion succeeds.
  vim.v.errmsg = ""
  local expanded = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  check(expanded:find("\\title{Course code", 1, true), "course starter title missing")
  check(expanded:find("\\section*{Problem 1}", 1, true), "course starter body missing")
  local current = ls.session.current_nodes[vim.api.nvim_get_current_buf()]
  check(current and current.pos == 1, "course starter did not select course code")
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
    { "sroot", "\\sqrt{}", true },
    { "frac", "\\frac{}{}", true },
    { "cur", "\\{\\}", true },
    { "lim", "\\lim_{ \\to }", true },
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
    { "forall", "\\forall" },
    { "exists", "\\exists" },
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

  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "frac " })
  vim.api.nvim_win_set_cursor(0, { 1, 4 })
  ls.expand_auto()
  vim.wait(50)
  check(vim.api.nvim_get_current_line() == "frac ", "math snippet expanded in prose")

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
