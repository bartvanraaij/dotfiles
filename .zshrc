export ZSH="$HOME/.config/zsh"

# Load zsh conf
source "$ZSH/load.zsh"

# pnpm
export PNPM_HOME="/Users/bartvanraaij/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
export PATH="/Users/bartvanraaij/tools:$PATH"
