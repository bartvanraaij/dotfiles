-- C# language server (Roslyn, same as VS Code's C# extension).
-- Server: global dotnet tool `roslyn-language-server`, install/update with:
--   dotnet tool update -g roslyn-language-server --prerelease \
--     --source https://pkgs.dev.azure.com/azure-public/vside/_packaging/vs-impl/nuget/v3/index.json
-- Pick a different .sln with :Roslyn target
return {
  "seblyng/roslyn.nvim",
  ft = { "cs", "razor" },
  ---@module 'roslyn.config'
  ---@type RoslynNvimConfig
  opts = {},
  config = function(_, opts)
    require("roslyn").setup(opts)

    -- "N references" code lens at the end of declaration lines (like Rider's usages hint).
    -- Rendered by our own lua/codelens_eol.lua instead of vim.lsp.codelens (virtual line above)
    local codelens_eol = require("codelens_eol")
    vim.lsp.config("roslyn", {
      settings = {
        ["csharp|code_lens"] = {
          dotnet_enable_references_code_lens = true,
        },
      },
      handlers = {
        ["workspace/codeLens/refresh"] = codelens_eol.on_refresh,
      },
    })
    local wrapped_clients = {} ---@type table<integer, boolean>
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserRoslynCodeLens", {}),
      callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not (client and client.name == "roslyn") then
          return
        end
        codelens_eol.attach(ev.buf, client)

        -- Counts fetched while the solution is still loading can be wrong (e.g. an overload call
        -- counted for the wrong overload). Re-fetch once Roslyn reports the solution is loaded,
        -- keeping roslyn.nvim's own handler for this notification
        if not wrapped_clients[client.id] then
          wrapped_clients[client.id] = true
          local method = "workspace/projectInitializationComplete"
          local original = client.handlers[method]
          client.handlers[method] = function(err, result, ctx)
            if original then
              original(err, result, ctx)
            end
            codelens_eol.refresh_client(client)
          end
        end
      end,
    })
  end,
}
