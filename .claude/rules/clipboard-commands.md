# Commands for me to run: put them on my clipboard

When I need to run a command myself (in another tmux pane or via `!`), also copy it to my clipboard with `printf '%s' "<command>" | pbcopy`, without the `!` prefix, and say it's there.

**Why:** Claude Code wraps long lines with real newlines, so selecting a command with the mouse in tmux/Ghostty pastes it broken (`zsh: parse error near '\n'`).
