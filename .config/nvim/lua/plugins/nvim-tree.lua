return {
  "nvim-tree/nvim-tree.lua",
  dependencies = "nvim-tree/nvim-web-devicons",
  cmd = { "NvimTreeOpen", "NvimTreeToggle" },
  enabled = false,
  config = function()
    require("nvim-tree").setup({
      sync_root_with_cwd = false,
      respect_buf_cwd = false,
      update_focused_file = {
        enable = true,
        update_root = false,
      },
    })
  end,
}
