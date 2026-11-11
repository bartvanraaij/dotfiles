#!/bin/sh
# Browse a git diff in a tmux popup: changed files in an fzf list on the left,
# the delta diff of the selected file on the right, in the terminal theme set by
# the `theme` shell function (light or dark).
#
#   show-diff.sh [git diff args]    e.g. --staged, main...HEAD, HEAD~1
#
# Without args: unstaged and staged changes against HEAD, plus untracked files;
# with no such changes, the branch against the default branch (origin/main...HEAD).

set -eu
script=$(cd "$(dirname "$0")" && pwd)/show-diff.sh

# Same check as the `theme` shell function.
mode=dark
grep -qs "github-light-bart" "$HOME/.config/ghostty/theme.ghostty" && mode=light

case "${1:-}" in
__list)
    shift
    if [ $# -eq 0 ]; then
        { git diff --name-only HEAD; git ls-files --others --exclude-standard; } | awk '!seen[$0]++'
    else
        git diff --name-only "$@"
    fi
    exit 0
    ;;
__preview)
    file=$2
    shift 2
    if [ $# -eq 0 ] && ! git ls-files --error-unmatch -- "$file" >/dev/null 2>&1; then
        git diff --no-index --color=always -- /dev/null "$file" || true
    elif [ $# -eq 0 ]; then
        git diff --color=always HEAD -- "$file"
    else
        git diff --color=always "$@" -- "$file"
    fi | delta --$mode --width="${FZF_PREVIEW_COLUMNS:-120}"
    exit 0
    ;;
__browse)
    shift
    args=""
    for a in "$@"; do args="$args '$a'"; done
    files=$("$script" __list "$@")
    if [ -z "$files" ]; then
        printf 'No changes.\n\nPress enter to close.'
        read -r _
        exit 0
    fi
    if [ "$mode" = light ]; then
        colors='light,bg:#ffffff,preview-bg:#ffffff'
    else
        colors='dark,bg:#0d1117,preview-bg:#0d1117'
    fi
    printf '%s\n' "$files" | fzf --color="$colors" \
        --layout=reverse --no-sort --cycle \
        --header 'enter/esc: close · ctrl-d/u: scroll diff' \
        --preview "'$script' __preview {}$args" \
        --preview-window 'right,80%,border-left' \
        --bind 'ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up' || true
    exit 0
    ;;
esac

if [ -z "${TMUX:-}" ]; then
    echo "show-diff: not inside tmux" >&2
    exit 1
fi
dir=$(git rev-parse --show-toplevel)
cd "$dir"

if [ $# -eq 0 ] && [ -z "$(git status --porcelain)" ]; then
    base=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || echo main)
    set -- "$base...HEAD"
fi

if [ "$mode" = light ]; then
    style='bg=#ffffff,fg=#1f2328'
    border='fg=#8c959f'
else
    style='bg=#0d1117,fg=#e6edf3'
    border='fg=#30363d'
fi
title=" diff: $(basename "$dir")${*:+ $*} "

# display-popup blocks until the popup closes; run it detached so the caller returns.
tmux display-popup -E -w 95% -h 95% \
    -s "$style" -S "$border" \
    -d "$dir" -T "$title" \
    "'$script' __browse $*" >/dev/null 2>&1 &
