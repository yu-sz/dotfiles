return {
  "sindrets/diffview.nvim",
  keys = {
    {
      "<leader>df",
      function()
        if next(require("diffview.lib").views) == nil then
          vim.cmd("DiffviewOpen")
        else
          vim.cmd("DiffviewClose")
        end
      end,
      silent = true,
      mode = "n",
      desc = "Toggle Diff View",
    },
    {
      "<leader>hf",
      function()
        if next(require("diffview.lib").views) == nil then
          vim.cmd("DiffviewFileHistory")
        else
          vim.cmd("DiffviewClose")
        end
      end,
      silent = true,
      mode = "n",
      desc = "Toggle Git File History",
    },
    {
      "<leader>dp",
      function()
        local open_pull_request_diffview = function()
          local handle = io.popen("gh pr view --json baseRefName --jq .baseRefName")
          if not handle then
            vim.notify("PR情報の取得に失敗しました", vim.log.levels.ERROR)
            return
          end
          local base_branch = handle:read("*a"):gsub("%s+", "")
          handle:close()

          if base_branch ~= "" then
            vim.cmd("DiffviewOpen origin/" .. base_branch .. "...HEAD")
            vim.notify("Opening Diffview against: origin/" .. base_branch .. "...HEAD")
          else
            vim.notify("PR情報が見つかりません", vim.log.levels.WARN)
          end
        end

        if next(require("diffview.lib").views) == nil then
          open_pull_request_diffview()
        else
          vim.cmd("DiffviewClose")
        end
      end,
    },
  },
  opts = {
    keymaps = {
      view = {
        ["<tab>"] = false,
        ["<s-tab>"] = false,
      },
      file_panel = {
        ["<tab>"] = false,
        ["<s-tab>"] = false,
        ["s"] = false,
      },
    },
  },
}
