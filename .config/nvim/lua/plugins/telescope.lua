return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.1",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-fzf-native.nvim",
    "nvim-telescope/telescope-live-grep-args.nvim",
    --		"nvim-telescope/telescope-ui-select.nvim",
  },
  --cmd = "Telescope",
  event = "VeryLazy",
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    local custom_dropdown = require("telescope.themes").get_dropdown({
      layout_config = {
        mirror = true,
        prompt_position = "bottom",
        --height = function(_, _, max_lines)
        --  return math.min(max_lines, 50)
        --end,
        height = function(_, _, max_lines)
          return math.min(max_lines, 24) -- Show 24 results on screen, or lower if fewer results
        end,
      },
      sorting_strategy = "descending",
      path_display = {
        truncate = 2,
      },
    })

    telescope.setup({
      defaults = vim.tbl_extend(
        "force",
        {}, --custom_dropdown,
        {
          mappings = {
            i = {
              ["<esc>"] = actions.close,
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-n>"] = actions.cycle_history_next,
              ["<C-p>"] = actions.cycle_history_prev,
            },
          },
          path_display = {
            truncate = 2,
          },
        }
      ),
      extensions = {
        --["ui-select"] = {
        --  custom_dropdown,
        --},
        live_grep_args = {
          auto_quoting = false,
        }
      },
      pickers = {
        buffers = {
          sort_lastused = true,
          sort_mru = true,
        },
        lsp_definitions = {
          --theme = 'dropdown',
          --fname_width = 100,
          show_line = false,
        },
        lsp_declarations = {
          show_line = false,
        },
        lsp_references = {
          --theme = 'dropdown',
          --layout_config = {
          --  mirror = true,
          --},
          --fname_width = 100,
          show_line = false,
        },
        lsp_implementations = {
          show_line = false,
        },
        colorscheme = {
          --theme = 'dropdown',
          enable_preview = true,
          --layout_config = {
          --  mirror = true,
          --}
          --          layout_config = {
          --            preview_cutoff = 120
          --          },
        },
        find_files = {
          hidden = true,
          -- no_ignore = true,
        },
      },
    })

    telescope.load_extension("fzf")
    telescope.load_extension("live_grep_args")
    --telescope.load_extension("projects")
    --telescope.load_extension("ui-select")

    -- Set the border color to be the same as Noice's Cmdline
    vim.api.nvim_set_hl(0, "TelescopeBorder", { link = "NoiceCmdlinePopupBorder" })
  end,
}
