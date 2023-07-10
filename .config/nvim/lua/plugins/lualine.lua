return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local function neotreeSrcSel()
      --print(vim.api.nvim_buf_get_name(0))
      if vim.bo.filetype == "neo-tree" then
        return "%{%v:lua.require'neo-tree.ui.selector'.get()%}"
      else
        return ""
      end
    end

    local bufferline = {
      "buffers",
      component_separators = {
        left = "",
        right = "",
      },
      mode = 2,
      show_modified_status = false,
      symbols = {
        alternate_file = "",
      },
      max_length = vim.o.columns,
    }

    local wb = {
      lualine_c = {
        --  function()
        --    if vim.bo.filetype == "neo-tree" then
        --      return "%{%v:lua.require'neo-tree.ui.selector'.get()%}"
        --    else
        --      return          ''
        --    end
        --  end,
        {
          "filetype",
          icon_only = true,
          separator = "",
          padding = 0,
          cond = function()
            return vim.bo.filetype ~= "neo-tree"
          end,
        },
        {
          "filename",
          separator = "a",

          cond = function()
            return vim.bo.filetype ~= "neo-tree"
          end,
        },
      },
      lualine_z = {
        -- bufferline,
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
      --tabline = {
      --  lualine_z = {
      --    bufferline,
      --  }
      --}
    })
  end,
}
