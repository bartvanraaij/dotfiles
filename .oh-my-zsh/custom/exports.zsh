export AWS_PROFILE=development
export AWS_REGION=eu-west-1
export DOCKER_BUILDKIT=0
export COMPOSE_DOCKER_CLI_BUILD=0

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# PHP 7.4
#export PATH="/opt/homebrew/opt/php@7.4/bin:$PATH"
#export PATH="/opt/homebrew/opt/php@7.4/sbin:$PATH"

# PHP 8.0
export PATH="/opt/homebrew/opt/php@8.0/bin:$PATH"
export PATH="/opt/homebrew/opt/php@8.0/sbin:$PATH"

# iTerm2
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Bart
export PATH="/Users/bart.vanraaij/.composer/vendor/bin:$PATH"
export PATH="/Users/bart.vanraaij/.bart/bin:$PATH"
