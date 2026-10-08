-- Follow the terminal's light/dark theme (Ghostty, passed on by tmux; switched with the
-- `theme` shell function): GitHub light or dark colorscheme.

local function colorscheme_for_background()
  return vim.o.background == "light" and "github_light_default" or "github_dark_default"
end

local function apply_colorscheme()
  -- The colorscheme sets 'background' itself; skip when already right to avoid a loop via OptionSet
  if vim.g.colors_name ~= colorscheme_for_background() then
    -- After a 'background' change nvim has unset g:colors_name, so github-theme skips its own
    -- `hi clear` and plugin highlights from the old theme survive (bufferline only sets defaults).
    vim.cmd("hi clear")
    vim.cmd.colorscheme(colorscheme_for_background())
  end
end

-- Startup: nvim already set 'background' from the terminal's background color
apply_colorscheme()

-- Live: nvim updates 'background' on every OSC 11 (background color) answer from the terminal.
-- After a Ghostty theme reload that answer usually arrives by itself; as a fallback, ask again
-- whenever nvim gains focus (tmux focus-events).
-- (Theme change notifications, DEC mode 2031, don't reach Lua: TermResponse only gets OSC/DCS/APC/DA1.)
local group = vim.api.nvim_create_augroup("UserTerminalTheme", {})
vim.api.nvim_create_autocmd("FocusGained", {
  group = group,
  callback = function()
    vim.api.nvim_ui_send("\27]11;?\7")
  end,
})
vim.api.nvim_create_autocmd("OptionSet", {
  group = group,
  pattern = "background",
  -- Scheduled: let nvim finish its own 'background' change first (it reloads the old colorscheme)
  callback = function()
    vim.schedule(apply_colorscheme)
  end,
})
