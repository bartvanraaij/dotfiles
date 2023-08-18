return {
  "williamboman/mason-lspconfig.nvim",
  dependencies = {
    "williamboman/mason.nvim",
    "neovim/nvim-lspconfig",
    --"jose-elias-alvarez/null-ls.nvim",
    "nvim-lua/plenary.nvim",
    "mhartington/formatter.nvim",
    "mfussenegger/nvim-lint",
  },
  --event = "VeryLazy",
  event = "User FileOpened",
  --ft = { "php" },
  --lazy = false,
  enabled = true,
  config = function()
    -- Setup Mason
    require("mason").setup()
    require("mason-lspconfig").setup({
      ensure_installed = { "lua_ls", "phpactor", "tsserver", "yamlls", "intelephense" },
      automatic_installation = { exclude = { "tailwindcss" } },
    })

    -- Auto setup handlers:
    --[[
    require("mason-lspconfig").setup_handlers({
      function(server_name) -- default handler (optional)
        require("lspconfig")[server_name].setup({})
      end,
    })
    --]]
    -- Manual setup handlers:
    require("lspconfig").lua_ls.setup({})
    require("lspconfig").phpactor.setup({})
    -- require("lspconfig").intelephense.setup({})
    require("lspconfig").tsserver.setup({})
    require("lspconfig").yamlls.setup({})

    -- Setup formatter.nvim
    local util = require("formatter.util")
    require("formatter").setup({
      -- Enable or disable logging
      logging = true,
      -- Set the log level
      log_level = vim.log.levels.WARN,
      -- All formatter configurations are opt-in
      filetype = {
        -- Formatter configurations for filetype "lua" go here
        -- and will be executed in order
        lua = {
          -- "formatter.filetypes.lua" defines default configurations for the
          -- "lua" filetype
          require("formatter.filetypes.lua").stylua,
        },
        php = {
          function()
            return {
              exe = "vendor/bin/phpcbf",
              args = {
                "--stdin-path=" .. util.quote_cmd_arg(util.get_current_buffer_file_path()),
                "-",
              },
              ignore_exitcode = true,
              stdin = true,
              no_append = true,
            }
          end,
        },
        javascript = {
          require("formatter.filetypes.javascript").semistandard,
        }

        -- Use the special "*" filetype for defining formatter configurations on
        -- any filetype
      --  ["*"] = {
          -- "formatter.filetypes.any" defines default configurations for any
          -- filetype
        --  require("formatter.filetypes.any").remove_trailing_whitespace,
        --},
      },
    })

    -- Setup nvim-linti
    local phpcs = require('lint').linters.phpcs
    phpcs.cmd = 'vendor/bin/phpcs'

    require('lint').linters_by_ft = {
      php = { 'phpcs', }
    }

    vim.api.nvim_create_autocmd({"TextChanged","TextChangedI","BufWritePost","BufEnter" }, {
      callback = function()
        require("lint").try_lint()
      end,
    })


    -- Setup Null-ls
    --
    -- local null_ls = require("null-ls")
    -- null_ls.setup({
    --   sources = {
    --     null_ls.builtins.diagnostics.phpcs.with({
    --       prefer_local = "vendor/bin",
    --       args = {
    --         "--report=json",
    --         "-q",
    --         "-s",
    --         "--runtime-set",
    --         "ignore_warnings_on_exit",
    --         "1",
    --         "--runtime-set",
    --         "ignore_errors_on_exit",
    --         "1",
    --         "--stdin-path=$FILENAME",
    --         "--basepath=",
    --       },
    --     }),
    --     null_ls.builtins.formatting.phpcbf.with({
    --       prefer_local = "vendor/bin",
    --     }),
    --     --null_ls.builtins.formatting.phpcsfixer.with({
    --     --  prefer_local = "vendor/bin",
    --     --}),
    --     null_ls.builtins.formatting.prettierd,
    --     null_ls.builtins.formatting.stylua,
    --     null_ls.builtins.formatting.shfmt.with({ filetypes = { "sh", "zsh" } }),
    --     null_ls.builtins.diagnostics.shellcheck.with({ filetypes = { "sh", "zsh" } }),
    --     null_ls.builtins.code_actions.shellcheck.with({ filetypes = { "sh", "zsh" } }),
    --     null_ls.builtins.diagnostics.zsh,
    --     null_ls.builtins.code_actions.gitsigns,
    --   },
    -- })
    --
    -- Setup lsp progress
    --require("lsp-progress").setup()

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
