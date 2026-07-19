-- ai integration
return {
  "folke/sidekick.nvim",
  ---@type sidekick.Config
  opts = {
    nes = { enabled = false },
    cli = {
      mux = {
        enabled = false,
        -- TODO: sidekick.nvim#333 マージ後に "herdr" へ切替（tmux は撤去済みで未使用）
        backend = "tmux",
      },
      ---@type sidekick.win.Opts
      win = {
        layout = "right",
        ---@type vim.api.keyset.win_config
        split = {
          width = math.floor(vim.o.columns * 0.4),
          height = 20,
        },
      },
      tools = {
        claude = {
          -- 外出ししているmcp設定ファイルを読み込ませる
          cmd = { "claude", "--mcp-config", vim.fn.expand("$HOME/.claude/mcp/.mcp.json") },
        },
      },
    },
  },
  keys = {
    {
      "<c-.>",
      function()
        require("sidekick.cli").toggle()
      end,
      desc = "Sidekick Toggle",
      mode = { "n", "t", "i", "x" },
    },
    {
      "<leader>aa",
      function()
        require("sidekick.cli").toggle()
      end,
      desc = "Sidekick Toggle CLI",
    },
    {
      "<leader>as",
      function()
        require("sidekick.cli").select()
      end,
      desc = "Select CLI",
    },
    {
      "<leader>ad",
      function()
        require("sidekick.cli").close()
      end,
      desc = "Detach a CLI Session",
    },
    {
      "<leader>at",
      function()
        require("sidekick.cli").send({ msg = "{this}" })
      end,
      mode = { "x", "n" },
      desc = "Send This",
    },
    {
      "<leader>af",
      function()
        require("sidekick.cli").send({ msg = "{file}" })
      end,
      desc = "Send File",
    },
    {
      "<leader>av",
      function()
        require("sidekick.cli").send({ msg = "{selection}" })
      end,
      mode = { "x" },
      desc = "Send Visual Selection",
    },
    {
      "<leader>ap",
      function()
        require("sidekick.cli").prompt()
      end,
      mode = { "n", "x" },
      desc = "Sidekick Select Prompt",
    },
    -- Example of a keybinding to open Claude directly
    {
      "<leader>ac",
      function()
        require("sidekick.cli").toggle({ name = "claude", focus = true })
      end,
      desc = "Sidekick Toggle Claude",
    },
  },
}
