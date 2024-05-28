return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    "theHamsta/nvim-dap-virtual-text",
    "nvim-telescope/telescope-dap.nvim",
  },
  --lazy = false,
  event = "VeryLazy",
  config = function()
    local dap = require("dap")
    require("telescope").load_extension("dap")

    dap.adapters.php = {
      type = "executable",
      command = "node",
      args = { os.getenv("HOME") .. "/Dev/vscode-php-debug/out/phpDebug.js" },
    }

    dap.configurations.php = {
      {
        type = "php",
        request = "launch",
        name = "Listen for Xdebug",
        port = 9004,
        log = true,
        pathMappings = {
          ["/srv/app"] = "${workspaceFolder}",
        },
      },
    }

    require("nvim-dap-virtual-text").setup()
    require("dapui").setup({
      layouts = {
        {
          elements = {
            {
              id = "scopes",
              size = 0.70,
            },
            {
              id = "breakpoints",
              size = 0.10,
            },
            {
              id = "stacks",
              size = 0.20,
            },
          },
          position = "left",
          size = 50,
        },
        {
          elements = {
            {
              id = "repl",
              size = 1,
            },
          },
          position = "bottom",
          size = 10,
        },
      },
    })
  end,
}
