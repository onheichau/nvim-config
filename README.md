# Neovim for code and LaTeX schoolwork

Requires **Neovim 0.12.4+**; tested with 0.12.5 on Apple Silicon macOS.
The leader is **Space** and VimTeX's local leader is **comma**.

## Start writing

Restart Neovim after upgrading. The first launch installs plugins with lazy.nvim;
wait for downloads and Mason's `texlab` / `lua-language-server` installation to finish.

```sh
cp -R ~/.config/nvim/examples/assignment ~/Documents/my-assignment
cd ~/Documents/my-assignment
nvim main.tex
```

- Every `:w` starts the continuous compiler when needed and rebuilds the PDF.
- **Space l c** manually starts/stops the continuous compiler.
- **Space l l** enables live editing for the current `.tex` buffer: after an **800 ms
  pause**, the buffer is saved and `latexmk` rebuilds the PDF in Skim. On a new, empty
  file it first creates a minimal article and places the cursor in the document body.
  The statusline says `LaTeX LIVE`. Press again to disable auto-save; manual saves still compile.
- **Space l v** opens the PDF and jumps to the current source position.
- **Space l s** disables auto-save for this buffer and stops its project's compiler.
- **Space l e** shows compilation errors; **Space l o** opens compiler output.
- **Space l t** opens the document outline; **Space l i** shows project information.

Live mode **writes your edits to disk**, including incomplete equations. It is opt-in,
per buffer and per session. Enable it separately in each chapter you edit; save `.bib`
files manually. It ignores unnamed/read-only/special buffers and pauses if the source
file changes outside Neovim. Normal writes, undo history and write hooks are preserved.
The previous successful PDF remains visible while a new edit has a compilation error.
Rendering follows a typing pause plus compiler time; it is not an unsaved-buffer renderer.

For included files, put `% !TeX root = ../main.tex` on the first line (adjust the path).
The sample includes a chapter, equation reference and BibTeX bibliography. VimTeX/latexmk
handle the main document, repeated passes and bibliography generation.
Use `% !TeX program = xelatex` or `lualatex` at the top of the main file if your course needs it.

## Completion and snippets

Texlab provides diagnostics and navigation; VimTeX completes citations, labels and LaTeX
commands. LuaSnip provides the snippet engine, including automatic-snippet support for the
custom LaTeX collection. Tab / Shift-Tab move between editable fields. Ctrl-j / Ctrl-k
select completion candidates; Enter confirms only a selected candidate; Ctrl-Space opens
completion and Ctrl-e closes it.

| Trigger | Expansion |
| --- | --- |
| `ii` | Inline math `\(…\)` while writing prose |
| `mm` | Display math `\[ … \]` while writing prose |
| `mc` | Display math containing a two-row `cases` environment |
| `st` | `\sqrt{…}` |
| `frac` | `\frac{…}{…}` |
| `pwo` | Power `^{…}`, including directly after a variable |
| `cur` | Escaped set braces `\{…\}` |
| `abs` / `norm` | Absolute value `\lvert … \rvert` / bold-vector norm `\lVert \mathbf{…} \rVert` |
| `mbf` | Bold math `\mathbf{…}` |
| `RR` / `ZZ` / `QQ` / `NN` / `CC` | Real, integer, rational, natural, and complex number sets |
| `lim` | `\lim_{… \to …}` followed by the expression |
| `not` / `and` / `or` | `\neg` / `\land` / `\lor` |
| `implies` / `iff` | `\implies` / `\iff` |
| `forall` / `exists` | `\forall` / `\exists` |
| `in` | Set membership `\in` |
| `mid` | Set-builder separator `\mid` |
| `md` | Dot product `\cdot` |
| `>=` / `<=` | `\ge` / `\le`, including directly after a variable |
| `starter` + **Tab** | Complete course-assignment document in an otherwise empty `.tex` file |
| `eq` / `sec` / `item` + **Tab** | Numbered equation, labeled section, or list item |

`mm` expands automatically outside math and places the cursor inside the display. The
other math triggers expand automatically only inside a VimTeX math zone. Their first
editable field is selected immediately; Tab / Shift-Tab moves through later fields. The
`starter` snippet asks for course code, assignment, name, and student ID in that order,
then places the cursor under Problem 1.

Existing personal mappings, PDF commands and snippets remain in `lua/paul/keyremap.lua`
and `lua/paul/snippets.lua`. The `a/A`, `v/V`, `s/S` swaps and buffer navigation are retained.
Native `gc` / `gcc` handle comments. `Space gs` opens Fugitive status, and `Space gc`
opens a commit editor. `Space ff/fg/fb/fh` find files/search/buffers/help; `Space f` formats.
Spellcheck and soft wrapping are scoped to prose and LaTeX; automatic directory changes
are disabled so multi-file project roots stay stable.

