-- Ctrl+h/j/k/l move between nvim splits and tmux panes.
-- Inside herdr without tmux, the same keys move to the neighboring herdr pane at the edge of the
-- nvim splits; herdr passes the keys to nvim through herdr/navigate.sh.
local in_herdr = vim.env.HERDR_ENV == "1" and vim.env.TMUX == nil

if in_herdr then
  local keys = { h = "left", j = "down", k = "up", l = "right" }
  for key, direction in pairs(keys) do
    vim.keymap.set("n", "<C-" .. key .. ">", function()
      local win = vim.api.nvim_get_current_win()
      vim.cmd.wincmd(key)
      if vim.api.nvim_get_current_win() == win then
        vim.system({ "herdr", "pane", "focus", "--current", "--direction", direction })
      end
    end, { desc = "Split or herdr pane " .. direction })
  end
end

return {
  "christoomey/vim-tmux-navigator",
  lazy = false,
  cond = not in_herdr,
}
