# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

`~/.config` is the user's hand-built terminal workspace (Ghostty, tmux, Herdr, zsh, Neovim, Claude Code). Not a distro: never suggest LazyVim, oh-my-zsh frameworks etc.; port ideas explicitly into the user's own files, with comments explaining why.

**Trying out Herdr.** The user is trying the Herdr app (see Herdr below) as their daily driver instead of Ghostty + tmux. The tmux setup stays as it is and must keep working: keep both in mind when changing anything they share (Claude usage, nvim pane navigation, theme).

For checkups, updates, breakage after updates or theme mismatches, use the `workspace-checkup` skill (`~/.claude/skills/workspace-checkup/SKILL.md`): it holds the full workspace map, update procedure, Neovim health checks and the list of fragile spots.

## Dotfiles repo

`~/.config` is **not** a git repo. Dotfiles live in a bare repo with work tree `$HOME`:

```sh
dot status --short -- ~/.config/nvim   # alias: git --git-dir=$HOME/.dot/ --work-tree=$HOME; defined in ~/.bashrc too, so it works in the Bash tool
# relative pathspecs resolve against cwd: use absolute paths or run from ~
```

- `status` hides untracked files; new config files must be added explicitly (`dot ls-files --error-unmatch <path>`).
- `dot status -sb` shows how far `main` is ahead of GitHub's (`origin/main`, updated by `dot fetch` and `dot push`).
- Scope `add`/`commit` to the paths you changed; never `commit -a` (it sweeps in all of `$HOME`'s tracked files).
- `~/.config/ghostty/theme.ghostty` is intentionally untracked (written by `theme`).
- Generated files have their own commands: `~/.Brewfile` → `brew-store-installed`. Check `zsh/aliases.zsh` before hand-editing generated files.

### When to commit

In this repo Claude commits without being asked (this replaces "only commit when I ask" from the global git rule), one commit per finished piece of work:
- A piece of work is finished when the user accepts it ("looks great", "nice") or moves on to something else. Commit then, not after each edit.
- Tweaks made while iterating on it (a color, a size, a bug in what was just built) go into that same commit. Nothing is committed while the user is still trying it out.
- A later change to what the last commit holds goes into that commit with `dot commit --amend`, as long as it isn't pushed (the user pushes by hand). Check first: `dot fetch -q && dot branch -r --contains HEAD` prints nothing for an unpushed commit. Any other change to something already committed is a new commit, named after what it changes.
- Separate pieces of work get separate commits, and the one-app-per-commit rule below still holds.
- Changes Claude didn't make stay out of the commit; mention them once.
- After committing, name the commit in one line. Don't ask "commit?".

**Why:** unprompted, a model commits every small edit and the history gets huge; asking for every commit got tedious (2026-11-20).

### Commit messages

One-line commit messages only. No body paragraphs; the only extra is the `Co-Authored-By` trailer (after a blank line) on commits Claude wrote, so `dot log --grep='Co-Authored-By: Claude'` tells Claude's changes from the user's own. No conventional-commit `type(scope):` prefix (some older commits use it; don't copy them).

Format: `<app>: verb noun phrase` (like `a9716a7 theme: switch tmux directly instead of via theme hooks`)
- `<app>` is the part of the workspace that changed: `nvim`, `zsh`, `tmux`, `herdr` (the TUI, `herdr/`), `herdr-app` (the desktop app, `herdr-app/`), `ghostty`, `fresh`, `theme`, `git`, `diffpane`, `Brewfile`, `claude` (Claude Code config, rules, CLAUDE.md), `workspace-checkup`, ...
- One app per commit: a change that touches several apps is split into one commit per app. Exception: `theme` for changes that switch colors across apps together.
- After the colon: lowercase imperative verb, no trailing period.
- Any imperative verb that fits works (add, fix, remove, allow, configure, rename, extract...). Never gerunds ("adding") or past tense ("added").
- Name the thing that changed, not the activity: `zsh: fix crash when history file is empty`, not `zsh: fix bug`.

Examples: `nvim: add dark mode toggle to settings`, `zsh: allow case-insensitive tab completion`, `workspace-checkup: extract update steps into own section`.

**Why:** Personal project. Commit bodies never get read back, and `type(scope):` prefixes add noise without value. The app prefix shows at a glance which part of the workspace changed, and verb-first keeps the log scannable.

## How the pieces connect

**Ghostty → tmux sessions.** `ghostty/config.ghostty` `command` starts every window in tmux (the line is commented out while the user tries Herdr; uncommenting it brings this back): the first attaches/creates session `main` (`new-session -A`), each further window gets its own session grouped with `main` (`main-1`, …, `destroy-unattached`). `tmux/tmux.conf` also runs `new-session -s main` whenever the server starts, so anything that creates `main` must tolerate it already existing.

**Light/dark theme.** One switch drives everything: the `theme dark|light|toggle` zsh function (`zsh/theme.zsh`) writes `ghostty/theme.ghostty` and sources `tmux/theme-<mode>.conf`. On load, `tmux.conf` picks its theme by grepping `theme.ghostty`. Neovim follows the terminal background via OSC 11 (`nvim/lua/config/theme.lua`); Claude Code, delta, bat, fzf, lazygit, starship and eza follow the terminal by themselves. New tool configs must work in both modes, preferably by following the terminal.

**Claude's shell is bash, the user's is zsh.** Claude Code's Bash tool runs Homebrew bash 5 (`CLAUDE_CODE_SHELL` in `~/.claude/settings.json`), so commands follow bash rules in every project. It inherits PATH and exported variables from the zsh terminal; `~/.bashrc` only adds what Claude needs (`dot`, `theme`, mise shims). Aliases for the user go in `zsh/aliases.zsh`; anything Claude must call also goes in `~/.bashrc`, as a function (non-interactive bash skips aliases).

**Claude Code's LSP plugins have their own servers, separate from Neovim's Mason.** Claude keeps working when the nvim setup breaks. `~/.claude/lsp/typescript/` pins `typescript-language-server` and TypeScript 6 (TypeScript 7, the Go port, has no `tsserver.js`); its `install.sh` installs them and links the server into `~/.local/bin`. A Homebrew `typescript-language-server` would come first on PATH and pull in TypeScript 7, so it stays uninstalled.

**Claude usage in tmux and Herdr.** `~/.claude/statusline.sh` writes three caches, each via rename so readers never see half a file:
- `~/.cache/claude-usage`: the 5-hour window, `<used_pct> <resets_at>`. `tmux/claude-usage.sh` renders it in `status-right`; the format must stay as it is for tmux.
- `~/.cache/claude-usage-7d`: the weekly window, same format. Both limit caches keep the highest value per window: a lower value is stale (an idle session redrawing), a later reset time is a new window.
- `~/.cache/claude-context/<terminal>`: context fill per Herdr terminal (`HC_TERMINAL_ID`, e.g. `t3`), JSON `{used, tokens, size, model}`. Written only inside Herdr.

The Herdr app's `claude-usage` mod reads all three (see Herdr).

**diffpane** (live view of files Claude changed) is not in this repo: it lives in `~/Dev/diffpane`, loaded as a local-directory Claude Code plugin. Only personal glue lives here: `diffpane/config` and the `prefix+C` / `prefix+g` bindings in `tmux.conf`.

## Herdr

Two programs share the name:
- **Herdr app** (`herdr-app`, config in `~/.config/herdr-app/`): the desktop app the user is trying as daily driver. Its terminals run in herdr-core (`hc`), so they survive closing or updating the window.
- **herdr TUI** (`herdr`, config in `herdr/`): the terminal version. `herdr/config.toml` has the GitHub Primer theme (light/dark follows the terminal), the tmux prefix and split keys, and ctrl+h/j/k/l through `herdr/navigate.sh`, which moves between herdr panes and nvim splits (with `nvim/lua/plugins/vim-tmux-navigator.lua`, which detects herdr by `HERDR_ENV=1`).

**Herdr app.** `~/.config/herdr-app/AGENTS.md` is the app's own manual, rewritten by the app on every start: read it before changing anything there. Main points:
- Everything is files and applies live: `layouts/<name>.json` (the window), `keys.json`, `settings.json`, `mods/<name>/` (panels in JavaScript, gpui-kit; types in `gpui-kit.d.ts` and `herdr.d.ts`).
- Shipped layouts and mods are replaced on every start. Change them only through clones (`herdr-app do layout.clone|mod.clone '{"name":"…","as":"…"}'`); a clone gets no Herdr updates after that.
- A mod can't import from another mod's folder (`herdr-app check` fails with "resolves outside the application directory").
- The look follows macOS appearance (settings.json sets no theme), not the `theme` zsh function.

The user's own parts, all tracked in dot:
- `layouts/my-main.json`: clone of `main`, the shown layout. Changes from `main`: the tab bar is a row of the shipped `tabs` mod plus a 124px `usage-button` block; the right panel stack has a third child `usage`; the `changes` child uses `my-changes`.
- `mods/claude-usage/`: the Claude usage panel, and with `props.button` the tab bar button (✻, 5-hour percentage and time left, in Claude orange, red from 90%). `usage.js` holds the cache readers, the thresholds and the colors (green, yellow, red from the theme's ansi colors). The button adds `"usage"` to the shared `workspace.panels` list, so the tab bar remembers the open panel per space.
- `mods/my-changes/`: clone of `changes` that falls back to the dotfiles repo (`~/.dot`, work tree `$HOME`) for folders under home that are in no other repo. Tracked files only. It has no commit field: the user has Claude commit. Its diff uses the terminal font, size and weight; `settings()` doesn't report `font_weight`, so the mod falls back to the weight in `settings.json`.
- `settings.json`: the terminal font matches Ghostty (BlexMono Nerd Font 13.5, weight 400, `terminal_line_height` 1.2). Ghostty draws Light with `font-thicken`; Herdr has no thicken, so it uses Regular. Herdr's Settings screen writes this file too.

Not tracked: the generated `gpui-kit.d.ts` and `jsconfig.json` in each mod folder, and everything the app writes (`shared.json`, `view.json`, `layouts/.state/`, `data/`, ...).

## Neovim

`nvim/init.lua` loads `lua/config/options`, bootstraps lazy.nvim with `require("lazy").setup("plugins")` (one plugin spec per file in `lua/plugins/`, lazy by default), then `config/theme`, `config/lsp` (capabilities for all servers via `vim.lsp.config("*")`), `config/keymap`, `config/icons`. LSP servers are enabled explicitly with `vim.lsp.enable` (mason-lspconfig `automatic_enable = false`). `lazy-lock.json` is tracked. Lua: 2-space indent.

## Reload / verify

```sh
tmux source-file ~/.config/tmux/tmux.conf      # "duplicate session: main" here is expected
zsh -ic exit                                   # shows zsh config errors
bash -lc 'type dot'                            # ~/.bashrc loads (Claude's shell): a function, not Graphviz
nvim --headless "+Lazy! sync" +qa              # update nvim plugins
NVIM=1 nvim --headless +'checkhealth vim.lsp' +qa   # NVIM=1 keeps auto-session from overwriting the user's session
herdr-app check ~/.config/herdr-app/mods/<name>      # loads and renders a mod once; run after every mod change
herdr-app status                               # shown layout, focus, overlays, and errors from files and mods
herdr-app shot <file.png>                      # screenshot of the Herdr window, for checking a mod's look
```

Ghostty reloads with Cmd+Shift+, (user does this). Keep UI verification light: syntax/load checks, then hand over to the user.

## Safety

- `herdr-app do …` acts on the user's live window. Open overlays only when needed: `overlay.close` doesn't close the welcome screen (the user closes it with Esc).
- The user and this Claude session run inside the default tmux server (when not in Herdr): never `tmux kill-server` or kill sessions/panes you didn't create. Test tmux behavior on a private socket: `tmux -L claude-test -f /dev/null …`.