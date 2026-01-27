-- toolset (fuzzy finder / dashboard / gh)

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

  keys = {
    {
      "<Space>q",
      function()
        Snacks.bufdelete()
      end,
      silent = true,
    },

    -- picker
    {
      "<leader>ff",
      function()
        project_files(false)
      end,
      mode = { "n", "x" },
      silent = true,
      desc = "Find Files (モノレポの各ディレクトリ毎)",
    },
    {
      "<leader>fF",
      function()
        project_files(true)
      end,
      silent = true,
      mode = { "n", "x" },
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
      mode = { "n", "x" },
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

    -- gh
    {
      "<leader>gi",
      function()
        Snacks.picker.gh_issue()
      end,
      desc = "GitHub Issues (open)",
    },
    {
      "<leader>gI",
      function()
        Snacks.picker.gh_issue({ state = "all" })
      end,
      desc = "GitHub Issues (all)",
    },
    {
      "<leader>gp",
      function()
        Snacks.picker.gh_pr()
      end,
      desc = "GitHub Pull Requests (open)",
    },
    {
      "<leader>gP",
      function()
        Snacks.picker.gh_pr({ state = "all" })
      end,
      desc = "GitHub Pull Requests (all)",
    },

    -- file explorer
    {
      "<leader>fe",
      function()
        Snacks.explorer()
      end,
      silent = true,
      desc = "Open File Explorer",
    },

    -- smart file searvh
    {
      "<leader><leader>",
      function()
        local root = require("snacks.git").get_root()
        local sources = require("snacks.picker.config.sources")

        local files = root == nil and sources.files
          or vim.tbl_deep_extend("force", sources.git_files, {
            untracked = true,
            cwd = vim.uv.cwd(),
          })

        Snacks.picker({
          multi = { "buffers", "recent", files },
          format = "file",
          matcher = { frecency = true, sort_empty = true },
          filter = { cwd = true },
          transform = "unique_file",
        })
      end,
      silent = true,
      desc = "Smart File Search",
    },
  },

  ---@type snacks.Config
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
          cycle = true,
          auto_close = true,
          layout = {
            { preview = true },
            layout = {
              box = "horizontal",
              width = 0.8,
              height = 0.8,
              {
                box = "vertical",
                border = "rounded",
                title = "{source} {live} {flags}",
                title_pos = "center",
                { win = "input", height = 1, border = "bottom" },
                { win = "list", border = "none" },
              },
              { win = "preview", border = "rounded", width = 0.6, title = "{preview}" },
            },
          },
        },
        files = {
          hidden = true,
          ignored = false,
        },
      },
    },
    explorer = { enabled = true },
    git = { enabled = true },
    gh = { enable = true },
    dashboard = {
      preset = {
        ---@type snacks.dashboard.Item[]
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "e", desc = "Open Explorer", action = ":lua Snacks.dashboard.pick('explorer')" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          {
            icon = " ",
            key = "c",
            desc = "Config",
            action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
          },
          { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
    },
  },
}
