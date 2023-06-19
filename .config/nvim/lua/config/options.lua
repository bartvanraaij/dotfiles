-- Set leader, needs to be first
vim.g.mapleader = " "

-- Line numbers on
vim.opt.number = true

-- Full color on
vim.opt.termguicolors = true

-- No file backups
vim.opt.backup = false

-- No swap file
vim.opt.swapfile = false

-- No vi compat mode
vim.opt.compatible = false

-- Case ignore for autocompletion and search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Decrease timeout
vim.opt.timeout = true
vim.opt.timeoutlen = 300

-- Disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Indentation
vim.opt.wrap = false
vim.opt.breakindent = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Show the cursorline
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number,screenline"

-- Reserve space for signs (lsp info) in gutter
vim.opt.signcolumn = "yes"

-- Use zsh as shell
vim.opt.shell = "zsh"

-- Hide not-saved messages
vim.opt.hidden = true

-- Don't show mode in command line (it's shown by Lualine)
vim.opt.showmode = false

-- Force horizontal splits to go below the current window
vim.opt.splitbelow = true

-- Force vertical splits to go right of the current window
vim.opt.splitright = true

-- Dont show last command
vim.opt.showcmd = false

-- Store stuff in session
--vim.opt.sessionoptions="curdir,folds,help,tabpages,localoptions"

-- Wrap navigation keys
-- This causes the left and right arrow keys, as well as h and l, to wrap when used at beginning or end of lines. ( < > are the cursor keys used in normal and visual mode, and [ ] are the cursor keys in insert mode).
vim.opt.whichwrap = "b,s,<,>,h,l,[,],"

-- Use the system keyboard
vim.opt.clipboard = "unnamedplus"

-- Default file-encoding
vim.opt.fileencoding = "utf-8"

-- Show title in terminal title bar
vim.opt.title = true
vim.opt.titlestring = " %t"
--vim.opt.titlestring = "NVIM" -- Just show NVIM

-- Allow the cursor to move just past the end of the line
vim.opt.virtualedit = "onemore"

-- Allow the cursor to move anywhere
--vim.opt.virtualedit = 'all'

-- Show non-visible characters like space and eol
--vim.opt.list = true
--vim.opt.listchars:append "space:⋅"
--vim.opt.listchars:append "eol:↵"

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 6
