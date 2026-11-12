# Show diffs and long content in a tmux popup

When I ask to see a diff or changes ("show diff", "show me the changes", also at the end of a bigger task), or to see something in a popup, run the script below directly with Bash. Both scripts return at once; the popup stays open until I close it. Don't wait or poll, and don't repeat the content in the chat. Reply in one line: what the popup shows. I know the keys.

## Diffs

```sh
~/.claude/popups/show-diff.sh [git diff args]
```

Run it from the repo the diff is about.
- No args: unstaged and staged changes against HEAD, plus untracked files. With none of those, the branch against the default branch (`origin/main...HEAD`).
- Git diff args for anything else: `--staged`, `HEAD~1`, `main...HEAD`, a commit range.
- Outside a git repo, under `$HOME`, it shows the dotfiles bare repo (`~/.dot`). New dotfiles show up only after `dot add`.
- "No changes." in the popup means the range is empty; say so and ask which range I meant.

## Anything else (files, write-ups, command output)

```sh
~/.claude/popups/show-popup.sh [-t title] path/to/file          # .md renders as markdown
some-command | ~/.claude/popups/show-popup.sh -t "title" [-l lang]
```

- A file: pass its path; `.md` renders with glow, other files get syntax highlighting.
- Text you write yourself (a plan, summary, table): write it as markdown to a `.md` file in the scratchpad directory and pass that path. The renderer wraps at 100 columns.
- Command output: pipe it in with `-t`; `-l md`, `-l json` etc. for highlighting.
- Don't build your own `tmux display-popup` command; the scripts handle theme, size, title and keys.

Outside tmux the scripts exit with "not inside tmux"; then show it in the chat instead (`git diff --stat` for diffs).

**Why:** A rule instead of a skill saves a round trip (no skill to load first), so the popup opens a few seconds sooner.
