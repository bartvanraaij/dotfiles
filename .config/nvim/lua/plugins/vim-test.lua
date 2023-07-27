return {
  "vim-test/vim-test",
  event = "User FileOpened",
  config = function ()
    vim.g["test#strategy"] = "vtr"
  end
}
