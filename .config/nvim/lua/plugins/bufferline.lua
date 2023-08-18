return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  dependencies = "nvim-tree/nvim-web-devicons",
  enabled = true,
  config = function()
    require("bufferline").setup({
      options = {
        numbers = "ordinal",
        show_buffer_close_icons = false,
        enforce_regular_tabs = true,
        offsets = {
          {
            filetype = "neo-tree",
            text = function()
              return ''
              --return require('neo-tree.sources.manager').get_state_for_window().display_name
              --return vim.fn.getcwd()
            end,
            highlight = "PanelHeading",
            padding = 1,
          },
        },
        separator_style = "thin",
      },
    })
  end,
}
