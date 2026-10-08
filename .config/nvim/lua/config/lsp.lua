-- Settings shared by all LSP servers. Loaded at startup (init.lua), before any server starts.

-- Tell servers what nvim-cmp supports (snippets, resolving completion details, ...). Without this
-- they only see nvim's default client capabilities and may skip snippet completions.
-- `require` lazy-loads cmp-nvim-lsp on its own.
vim.lsp.config("*", {
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
})
