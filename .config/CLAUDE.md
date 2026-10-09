# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

`~/.config` is the user's hand-built terminal workspace (Ghostty, tmux, zsh, Neovim, Claude Code). Not a distro: never suggest LazyVim, oh-my-zsh frameworks etc.; port ideas explicitly into the user's own files, with comments explaining why.

For checkups, updates, breakage after updates or theme mismatches, use the `workspace-checkup` skill (`~/.claude/skills/workspace-checkup/SKILL.md`): it holds the full workspace map, update procedure, Neovim health checks and the list of fragile spots.

## Dotfiles repo

`~/.config` is **not** a git repo. Dotfiles live in a bare repo with work tree `$HOME`:

```sh
dot status --short -- ~/.config/nvim   # alias: git --git-dir=$HOME/.dot/ --work-tree=$HOME; works in the Bash tool too
# relative pathspecs resolve against cwd: use absolute paths or run from ~
```

- `status` hides untracked files; new config files must be added explicitly (`dot ls-files --error-unmatch <path>`).
- Scope `add`/`commit` to the paths you changed; never `commit -a` (it sweeps in all of `$HOME`'s tracked files).
- `~/.config/ghostty/theme.ghostty` is intentionally untracked (written by `theme`).
- Generated files have their own commands: `~/.Brewfile` → `brew-store-installed`. Check `zsh/aliases.zsh` before hand-editing generated files.

## How the pieces connect

**Ghostty → tmux sessions.** `ghostty/config.ghostty` `command` starts every window in tmux: the first attaches/creates session `main` (`new-session -A`), each further window gets its own session grouped with `main` (`main-1`, …, `destroy-unattached`). `tmux/tmux.conf` also runs `new-session -s main` whenever the server starts, so anything that creates `main` must tolerate it already existing.

**Light/dark theme.** One switch drives everything: the `theme dark|light|toggle` zsh function (`zsh/theme.zsh`) writes `ghostty/theme.ghostty` and sources `tmux/theme-<mode>.conf`. On load, `tmux.conf` picks its theme by grepping `theme.ghostty`. Neovim follows the terminal background via OSC 11 (`nvim/lua/config/theme.lua`); Claude Code, delta, bat, fzf, lazygit, starship and eza follow the terminal by themselves. New tool configs must work in both modes, preferably by following the terminal.

**Claude usage in tmux.** `~/.claude/statusline.sh` writes the 5-hour rate limit to `~/.cache/claude-usage`; `tmux/claude-usage.sh` renders it in `status-right`.

**diffpane** (live view of files Claude changed) is not in this repo: it lives in `~/Dev/diffpane`, loaded as a local-directory Claude Code plugin. Only personal glue lives here: `diffpane/config` and the `prefix+C` / `prefix+g` bindings in `tmux.conf`.

## Neovim

`nvim/init.lua` loads `lua/config/options`, bootstraps lazy.nvim with `require("lazy").setup("plugins")` (one plugin spec per file in `lua/plugins/`, lazy by default), then `config/theme`, `config/lsp` (capabilities for all servers via `vim.lsp.config("*")`), `config/keymap`, `config/icons`. LSP servers are enabled explicitly with `vim.lsp.enable` (mason-lspconfig `automatic_enable = false`). `lazy-lock.json` is tracked. Lua: 2-space indent.

## Reload / verify

```sh
tmux source-file ~/.config/tmux/tmux.conf      # "duplicate session: main" here is expected
zsh -ic exit                                   # shows zsh config errors
nvim --headless "+Lazy! sync" +qa              # update nvim plugins
NVIM=1 nvim --headless +'checkhealth vim.lsp' +qa   # NVIM=1 keeps auto-session from overwriting the user's session
```

Ghostty reloads with Cmd+Shift+, (user does this). Keep UI verification light: syntax/load checks, then hand over to the user.

## Safety

- The user and this Claude session run inside the default tmux server: never `tmux kill-server` or kill sessions/panes you didn't create. Test tmux behavior on a private socket: `tmux -L claude-test -f /dev/null …`.
- `ls` is aliased to eza; use `command ls` in scripts.
