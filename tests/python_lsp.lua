local source = vim.fn.tempname() .. ".py"

local function check(value, message)
  assert(value, message)
end

local function run()
  vim.fn.writefile({ "import re", "", "re. " }, source)
  vim.cmd.edit(vim.fn.fnameescape(source))

  check(
    vim.wait(8000, function()
      return #vim.lsp.get_clients({ bufnr = 0, name = "pyright" }) == 1
    end, 100),
    "Pyright did not attach to a Python buffer"
  )

  local client = vim.lsp.get_clients({ bufnr = 0, name = "pyright" })[1]
  vim.wait(1000)
  vim.api.nvim_win_set_cursor(0, { 3, 3 })

  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
  local responses = vim.lsp.buf_request_sync(0, "textDocument/completion", params, 8000)
  check(responses, "Pyright completion request timed out")

  local labels = {}
  for _, response in pairs(responses) do
    local result = response.result
    local items = result and (result.items or result) or {}
    for _, item in ipairs(items) do
      labels[item.label] = true
    end
  end

  check(labels.compile, "Pyright did not offer re.compile")
  check(labels.search, "Pyright did not offer re.search")
  check(labels.match, "Pyright did not offer re.match")

  require("lazy").load({ plugins = { "nvim-cmp" } })
  local cmp = require("cmp")
  local autocomplete = cmp.get_config().completion.autocomplete
  check(vim.tbl_contains(autocomplete, cmp.TriggerEvent.TextChanged), "automatic completion is disabled")

  print("PASS: Pyright attaches, completes the re module, and automatic completion is enabled")
end

local ok, err = xpcall(run, debug.traceback)
vim.fn.delete(source)
if not ok then
  error(err)
end
