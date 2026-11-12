#!/bin/sh
# Show a file or piped text in a tmux popup, in the terminal theme set by the
# `theme` shell function (light or dark). Markdown renders with glow (our
# styles in ~/.config/glow), other files with moor's syntax highlighting; both
# scroll in moor.
#
#   show-popup.sh [-t title] file
#   command | show-popup.sh [-t title] [-l lang]     lang: md, json, sh, ... (default: plain text)

set -eu
script=$(cd "$(dirname "$0")" && pwd)/show-popup.sh

# Same check as the `theme` shell function.
mode=dark
grep -qs "github-light-bart" "$HOME/.config/ghostty/theme.ghostty" && mode=light

if [ "${1:-}" = __render ]; then
    file=$2 lang=$3 cleanup=$4
    [ "$cleanup" = 1 ] && trap 'rm -f "$file"' EXIT
    cols=$(tput cols)
    width=$((cols - 4))
    [ "$width" -gt 100 ] && width=100
    # moor has the same keys as show-diff.sh: esc or q closes,
    # ctrl-d/ctrl-u scroll. The GitHub style colors its status bar and line
    # numbers in the theme text color.
    style=github
    [ "$mode" = dark ] && style=github-dark
    set -- -style "$style" -statusbar plain
    case "$lang" in
    md | markdown)
        CLICOLOR_FORCE=1 glow -s "$HOME/.config/glow/style-$mode.json" -w "$width" "$file" |
            sed "/./,\$!d" |
            moor "$@" -no-linenumbers
        ;;
    *)
        [ -n "$lang" ] && set -- "$@" -lang "$lang"
        moor "$@" "$file"
        ;;
    esac
    exit 0
fi

title="" lang="" cleanup=0
while getopts t:l: opt; do
    case $opt in
    t) title=$OPTARG ;;
    l) lang=$OPTARG ;;
    *) exit 2 ;;
    esac
done
shift $((OPTIND - 1))

if [ -z "${TMUX:-}" ]; then
    echo "show-popup: not inside tmux" >&2
    exit 1
fi

if [ $# -eq 0 ] || [ "$1" = - ]; then
    file=$(mktemp "${TMPDIR:-/tmp}/show-popup.XXXXXX")
    cat >"$file"
    cleanup=1
    : "${title:=output}"
else
    file=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
    [ -f "$file" ] || { echo "show-popup: no such file: $1" >&2; exit 1; }
    : "${title:=$(basename "$file")}"
    if [ -z "$lang" ]; then
        case "$file" in *.md | *.markdown) lang=md ;; esac
    fi
fi

# Markdown wraps at 100 columns, so a narrower popup keeps it centred.
client=$(tmux display -p '#{client_width}')
if [ "$lang" = md ] || [ "$lang" = markdown ]; then
    width=$((client * 90 / 100))
    [ "$width" -gt 108 ] && width=108
else
    width=90%
fi

# display-popup blocks until the popup closes; run it detached so the caller returns.
tmux display-popup -E -w "$width" -h 90% -T "#[fg=#{@popup-title}] $(printf %s "$title" | sed "s/#/##/g") " \
    "'$script' __render '$file' '$lang' $cleanup" >/dev/null 2>&1 &
