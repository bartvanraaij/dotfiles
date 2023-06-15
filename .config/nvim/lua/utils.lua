local M = {}
function M.map(mode, keyphrase, command, desc, opts)
    local options = { noremap = true, silent = true, desc = desc }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.keymap.set(mode, keyphrase, command, options)
end

return M
