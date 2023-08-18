return {
  "folke/which-key.nvim",
  keys = "<leader>", -- Load on leader key press
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup()
    wk.register({
      --["e"] = { "<cmd>NvimTreeToggle<CR>", "Toggle file explorer" },
      f = {
        name = "Find", -- optional group name
        ----f = { "<cmd>Telescope find_files<cr>", "Find files" }, -- create a binding with label
        ----r = { "<cmd>Telescope oldfiles<cr>", "Recent files" }, -- additional options for creating the keymap
        ----g = { "<cmd>Telescope live_grep<cr>", "Find in files" }, -- additional options for creating the keymap
        ----r = { "<cmd>Telescope oldfiles<cr>", "Recent files", noremap = false }, -- additional options for creating the keymap
        --n = { "New File" }, -- just a label. don't create any mapping
        --e = "Edit File", -- same as above
        --["1"] = "which_key_ignore", -- special label to hide it in the popup
        --b = { function()
        --  print("bar")
        --end, "Foobar" }                               -- you can also pass functions!
      },
      b = {
        name = "Buffers",
      },
      c = {
        name = "Code",
      },
      t = {
        name = "Test",
        --f = { "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<cr>", "File" },
        --o = { "<cmd>lua require('neotest').output_panel.open({ enter = true, short = false })<cr>", "Output" },
        --r = { "<cmd>lua require('neotest').run.run({env=require('user.ntest').get_env()})<cr>", "Run" },
        --a = { "<cmd>lua require('user.ntest').run_all()<cr>", "Run All" },
        --c = { "<cmd>lua require('user.ntest').cancel()<cr>", "Cancel" },
        --s = { "<cmd>lua require('neotest').summary.toggle()<cr>", "Summary" },
        --d = { "<cmd>lua require('neotest').run.run({ strategy = 'dap' })<cr>", "Dap Run" },
      },
      p = {
        name = "Plugins",
      },
    }, { prefix = "<leader>" })
  end,
}
