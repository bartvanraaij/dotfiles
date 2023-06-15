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

