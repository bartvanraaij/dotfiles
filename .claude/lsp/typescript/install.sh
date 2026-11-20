#!/usr/bin/env bash
# Install the TypeScript language server for Claude Code's typescript-lsp plugin.
# The plugin runs `typescript-language-server` from PATH; ~/.local/bin holds the link to this install.
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

npm ci --prefix "$dir" --no-fund --no-audit
mkdir -p "$HOME/.local/bin"
ln -sf "$dir/node_modules/.bin/typescript-language-server" "$HOME/.local/bin/typescript-language-server"

# Homebrew's bin comes before ~/.local/bin on PATH, so a Homebrew install would win.
found="$(command -v typescript-language-server || true)"
if [[ "$found" != "$HOME/.local/bin/typescript-language-server" ]]; then
  echo "warning: typescript-language-server resolves to ${found:-nothing}, not ~/.local/bin" >&2
  exit 1
fi
echo "typescript-language-server $(typescript-language-server --version) with typescript $(node -p "require('$dir/node_modules/typescript/package.json').version")"
