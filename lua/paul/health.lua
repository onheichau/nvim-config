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
    if
      vim.fn.isdirectory("/Applications/Skim.app") == 1
      or vim.fn.isdirectory(vim.fn.expand("~/Applications/Skim.app")) == 1
    then
      vim.health.ok("Skim installed; <Space>lv opens the PDF at the current source line")
    else
      vim.health.error("Skim is missing", "brew install --cask skim")
    end
  end
  vim.health.info(
    "<Space>ll toggles auto-save for the current TeX buffer; <Space>ls stops it and the compiler."
  )
end
return M
