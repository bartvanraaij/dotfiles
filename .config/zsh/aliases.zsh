alias vim="nvim"

# exa, prettier ls replacement
alias ls="eza -a --icons"
alias la="eza -a --long --icons --header --no-user --git"

# Myonlinestore Psalm single file
alias mospsalm="vendor/bin/psalm --config=psalm.xml.dist --show-info=true  --ignore-baseline"

# History grep
alias h='history'
function hs {
	history 0 | grep $*
}
alias hsi='hs -i'

# Update brew bundle
alias 'brew-store-installed'='brew bundle dump --global --force'

# Dotfiles git
alias dot='git --git-dir=$HOME/.dot/ --work-tree=$HOME'
alias dotedit='GIT_DIR=$HOME/.dot GIT_WORK_TREE=$HOME nvim'

# Git
alias gs='git s'
alias gc='git commit -m'
alias gl='git l'
alias gd='git d'
alias gdc='git dc'
alias ga='git add'

# Docker
alias dc='docker compose'
alias dstats='docker stats --no-stream --format "table {{.Name}}\t{{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | sort -k 4 -h'

# Tmux kill detached sessions
function tmux-kill-detached-sessions {
	tmux list-sessions -F '#{session_attached} #{session_id}' |
		awk '/^0/{print $2}' |
		xargs -n 1 tmux kill-session -t
    tmux list-sessions
}

# Color utils
function tmuxcolors {
	for i in {0..255}; do
		printf "\x1b[38;5;${i}mcolor%-5i\x1b[0m" $i
		if ! ((($i - 3) % 6)); then echo; fi
	done
}

function ansicolors {
	echo -e "\u001b[30m Black\t \u001b[30;1m Bright Black \u001b[0m"
	echo -e "\u001b[31m Red\t \u001b[31;1m Bright Red \u001b[0m"
	echo -e "\u001b[32m Green\t \u001b[32;1m Bright Green \u001b[0m"
	echo -e "\u001b[33m Yellow\t \u001b[33;1m Bright Yellow \u001b[0m"
	echo -e "\u001b[34m Blue\t \u001b[34;1m Bright Blue \u001b[0m"
	echo -e "\u001b[35m Magenta \u001b[35;1m Bright Magenta \u001b[0m"
	echo -e "\u001b[36m Cyan\t \u001b[36;1m Bright Cyan \u001b[0m"
	echo -e "\u001b[37m White\t \u001b[37;1m Bright White \u001b[0m"
}
