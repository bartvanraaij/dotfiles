# Herdr: the desktop app is `herdr-app`, not the `herdr` CLI

I run Claude Code inside the Herdr desktop app. When I ask for anything about panes, splits, tabs, sessions ("spaces" in its API) or "next to this one", use `herdr-app` and the cheat sheet below directly. Read `~/.config/herdr-app/AGENTS.md` (rewritten by the app on every start) or run `herdr-app commands` only for something the cheat sheet doesn't cover, or when a listed call fails; then fix the entry here.

- Don't use the `herdr` CLI for this. It controls the Herdr TUI's separate server (`~/.config/herdr/herdr.sock`), which I don't use and which doesn't contain my app's spaces.
- `HERDR_ENV` / `HERDR_PANE_ID` are not set, and `TMUX_PANE` may still be set from how the session started. Neither means "not in Herdr". `HC_TERMINAL_ID` (e.g. `t1d`) is set: it is this Claude session's terminal.
- Don't close spaces, tabs or panes you didn't create.

## Cheat sheet (run 2026-11-19, except where marked)

`herdr-app do <command> '<json args>'` works for every command; `--name value` flags work too. It prints what it made (`space`, `tab`, `pane`, `terminal`) or `{"ok": true}`, else an error.

```sh
# This Claude session's space, tab and pane
herdr-app ls | jq -r --arg t "$HC_TERMINAL_ID" '.spaces[] | . as $s | .tabs[] | . as $tab | .terminals[] | select(.terminal==$t) | "\($s.id) \($tab.id) \(.pane)"'

# New work session with Claude and its first message; focus false keeps me where I am
herdr-app do space.new '{"folder":"/abs/dir","argv":["claude"],"task":"<first message>","focus":false}'

# New tab in a space (default: the shown one), same argv/task/folder/focus (run 2026-11-20)
herdr-app do tab.new '{"space":"<sp id>","folder":"/abs/dir","argv":["claude"],"task":"<first message>"}'

# Split next to a pane: a shell, a program, or a mod pane. No folder argument:
# start elsewhere with ["zsh","-lc","cd <dir> && exec claude \"<first message>\""]
herdr-app do pane.split '{"direction":"right","pane":"<pane id>","argv":["zsh"]}'     # direction: right | down
herdr-app do pane.split '{"direction":"right","pane":"<pane id>","mod":"files"}'

herdr-app do pane.close '{"pane":"<pane id>"}'
herdr-app do space.select '{"id":"<sp id>"}'        # also tab.select {id}, pane.focus {pane | terminal}; pane.zoom {pane} not run yet
herdr-app status                                    # shown layout, focused space/tab/pane, errors
herdr-app shot <file.png>                           # screenshot of the window
```

Names and projects of work sessions go through `~/.claude/herdr-session.sh` (see `herdr-sessions.md`), not `space.rename`.

Other commands, args with `?` optional: `space.close ?id`, `space.rename ?id ?name`, `space.move id index`, `tab.close ?id`, `tab.rename ?id ?name`, `tab.move ?id ?index ?by`, `tab.settle ?id`, `pane.swap ?direction ?pane ?target`, `pane.go direction`, `terminal.open ?argv ?folder ?place ?name` (splits next to the focused pane), `terminal.kill terminal`, `terminal.peek terminal`, `agent.focus terminal`, `layout.switch ?name`, `mod.open name`, `app.settings ?section`.

There is no markdown viewer mod; Herdr ships none (`mods/` has files, changes, agents, ...).

**Why:** a session once said "not running inside Herdr" and refused to split, because it checked the `herdr` CLI and environment variables instead of the app (2026-11-17). Looking up `herdr-app commands` and AGENTS.md before every pane or session request made simple asks slow (2026-11-19).
