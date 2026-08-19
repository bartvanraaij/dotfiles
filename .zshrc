export ZSH="$HOME/.config/zsh"

# Completions
#fpath=($HOME/.local/zsh-completions/src $fpath)
#autoload -U compinit && compinit
#eval "$(dotnet completions script zsh)"

# FZF tab completions
#source ~/.local/fzf-tab/fzf-tab.plugin.zsh
# use tmux popup
#zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
# disable sort when completing `git checkout`
#zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
# NOTE: don't use escape sequences (like '%F{red}%d%f') here, fzf-tab will ignore them
#zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
#zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
#zstyle ':completion:*' menu no
# custom fzf flags
# NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
#zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
# To make fzf-tab follow FZF_DEFAULT_OPTS.
# NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
#zstyle ':fzf-tab:*' use-fzf-default-opts yes
# switch group using `<` and `>`
#zstyle ':fzf-tab:*' switch-group '<' '>'


# Load zsh conf
source "$ZSH/load.zsh"

# pnpm
export PNPM_HOME="/Users/bartvanraaij/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"

export GPG_TTY=$(tty)
#export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

# mise — Node, pnpm, and other tool version manager
eval "$(mise activate zsh)"

# bun completions
[ -s "/Users/bartvanraaij/.bun/_bun" ] && source "/Users/bartvanraaij/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
