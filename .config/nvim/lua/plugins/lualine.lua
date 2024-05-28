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

    local function LspIcon()
      local active_clients_count = #vim.lsp.get_active_clients()
      return active_clients_count > 0 and " LSP" or ""
    end

    local function LspStatus()
      return require("lsp-progress").progress({
        format = function(messages)
          return #messages > 0 and table.concat(messages, " ") or ""
        end,
      })
    end

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
        --lualine_x = {
        --  "require('lsp-progress').progress()",
        --},
      },
      --      winbar = wb,
      --     inactive_winbar = wb,
      --tabline = {
      --  lualine_z = {
      --    bufferline,
      --  }
      --}
    })

    -- listen lsp-progress event and refresh lualine
    vim.api.nvim_create_augroup("lualine_augroup", { clear = true })
    vim.api.nvim_create_autocmd("User", {
      group = "lualine_augroup",
      pattern = "LspProgressStatusUpdated",
      callback = require("lualine").refresh,
    })
  end,
}
