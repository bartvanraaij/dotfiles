# Global bins
export PATH=/opt/homebrew/bin:$HOME/.bart/bin:$HOME/.local/bin:/$HOME/bin:/usr/local/bin:$HOME/.composer/vendor/bin:$PATH

# Config dir
export XDG_CONFIG_HOME="$HOME/.config"

# Google Cloud SDK.
if [ -f '/Users/bart/.bart/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/bart/.bart/google-cloud-sdk/path.zsh.inc'; fi
if [ -f '/Users/bart/.bart/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/bart/.bart/google-cloud-sdk/completion.zsh.inc'; fi

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Homebrew PHP
export PATH="/opt/homebrew/opt/php@8.3/bin:$PATH"
export PATH="/opt/homebrew/opt/php@8.3/sbin:$PATH"

# Chromium
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH="/opt/homebrew/bin/chromium"

# Dotnet
 export DOTNET_ROOT="/opt/homebrew/opt/dotnet/libexec"

 # Mysql
 export PATH="/opt/homebrew/opt/mysql-client@8.4/bin:$PATH"
