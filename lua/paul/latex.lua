local M = {}
local timers, disk_versions = {}, {}

local starter_document = {
  "\\documentclass[11pt]{article}",
  "\\usepackage[T1]{fontenc}",
  "\\usepackage{amsmath,amssymb}",
  "\\usepackage[margin=1in]{geometry}",
  "\\usepackage{hyperref}",
  "",
  "\\title{Untitled}",
  "\\author{Your name}",
  "\\date{\\today}",
  "",
  "\\begin{document}",
  "\\maketitle",
  "",
  "Start writing here.",
  "",
  "\\end{document}",
}

local function disk_version(buf)
  local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
  return stat and table.concat({ stat.mtime.sec, stat.mtime.nsec, stat.size }, ":") or "missing"
end

local function cancel(buf)
  if timers[buf] then
    timers[buf]:stop()
    timers[buf]:close()
    timers[buf] = nil
  end
end

function M.stop(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  cancel(buf)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.b[buf].latex_live = false
  end
  disk_versions[buf] = nil
end

local function writable(buf)
  return vim.api.nvim_buf_is_valid(buf)
    and vim.api.nvim_buf_is_loaded(buf)
    and vim.bo[buf].buftype == ""
    and vim.bo[buf].modifiable
    and not vim.bo[buf].readonly
    and vim.api.nvim_buf_get_name(buf) ~= ""
    and vim.bo[buf].filetype == "tex"
end

local function empty(buf)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    if line:find("%S") then
      return false
    end
  end
  return true
end

local function create_starter(buf)
  if not empty(buf) then
    return false
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, starter_document)
  vim.api.nvim_win_set_cursor(0, { 14, 0 })
  vim.cmd.update()
  -- VimTeX inspected the empty buffer during FileType. Re-detect the main file
  -- now that it contains a complete document.
  vim.cmd("silent VimtexReloadState")
  return true
end

function M.save(buf)
  if not writable(buf) or not vim.b[buf].latex_live or not vim.bo[buf].modified then
    return
  end
  if disk_versions[buf] ~= disk_version(buf) then
    M.stop(buf)
    vim.notify(
      "LaTeX live paused: file changed outside Neovim. Resolve it before enabling live again.",
      vim.log.levels.WARN
    )
    return
  end
  local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
    vim.cmd("silent update")
  end)
  if not ok then
    M.stop(buf)
    vim.notify("LaTeX live paused: " .. tostring(err), vim.log.levels.ERROR)
  end
end

function M.schedule(buf)
  cancel(buf)
  if not writable(buf) or not vim.b[buf].latex_live then
    return
  end
  local timer = assert(vim.uv.new_timer())
  timers[buf] = timer
  timer:start(
    vim.g.latex_live_delay or 800,
    0,
    vim.schedule_wrap(function()
      -- A stopped/replaced timer can already have a callback on the main queue.
      if timers[buf] ~= timer then
        return
      end
      cancel(buf)
      M.save(buf)
    end)
  )
end

function M.toggle()
  local buf = vim.api.nvim_get_current_buf()
  if vim.b[buf].latex_live then
    M.stop(buf)
    vim.notify("LaTeX live off. The compiler still updates the PDF on manual saves.")
    return
  end
  if not writable(buf) or not vim.b.vimtex then
    vim.notify("Open a named, writable LaTeX file first.", vim.log.levels.WARN)
    return
  end
  if vim.fn.executable("latexmk") == 0 then
    vim.notify("latexmk is missing. See the README's LaTeX installation steps.", vim.log.levels.ERROR)
    return
  end
  local created = create_starter(buf)
  -- Regular :update preserves normal write hooks and file-conflict protection.
  vim.cmd.update()
  if vim.fn.eval("b:vimtex.compiler.is_running() ? 1 : 0") == 0 then
    vim.fn["vimtex#compiler#start"]()
  end
  if vim.fn.eval("b:vimtex.compiler.is_running() ? 1 : 0") == 0 then
    vim.notify("LaTeX live could not start the compiler. See :VimtexInfo.", vim.log.levels.ERROR)
    return
  end
  vim.b[buf].latex_live = true
  disk_versions[buf] = disk_version(buf)
  if created then
    vim.notify("Created a starter document. LaTeX live is on; start typing in the document body.")
    if #vim.api.nvim_list_uis() > 0 then
      vim.cmd.startinsert()
    end
  else
    vim.notify("LaTeX live on: this buffer saves after an 800 ms typing pause.")
  end
end

function M.setup()
  vim.api.nvim_create_user_command(
    "LatexLive",
    M.toggle,
    { desc = "Toggle LaTeX live auto-save for this buffer" }
  )
  local group = vim.api.nvim_create_augroup("PaulLatexLive", { clear = true })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP", "InsertLeave" }, {
    group = group,
    callback = function(event)
      M.schedule(event.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(event)
      if vim.b[event.buf].latex_live then
        disk_versions[event.buf] = disk_version(event.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = group,
    callback = function(event)
      M.stop(event.buf)
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      for buf in pairs(timers) do
        cancel(buf)
      end
    end,
  })
end

return M
