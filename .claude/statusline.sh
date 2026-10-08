#!/bin/bash
# Claude Code status line (settings.json "statusLine"): cwd | model | ctx remaining.
# Also records the 5-hour plan usage ("Current session" in /usage) for the tmux status bar,
# read by ~/.config/tmux/claude-usage.sh.

input=$(cat)
sep=$'\x1f' # not tab: read collapses empty tab-separated fields
IFS="$sep" read -r cwd model remaining five_pct five_reset < <(
  jq -r --arg sep "$sep" '[
    .workspace.current_dir,
    .model.display_name,
    (.context_window.remaining_percentage // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.five_hour.resets_at // "")
  ] | map(tostring) | join($sep)' <<<"$input"
)

# Usage cache: "<used_percentage> <resets_at>". Every session writes it (the limit is per account).
# Within one window usage only rises, so a lower value is stale (an idle session redrawing) and is
# skipped; a later reset time is a new window and replaces it. Write via rename: tmux never reads half a file.
cache="$HOME/.cache/claude-usage"
if [ -n "$five_pct" ] && [ -n "$five_reset" ]; then
  old_pct="" old_reset=""
  [ -f "$cache" ] && read -r old_pct old_reset <"$cache"
  if awk -v p="$five_pct" -v r="$five_reset" -v op="$old_pct" -v or="$old_reset" \
    'BEGIN { exit !(or == "" || r + 0 > or + 0 || (r + 0 == or + 0 && p + 0 > op + 0)) }'; then
    mkdir -p "$(dirname "$cache")"
    tmp=$(mktemp "$cache.XXXXXX") && echo "$five_pct $five_reset" >"$tmp" && mv "$tmp" "$cache"
  fi
fi

ctx_part=""
[ -n "$remaining" ] && ctx_part=" | ctx: ${remaining}% remaining"
echo "${cwd} | ${model}${ctx_part}"
