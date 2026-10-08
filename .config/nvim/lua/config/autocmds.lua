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

-- LSP lookups that get a spinner when slow (servers don't send progress for these themselves)
local slow_lsp_requests = {
  ["textDocument/definition"] = "Finding definition",
  ["textDocument/references"] = "Finding references",
  ["textDocument/implementation"] = "Finding implementations",
  ["textDocument/typeDefinition"] = "Finding type definition",
}
local shown_lsp_requests = {}

local autocmds = {
  { -- Show pending gd/gr/gi lookups as noice LSP progress (same spinner as server progress)
    { "LspRequest" },
    {
      group = "_slow_lsp_request",
      callback = function(ev)
        local client_id, request_id, request = ev.data.client_id, ev.data.request_id, ev.data.request
        local title = slow_lsp_requests[request.method]
        local ok, progress = pcall(require, "noice.lsp.progress")
        if not (title and ok) then
          return
        end
        local token = "user_request_" .. request_id
        local key = client_id .. "." .. token -- noice's progress message id

        if request.type == "pending" then
          -- Only show when still pending after 200ms, so fast answers don't flash a spinner
          vim.defer_fn(function()
            local client = vim.lsp.get_client_by_id(client_id)
            local pending = client and client.requests[request_id]
            if pending and pending.type == "pending" then
              shown_lsp_requests[key] = true
              progress.progress({ client_id = client_id, params = { token = token, value = { kind = "begin", title = title } } })
            end
          end, 200)
        elseif shown_lsp_requests[key] then -- complete or cancel
          shown_lsp_requests[key] = nil
          -- Close right away instead of a "done" end-event, which noice keeps on screen a bit longer
          progress.close(key)
        end
      end,
    },
  },
  { -- taken from LunarVim
    { "BufRead", "BufWinEnter", "BufNewFile" },
    {
      group = "_file_opened",
      nested = true,
      callback = function(args)
        local buftype = vim.api.nvim_get_option_value("buftype", { buf = args.buf })
        if not (vim.fn.expand("%") == "" or buftype == "nofile") then
          vim.api.nvim_del_augroup_by_name("_file_opened")
          -- Deferred until BufRead (incl. filetype detection) is done: plugins loaded on FileOpened
          -- (e.g. vim.lsp.enable) can fire FileType, which makes the pending `:setf` a no-op,
          -- leaving the buffer without filetype (seen on auto-session restore)
          vim.schedule(function()
            vim.api.nvim_exec_autocmds("User", { pattern = "FileOpened" })
          end)
        end
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
    { "BufRead", "BufWinEnter", "BufNewFile" },
    {
      command = "set formatoptions-=c formatoptions-=r formatoptions-=o",
    },
  },
--   {
--     { "TermOpen term://*" },
--     {
--       callback = function()
--         local opts = { buffer = 0 }
--         vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
--       end,
--     },
--   },
  --{
  --	{ "VimEnter"},
  --	{
  --		command = 'set background=dark',
  --	}
  --},
}



define_autocmds(autocmds)

-- Reload files changed outside nvim (e.g. by Claude in another tmux pane), even while this nvim
-- isn't focused: watch each file buffer and run :checktime when it changes on disk.
-- With 'autoread' (default on) unmodified buffers reload silently; buffers with unsaved changes
-- are never overwritten, nvim warns about the conflict instead.
local file_watchers = {} ---@type table<integer, uv.uv_fs_event_t>
local watch_group = vim.api.nvim_create_augroup("_file_watch", {})

local function unwatch(bufnr)
  local watcher = file_watchers[bufnr]
  file_watchers[bufnr] = nil
  if watcher and not watcher:is_closing() then
    watcher:close()
  end
end

local function watch(bufnr)
  unwatch(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then
    return
  end
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" or not vim.uv.fs_stat(path) then
    return
  end
  local watcher = vim.uv.new_fs_event()
  if not watcher then
    return
  end
  file_watchers[bufnr] = watcher
  watcher:start(path, {}, function(err)
    -- Short delay: lets multi-step saves finish, and atomic saves (write temp file, rename it
    -- over this one) replace the file, which ends this watch, so re-attach to the new file
    vim.defer_fn(function()
      if err or not vim.api.nvim_buf_is_valid(bufnr) then
        return unwatch(bufnr)
      end
      pcall(vim.cmd.checktime, bufnr)
      watch(bufnr)
    end, 100)
  end)
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "BufFilePost" }, {
  group = watch_group,
  callback = function(ev)
    watch(ev.buf)
  end,
})
vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
  group = watch_group,
  callback = function(ev)
    unwatch(ev.buf)
  end,
})
-- Backup for changes made while no watcher was running
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  group = watch_group,
  callback = function()
    pcall(vim.cmd.checktime)
  end,
})
