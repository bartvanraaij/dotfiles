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
}
