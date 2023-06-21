return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  dependencies = "nvim-tree/nvim-web-devicons",
  enabled = false,
  config = function()
    require("bufferline").setup({
      options = {
        offsets = {
          {
            filetype = "NvimTree",
            text = nil,
            highlight = "PanelHeading",
            padding = 1,
          },
        },
        separator_style = "thin",
      },
    })
  end,
}
