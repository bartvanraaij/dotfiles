#!/bin/bash
# tmux status-right: Claude Code 5-hour usage, e.g. "✻ 42% (2h46m) | " (used, time until reset).
# Data comes from ~/.claude/statusline.sh. Prints nothing when unknown or the window has expired.

cache="$HOME/.cache/claude-usage"
[ -f "$cache" ] || exit 0
read -r pct reset <"$cache"
reset=${reset%.*}
left=$(( ${reset:-0} - $(date +%s) ))
[ -n "$pct" ] && [ "$left" -gt 0 ] || exit 0

pct=$(printf '%.0f' "$pct")
hours=$((left / 3600)) minutes=$((left % 3600 / 60))
if [ "$hours" -gt 0 ]; then remaining="${hours}h${minutes}m"; else remaining="${minutes}m"; fi

# Claude orange; red from 90%. Darker variants for the light theme so they stay readable on white.
# Separator in the theme's muted grey (same as @muted in theme-*.conf).
if grep -qs github-light-bart "$HOME/.config/ghostty/theme.ghostty"; then
  orange="#c15f3c" red="#cf222e" muted="#656d76"
else
  orange="#d97757" red="#f85149" muted="#7d8590"
fi
color=$orange
[ "$pct" -ge 90 ] && color=$red

echo "#[fg=$color]✻ ${pct}% (${remaining}) #[fg=$muted]|#[default] "
