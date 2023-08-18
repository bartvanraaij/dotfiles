return {
  "numToStr/Comment.nvim",
  event = "User FileOpened",
  enabled = false,
  config = function()
    require("Comment").setup({
      opleader = {
        line = "#",
        block = "/*",
      },
    })
  end,
}
