# tmux: never touch the default server

I run my terminals, including Claude Code itself, inside the default tmux server. Never run `tmux kill-server`, and never kill sessions, windows or panes you didn't create there. A `kill-server` once took down all my work, including the Claude session.

For scripted tests that need tmux (driving a TUI, testing key bindings), use a private server and ignore my tmux config, so plugins don't interfere:

```sh
T="tmux -L claude-test -f /dev/null"
$T new-session -d -s t -x 160 -y 40 '...'
$T send-keys -t t ...; $T capture-pane -p -t t
$T kill-server   # only ever on the private socket
```

Read-only queries against the default server (`display`, `list-panes`, `capture-pane`) are fine.
