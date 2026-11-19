#!/bin/bash
# SessionStart hook: inside Herdr, when this work session has no project, tells Claude to find one
# (rule: ~/.claude/rules/herdr-sessions.md). Prints nothing otherwise.
[ -n "${HC_TERMINAL_ID:-}" ] || exit 0
status=$(~/.claude/herdr-session.sh status 2>/dev/null) || exit 0
# A session made a moment ago isn't in the sidebar's view yet (it updates every 2 seconds).
if grep -q '^Folders: $' <<<"$status"; then sleep 2; status=$(~/.claude/herdr-session.sh status 2>/dev/null) || exit 0; fi
grep -q '^Project: none' <<<"$status" || exit 0
jq -n --arg s "$status" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext:
  ("This Herdr work session has no project yet:\n" + $s + "\nOn your first reply, decide which project its folders belong to, or ask the user when unclear, then run herdr-session.sh add-folder and project (see ~/.claude/rules/herdr-sessions.md).")}}'
