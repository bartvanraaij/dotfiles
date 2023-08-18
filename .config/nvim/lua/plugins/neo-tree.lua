return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  --event = "VeryLazy",
  lazy = false,
  enabled = true,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("neo-tree").setup({
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = false,
        },
        follow_current_file = {
          enabled = true,
        },
      },
      hide_root_node = true,
      source_selector = {
        winbar = true,
        statusline = false,
        -- show_scrolled_off_parent_node=true,

        highlight_tab = "BufferLineBuffer",
        highlight_tab_active = "BufferLineBufferSelected",
        highlight_background = "Somethign1",
        highlight_separator = "BufferLineSeparator",
        highlight_separator_active = "BufferLineSeparatorSelected",
      },
    })
  end,
}
