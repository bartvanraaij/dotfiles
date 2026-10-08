---
name: workspace-checkup
description: Use when the user asks for a checkup, update or maintenance of their terminal workspace or any part of it (Ghostty, tmux, Neovim, zsh, git/delta, Claude Code config, Homebrew tools, color scheme), says things like "update everything", "nvim checkup", "is my setup up to date", or reports breakage, deprecation warnings or theme mismatches after an update.
---

# Workspace checkup

The user's terminal workspace is hand-built and lives in a dotfiles bare repo. Keep it current and consistent without changing its character: never suggest distros (LazyVim, oh-my-zsh frameworks); port ideas explicitly into the user's own files, with comments.

## Workspace map

| Part | Config (all tracked in dotfiles) | Update | Verify / reload |
|---|---|---|---|
| Ghostty | `~/.config/ghostty/config.ghostty`, `themes/` | `brew upgrade --cask ghostty` | Cmd+Shift+, in Ghostty |
| tmux | `~/.config/tmux/tmux.conf`; plugins in `~/.config/tmux/plugins/` (tpm, tmux-sensible, vim-tmux-navigator, better-mouse-mode), each its own git clone | `git -C <plugin> pull` or tpm `prefix + U` | `tmux source-file ~/.config/tmux/tmux.conf` |
| zsh | `~/.zshrc`, `~/.zprofile`, `~/.config/zsh/{aliases,config,load,paths}.zsh` | brew (starship etc.) | `zsh -ic exit` shows errors |
| Prompt etc. | `~/.config/starship.toml`, `lazygit/`, `fastfetch/`, `gh/` | brew | run the tool |
| Neovim | `~/.config/nvim` (lazy.nvim, `lazy-lock.json`) | see Neovim section | headless checks below |
| git | `~/.gitconfig` (delta pager, `dark = true`) | brew (git, git-delta) | `git log -p -1` |
| Claude Code | `~/.claude/settings.json`, `rules/`, own `skills/` (not `skills/synced/`) | Claude Code self-updates | `jq . ~/.claude/settings.json` |
| Tools | `~/.Brewfile` (regenerate with `brew-store-installed`) | `brew update && brew outdated` | `brew bundle check --global` |

