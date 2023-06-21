return {
  "rcarriga/nvim-notify",
  optional = true,
  config = function ()
    require('notify').setup({
      stages = "static",
    })
  end
}
