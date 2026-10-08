---
name: nvim-checkup
description: Monthly maintenance of the user's own Neovim config (~/.config/nvim, lazy.nvim): snapshot, update plugins, explain what changed, find deprecations/breakage/archived plugins, fix them one by one, commit via the `dot` bare repo. Use when the user says "nvim checkup", "update nvim", "nvim maintenance", or reports nvim deprecation warnings after an update.
---

# nvim checkup

User keeps a hand-rolled, LazyVim-*inspired* config. Never suggest switching to LazyVim or another distro. When borrowing LazyVim ideas, port them explicitly into the user's own plugin files, with comments, so settings stay discoverable.

## Environment facts

- Config: `~/.config/nvim` — `init.lua` (lazy.nvim bootstrap + `require("lazy").setup("plugins", ...)`), `lua/plugins/*.lua` (one plugin per file), `lua/config/{options,keymap,autocmds}.lua`.
- Plugins on disk: `~/.local/share/nvim/lazy/<name>`. Lockfile: `~/.config/nvim/lazy-lock.json`.
- Dotfiles are a **bare repo**. `dot` is a zsh alias (`git --git-dir=$HOME/.dot/ --work-tree=$HOME`); in Bash call it as `zsh -ic 'dot ...'` or spell out the git flags.
  - Always pass **absolute paths** (`$HOME/.config/nvim/...`) as pathspecs; relative ones resolve against cwd and silently match nothing.
  - Scope adds/commits to `$HOME/.config/nvim` — never `commit -a` (would sweep in unrelated dotfiles).
  - `status` may hide untracked files; after committing, verify with `show --stat HEAD` that new plugin files got in.
- Headless nvim skips auto-session's auto-restore and other UI-only paths. To test those, drive a real nvim in tmux on a **private socket only**: `tmux -L claude-test new-session -d -s t "nvim"`, `tmux -L claude-test send-keys -t t ...`, cleanup `tmux -L claude-test kill-server`. NEVER plain `tmux kill-server`: the user (and this Claude session) live in the default tmux server.
- Neovim via Homebrew. Shell `ls` is aliased to eza — use `command ls`.
- Deleting files may be blocked by the permission classifier. Prefer `enabled = false` on a plugin spec; list files to delete for the user to remove themselves.
- Fetch plugin docs with the `ctx7` CLI (`npx ctx7@latest library <name> "<q>"` then `docs <id> "<q>"`) before rewriting any plugin config.

## Procedure

Ask before each commit. Stop and report if any step shows breakage you can't explain.

1. **Snapshot.** `dot status --short $HOME/.config/nvim`. If dirty, show the diff and ask to commit it as `nvim: pre-update snapshot` first. Record `nvim --version | head -1` and `brew outdated neovim`.

2. **Update.** Save old lockfile to scratchpad, then:
   `nvim --headless "+Lazy! sync" +qa 2>&1 | tail -5` (sync = install + clean + update).
   Also `rustup update` (Rust toolchain: rustc, cargo, rustfmt, clippy, rust-analyzer; Homebrew rustup, keg-only, on PATH via `~/.config/zsh/paths.zsh`) and `brew upgrade stylua`.
   C# tooling is global dotnet tools in `~/.dotnet/tools`: `dotnet tool update -g csharpier` and `dotnet tool update -g roslyn-language-server --prerelease --source https://pkgs.dev.azure.com/azure-public/vside/_packaging/vs-impl/nuget/v3/index.json` (roslyn.nvim needs server >= its README's minimum).
   If the Homebrew neovim is outdated, ask before `brew upgrade neovim`; on a minor bump (0.x → 0.y), read `:help news` (`nvim --headless +'help news' +'w! <scratch>/news.txt' +qa`) and flag deprecations relevant to this config.

3. **Explain the diff.** Compare old vs new lockfile. For each plugin that moved, run
   `git -C ~/.local/share/nvim/lazy/<p> log --oneline <old>..<new>` and flag commits mentioning `breaking`, `deprecat`, `remove`, `rename`, `!:`. Give the user a short table: plugin, #commits, notable changes, whether their config is affected (grep their config for the changed APIs/options).

4. **Health.**
   - `nvim --headless +'checkhealth lazy vim.deprecated vim.lsp' +'w! <scratch>/health.txt' +qa`, grep `WARNING|ERROR`.
   - Load everything and capture messages:
     `nvim --headless <some file> +'lua for n,p in pairs(require("lazy.core.config").plugins) do pcall(require("lazy").load,{plugins={n}}) end' +messages +qa 2>&1 | grep -iE "error|deprecat|warn"`
   - Grep config for known-deprecated APIs: `nvim_buf_set_option`, `nvim_win_set_option`, `nvim_buf_get_option`, `vim.lsp.get_active_clients`, `vim.diagnostic.goto_`, `require("lspconfig")[...].setup`, `vim.loop`.
   - Check every `<cmd>Foo<cr>` / `vim.cmd("Foo")` in `lua/config/keymap.lua` and plugin specs still exists (`nvim --headless +'lua require("lazy").load({plugins={...}})' +'lua print(vim.fn.exists(":Foo"))'`). Plugin major versions rename commands (e.g. trouble v3 dropped `:TroubleToggle` for `:Trouble diagnostics toggle`); headless load won't catch these since they only fail on keypress.

5. **Ecosystem scan.** For each plugin repo in the lockfile, check whether it's archived or moved (`gh repo view <owner/repo> --json isArchived,nameWithOwner` — a different `nameWithOwner` means moved). Known watch items:
   - `nvim-treesitter` is on the `main` branch (migrated 2026-10; master doesn't support nvim 0.12). After plugin updates run `:TSUpdate` (lazy `build` does this) — main requires parsers to match plugin version. Needs `tree-sitter-cli` from brew (`brew upgrade tree-sitter-cli`). Highlighting = own FileType autocmd in `lua/plugins/treesitter.lua`; don't call `vim.treesitter.query.get` before a parser is installed (it caches nil).
   - `noice.nvim`: `lua/config/autocmds.lua` (gd/gr/gi spinner) calls internal `require("noice.lsp.progress").progress()` / `.close(id)`; `lua/plugins/noice.lua` routes it to view `mini_quick` by `opts.progress.id` containing `user_request_`. If noice moved, check those still exist.
   - C# reference counts: own `lua/codelens_eol.lua` (cursor-line code lens) wired in `lua/plugins/roslyn.lua`; it wraps `client.handlers["workspace/projectInitializationComplete"]` (set by roslyn.nvim) and handles `workspace/codeLens/refresh`. If roslyn.nvim or nvim's LSP client changes these, counts go stale or vanish.
   - `nvim-cmp` vs `blink.cmp`, `lspsaga`, `noice`: mention only if archived/broken, don't churn working setups.

6. **Fix.** Propose fixes as a numbered list; apply after user picks. One logical change per edit, keep the user's code style (2-space indent, one plugin per file, short comments). After edits: `nvim --headless "+Lazy! install" +qa`, rerun step 4.

7. **User test.** Ask the user to open nvim and try PHP, TS and Lua files: LSP attach (`:checkhealth vim.lsp`), `<leader>cf` / `:Format`, linting, neo-tree, telescope. Headless can't verify UI.

8. **Commit.** `dot add $HOME/.config/nvim && dot commit -m "nvim: update plugins ..."` (body lists notable changes and fixes), then `dot show --stat HEAD`.

## Rollback

```sh
dot checkout HEAD~1 -- $HOME/.config/nvim/lazy-lock.json   # or the pre-update commit
nvim  →  :Lazy restore
```
