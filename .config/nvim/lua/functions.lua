local M = {}
function M.map(mode, keyphrase, command, desc, opts)
  local options = { remap = false, silent = true, desc = desc }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.keymap.set(mode, keyphrase, command, options)
end

function M.lsp_format(bufnr)
  --print(vim.inspect(bufnr))
  vim.lsp.buf.format({
    filter = function(client)
      -- Don't use ts_ls for formatting
      return client.name ~= "ts_ls"
    end,
    bufnr = bufnr,
  })
end

--vim.api.nvim_create_user_command('LspFormat', lsp_format, {})

return M
