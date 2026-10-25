-- Real TeX + SyncTeX + native PDFKit; intercept only Preview GUI launch.
local ok, err = pcall(function()
  vim.g.vimtex_view_enabled = 0
  local root = vim.fn.tempname() .. " natural page test"
  vim.fn.mkdir(root, "p")
  local source, pdf = root .. "/main.tex", root .. "/main.pdf"
  local sentences = {}
  for index = 1, 300 do
    sentences[#sentences + 1] = ("Unique%d text wraps naturally and continues along the page."):format(index)
  end
  local body = table.concat(sentences, " ")
  vim.fn.writefile({
    "\\documentclass[11pt]{article}",
    "\\usepackage[margin=1in]{geometry}",
    "\\begin{document}",
    body,
    "\\end{document}",
  }, source)
  local build = vim
    .system({ "pdflatex", "-synctex=1", "-interaction=nonstopmode", "main.tex" }, {
      cwd = root,
      text = true,
    })
    :wait()
  assert(build.code == 0, build.stdout)
  local resolver = vim.api.nvim_get_runtime_file("scripts/preview-page.js", false)[1]
  local inspected = vim
    .system({ "osascript", "-l", "JavaScript", resolver, "--inspect", pdf }, { text = true })
    :wait()
  assert(inspected.code == 0, inspected.stderr)
  local pages = vim.json.decode(inspected.stdout)
  assert(#pages >= 3, "fixture did not flow naturally across three pages")
  local marker = tonumber(pages[2].text:match("Unique(%d+)"))
  local marker_start = assert(body:find("Unique" .. marker .. " ", 1, true))
  local previous_start = assert(body:find("Unique" .. (marker - 1) .. " ", 1, true))
  local first_word = assert(pages[2].text:match("^%s*([%w]+)"))
  local segment = body:sub(previous_start, marker_start - 1)
  local offset = segment:find(first_word, 1, true)
  local boundary = offset and (previous_start + offset - 1) or marker_start
  local previous_word = assert(body:sub(1, boundary - 1):find("%w+%W*$"))
  local third_marker = assert(pages[3].text:match("Unique%d+"))

  vim.cmd.edit(vim.fn.fnameescape(source))
  local system = vim.system
  local launches = {}
  vim.system = function(command, options, callback)
    if command[1] == "osascript" and command[2]:match("preview%-sync%.applescript$") then
      launches[#launches + 1] = command
      vim.schedule(function()
        callback({ code = 0, stdout = "", stderr = "" })
      end)
      return {}
    end
    return system(command, options, callback)
  end
  vim.g.vimtex_view_enabled = 1
  for index, case in ipairs({
    { previous_word, 1 },
    { boundary, 2 },
    { marker_start, 2 },
    { assert(body:find(third_marker .. " ", 1, true)), 3 },
  }) do
    vim.api.nvim_win_set_cursor(0, { 4, case[1] - 1 })
    require("paul.preview").refresh()
    assert(
      vim.wait(5000, function()
        return #launches == index
      end, 10),
      "natural-page refresh timed out"
    )
    assert(
      tonumber(launches[index][5]) == case[2],
      ("cursor column %d: expected page %d, got %s"):format(case[1], case[2], launches[index][5])
    )
    vim.wait(30)
  end
  vim.system = system
  vim.g.vimtex_view_enabled = 0
  print("PASS: no newpage commands; both sides of the page 1/2 boundary; natural pages 2 and 3")
end)
if not ok then
  print(err)
  vim.g.vimtex_view_enabled = 0
  vim.cmd("cquit 1")
end
vim.cmd("qall!")
