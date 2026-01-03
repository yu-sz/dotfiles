-- toolset (fuzzy finder)

-- visual mode時に選択範囲を取得する
local function get_text()
  local visual = Snacks.picker.util.visual()
  return visual and visual.text or ""
end

-- monorepo / gitを考慮しつつファイル検索をする
---@param use_git_root boolean
local function project_files(use_git_root)
  local text = get_text()

  local root = require("snacks.git").get_root()
  if root == nil then
    Snacks.picker.files({ pattern = text })
    return
  end
  if use_git_root then
    Snacks.picker.git_files({
      untracked = true,
      pattern = text,
    })
  else
    Snacks.picker.git_files({
      untracked = true,
      pattern = text,
      cwd = vim.uv.cwd(),
    })
  end
end

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    picker = { enabled = true },
    explorer = { enabled = true },
    git = { enabled = true },
  },
  keys = {
    {
      "<Space>q",
      function()
        Snacks.bufdelete()
      end,
      silent = true,
    },

    {
      "<leader>ff",
      function()
        project_files(false)
      end,
      silent = true,
      desc = "Find Files (モノレポの各ディレクトリ毎)",
    },
    {
      "<leader>fF",
      function()
        project_files(true)
      end,
      silent = true,
      desc = "Find Files (モノレポでプロジェクト全体)",
    },
    {
      "<leader>fg",
      function()
        local text = get_text()
        Snacks.picker.grep({
          on_show = function()
            vim.api.nvim_put({ text }, "c", true, true)
          end,
        })
      end,
      silent = true,
      desc = "Live Grep (default grep)",
    },
    {
      "<leader>ls",
      function()
        Snacks.picker.buffers()
      end,
      silent = true,
      desc = "Open Current Buffers",
    },
    {
      "<leader>fl",
      function()
        Snacks.picker.lines()
      end,
      silent = true,
      desc = "Search Line In The Current Buffer",
    },

    {
      "<leader>fd",
      function()
        Snacks.picker.lsp_definitions()
      end,
      silent = true,
      desc = "View Lsp Definitions",
    },
    {
      "<leader>fqf",
      function()
        Snacks.picker.qflist()
      end,
      silent = true,
      desc = "Quick Fix List",
    },
    {
      "<leader>fk",
      function()
        Snacks.picker.keymaps()
      end,
      silent = true,
      desc = "find Keymaps",
    },

    {
      "<leader>fe",
      function()
        Snacks.explorer()
      end,
      silent = true,
      desc = "Open File Explorer",
    },
  },
}
