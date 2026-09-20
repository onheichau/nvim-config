vim.opt_local.conceallevel = 0
vim.opt_local.foldenable = false
local function map(key, command, desc)
  vim.keymap.set("n", "<leader>l" .. key, command, { buffer = true, desc = desc })
end
map("l", "<cmd>LatexLive<cr>", "Toggle LaTeX live auto-save")
map("c", "<cmd>VimtexCompile<cr>", "Start/stop continuous compiler")
map("v", "<cmd>VimtexView<cr>", "View PDF / forward search")
map("e", "<cmd>VimtexErrors<cr>", "LaTeX errors")
map("o", "<cmd>VimtexCompileOutput<cr>", "LaTeX compiler output")
map("t", "<cmd>VimtexTocOpen<cr>", "LaTeX table of contents")
map("i", "<cmd>VimtexInfo<cr>", "LaTeX project info")
map("s", function()
  require("paul.latex").stop()
  vim.cmd.VimtexStop()
end, "Stop live mode and compiler")
