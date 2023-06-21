local function close_neo_tree()
  require("neo-tree.sources.manager").close_all()
end

local function open_neo_tree()
  require("neo-tree.sources.manager").show("filesystem")
end

return {
  "rmagatti/auto-session",
  lazy = false,
  enabled = true,
  config = function()
    require("auto-session").setup({
      bypass_session_save_file_types = {
        "neo-tree",
        "tsplayground",
        "query",
      },
      pre_save_cmds = {
        close_neo_tree,
      },
      post_restore_cmds = {
        open_neo_tree,
      },
    })
  end,
}
