##
# HISTORY
## 
export HISTFILE=~/.zsh_history
SAVEHIST=5000 # Save 5000 rows
HISTSIZE=2000 # Load 2000 rows in memory
setopt SHARE_HISTORY # share history across multiple zsh sessions
setopt APPEND_HISTORY # append to history file (no overwriting)
setopt INC_APPEND_HISTORY # Immediately add them, not on shell exit
setopt HIST_IGNORE_DUPS # Do not store duplicates
setopt HIST_REDUCE_BLANKS # Remove blank lines

# enable corrections
setopt CORRECT
setopt CORRECT_ALL

function zvm_config() {
# ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
}