## Install on macOS

```sh
brew install neovim git ripgrep tree-sitter-cli
brew install --cask skim
```

Install **one** TeX distribution. A compact, non-admin option is
[TinyTeX](https://github.com/rstudio/tinytex-releases). The current official macOS bundle
can be installed without changing your shell profile:

```sh
# Refuse to replace an existing installation.
test ! -e "$HOME/Library/TinyTeX" && (
  archive=$(mktemp -t tinytex)
  curl -fL https://github.com/rstudio/tinytex-releases/releases/download/daily/TinyTeX-1-darwin.tar.xz -o "$archive" &&
  tar -xf "$archive" -C "$HOME/Library"
  rm -f "$archive"
)
export PATH="$HOME/Library/TinyTeX/bin/universal-darwin:$PATH"
tlmgr postaction install script xetex
tlmgr install latexmk amsmath amsfonts geometry hyperref collection-fontsrecommended chktex texcount
```

Neovim detects `~/Library/TinyTeX/bin/universal-darwin` automatically. To use `latexmk`
or `tlmgr` directly from a new terminal, add that `export PATH=...` line to your shell
profile. Add course-specific packages with `tlmgr install PACKAGE`; for example,
`tlmgr install biblatex biber` for a course using BibLaTeX.

Alternatively, install `brew install --cask basictex` (administrator password required),
then `/Library/TeX/texbin` is detected automatically. Install extra packages with
`sudo /Library/TeX/texbin/tlmgr install latexmk amsmath amsfonts geometry hyperref collection-fontsrecommended`.
Full MacTeX works as well. On Linux, install your distribution's TeX Live, latexmk and
Zathura packages; the config selects Zathura there.

In **Skim → Settings → Sync**:

- Enable checking for file changes and automatic reload.
- Select **Custom** PDF–TeX sync.
- Command: `/opt/homebrew/bin/nvim` (Intel Homebrew: `/usr/local/bin/nvim`).
- Arguments: `--headless -c "VimtexInverseSearch %line '%file'"`

**Command-Shift-click** text in Skim to jump back to its source in an existing Neovim
session. Keep that session open. If macOS requests permission for your terminal to
control Skim, allow it for forward search. VimTeX opens/reloads Skim in the background
so typing keeps focus. The [upstream Skim integration guide](https://github.com/lervag/vimtex/blob/master/doc/vimtex.txt)
describes this configuration. VimTeX must load eagerly for inverse search to work.

## Maintenance and migration

- `:Lazy` manages plugins; `:Lazy restore` restores the committed `lazy-lock.json`.
  Use `:Lazy update` deliberately, verify your workflow, and commit the resulting lockfile.
- `:Mason` manages servers and formatters. Lua and Texlab install automatically.
  Existing Mason servers continue to work. For optional languages:
  `:MasonInstall clangd pyright typescript-language-server bash-language-server css-lsp tailwindcss-language-server vim-language-server eslint-lsp`.
- Conform replaces archived null-ls; existing Black, clang-format, StyLua and Prettier
  installations are reused. Install them via `:MasonInstall black clang-format stylua prettier`.
  R formatting requires R's `styler` package. LaTeX is not reformatted on each live save.
- Tree-sitter uses the current `main` API and `tree-sitter-cli` (0.26.1+); `:TSUpdate`
  updates parsers. LaTeX uses VimTeX's syntax engine so math-zone features work.
- Packer and its generated loader were removed from the repo. Lazy resets the package
  path so old `site/pack/packer` plugins are not loaded. No old plugin files need deletion.
- Before applying the migration, preserve the previous commit with
  `git branch backup-before-modernize`. To roll back a clean working tree, check out that
  branch and restart Neovim. The old Packer installation can still be used by it.

## Diagnose and verify

Run `:checkhealth paul vimtex lazy mason vim.lsp` and `:VimtexInfo`.
Missing unrelated language runtimes in Mason's general health check are optional.
If a PDF does not refresh, check `Space l o`, ensure the compiler is running, and check
that `latexmk` and your chosen TeX engine are executable. `:LspInfo` shows Texlab attachment.

A repeatable integration test uses **only a disposable copy** of the example. It checks
actual PDF/SyncTeX/BibTeX output, a live rebuild, multi-file roots, completion setup,
snippet expansion, personal mappings, and auto-save protections:

```sh
test_project=$(mktemp -d)
cp -R ~/.config/nvim/examples/assignment/. "$test_project/"
NVIM_TEST_PROJECT="$test_project" nvim --headless '+luafile ~/.config/nvim/tests/smoke.lua'
```

The test needs installed plugins, Texlab and TeX. For an isolated run, set
`XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, and `XDG_CACHE_HOME` to a disposable
profile and put this config at `$XDG_CONFIG_HOME/nvim` before launching Neovim.
