# UI changes: I check the look myself

For visual or interactive tweaks (colors, layout, keymaps, spinners, popups in nvim, tmux or TUIs), keep your own verification light: a quick load/syntax check or a short scripted render is enough, then hand over and I'll try it. Don't run long headless harnesses for that (e.g. a 60s+ LSP startup) — I can see the result faster.

Keep heavier verification for risky changes: plugin migrations, startup or session behavior, anything that can lose data.
