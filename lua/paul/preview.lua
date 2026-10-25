local M = {}
local locations = {}
local scroll_anchors = {}
local opened_sources = {}
local active_project
local last_method = "No refresh yet"
local last_detail = ""
local generation = 0
local busy, pending, warned = false, nil, false

local function remember()
  local state = vim.b.vimtex
  if vim.bo.filetype == "tex" and state and state.tex then
    if active_project ~= state.tex then
      active_project = state.tex
      generation = generation + 1
      pending = nil
    end
    locations[state.tex] = {
      source = vim.api.nvim_buf_get_name(0),
      line = vim.api.nvim_win_get_cursor(0)[1],
    }
  end
end

local function warn(message)
  if not warned then
    warned = true
    vim.notify("Preview sync: " .. message, vim.log.levels.WARN)
  end
end

local function source_identity(path)
  local stat = vim.uv.fs_stat(path)
  return stat and table.concat({ path, stat.dev, stat.ino }, ":") or nil
end

local function pdf_ready(path)
  local fd = vim.uv.fs_open(path, "r", 0)
  if not fd then
    return false
  end
  local stat = vim.uv.fs_fstat(fd)
  local header = stat and vim.uv.fs_read(fd, 5, 0)
  local tail = stat and vim.uv.fs_read(fd, math.min(1024, stat.size), math.max(0, stat.size - 1024))
  vim.uv.fs_close(fd)
  return header == "%PDF-" and tail and tail:find("%%EOF", 1, true) ~= nil
end

local launch
launch = function(request)
  -- Revalidate after async SyncTeX/queued UI work: the source may have been
  -- deleted or replaced, or a different document may now be active.
  if
    request.generation ~= generation
    or source_identity(request.main) ~= request.identity
    or not pdf_ready(request.pdf)
  then
    return
  end
  if busy then
    pending = request
    return
  end
  local reopen = opened_sources[request.pdf] ~= request.identity
  if reopen then
    scroll_anchors[request.pdf] = nil
  end
  busy = true
  local script = vim.api.nvim_get_runtime_file("scripts/preview-sync.applescript", false)[1]
  if not script then
    busy = false
    return warn("preview-sync.applescript is missing")
  end
  local display_script = vim.g.latex_preview_builtin_display ~= false
      and vim.api.nvim_get_runtime_file("scripts/preview-display.js", false)[1]
    or ""
  vim.system(
    {
      "osascript",
      script,
      request.pdf,
      vim.uri_from_fname(request.pdf),
      tostring(request.page),
      display_script or "",
      vim.g.latex_preview_scroll_restore ~= false and (scroll_anchors[request.pdf] or "") or "",
      reopen and "1" or "0",
    },
    {
      text = true,
    },
    vim.schedule_wrap(function(result)
      busy = false
      if result.code ~= 0 then
        scroll_anchors[request.pdf] = nil
        local message = vim.trim(result.stderr)
        if message:find("(-1719)", 1, true) or message:find("(-1743)", 1, true) then
          message = message .. " (check your terminal's macOS Accessibility/Automation access)"
        end
        warn(message)
      else
        opened_sources[request.pdf] = request.identity
        scroll_anchors[request.pdf] = nil
        for line in result.stdout:gmatch("[^\r\n]+") do
          local anchor = line:match("^PREVIEW_ANCHOR:(.+)$")
          local method = line:match("^PREVIEW_METHOD:(.+)$")
          local detail = line:match("^PREVIEW_DETAIL:(.+)$")
          if anchor then
            scroll_anchors[request.pdf] = anchor
          elseif method then
            last_method = method
          elseif detail then
            last_detail = detail
          elseif vim.trim(line) ~= "" then
            warn(vim.trim(line))
          end
        end
      end
      if pending then
        local next_request = pending
        pending = nil
        launch(next_request)
      end
    end)
  )
end

function M.refresh()
  local state = vim.b.vimtex
  if not state or vim.g.vimtex_view_enabled == 0 then
    return
  end
  remember()
  local ok, pdf = pcall(vim.fn.eval, "b:vimtex.compiler.get_file('pdf')")
  if not ok or pdf == "" or vim.fn.filereadable(pdf) ~= 1 then
    return
  end
  pdf = vim.uv.fs_realpath(pdf) or pdf
  local location = locations[state.tex]
  generation = generation + 1
  local current = generation
  local identity = source_identity(state.tex)
  if not identity then
    scroll_anchors[pdf] = nil
    opened_sources[pdf] = nil
    return
  end
  local function request(page)
    launch({ pdf = pdf, page = page, main = state.tex, identity = identity, generation = current })
  end
  if not location or vim.g.latex_preview_follow_cursor == false then
    request(0)
    return
  end
  if vim.fn.executable("synctex") == 0 then
    warn("synctex is missing; install it with tlmgr install synctex")
    request(0)
    return
  end
  vim.system(
    {
      "synctex",
      "view",
      "-i",
      location.line .. ":1:" .. location.source,
      "-o",
      pdf,
    },
    { text = true },
    vim.schedule_wrap(function(result)
      if current ~= generation then
        return
      end
      local page = result.code == 0 and tonumber(result.stdout:match("\nPage:(%d+)")) or nil
      -- Blank lines/preamble may have no SyncTeX location: refresh without jumping.
      request(page or 0)
    end)
  )
end

function M.setup()
  local group = vim.api.nvim_create_augroup("LatexPreviewRefresh", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "CursorMoved", "CursorMovedI" }, {
    group = group,
    pattern = "*.tex",
    callback = remember,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "VimtexEventCompileSuccess",
    callback = M.refresh,
  })
  vim.api.nvim_create_user_command("LatexPreview", M.refresh, {
    desc = "Refresh native Preview and follow the cursor's PDF page",
    force = true,
  })
  vim.api.nvim_create_user_command("LatexPreviewInfo", function()
    vim.notify("Preview refresh method: " .. last_method .. "; " .. last_detail)
  end, { desc = "Show the most recent Preview refresh method", force = true })
end

return M
