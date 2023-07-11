export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export EDITOR=nvim
export VISUAL=nvim

# Set the XDG config dir
export XDG_CONFIG_HOME="$HOME/.config"

# Set emacs navigation mode keys (C-a, C-e etc)
#bindkey -e

# Set vim navigation mode keys
bindkey -v

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/.bart/bin:$HOME/.local/bin:/$HOME/bin:/usr/local/bin:$HOME/.composer/vendor/bin:$PATH

export ZSH="/Users/bart/.config/zsh"

# Directory as window title
set_window_title () { print -Pn "\e]0;  $(print -rD $PWD)\a" }
precmd_functions+=(set_window_title)

# Load zsh conf
source "$ZSH/load.zsh"

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Google Cloud SDK.
if [ -f '/Users/bart/.bart/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/bart/.bart/google-cloud-sdk/path.zsh.inc'; fi
if [ -f '/Users/bart/.bart/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/bart/.bart/google-cloud-sdk/completion.zsh.inc'; fi

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Homebrew PHP
export PATH="/opt/homebrew/opt/php@8.1/bin:$PATH"
export PATH="/opt/homebrew/opt/php@8.1/sbin:$PATH"

# Starship
eval "$(starship init zsh)"

