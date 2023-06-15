return {
    "akinsho/toggleterm.nvim",
    lazy = false,
    version = "*",
    config = function()
      require('toggleterm').setup({
        open_mapping = [[<c-\>]],
      })
    end,
}
