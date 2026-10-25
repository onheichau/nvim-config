local M = {}
function M.check()
  vim.health.start("School / LaTeX workflow")
  for _, executable in ipairs({ "git", "rg", "tree-sitter", "latexmk", "pdflatex", "bibtex", "texlab" }) do
    if vim.fn.executable(executable) == 1 then
      vim.health.ok(executable .. ": " .. vim.fn.exepath(executable))
    else
      vim.health.error(
        executable .. " is missing",
        "See README.md installation steps; :MasonInstall texlab for Texlab."
      )
    end
  end
  if vim.fn.has("mac") == 1 then
    if vim.fn.executable("synctex") == 1 then
      vim.health.ok("SyncTeX installed; <Space>lv follows the cursor's PDF page in native Preview")
    else
      vim.health.error("synctex is missing", "tlmgr install synctex")
    end
    vim.health.info("Preview UI automation uses your terminal's macOS Accessibility/Automation access.")
  end
  vim.health.info(
    "<Space>ll toggles auto-save for the current TeX buffer; <Space>ls stops it and the compiler."
  )
end
return M
