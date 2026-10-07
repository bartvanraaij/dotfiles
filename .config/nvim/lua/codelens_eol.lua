-- Code lens at the end of the cursor line (Rider-style "11 references" hint), instead of
-- nvim's built-in rendering as a virtual line above every declaration.
-- Fetches and resolves lenses itself. Usage (see plugins/roslyn.lua):
--   attach(bufnr, client) from LspAttach, and on_refresh as the server's
--   "workspace/codeLens/refresh" handler.
local M = {}

local ns = vim.api.nvim_create_namespace("user_codelens_eol")
local generation = {} ---@type table<integer, integer> bufnr -> latest request, to drop stale answers
local attached = {} ---@type table<integer, boolean>
local lens_rows = {} ---@type table<integer, table<integer, {col: integer, end_col: integer, title: string}[]>>

-- Underline for the identifier a lens belongs to. `default` so themes can override
local function set_target_hl()
  vim.api.nvim_set_hl(0, "LspCodeLensTarget", { underline = true, default = true })
end
set_target_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("user_codelens_eol_hl", {}),
  callback = set_target_hl,
})

--- Show the lens of the cursor line only: the count at the end of the line, and an underline
--- on the declared identifier(s) it belongs to (e.g. which `From` in `From(Field f) => From(...)`)
---@param bufnr integer
local function show_cursor_lens(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  if vim.api.nvim_get_current_buf() ~= bufnr or vim.fn.mode() ~= "n" then
    return
  end
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local lenses = (lens_rows[bufnr] or {})[row]
  if not lenses then
    return
  end

  for _, lens in ipairs(lenses) do
    pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, row, lens.col, {
      end_col = lens.end_col,
      hl_group = "LspCodeLensTarget",
    })
  end
  local titles = vim.tbl_map(function(lens)
    return lens.title
  end, lenses)
  pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, row, 0, {
    virt_text = { { "  " .. table.concat(titles, " | "), "LspCodeLens" } },
    virt_text_pos = "eol",
    hl_mode = "combine",
  })
end

--- LSP positions count UTF-16 code units; extmarks want byte columns
---@param bufnr integer
---@param pos lsp.Position
local function byte_col(bufnr, pos)
  local line = vim.api.nvim_buf_get_lines(bufnr, pos.line, pos.line + 1, false)[1] or ""
  local ok, col = pcall(vim.str_byteindex, line, "utf-16", pos.character, false)
  return ok and col or pos.character
end

---@param bufnr integer
---@param rows table<integer, {col: integer, end_col: integer, title: string}[]>
local function render(bufnr, rows)
  -- Several declarations on one line: show in column order
  for _, lenses in pairs(rows) do
    table.sort(lenses, function(a, b)
      return a.col < b.col
    end)
  end
  lens_rows[bufnr] = rows
  show_cursor_lens(bufnr)
end

---@param bufnr integer
---@param client vim.lsp.Client
function M.refresh(bufnr, client)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  generation[bufnr] = (generation[bufnr] or 0) + 1
  local gen = generation[bufnr]
  local function current()
    return gen == generation[bufnr] and vim.api.nvim_buf_is_valid(bufnr)
  end

  local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
  client:request("textDocument/codeLens", params, function(err, lenses)
    if err or not current() then
      return
    end
    lenses = lenses or {}
    local rows, pending = {}, #lenses

    ---@param lens? lsp.CodeLens
    local function add(lens)
      if lens and lens.command and lens.command.title ~= "" then
        local row = lens.range.start.line
        rows[row] = rows[row] or {}
        -- Roslyn's lens range is exactly the declared identifier
        table.insert(rows[row], {
          col = byte_col(bufnr, lens.range.start),
          end_col = byte_col(bufnr, lens.range["end"]),
          title = lens.command.title,
        })
      end
      pending = pending - 1
      if pending == 0 and current() then
        render(bufnr, rows)
      end
    end

    if pending == 0 then
      render(bufnr, rows)
      return
    end
    for _, lens in ipairs(lenses) do
      if lens.command then
        add(lens)
      else
        -- Roslyn only computes the reference count on resolve
        client:request("codeLens/resolve", lens, function(resolve_err, resolved)
          add(not resolve_err and resolved or nil)
        end, bufnr)
      end
    end
  end, bufnr)
end

---@param bufnr integer
---@param client vim.lsp.Client
function M.attach(bufnr, client)
  if attached[bufnr] then
    return
  end
  attached[bufnr] = true

  local group = vim.api.nvim_create_augroup("user_codelens_eol_" .. bufnr, {})
  local timer = assert(vim.uv.new_timer())
  local function refresh_after(delay)
    timer:stop()
    timer:start(delay, 0, vim.schedule_wrap(function()
      M.refresh(bufnr, client)
    end))
  end

  vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "BufWritePost" }, {
    group = group,
    buffer = bufnr,
    callback = function()
      refresh_after(0)
    end,
  })
  vim.api.nvim_create_autocmd("TextChanged", {
    group = group,
    buffer = bufnr,
    callback = function()
      refresh_after(500)
    end,
  })
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    buffer = bufnr,
    callback = function()
      show_cursor_lens(bufnr)
    end,
  })
  vim.api.nvim_create_autocmd({ "InsertEnter", "BufLeave" }, {
    group = group,
    buffer = bufnr,
    callback = function()
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end,
  })
  vim.api.nvim_create_autocmd("LspDetach", {
    group = group,
    buffer = bufnr,
    callback = function(ev)
      if ev.data.client_id ~= client.id then
        return
      end
      attached[bufnr] = nil
      generation[bufnr] = nil
      lens_rows[bufnr] = nil
      timer:stop()
      timer:close()
      vim.api.nvim_del_augroup_by_id(group)
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
      end
    end,
  })

  M.refresh(bufnr, client)
end

--- Re-fetch lenses in all buffers of this client that we're attached to
---@param client vim.lsp.Client
function M.refresh_client(client)
  for bufnr in pairs(client.attached_buffers) do
    if attached[bufnr] then
      M.refresh(bufnr, client)
    end
  end
end

--- Handler for "workspace/codeLens/refresh": the server says counts changed
---@type lsp.Handler
function M.on_refresh(_, _, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  if client then
    M.refresh_client(client)
  end
  return vim.NIL
end

return M
