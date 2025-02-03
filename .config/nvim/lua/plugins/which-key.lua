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

    -- wk.register({
    --   --["e"] = { "<cmd>NvimTreeToggle<CR>", "Toggle file explorer" },
    -- f = {
    --   name = "Find", -- optional group name
    ----f = { "<cmd>Telescope find_files<cr>", "Find files" }, -- create a binding with label
    ----r = { "<cmd>Telescope oldfiles<cr>", "Recent files" }, -- additional options for creating the keymap
    ----g = { "<cmd>Telescope live_grep<cr>", "Find in files" }, -- additional options for creating the keymap
    ----r = { "<cmd>Telescope oldfiles<cr>", "Recent files", noremap = false }, -- additional options for creating the keymap
    --n = { "New File" }, -- just a label. don't create any mapping
    --e = "Edit File", -- same as above
    --["1"] = "which_key_ignore", -- special label to hide it in the popup
    --b = { function()
    --  print("bar")
    --   --end, "Foobar" }                               -- you can also pass functions!
    -- },
    --   b = {
    --     name = "Buffers",
    --  },
    --  c = {
    -- --   name = "Code",
    --  },
    -- t = {
    --   name = "Test",
    --f = { "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<cr>", "File" },
    --o = { "<cmd>lua require('neotest').output_panel.open({ enter = true, short = false })<cr>", "Output" },
    --r = { "<cmd>lua require('neotest').run.run({env=require('user.ntest').get_env()})<cr>", "Run" },
    --a = { "<cmd>lua require('user.ntest').run_all()<cr>", "Run All" },
    --c = { "<cmd>lua require('user.ntest').cancel()<cr>", "Cancel" },
    --s = { "<cmd>lua require('neotest').summary.toggle()<cr>", "Summary" },
    --d = { "<cmd>lua require('neotest').run.run({ strategy = 'dap' })<cr>", "Dap Run" },
    -- },
    -- p = {
    --     name = "Plugins",
    -- --   },
    -- }, { prefix = "<leader>" })
  end,
}
