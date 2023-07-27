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
      },
      source_selector = {
        winbar = true,
      }
    })
  end,
}
