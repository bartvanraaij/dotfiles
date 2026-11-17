#!/bin/bash
# Claude Code status line (settings.json "statusLine"): cwd basename | model | ctx remaining.
# Also records plan usage and context fill for the tmux status bar (~/.config/tmux/claude-usage.sh)
# and the Herdr usage panel (~/.config/herdr-app/mods/claude-usage).

input=$(cat)
sep=$'\x1f' # not tab: read collapses empty tab-separated fields
IFS="$sep" read -r cwd model remaining five_pct five_reset week_pct week_reset < <(
  jq -r --arg sep "$sep" '[
    .workspace.current_dir,
    .model.display_name,
    (.context_window.remaining_percentage // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.five_hour.resets_at // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.rate_limits.seven_day.resets_at // "")
  ] | map(tostring) | join($sep)' <<<"$input"
)

# Usage cache: "<used_percentage> <resets_at>". Every session writes it (the limit is per account).
# Within one window usage only rises, so a lower value is stale (an idle session redrawing) and is
# skipped; a later reset time is a new window and replaces it. Write via rename: readers never see half a file.
record_usage() {
  local cache=$1 pct=$2 reset=$3 old_pct="" old_reset="" tmp
  [ -n "$pct" ] && [ -n "$reset" ] || return 0
  [ -f "$cache" ] && read -r old_pct old_reset <"$cache"
  if awk -v p="$pct" -v r="$reset" -v op="$old_pct" -v or="$old_reset" \
    'BEGIN { exit !(or == "" || r + 0 > or + 0 || (r + 0 == or + 0 && p + 0 > op + 0)) }'; then
    mkdir -p "$(dirname "$cache")"
    tmp=$(mktemp "$cache.XXXXXX") && echo "$pct $reset" >"$tmp" && mv "$tmp" "$cache"
  fi
}
record_usage "$HOME/.cache/claude-usage" "$five_pct" "$five_reset"
record_usage "$HOME/.cache/claude-usage-7d" "$week_pct" "$week_reset"

# Context fill per Herdr terminal (HC_TERMINAL_ID, e.g. t3), so the Herdr panel can match it to its agent.
if [ -n "$HC_TERMINAL_ID" ]; then
  dir="$HOME/.cache/claude-context"
  mkdir -p "$dir"
  tmp=$(mktemp "$dir/.$HC_TERMINAL_ID.XXXXXX") &&
    jq -c '{
      used: .context_window.used_percentage,
      tokens: .context_window.total_input_tokens,
      size: .context_window.context_window_size,
      model: .model.display_name
    }' <<<"$input" >"$tmp" && mv "$tmp" "$dir/$HC_TERMINAL_ID"
fi

ctx_part=""
[ -n "$remaining" ] && ctx_part=" | ctx: ${remaining}% remaining"
echo "${cwd##*/} | ${model}${ctx_part}"
