-- Load Vim options
require("config.options")

-- Enable Lua loader
vim.loader.enable()

-- Custom functions
require("functions")

-- Autocmds
require("config.autocmds")

-- Load lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

vim.opt.runtimepath:prepend(lazypath)

require("lazy").setup("plugins", {
  defaults = { lazy = true },
  install = {
    colorscheme = { "github_light" },
  },
  change_detection = {
    enabled = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
        "matchit",
      },
    },
  },
})

-- Keymap
require("config.keymap")

-- Colorscheme
vim.cmd([[colorscheme github_light]])

-- Icons
require("config.icons")
