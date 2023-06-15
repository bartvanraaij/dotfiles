--- Create autocommand groups based on the passed definitions
--- Also creates the augroup automatically if it doesn't exist
--- Taken from LunarVim
---@param definitions table contains a tuple of event, opts, see `:h nvim_create_autocmd`
local function define_autocmds(definitions)
  for _, entry in ipairs(definitions) do
    local event = entry[1]
    local opts = entry[2]
    if type(opts.group) == "string" and opts.group ~= "" then
      local exists, _ = pcall(vim.api.nvim_get_autocmds, { group = opts.group })
      if not exists then
        vim.api.nvim_create_augroup(opts.group, {})
      end
    end
    vim.api.nvim_create_autocmd(event, opts)
  end
end

local autocmds = {
  { -- taken from AstroNvim
    { "BufRead", "BufWinEnter", "BufNewFile" },
    {
      group = "_file_opened",
      nested = true,
      callback = function(args)
        local buftype = vim.api.nvim_get_option_value("buftype", { buf = args.buf })
        if not (vim.fn.expand("%") == "" or buftype == "nofile") then
          vim.api.nvim_del_augroup_by_name("_file_opened")
          vim.cmd("do User FileOpened")
        end
      end,
    },
  },
  { -- Fix for NvimTree in session restore
    { "BufEnter" },
    {
      pattern = "NvimTree*",
      callback = function()
        local api = require("nvim-tree.api")
        local view = require("nvim-tree.view")

        if not view.is_visible() then
          api.tree.open()
        end
      end,
    },
  },
  {
    { "VimEnter" },
    {
      callback = function()
        --require("nvim-tree.api").tree.open({ focus = false }) -- Open nvim-tree
      end,
    },
  },
  {
    { "BufLeave", "FocusLost" },
    {
      callback = function()
        -- Auto save
        --if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" and vim.bo.buftype == "" then
        --  vim.api.nvim_command('silent update')
        --end
      end,
    },
  },
  {
    { "User FileOpened" },
    {
      command = "set formatoptions-=c formatoptions-=r formatoptions-=o",
    },
  },
  {
    { "TermOpen term://*" },
    {
      callback = function()
        local opts = { buffer = 0 }
        vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
      end,
    },
  },
  --{
  --	{ "VimEnter"},
  --	{
  --		command = 'set background=dark',
  --	}
  --},
}

define_autocmds(autocmds)
