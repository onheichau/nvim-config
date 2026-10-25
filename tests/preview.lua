-- Run headlessly with this config loaded. Actual SyncTeX; intercept only GUI launch.
local ok, err = pcall(function()
  vim.g.vimtex_view_enabled = 0
  local root = vim.fn.tempname() .. " preview test"
  vim.fn.mkdir(root, "p")
  local source = root .. "/main.tex"
  vim.fn.writefile({
    "\\documentclass{article}",
    "\\begin{document}",
    "First page.",
    "\\newpage",
    "Second page.",
    "\\newpage",
    "Third page: cursor target.",
    "\\end{document}",
  }, source)
  local build = vim
    .system({ "pdflatex", "-synctex=1", "-interaction=nonstopmode", "main.tex" }, {
      cwd = root,
      text = true,
    })
    :wait()
  assert(build.code == 0, build.stdout)
  vim.cmd.edit(vim.fn.fnameescape(source))
  local preview = require("paul.preview")
  preview.setup()
  local system = vim.system
  local launches = {}
  vim.system = function(command, options, callback)
    if command[1] ~= "osascript" then
      return system(command, options, callback)
    end
    launches[#launches + 1] = command
    vim.schedule(function()
      callback({ code = 0, stdout = "", stderr = "" })
    end)
    return {}
  end
  vim.g.vimtex_view_enabled = 1
  for index, case in ipairs({ { 7, "3" }, { 3, "1" } }) do
    vim.api.nvim_win_set_cursor(0, { case[1], 0 })
    if index == 1 then
      vim.api.nvim_exec_autocmds("User", { pattern = "VimtexEventCompileSuccess" })
    else
      vim.cmd.LatexPreview()
    end
    assert(
      vim.wait(5000, function()
        return #launches == index
      end, 10),
      "Preview request did not complete"
    )
    assert(launches[index][3] == vim.uv.fs_realpath(root .. "/main.pdf"), "wrong PDF")
    assert(launches[index][5] == case[2], "wrong SyncTeX page")
    assert(launches[index][6]:match("preview%-display%.js$"), "display placement helper missing")
  end
  vim.g.latex_preview_follow_cursor = false
  preview.refresh()
  assert(
    vim.wait(5000, function()
      return #launches == 3
    end, 10),
    "refresh without cursor following failed"
  )
  assert(launches[3][5] == "0", "disabled following still jumped to a page")
  vim.g.latex_preview_builtin_display = false
  preview.refresh()
  assert(
    vim.wait(5000, function()
      return #launches == 4
    end, 10),
    "refresh with display placement disabled failed"
  )
  assert(launches[4][6] == "", "disabled display placement still invoked the helper")
  vim.system = system
  vim.g.vimtex_view_enabled = 0
  print("PASS: real SyncTeX maps cursor to pages 3 and 1; paths with spaces; follow toggle")
end)
if not ok then
  print(err)
  vim.cmd("cquit 1")
end
vim.cmd("qall!")
