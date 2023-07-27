return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  enabled = false,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("alpha").setup(require("alpha.themes.dashboard").config)
  end,
}
