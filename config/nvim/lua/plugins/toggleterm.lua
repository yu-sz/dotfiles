-- tarminal
-- float形式のターミナルはToggle操作したいためグローバル管理
local float_term
local right_term
local bottom_terms = {}

return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({})
  end,
  keys = {
    -- tools
    {
      "<leader>lg",
      function()
        local Terminal = require("toggleterm.terminal").Terminal
        local lazygit = Terminal:new({
          cmd = "lazygit",
          direction = "float",
          hidden = true,
        })
        lazygit:toggle()
      end,
      desc = "open lazygit",
    },

    -- floot
    {
      "<leader>tf",
      function()
        if not float_term then
          local Terminal = require("toggleterm.terminal").Terminal
          float_term = Terminal:new({
            direction = "float",
            hidden = true,
          })
        end
        float_term:toggle()
      end,
      mode = { "n", "t" },
      desc = "float",
    },

    -- right
    {
      "<leader>tr",
      function()
        if not right_term then
          local Terminal = require("toggleterm.terminal").Terminal
          right_term = Terminal:new({
            direction = "vertical",
            hidden = true,
          })
        end
        right_term:toggle()
      end,
      mode = { "n", "t" },
      desc = "Toggle Right Side Terminal",
    },

    -- bottom
    {
      "<leader>ttb",
      function()
        if #bottom_terms == 0 then
          local Terminal = require("toggleterm.terminal").Terminal
          local new_term = Terminal:new({
            direction = "horizontal",
            hidden = true,
          })
          table.insert(bottom_terms, new_term)
          new_term:toggle()
        else
          for _, term in ipairs(bottom_terms) do
            term:toggle()
          end
        end
      end,
      mode = { "n", "t" },
      desc = "Smart Toggle Right Terminals",
    },
    {
      "<leader>tab",
      function()
        local Terminal = require("toggleterm.terminal").Terminal
        local new_term = Terminal:new({
          direction = "horizontal",
          hidden = true,
        })
        table.insert(bottom_terms, new_term)
        new_term:toggle()
      end,
      mode = { "n", "t" },
      desc = "Add New Right Terminal",
    },
  },
}
