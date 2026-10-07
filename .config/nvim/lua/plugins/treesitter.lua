-- nvim-treesitter `main` branch (master is frozen and doesn't support nvim 0.12).
-- It only installs parsers/queries; highlighting is nvim's own vim.treesitter.start().
-- No lazy-loading: highlighting must be ready before auto-session restores buffers.
local ensure_installed = {
  "c", "lua", "vim", "vimdoc", "query", "php", "javascript", "rust", "toml",
  "c_sharp", "typescript", "json", "yaml", "bash",
  "markdown", "markdown_inline", -- used by noice and LSP hover popups
}

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local ts = require("nvim-treesitter")
    ts.install(ensure_installed)

    -- Only take over from regex syntax when there's a highlights query (e.g. tmux has a parser but none)
    -- Checks the file, not vim.treesitter.query.get(): that caches a nil result, which would
    -- keep highlighting off after auto-installing the parser below
    local function start(buf, lang)
      local has_query = #vim.api.nvim_get_runtime_file("queries/" .. lang .. "/highlights.scm", false) > 0
      return has_query and pcall(vim.treesitter.start, buf, lang)
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("UserTreesitter", {}),
      callback = function(ev)
        local lang = vim.treesitter.language.get_lang(ev.match)
        if not lang then
          return
        end
        if start(ev.buf, lang) then
          return
        end
        -- Replaces master's auto_install: install missing parser, then start highlighting
        if vim.tbl_contains(ts.get_available(), lang) and not vim.tbl_contains(ts.get_installed(), lang) then
          ts.install(lang):await(function()
            vim.schedule(function()
              if vim.api.nvim_buf_is_valid(ev.buf) then
                start(ev.buf, lang)
              end
            end)
          end)
        end
      end,
    })
  end,
}
