local map = require("../functions").map
local lsp_format = require("../functions").lsp_format
-- Unmap macro recording
vim.keymap.set("n", "q", "")

-- Save
map("n", "<C-s>", ":w<cr>", "Save")
map("i", "<C-s>", "<Esc>:w<cr>a", "Save")

-- Plugins
map("n", "<leader>pl", "<cmd>Lazy<cr>", "Lazy.nvim")

-- File explorer
map("n", "<leader>e", "<cmd>Neotree focus filesystem toggle reveal<cr>", "Explore files")
map("n", "<leader>eb", "<cmd>Neotree focus buffers toggle reveal<cr>", "Explore buffers")

-- Telescope
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", "Find file")
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", "Find text")
map("n", "<leader>fb", "<cmd>Telescope buffers previewer=false<cr>", "Find buffer")
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", "Find help tag")
map("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", "Find recent file")

-- Buffer navigation
map("n", "<S-Tab>", "<cmd>BufferLineCycleNext<cr>")

-- Code actions
--map("n", "<leader>cf", "<cmd>lua vim.lsp.buf.format()<cr>", "Code format")
map("n", "<leader>cf", "<cmd>LspFormat<cr>", "Code format")
map({ "n", "v" }, "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<cr>", "Code action")
map("v", "a", "<cmd>lua vim.lsp.buf.code_action()<cr>", "Code action")
map("n", "<leader>cr", "<cmd>lua vim.lsp.buf.rename()<cr>", "Code rename")
map("n", "<leader>ct", "<cmd>TroubleToggle<cr>", "Code trouble") -- TOdo improve

-- Test
map("n", "<leader>tf", "<cmd>TestFile<cr>", "Test File")

-- Code navigation
map({ "n", "i" }, "<C-a>", "<Home>") -- Ctrl-a to beginning of line
map({ "n", "i" }, "<C-e>", "<End>") -- Ctrl-e to end of line
--map({ 'n' }, '<C-[>', '<Nop>') -- Unmap default Ctrl-[
map({ "n" }, "gb", "<C-o>", "Go back") -- Previous edit location
map({ "n" }, "gf", "<C-i>", "Go forward") -- Next edit location

--vmap <LeftRelease> "*ygv
map("v", "<LeftRelease>", '"*ygv') -- Copy contents of mouse selection to clipboard on mouse switch release

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o> / <C-Space>
    --vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc

    local function buf_lsp_format()
      lsp_format(ev.buf)
    end
    vim.api.nvim_buf_create_user_command(ev.buf, "LspFormat", buf_lsp_format, {})
    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }
    map("n", "gD", vim.lsp.buf.declaration, "Go to declaration", opts)
    map("n", "gd", "<cmd>Telescope lsp_definitions<cr>", "Go to definition", opts)
    map("n", "gr", "<cmd>Telescope lsp_references<cr>", "Show references", opts)
    map("n", "gi", "<cmd>Telescope lsp_implementations<cr>", "Show implementations", opts)

    --vim.keymap.set({ "n", "i" }, "<C-p>", vim.lsp.buf.hover, opts)
    map({ "n", "i" }, "<C-p>", vim.lsp.buf.hover, "Info popup", opts)
    --map({'n','i'}, '<C-p>', '<cmd>lua vim.lsp.buf.hover()<cr>', 'Info popup')

    --vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    --vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    --vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
    map("n", "<C-k>", vim.lsp.buf.signature_help, "Signature help", opts)
    --vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
    --vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
    --vim.keymap.set('n', '<space>wl', function()
    --  print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    --end, opts)
    --vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
    --vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
    --vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
    --vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    --vim.keymap.set('n', '<space>f', function()
    --  vim.lsp.buf.format { async = true }
    --end, opts)
  end,
})
