// Follow the workspace light/dark theme. The `theme` zsh function (zsh/theme.zsh) writes
// ghostty/theme.ghostty; Fresh can't detect the terminal background itself, so read that file.
const home = editor.getEnv("HOME");
const ghosttyTheme = editor.readFile(`${home}/.config/ghostty/theme.ghostty`) ?? "";
editor.applyTheme(/light/i.test(ghosttyTheme) ? "github-light" : "github-dark");
