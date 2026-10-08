return {
  "folke/which-key.nvim",
  keys = "<leader>", -- Load on leader key press
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup()

    wk.add({
      { "<leader>b", group = "Buffers" }, -- group
      { "<leader>c", group = "Code" },
      { "<leader>f", group = "Find" },
      { "<leader>p", group = "Plugins" },
      { "<leader>t", group = "Test" },
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File", mode = "n" },
      {
        "<leader>fb",
        function()
          print("hello")
        end,
        desc = "Foobar",
      },
      { "<leader>fn", desc = "New File" },
      { "<leader>f1", hidden = true }, -- hide this keymap
      { "<leader>w", proxy = "<c-w>", group = "windows" }, -- proxy to window mappings
      {
        "<leader>b",
        group = "buffers",
        expand = function()
          return require("which-key.extras").expand.buf()
        end,
      },
      {
        -- Nested mappings are allowed and can be added in any order
        -- Most attributes can be inherited or overridden on any level
        -- There's no limit to the depth of nesting
        mode = { "n", "v" }, -- NORMAL and VISUAL mode
        { "<leader>q", "<cmd>q<cr>", desc = "Quit" }, -- no need to specify mode since it's inherited
        { "<leader>w", "<cmd>w<cr>", desc = "Write" },
      },
    })
  end,
}