**Color scheme: GitHub (Primer) light or dark, switched with the `theme` zsh function** (`theme dark|light|toggle`, `~/.config/zsh/theme.zsh`), independent of macOS appearance (which stays light). It only writes `~/.config/ghostty/theme.ghostty` (untracked, in `~/.dot/info/exclude`): dark = `GitHub Dark Default`, light = the user's `github-light-bart`; the user reloads Ghostty (Cmd+Shift+,). Everything else follows Ghostty:
- tmux: `client-dark-theme`/`client-light-theme` hooks load `tmux/theme-dark.conf` / `theme-light.conf` (hex colors, palette legend in each).
- nvim: `lua/config/theme.lua` maps `'background'` (from the terminal's OSC 11 answer) to `github_dark_default`/`github_light_default`, live. Needs the `hi clear` before switching (see fragile spots).
- Claude Code `"theme": "auto"`; delta and bat detect per run; fzf, lazygit, starship, eza use the ANSI palette.
Any new tool config: support both modes, preferably by following the terminal; hex colors over ANSI names when a tool needs explicit colors.

## Dotfiles repo

- `dot` = `git --git-dir=$HOME/.dot/ --work-tree=$HOME` (zsh alias). In Bash use `zsh -ic 'dot …'` or a function: `g() { git --git-dir=$HOME/.dot/ --work-tree=$HOME "$@"; }` (a `$G="git …"` variable does not word-split in zsh).
- Pathspecs: run from `~` with paths like `.config/nvim/...`, or pass absolute paths. Relative paths resolve against cwd and silently match nothing.
- `status` hides untracked files. New config files must be added explicitly; check `ls-files --error-unmatch <path>` and add any untracked config the user uses.
- Scope adds to the paths you changed; never `commit -a`. One logical change per commit; split mixed files with a filtered patch + `git apply --cached`.
- Ask before committing unless the user already said to commit.

## Procedure

1. **Snapshot.** `dot status --short` for touched areas. Dirty? Show it, ask to commit as a pre-update snapshot.
2. **Inventory drift.**
   - `brew outdated`; `brew bundle check --global` (listed but not installed).
   - Sync `~/.Brewfile` with what's installed using the user's alias `brew-store-installed` (= `brew bundle dump --global --force`), never by hand-editing. Then compare package sets old vs new (strip `# description` comments and `, trusted: true`) and show the user what was added/removed before committing.
   - Plugin clones: `.gitmodules` lists tpm and tmux-sensible, but in this bare-repo setup `dot submodule status` shows them as `-` (uninitialized); it says nothing about freshness. Check each clone in `~/.config/tmux/plugins/` instead: `git -C <dir> fetch -q && git -C <dir> rev-list --count HEAD..@{u}`. After pulling tpm or tmux-sensible, `dot add` the dir to record the new commit. Old upstream dates (tmux-sensible 2022, better-mouse-mode 2017) are inactive upstreams, not drift.
   - Untracked config under `~/.config/*` and `~/.claude/{rules,skills}`.
3. **Update** (ask first for anything beyond nvim plugins): brew upgrades, `rustup update`, `dotnet tool update -g csharpier` and roslyn-language-server (see Neovim), tmux plugin clones, nvim plugins.
4. **Explain what changed.** For each updated nvim plugin: `git -C ~/.local/share/nvim/lazy/<p> log --oneline <old>..<new>`, flag `breaking|deprecat|remove|rename|!:`, and grep the user's config for affected APIs. For brew: release notes of tools whose config we own (Neovim minor bump → read `:help news`).
5. **Check health.** Neovim checks below; `zsh -ic exit`; `tmux source-file` (a `duplicate session: main` message is expected and harmless); theme consistency against the color section.
6. **Fix** as a numbered proposal; apply after the user picks. Match each file's style.
7. **User test.** Hand over for interactive checks (UI can't be verified headless). Keep own testing short: load/syntax checks, not long harnesses.
8. **Commit** via dotfiles, then `dot show --stat HEAD` to confirm new files got in.

## Neovim

- Layout: `init.lua` (lazy bootstrap + setup), `lua/config/{options,keymap,autocmds,lsp}.lua`, `lua/plugins/*.lua` (one plugin per file), `lua/codelens_eol.lua`.
- Update: `nvim --headless "+Lazy! sync" +qa`; `:TSUpdate` runs via lazy `build`. Neovim itself via brew.
- Checks:
  - `nvim --headless +'checkhealth lazy vim.deprecated vim.lsp' +'w! <scratch>/health.txt' +qa`, grep `WARNING|ERROR`.
  - Load all plugins, grep messages: `nvim --headless <file> +'lua for n in pairs(require("lazy.core.config").plugins) do pcall(require("lazy").load,{plugins={n}}) end' +messages +qa 2>&1 | grep -iE "error|deprecat|warn"`
  - Keymap commands still exist (`vim.fn.exists(":Cmd")`): plugin majors rename commands and headless loads won't catch it (trouble v3 dropped `:TroubleToggle`).
  - `:checkhealth` "No healthcheck found" for lazy-loaded plugins (conform) is normal.
- Plugin docs: `ctx7` CLI first (rule in `~/.claude/rules/context7.md`), else the plugin README via `gh api`.
- C# tooling = global dotnet tools in `~/.dotnet/tools`: csharpier; `dotnet tool update -g roslyn-language-server --prerelease --source https://pkgs.dev.azure.com/azure-public/vside/_packaging/vs-impl/nuget/v3/index.json`.

**Fragile spots to re-check after updates:**

| Where | Depends on |
|---|---|
| `plugins/treesitter.lua` (main branch, own FileType autocmd) | parsers matching plugin version (`:TSUpdate`), `tree-sitter-cli`. Don't call `vim.treesitter.query.get` before a parser exists (caches nil). |
| `config/autocmds.lua` FileOpened is `vim.schedule`d | firing inside BufRead lets `vim.lsp.enable` (doautoall FileType) make `:setf` a no-op: restored session buffers lose filetype |
| `config/autocmds.lua` gd/gr/gi spinner + `plugins/noice.lua` `mini_quick` route | internal `noice.lsp.progress.progress()`/`.close()` |
| `codelens_eol.lua` + `plugins/roslyn.lua` | wraps `client.handlers["workspace/projectInitializationComplete"]` (set by roslyn.nvim), handles `workspace/codeLens/refresh` |
| `config/lsp.lua` | `cmp_nvim_lsp.default_capabilities()` into `vim.lsp.config("*")` |
| `config/keymap.lua` deletes default `grr gri grn gra grt grx` | new nvim default `gr*` maps make `gr` wait `timeoutlen` again |
| `config/theme.lua` live light/dark switch | nvim updating `'background'` on OSC 11 answers (TermResponse only sees OSC/DCS/APC/DA1, not DEC 2031 `?997` reports); `hi clear` before `:colorscheme` because nvim unsets `g:colors_name` on a `'background'` change and github-theme then skips its own clear (bufferline keeps old colors otherwise) |
| `plugins/lsp.lua` mason-lspconfig `automatic_enable = false` | servers enabled explicitly via `vim.lsp.enable`; intelephense installed but off |

## Safety

- tmux UI tests only on a private socket: `tmux -L claude-test …`, clean up with `tmux -L claude-test kill-server`. Never plain `kill-server`: the user and this session live in the default server.
- Headless nvim in a real project: set `NVIM=1` so auto-session doesn't overwrite the user's session on exit. Headless also skips auto-session restore; use tmux (private socket) for that.
- Deleting files may be blocked by the permission classifier: give the user the `rm` command instead of working around it.
- Shell `ls` is eza: use `command ls`.

## Rollback

```sh
dot checkout <pre-update commit> -- .config/nvim/lazy-lock.json   # then :Lazy restore in nvim
dot checkout <commit> -- <other config file>
```
