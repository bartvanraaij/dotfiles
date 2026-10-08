return {
  "mason-org/mason-lspconfig.nvim",
  dependencies = {
    "mason-org/mason.nvim",
    "neovim/nvim-lspconfig",
    "nvim-lua/plenary.nvim",
    "mfussenegger/nvim-lint",
    "linrongbin16/lsp-progress.nvim",
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
      ensure_installed = { "lua_ls", "phpactor", "ts_ls", "yamlls", "intelephense", "rust_analyzer", "jsonls" },
      -- Enable servers manually below (keeps intelephense installed but disabled)
      automatic_enable = false,
    })

    -- Enable servers (nvim 0.11+ native API; configs come from nvim-lspconfig's lsp/ dir).
    -- Per-server overrides: vim.lsp.config("lua_ls", { settings = { ... } })
    vim.lsp.enable({
      "lua_ls",
      "phpactor",
      -- "intelephense",
      "ts_ls",
      "yamlls",
      "rust_analyzer",
      "jsonls",
    })

    -- Setup nvim-linti
    local phpcs = require("lint").linters.phpcs
    phpcs.cmd = "vendor/bin/phpcs"

    require("lint").linters_by_ft = {
      php = { "phpcs" },
    }

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost", "BufEnter" }, {
      callback = function()
        require("lint").try_lint()
      end,
    })

    -- Setup lsp progress
    require("lsp-progress").setup()

    local Float = require("plenary.window.float")

    vim.cmd([[
    augroup LspPhpactor
      autocmd!
      autocmd Filetype php command! -nargs=0 LspPhpactorReindex lua vim.lsp.buf_notify(0, "phpactor/indexer/reindex",{})
      autocmd Filetype php command! -nargs=0 LspPhpactorConfig lua LspPhpactorDumpConfig()
      autocmd Filetype php command! -nargs=0 LspPhpactorStatus lua LspPhpactorStatus()
      autocmd Filetype php command! -nargs=0 LspPhpactorBlackfireStart lua LspPhpactorBlackfireStart()
      autocmd Filetype php command! -nargs=0 LspPhpactorBlackfireFinish lua LspPhpactorBlackfireFinish()
    augroup END
]])

    local function showWindow(title, syntax, contents)
      local out = {}
      for match in string.gmatch(contents, "[^\n]+") do
        table.insert(out, match)
      end

      local float = Float.percentage_range_window(0.6, 0.4, { winblend = 0 }, {
        title = title,
        topleft = "┌",
        topright = "┐",
        top = "─",
        left = "│",
        right = "│",
        botleft = "└",
        botright = "┘",
        bot = "─",
      })

      vim.bo[float.bufnr].filetype = syntax
      vim.api.nvim_buf_set_lines(float.bufnr, 0, -1, false, out)
    end

    function LspPhpactorDumpConfig()
      local results, _ = vim.lsp.buf_request_sync(0, "phpactor/debug/config", { ["return"] = true })
      for _, res in pairs(results or {}) do
        showWindow("Phpactor LSP Configuration", "json", res["result"])
      end
    end
    function LspPhpactorStatus()
      local results, _ = vim.lsp.buf_request_sync(0, "phpactor/status", { ["return"] = true })
      for _, res in pairs(results or {}) do
        showWindow("Phpactor Status", "markdown", res["result"])
      end
    end

    function LspPhpactorBlackfireStart()
      local _, _ = vim.lsp.buf_request_sync(0, "blackfire/start", {})
    end
    function LspPhpactorBlackfireFinish()
      local _, _ = vim.lsp.buf_request_sync(0, "blackfire/finish", {})
    end
  end,
  build = ":MasonUpdate",
}
