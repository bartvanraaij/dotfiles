source "$ZSH/paths.zsh"
source "$ZSH/config.zsh"
source "$ZSH/aliases.zsh"
source "$ZSH/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh"

# Directory as window title
set_window_title () { print -Pn "\e]0;  $(print -rD $PWD)\a" }
precmd_functions+=(set_window_title)

# Starship
eval "$(starship init zsh)"
