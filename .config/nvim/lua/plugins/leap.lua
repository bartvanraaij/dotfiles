return {
  url = "https://codeberg.org/andyg/leap.nvim",
  lazy = false,
  config = function()
   require('leap').add_default_mappings()
  end,
  enabled = true,
}
