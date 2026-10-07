return {
  "folke/noice.nvim",
  --event = "VeryLazy",
  lazy = false,
  dependencies = { -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
    "MunifTanjim/nui.nvim",
    -- OPTIONAL:
    --   `nvim-notify` is only needed, if you want to use the notification view.
    --   If not available, we use `mini` as the fallback
    "rcarriga/nvim-notify",
  },
  enabled = true,
  config = function()
    require("noice").setup({
      lsp = {
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
        hover = {
          enabled = true,
        },
        signature = {
          enabled = true,
        },
      },
      messages = {
        enabled = true,
      },
      -- you can enable a preset for easier configuration
      presets = {
        bottom_search = false, -- use a classic bottom cmdline for search
        command_palette = false, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = false, -- add a border to hover docs and signature help
      },
      views = {
        -- mini keeps messages 2s after their last update; this one hides ~right away.
        -- Must stay above lsp.progress.throttle (100ms) or a running spinner flickers
        mini_quick = { view = "mini", timeout = 150 },
      },
      routes = {
        { -- gd/gr/gi "Finding ..." spinner (config/autocmds.lua): gone as soon as the server answers
          view = "mini_quick",
          filter = {
            event = "lsp",
            kind = "progress",
            cond = function(message)
              return tostring(message.opts.progress and message.opts.progress.id):find("user_request_", 1, true) ~= nil
            end,
          },
        },
      },
      cmdline = {
        view = "cmdline_popup",
        opts = {
          position = {
            row = "40%",
            col = "50%",
          },
        },
      },
    })
  end,
}
