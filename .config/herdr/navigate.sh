#!/usr/bin/env bash
# Ctrl+h/j/k/l from herdr (config.toml [[keys.command]]): move to the neighboring herdr pane,
# or pass the key to nvim when nvim runs in the focused pane, like vim-tmux-navigator in tmux.
# nvim moves to the herdr pane itself at the edge of its splits (nvim/lua/plugins/vim-tmux-navigator.lua).
#   navigate.sh left|down|up|right
set -euo pipefail

dir="$1"
pane="${HERDR_ACTIVE_PANE_ID:?}"
herdr="${HERDR_BIN_PATH:-herdr}"

case "$dir" in
  left) key=ctrl+h ;;
  down) key=ctrl+j ;;
  up) key=ctrl+k ;;
  right) key=ctrl+l ;;
  *) echo "usage: navigate.sh left|down|up|right" >&2; exit 2 ;;
esac

if "$herdr" pane process-info --pane "$pane" |
  jq -e '[.result.process_info.foreground_processes[].name] | any(test("^n?vim$"))' >/dev/null; then
  "$herdr" pane send-keys "$pane" "$key"
else
  "$herdr" pane focus --pane "$pane" --direction "$dir" >/dev/null
fi
