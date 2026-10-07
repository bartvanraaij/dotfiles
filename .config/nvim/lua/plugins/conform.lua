-- Formatting (replaces formatter.nvim). Manual only: :Format (<leader>cf in config/keymap.lua)
return {
  "stevearc/conform.nvim",
  cmd = { "ConformInfo", "Format" },
  ---@module "conform"
  ---@type conform.setupOpts
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      php = { "phpcbf" },
      javascript = { "semistandard" },
      json = { "prettier" },
      typescript = { "prettier" },
      rust = { "rustfmt" },
      -- Uses project-local `dotnet csharpier` if in the tool manifest, else global ~/.dotnet/tools/csharpier
      cs = { "csharpier" },
    },
    -- Filetypes without a formatter above fall back to the LSP formatter
    default_format_opts = {
      lsp_format = "fallback",
    },
    -- Built-in phpcbf already prefers vendor/bin/phpcbf and accepts its exit codes 1/2
    formatters = {
      -- Not built in: same as standardjs, but with the semistandard binary
      semistandard = {
        inherit = "standardjs",
        command = function(self, ctx)
          return require("conform.util").from_node_modules("semistandard")(self, ctx)
        end,
      },
    },
  },
  config = function(_, opts)
    require("conform").setup(opts)
    -- Keep the old formatter.nvim :Format command
    vim.api.nvim_create_user_command("Format", function(args)
      local range = nil
      if args.count ~= -1 then
        local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
        range = { start = { args.line1, 0 }, ["end"] = { args.line2, end_line:len() } }
      end
      require("conform").format({ async = true, range = range })
    end, { range = true })
  end,
}
