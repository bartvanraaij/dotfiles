#!/bin/sh
# Browse a git diff in a tmux popup: changed files in an fzf list on the left,
# the delta diff of the selected file on the right, in the terminal theme set by
# the `theme` shell function (light or dark).
#
#   show-diff.sh [git diff args]    e.g. --staged, main...HEAD, HEAD~1
#
# Without args: unstaged and staged changes against HEAD, plus untracked files;
# with no such changes, the branch against the default branch (origin/main...HEAD).
# Outside a git repo, under $HOME: the dotfiles bare repo (~/.dot, work tree $HOME).

set -eu
script=$(cd "$(dirname "$0")" && pwd)/show-diff.sh

# Same check as the `theme` shell function.
mode=dark
grep -qs "github-light-bart" "$HOME/.config/ghostty/theme.ghostty" && mode=light

case "${1:-}" in
__list)
    shift
    if [ $# -eq 0 ]; then
        # The dotfiles repo sets status.showUntrackedFiles=no: untracked there is all of $HOME.
        if [ "$(git config status.showUntrackedFiles)" = no ]; then
            git diff --name-only HEAD
        else
            { git diff --name-only HEAD; git ls-files --others --exclude-standard; } | awk '!seen[$0]++'
        fi
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
    # GitHub Primer colors, as in ~/.config/tmux/theme-*.conf: accent for the
    # pointer, matches and prompt, a light accent tint for the selected line.
    # fzf draws the diff's line indicator (top right) in the info color, reversed,
    # so info uses the accent too, like tmux's mode-style.
    if [ "$mode" = light ]; then
        colors='light,fg:#1f2328,bg:#ffffff,preview-bg:#ffffff,fg+:#1f2328,bg+:#ddf4ff,gutter:#ffffff'
        colors="$colors,hl:#0969da,hl+:#0969da,pointer:#0969da,marker:#0969da,prompt:#0969da,spinner:#0969da"
        colors="$colors,info:#0969da,header:#656d76,border:#d0d7de,separator:#d0d7de,scrollbar:#d0d7de"
    else
        colors='dark,fg:#e6edf3,bg:#0d1117,preview-bg:#0d1117,fg+:#e6edf3,bg+:#112441,gutter:#0d1117'
        colors="$colors,hl:#58a6ff,hl+:#58a6ff,pointer:#58a6ff,marker:#58a6ff,prompt:#58a6ff,spinner:#58a6ff"
        colors="$colors,info:#58a6ff,header:#7d8590,border:#30363d,separator:#30363d,scrollbar:#30363d"
    fi
    # Same keys as show-popup.sh: esc or q closes (q types into a
    # non-empty filter), ctrl-d/ctrl-u scroll.
    printf '%s\n' "$files" | fzf --color="$colors" \
        --layout=reverse --no-sort --cycle \
        --header 'esc/q close · ctrl-d/u scroll diff · type to filter' \
        --preview "'$script' __preview {}$args" \
        --preview-window 'right,80%,border-left' \
        --bind 'ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up' \
        --bind 'q:transform:[ -n "$FZF_QUERY" ] && echo "put(q)" || echo abort' || true
    exit 0
    ;;
esac

if [ -z "${TMUX:-}" ]; then
    echo "show-diff: not inside tmux" >&2
    exit 1
fi
popup_env=""
if dir=$(git rev-parse --show-toplevel 2>/dev/null); then
    name=$(basename "$dir")
else
    case "$PWD/" in
    "$HOME"/*) [ -d "$HOME/.dot" ] || { echo "show-diff: not a git repository" >&2; exit 1; } ;;
    *) echo "show-diff: not a git repository" >&2; exit 1 ;;
    esac
    export GIT_DIR="$HOME/.dot" GIT_WORK_TREE="$HOME"
    popup_env="-e GIT_DIR=$GIT_DIR -e GIT_WORK_TREE=$GIT_WORK_TREE"
    dir=$HOME name=dotfiles
fi
cd "$dir"

if [ $# -eq 0 ] && [ -z "$popup_env" ] && [ -z "$(git status --porcelain)" ]; then
    base=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || echo main)
    set -- "$base...HEAD"
fi

title="#[fg=#{@popup-title}]$(printf " diff: %s%s " "$name" "${*:+ $*}" | sed "s/#/##/g")"

# display-popup blocks until the popup closes; run it detached so the caller returns.
# Popup colors come from popup-style in ~/.config/tmux/theme-*.conf.
# shellcheck disable=SC2086 # popup_env holds separate -e flags
tmux display-popup -E -w 95% -h 95% $popup_env \
    -d "$dir" -T "$title" \
    "'$script' __browse $*" >/dev/null 2>&1 &
