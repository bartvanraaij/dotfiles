# Herdr: projects and work sessions

In Herdr, the user works in **work sessions** ("session" for short): one piece of work, with one or more tabs, panes and Claude sessions, often in several repos (backend, frontend, infra). Each session belongs to a **project**, the group: Merlin, Homeops, Playgrid, .config, ... The sidebar lists sessions under their project, with the project's dot.

Use these two words with the user. Herdr's own name for a session, "space", appears only in its API, commands and files (`spaces()`, `space.rename`); don't use it in conversation.

- A session's title starts as the title of the first Claude session in it. Its project comes from the folders open in it (`~/.config/herdr-app/projects.json`), settled once when it gets its title.
- `~/.claude/herdr-session.sh` reads and changes both; it finds this Claude session's work session through `HC_TERMINAL_ID`, so it works from any pane. Outside Herdr it fails; say so.

```sh
~/.claude/herdr-session.sh status                        # title, project, folders
~/.claude/herdr-session.sh title "<title>"               # rename the work session
~/.claude/herdr-session.sh project "<project>"           # set this session's project
~/.claude/herdr-session.sh add-folder "<project>" <dir>  # this folder belongs to that project from now on
```

**Title.** When the user asks to update the session title (also "herdr session title", "rename the session"), make one from the work in this conversation, unless the user gives one. Two to five words: what happens to which thing, at the level of the whole session, with the thing named as the user calls it ("Improving Herdr usage panel", "Adding vehicle images", "Fixing nvim LSP startup"). Not one part of it (the panel, not a section of the panel), and not a bare noun label. Rename only when asked.

**Project.** Set it only when the user asks. A session whose folders are in no project stays under "Other" in the sidebar; don't ask about it or set one on your own.
- "Move this session to <project>": `project "<project>"`, plus `add-folder "<project>" <dir>` for each of its folders that matches no pattern in `projects.json` yet, so the next session there lands in that project too. A folder already in another project stays there.
- "This folder belongs to <project>": `add-folder "<project>" <dir>` only.

**Why:** the user works in Claude, not in Herdr's menus, and finds work in the sidebar by project and session title.
