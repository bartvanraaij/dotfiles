source "$ZSH/paths.zsh"
source "$ZSH/config.zsh"
source "$ZSH/aliases.zsh"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Directory as window title
set_window_title () { print -Pn "\e]0;  $(print -rD $PWD)\a" }
precmd_functions+=(set_window_title)

# Starship
eval "$(starship init zsh)"

# Neofetch
#neofetch

# Fzf
# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Fastfetch
fastfetch
