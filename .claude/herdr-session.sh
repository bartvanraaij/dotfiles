#!/bin/bash
# The Herdr work session (a Herdr space) this Claude session runs in, found by HC_TERMINAL_ID, and its project.
#   herdr-session.sh status                    title, project and the folders open in the session
#   herdr-session.sh title ["<title>"]         print or set the session title
#   herdr-session.sh project ["<project>"]     print or set the project of this session only
#   herdr-session.sh add-folder "<project>" <dir>   add a folder to a project (a new project is created)
# Projects by folder: ~/.config/herdr-app/projects.json (a trailing * matches any suffix).
# Projects set per session: ~/.config/herdr-app/sessions.json. What the sidebar shows, written by its
# my-spaces mod: ~/.config/herdr-app/sessions-live.json. Rule: ~/.claude/rules/herdr-sessions.md
set -euo pipefail
dir=$HOME/.config/herdr-app
term=${HC_TERMINAL_ID:?not running inside Herdr}
id=$(herdr-app ls | jq -r --arg t "$term" 'first(.spaces[] | select(any(.tabs[].terminals[]; .terminal == $t)) | .id) // empty')
[ -n "$id" ] || { echo "no Herdr session holds terminal $term" >&2; exit 1; }
live() { jq -c --arg id "$id" '.[$id] // {}' "$dir/sessions-live.json" 2>/dev/null || echo '{}'; }
# Writes JSON from stdin to $1 via rename, so the Herdr mod never reads half a file.
write() { local tmp; tmp=$(mktemp "$1.XXXXXX") && cat >"$tmp" && mv "$tmp" "$1"; }

case "${1:-status}" in
  status)
    l=$(live)
    echo "Session: $(herdr-app ls | jq -r --arg id "$id" '.spaces[] | select(.id == $id) | .name')"
    echo "Project: $(jq -r 'if .project then .project + (if .set then " (set for this session)" else " (from its folders)" end) else "none (shown under Other)" end' <<<"$l")"
    echo "Projects: $(jq -r 'keys | join(", ")' "$dir/projects.json")"
    echo "Folders: $(jq -r '(.folders // []) | join(", ")' <<<"$l" | sed "s|$HOME|~|g")" ;;
  title)
    if [ $# -lt 2 ]; then herdr-app ls | jq -r --arg id "$id" '.spaces[] | select(.id == $id) | .name'; else
      herdr-app do space.rename --id "$id" --name "$2" >/dev/null && echo "Session renamed to: $2"; fi ;;
  project)
    if [ $# -lt 2 ]; then live | jq -r '.project // "none"'; else
      { cat "$dir/sessions.json" 2>/dev/null || echo '{}'; } | jq --arg id "$id" --arg p "$2" '.[$id] = $p' | write "$dir/sessions.json"
      echo "Project set to: $2"; fi ;;
  add-folder)
    [ $# -eq 3 ] || { echo 'usage: herdr-session.sh add-folder "<project>" <dir>' >&2; exit 2; }
    d=$(cd "$3" && pwd); d=${d/#$HOME/\~}
    jq --arg p "$2" --arg d "$d" '.[$p] = ((.[$p] // []) + [$d] | unique)' "$dir/projects.json" | write "$dir/projects.json"
    echo "Added $d to $2" ;;
  *) sed -n '2,7p' "$0" >&2; exit 2 ;;
esac
