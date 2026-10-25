local M = {}
local locations = {}
local scroll_anchors = {}
local last_method = "No refresh yet"
local last_detail = ""
local generation = 0
local busy, pending, warned = false, nil, false
local active_process, last_project
local closing = false
local handed_off = {}

local function remember()
  local state = vim.b.vimtex
  if vim.bo.filetype == "tex" and state and state.tex then
    last_project = state.tex
    handed_off[state.tex] = nil
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = vim.api.nvim_get_current_line()
    locations[state.tex] = {
      source = vim.api.nvim_buf_get_name(0),
      line = cursor[1],
      column = cursor[2] + 1,
      before = line:sub(1, cursor[2]),
      after = line:sub(cursor[2] + 1),
    }
  end
end

local function warn(message)
  if not warned then
    warned = true
    vim.notify("Preview sync: " .. message, vim.log.levels.WARN)
  end
end

local launch
launch = function(request)
  if closing then
    return
  end
  if busy then
    pending = request
    return
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
  active_process = vim.system(
    {
      "osascript",
      script,
      request.pdf,
      vim.uri_from_fname(request.pdf),
      tostring(request.page),
      display_script or "",
      vim.g.latex_preview_scroll_restore ~= false and (scroll_anchors[request.pdf] or "") or "",
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
  if closing then
    return
  end
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
  if not location or vim.g.latex_preview_follow_cursor == false then
    launch({ pdf = pdf, page = 0 })
    return
  end
  if vim.fn.executable("synctex") == 0 then
    warn("synctex is missing; install it with tlmgr install synctex")
    launch({ pdf = pdf, page = 0 })
    return
  end
  vim.system(
    {
      "synctex",
      "view",
      "-i",
      location.line .. ":" .. location.column .. ":" .. location.source,
      "-o",
      pdf,
    },
    { text = true },
    vim.schedule_wrap(function(result)
      if current ~= generation then
        return
      end
      local page = result.code == 0 and tonumber(result.stdout:match("\nPage:(%d+)")) or nil
      local pages, seen = {}, {}
      for candidate in result.stdout:gmatch("\nPage:(%d+)") do
        candidate = tonumber(candidate)
        if not seen[candidate] then
          pages[#pages + 1] = candidate
          seen[candidate] = true
        end
      end
      local resolver = vim.api.nvim_get_runtime_file("scripts/preview-page.js", false)[1]
      if #pages > 1 and resolver and vim.fn.has("mac") == 1 then
        -- SyncTeX may map a long soft-wrapped source line to several pages.
        -- Use PDFKit text around the cursor only for that ambiguous case.
        vim.system(
          { "osascript", "-l", "JavaScript", resolver, pdf },
          {
            text = true,
            stdin = vim.json.encode({ pages = pages, before = location.before, after = location.after }),
          },
          vim.schedule_wrap(function(resolved)
            if current ~= generation then
              return
            end
            local decoded, answer = pcall(vim.json.decode, resolved.stdout or "")
            local selected = resolved.code == 0 and decoded and type(answer) == "table" and answer.page
            launch({
              pdf = pdf,
              page = type(selected) == "number" and seen[selected] and selected or page or 0,
            })
          end)
        )
        return
      end
      -- Blank lines/preamble may have no SyncTeX location: refresh without jumping.
      launch({ pdf = pdf, page = page or 0 })
    end)
  )
end

function M.finish()
  if vim.g.latex_preview_focus_on_exit == false or vim.g.vimtex_view_enabled == 0 then
    return
  end
  local state = vim.b.vimtex
  if not state or handed_off[state.tex] then
    return
  end
  local exiting = vim.v.exiting ~= vim.NIL
  -- VimTeX quits every loaded project at exit; hand off only the last edited one.
  if exiting and last_project and state.tex ~= last_project then
    return
  end
  local ok, pdf = pcall(vim.fn.eval, "b:vimtex.compiler.get_file('pdf')")
  if not ok or pdf == "" or vim.fn.filereadable(pdf) ~= 1 then
    return
  end
  local script = vim.api.nvim_get_runtime_file("scripts/preview-finish.applescript", false)[1]
  local display = vim.api.nvim_get_runtime_file("scripts/preview-display.js", false)[1]
  if not script or not display then
    return
  end
  closing = true
  generation = generation + 1
  pending = nil
  handed_off[state.tex] = true
  pdf = vim.uv.fs_realpath(pdf) or pdf
  vim.fn.jobstart({
    "osascript",
    script,
    pdf,
    vim.uri_from_fname(pdf),
    display,
    tostring(busy and active_process and active_process.pid or 0),
  }, { detach = true })
  if not exiting then
    closing = false
  end
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
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "VimtexEventQuit",
    callback = M.finish,
    desc = "Focus the completed PDF and move it to an external display on project exit",
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
