alias vim="nvim"

# exa, prettier ls replacement
alias ls="exa -a --icons"
alias la="exa -a --long --icons --header --no-user --git"

# Myonlinestore Psalm single file
alias mospsalm="vendor/bin/psalm --config=psalm.xml.dist --show-info=true  --ignore-baseline"

# History grep
alias h='history'
function hs
{
    history 0 | grep $*
}
alias hsi='hs -i'

# Update brew bundle
alias 'brew-store-installed'='brew bundle dump --global'

# Dotfiles git
alias dot='git --git-dir=$HOME/.dot/ --work-tree=$HOME'

# Git
alias gs='git s'
alias gc='git commit -m'
alias gl='git l'
alias gdc='git dc'

# Color utils
function tmuxcolors
{
  for i in {0..255}; do  printf "\x1b[38;5;${i}mcolor%-5i\x1b[0m" $i ; if ! (( ($i - 3) % 6 )); then echo ; fi ; done
}

function ansicolors
{
  echo -e "\u001b[30m Black\t \u001b[30;1m Bright Black \u001b[0m"
  echo -e "\u001b[31m Red\t \u001b[31;1m Bright Red \u001b[0m"
  echo -e "\u001b[32m Green\t \u001b[32;1m Bright Green \u001b[0m"
  echo -e "\u001b[33m Yellow\t \u001b[33;1m Bright Yellow \u001b[0m"
  echo -e "\u001b[34m Blue\t \u001b[34;1m Bright Blue \u001b[0m"
  echo -e "\u001b[35m Magenta \u001b[35;1m Bright Magenta \u001b[0m"
  echo -e "\u001b[36m Cyan\t \u001b[36;1m Bright Cyan \u001b[0m"
  echo -e "\u001b[37m White\t \u001b[37;1m Bright White \u001b[0m"
}
