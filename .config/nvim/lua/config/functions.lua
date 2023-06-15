local lazygit_terminal
local function toggle_lazygit()
  if lazygit_terminal == nil then
    lazygit_terminal = require("toggleterm.terminal").Terminal:new({
      cmd = "lazygit",
      dir = "git_dir",
      direction = "float",
      hidden = true,
    })
  end
  return lazygit_terminal:toggle()
end
vim.api.nvim_create_user_command("LazygitToggle", toggle_lazygit, {})

vim.filetype.add({
  extension = {
    njk = "html",
  },
})
