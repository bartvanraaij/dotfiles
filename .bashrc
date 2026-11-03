# Shell for Claude Code's Bash tool (CLAUDE_CODE_SHELL in ~/.claude/settings.json).
# The interactive shell is zsh. PATH and exported variables come from the zsh
# terminal that starts Claude Code, so this file only adds what Claude needs.
# Keep it silent: anything printed here ends up in Claude's command output.

# Dotfiles git. A function, not an alias: non-interactive bash skips aliases,
# and Graphviz's /opt/homebrew/bin/dot would run instead.
dot() { git --git-dir="$HOME/.dot/" --work-tree="$HOME" "$@"; }

# Terminal light/dark switch; the zsh file is plain bash too.
source "$HOME/.config/zsh/theme.zsh"

# mise shims pick each project's tool versions on every command. `mise activate`
# switches versions from a prompt hook, which never runs for one-off commands.
eval "$(/opt/homebrew/bin/mise activate bash --shims)"
