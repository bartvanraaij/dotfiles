---
name: show-diff
description: Use when the user asks to "show the diff", "show me the diff", "let me see the changes" or similar for a git repository. Opens a tmux popup, in the terminal theme (light or dark), with the changed files in an fzf list on the left and the delta diff of the selected file on the right, instead of printing the diff in the chat.
---

# Show the diff

Run the script from the repository the diff is about (the worktree you work in):

```sh
~/.claude/skills/show-diff/show-diff.sh [git diff args]
```

- No args: unstaged and staged changes against HEAD, plus untracked files. With none of those, the branch against the default branch (`origin/main...HEAD`). This is the default for "show the diff".
- Pass git diff args for anything else: `--staged`, `HEAD~1`, `main...HEAD` (a branch or PR), a commit range.
- The script returns at once; the popup stays open until the user closes it. Don't wait or poll.
- Don't print the diff in the chat as well. Reply in one or two lines: what the popup shows (which range, how many files) and the keys: ↑/↓ or type to pick a file, ctrl-d/ctrl-u to scroll the diff, esc to close.
- The theme follows the user's `theme` shell function (it reads `~/.config/ghostty/theme.ghostty`); no flag needed.
- "No changes." in the popup means the range is empty; say so and ask which range they meant.
- Outside tmux the script exits with "not inside tmux"; then show `git diff --stat` and ask how they want to see it.
