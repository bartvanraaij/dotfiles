return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local wb = {
      lualine_c = {
        {
          "filetype",
          icon_only = true,
          separator = '',
        },
        {
          "filename",
          separator = '',
        },
      },
    }

    require("lualine").setup({
      options = {
        globalstatus = true, 
        theme = "auto",
        component_separators = { left = "•", right = "•" },
        section_separators = "",
      },
      extensions = {
        --'nvim-tree',
      },
      sections = {
        lualine_a = {
          {
            "mode",
            fmt = function(str)
              return str:sub(1, 1)
            end,
          },
        },
        lualine_c = {
          require("auto-session.lib").current_session_name,
          "%f", -- Full file path
        },
      },
      winbar = wb,
      inactive_winbar = wb,
    })
  end,
}
