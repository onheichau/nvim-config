"""Run with python3 tests/cleanup.py; all compilation/deletion uses temporary files."""

import os
import json
from pathlib import Path
import subprocess
import tempfile


SOURCE = r"""\documentclass{article}
\usepackage{hyperref}
\begin{document}
Cleanup test.
\end{document}
"""

SCRIPT = r"""
local ok, err = pcall(function()
  vim.g.vimtex_view_enabled = 0
  vim.cmd.edit(vim.fn.fnameescape(vim.env.CLEANUP_SOURCE))
  assert(require('paul.latex').compile(), 'compiler did not start')
  local root = vim.fn.fnamemodify(vim.env.CLEANUP_SOURCE, ':h')
  assert(vim.wait(30000, function()
    return vim.fn.filereadable(root .. '/test.pdf') == 1
      and vim.fn.filereadable(root .. '/test.synctex.gz') == 1
      and vim.fn.eval('b:vimtex.compiler.status') == 2
  end, 100), 'PDF and SyncTeX were not generated')
  vim.wait(300)
  vim.fn.writefile({'formatter log'}, root .. '/indent.log')
  -- Capture the real quit event's detached handoff; never launch GUI in tests.
  local jobstart = vim.fn.jobstart
  vim.fn.jobstart = function(command, options)
    if command[1] == 'osascript' and command[2]:find('preview%-finish%.applescript$') then
      vim.fn.writefile({vim.json.encode({command = command, detach = options.detach})}, vim.env.CLEANUP_HANDOFF)
      return 123
    end
    return jobstart(command, options)
  end
  local system = vim.system
  vim.system = function(command, options, callback)
    if command[1] == 'osascript' then
      if callback then callback({code = 0, stdout = '', stderr = ''}) end
      return {pid = 0}
    end
    return system(command, options, callback)
  end
  vim.g.vimtex_view_enabled = 1
  if vim.env.CLEANUP_QUIT == 'q!' then
    vim.api.nvim_buf_set_lines(0, -1, -1, false, {'% unsaved edit'})
  elseif vim.env.CLEANUP_QUIT == 'x' then
    vim.bo.modified = true
  end
  vim.cmd(vim.env.CLEANUP_QUIT)
  if vim.env.CLEANUP_QUIT == 'bwipeout!' then
    vim.cmd('qall!')
  end
end)
if not ok then
  print(err)
  vim.cmd('cquit 1')
end
"""


with tempfile.TemporaryDirectory(prefix="nvim-latex-cleanup-") as temporary:
    base = Path(temporary)
    config = base / "config"
    config.mkdir()
    (config / "nvim").symlink_to(Path(__file__).resolve().parents[1])
    script = base / "cleanup.lua"
    script.write_text(SCRIPT)
    for command in ("q", "q!", "x", "wq", "bwipeout!"):
        project = base / ("project with spaces " + command)
        project.mkdir()
        source = project / "test.tex"
        source.write_text(SOURCE)
        protected = {
            "notes.txt": "Keep these notes",
            "other.tex": "Other source",
            "other.pdf": "Other PDF",
            "other.aux": "Other project's auxiliary file",
            "references.bib": "Bibliography source",
        }
        for name, contents in protected.items():
            (project / name).write_text(contents)
        env = dict(os.environ, XDG_CONFIG_HOME=str(config),
                   XDG_STATE_HOME=str(base / "state"), XDG_CACHE_HOME=str(base / "cache"),
                   CLEANUP_SOURCE=str(source), CLEANUP_QUIT=command,
                   CLEANUP_HANDOFF=str(base / ("handoff-" + command + ".json")))
        result = subprocess.run(
            ["nvim", "--headless", "-i", "NONE", "+luafile " + str(script)],
            env=env, cwd=project, text=True, capture_output=True, timeout=45,
        )
        assert result.returncode == 0, result.stdout + result.stderr
        assert "LaTeX cleanup:" not in result.stderr, result.stderr
        assert source.read_text() == SOURCE, f"{command}: source changed"
        assert (project / "test.pdf").read_bytes().startswith(b"%PDF"), command
        for name, contents in protected.items():
            assert (project / name).read_text() == contents, f"{command}: changed {name}"
        remaining = {path.name for path in project.iterdir()}
        assert remaining == {*protected, "test.tex", "test.pdf"}, (command, remaining)
        handoff = json.loads(Path(env['CLEANUP_HANDOFF']).read_text())
        assert handoff['detach'] is True, "PDF handoff would end when Neovim exits"
        assert handoff['command'][2] == str((project / 'test.pdf').resolve()), handoff
        assert handoff['command'][4].endswith('/scripts/preview-display.js'), handoff
        print(f"PASS {command}: cleanup and detached handoff of the correct PDF")
