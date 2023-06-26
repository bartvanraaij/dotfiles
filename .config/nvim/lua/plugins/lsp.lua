return {
  "williamboman/mason-lspconfig.nvim",
  dependencies = {
    "williamboman/mason.nvim",
    "neovim/nvim-lspconfig",
    "jose-elias-alvarez/null-ls.nvim",
    "nvim-lua/plenary.nvim",
  },
  event = "VeryLazy",
    --event = "VeryLazy",
  --ft = { "php" },
  --lazy = false,
  enabled = true,
  config = function()
    -- Setup Mason
    require("mason").setup()
    require("mason-lspconfig").setup({
      ensure_installed = { "lua_ls", "phpactor", "tsserver", "yamlls" },
      automatic_installation = { exclude = { "tailwindcss" } },
    })


    -- Auto setup handlers:
    require("mason-lspconfig").setup_handlers({
      function(server_name) -- default handler (optional)
     --   print("Setting up " .. server_name)
        require("lspconfig")[server_name].setup({
        })
      end,
    })
    -- Manual setup handlers:
    --require("lspconfig").lua_ls.setup({})
    --require("lspconfig").phpactor.setup({})
    --require("lspconfig").tsserver.setup({})
    --require("lspconfig").yamlls.setup({})

    -- Setup Null-ls
    local null_ls = require("null-ls")
    null_ls.setup({
      sources = {
        null_ls.builtins.diagnostics.phpcs.with({
          prefer_local = "vendor/bin",
        }),
        null_ls.builtins.formatting.phpcbf.with({
          prefer_local = "vendor/bin",
        }),
        null_ls.builtins.formatting.phpcsfixer.with({
          prefer_local = "vendor/bin",
        }),
        null_ls.builtins.formatting.prettierd,
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.formatting.shfmt.with({ filetypes = { "sh", "zsh" } }),
        null_ls.builtins.diagnostics.shellcheck.with({ filetypes = { "sh", "zsh" } }),
        null_ls.builtins.code_actions.shellcheck.with({ filetypes = { "sh", "zsh" } }),
        null_ls.builtins.diagnostics.zsh,
        null_ls.builtins.code_actions.gitsigns,
      },
    })

    -- Todo setup useful keybinds
    -- Setup keybinds
    --vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
    --vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
    --vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
    --vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)
    --
    ---- Use LspAttach autocommand to only map the following keys
    ---- after the language server attaches to the current buffer
    --vim.api.nvim_create_autocmd('LspAttach', {
    --  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    --  callback = function(ev)
    --    -- Enable completion triggered by <c-x><c-o>
    --    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'
    --
    --    -- Buffer local mappings.
    --    -- See `:help vim.lsp.*` for documentation on any of the below functions
    --    local opts = { buffer = ev.buf }
    --    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    --    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    --    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    --    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    --    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    --    vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
    --    vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
    --    vim.keymap.set('n', '<space>wl', function()
    --      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    --    end, opts)
    --    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
    --    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
    --    vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
    --    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    --    vim.keymap.set('n', '<space>cf', function()
    --      vim.lsp.buf.format { async = true }
    --    end, opts)
    --  end,
    --})
  end,
  build = ":MasonUpdate",
}
