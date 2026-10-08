# Terminal light/dark theme, independent of macOS appearance.
#   theme            show current mode
#   theme dark|light switch
#   theme toggle     flip
# Only Ghostty is switched here (via ~/.config/ghostty/theme.ghostty, not in dotfiles).
# Everything else follows Ghostty's theme by itself:
#   tmux        client-light-theme/client-dark-theme hooks in tmux.conf
#   nvim        theme notifications (DEC mode 2031), lua/config/theme.lua
#   Claude Code "theme": "auto"
#   delta, bat  detect the terminal background per run
#   fzf, lazygit, starship, eza  use the terminal's ANSI palette
theme() {
  local file="$HOME/.config/ghostty/theme.ghostty"
  local current="dark"
  [[ -f "$file" ]] && grep -q "github-light-bart" "$file" && current="light"

  local mode="$1"
  case "$mode" in
    "") echo "$current"; return ;;
    toggle) [[ "$current" == "dark" ]] && mode="light" || mode="dark" ;;
    dark | light) ;;
    *) echo "usage: theme [dark|light|toggle]" >&2; return 1 ;;
  esac

  if [[ "$mode" == "light" ]]; then
    echo "theme = github-light-bart" >"$file"
  else
    echo "theme = GitHub Dark Default" >"$file"
  fi
  echo "Terminal theme: $mode. Reload Ghostty with Cmd+Shift+, to apply."
}
