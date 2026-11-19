# Herdr: projects and work sessions

In Herdr, the user works in **work sessions** (Herdr calls them spaces): one piece of work, often with panes in several repos (backend, frontend, infra). Each session belongs to a **project**: Merlin, Homeops, Playgrid, .config, ... The sidebar lists sessions under their project, with the project's badge.

- A session's title starts as the title of the first Claude session in it. Its project comes from the folders open in it (`~/.config/herdr-app/projects.json`), settled once when it gets its title.
- `~/.claude/herdr-session.sh` reads and changes both; it finds this Claude session's work session through `HC_TERMINAL_ID`, so it works from any pane. Outside Herdr it fails; say so.

```sh
~/.claude/herdr-session.sh status                        # title, project, folders
~/.claude/herdr-session.sh title "<title>"               # rename the work session
~/.claude/herdr-session.sh project "<project>"           # set this session's project
~/.claude/herdr-session.sh add-folder "<project>" <dir>  # this folder belongs to that project from now on
```

**Title.** When the user asks to update the session title (also "space title", "rename the session"), make one from the work in this conversation, unless the user gives one. Short and sweet: two to four words, the feature or goal ("Vehicle images", "Claude usage panel"). Rename only when asked.

**Project.** When the user asks, set it with `project`. On your own, only when the session has no project: a SessionStart hook then tells you so. Decide from context which project the session's folders belong to (an existing one, or a new one when it's clearly separate); when it's unclear, ask the user ("Which project does `~/Dev/foo` belong to: Merlin, Homeops, …?"). Then run `add-folder` for the folder, so the next session there needs no question, and `project` for this session. Mention it in one line.

**Why:** the user works in Claude, not in Herdr's menus, and finds work in the sidebar by project and session title.
