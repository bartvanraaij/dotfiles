return {
    "nvim-tree/nvim-tree.lua",
    dependencies = "nvim-tree/nvim-web-devicons",
    cmd = { 'NvimTreeOpen', 'NvimTreeToggle' },
		config = function ()
			require('nvim-tree').setup({
				sync_root_with_cwd = true,
				respect_buf_cwd = true,
				update_focused_file = {
    			enable = true,
    			update_root = true,
  			},
			})
		end
}
