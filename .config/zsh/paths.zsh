typeset -U path PATH
# Global bins
export PATH=/opt/homebrew/bin:$HOME/.bart/bin:$HOME/.local/bin:$HOME/bin:/usr/local/bin:$HOME/.composer/vendor/bin:$PATH

# Config dir
export XDG_CONFIG_HOME="$HOME/.config"

# NVM
#export NVM_DIR="$HOME/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Homebrew PHP
export PATH="$PATH:/opt/homebrew/opt/php@8.3/bin"
export PATH="$PATH:/opt/homebrew/opt/php@8.3/sbin"

# Chromium
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH="/opt/homebrew/bin/chromium"

# Dotnet
# The dotnet-sdk cask goes before the dotnet formula in /opt/homebrew/bin, because only the cask has the 11.0 SDK.
export DOTNET_ROOT="/usr/local/share/dotnet"
export PATH="$DOTNET_ROOT:$PATH:/Users/bartvanraaij/.dotnet/tools"

# Psql
export PATH="$PATH:/opt/homebrew/opt/libpq/bin"

 # Mysql
#export PATH="$PATH:/opt/homebrew/opt/mysql-client@8.4/bin"

# Rust (Homebrew rustup is keg-only; its bin holds the cargo/rustc/rustfmt proxies)
export PATH="/opt/homebrew/opt/rustup/bin:$HOME/.cargo/bin:$PATH"
