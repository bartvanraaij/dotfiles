return {
  "rcarriga/nvim-notify",
  optional = true,
  config = function()
    require("notify").setup({
      stages = "static",
      fps = 1,
      timeout = 10000, -- ms a popup stays (default 5000 was too short to read); see :Noice history
    })
  end,
}
