return {
  "rebelot/kanagawa.nvim",
  lazy = false, -- make sure we load this during startup if it is your main colorscheme
  priority = 1000,
  config = function()
    require("kanagawa").setup({
      overrides = function(colors)
        --local theme = colors.theme
        return {
          WinSeparator = {
            fg = colors.theme.ui.nontext --Higher contrast window splits
          }
        }
      end,
    })
  end,
}
