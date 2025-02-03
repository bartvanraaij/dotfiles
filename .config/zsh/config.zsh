# Locale
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Editor
export EDITOR=nvim
export VISUAL=nvim

# Set the XDG config dir
export XDG_CONFIG_HOME="$HOME/.config"

# History
export HISTFILE=~/.zsh_history
SAVEHIST=5000 # Save 5000 rows
HISTSIZE=5000 # Load 2000 rows in memory
setopt SHARE_HISTORY # share history across multiple zsh sessions
setopt APPEND_HISTORY # append to history file (no overwriting)
setopt INC_APPEND_HISTORY # Immediately add them, not on shell exit
setopt HIST_IGNORE_DUPS # Do not store duplicates
setopt HIST_REDUCE_BLANKS # Remove blank lines

# enable corrections
setopt CORRECT # Try to correct the spelling of commands.
#setopt CORRECT_ALL # Try to correct the spelling of all arguments in a line.

function zvm_config() {
# ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
}

# Set emacs navigation mode keys (C-a, C-e etc)
bindkey -e
# Set vim navigation mode keys
#bindkey -v

# Fzf colors - Github light
#export FZF_DEFAULT_OPTS="--color=bg+:#e7eaf0,bg:#ffffff,spinner:#cf222e,hl:#6e7781,fg:#1f2328,header:#6e7781,info:#cf222e,pointer:#cf222e,marker:#cf222e,fg+:#1f2328,preview-bg:#f6f8fa,prompt:#cf222e,hl+:#cf222e"

# Fzf colors - Tokyonight
#export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS' 
#--color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
#	--color=fg+:#c0caf5,bg+:#1a1b26,hl+:#7dcfff
#	--color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff 
#	--color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a'


