-- tarminal
-- float形式のターミナルはToggle操作したいためグローバル管理
local float_term

return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({})
  end,
  keys = {
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
    {
      "<leader>ld",
      function()
        local Terminal = require("toggleterm.terminal").Terminal
        local lazygit = Terminal:new({
          cmd = "lazydocker",
          direction = "float",
          hidden = true,
        })
        lazygit:toggle()
      end,
      desc = "open lazydocker",
    },
    {
      "<leader>@",
      function()
        local Terminal = require("toggleterm.terminal").Terminal
        local term1 = Terminal:new({
          direction = "horizontal",
          hidden = true,
        })
        local term2 = Terminal:new({
          direction = "horizontal",
          hidden = true,
        })
        term1:toggle()
        term2:toggle()
      end,
      desc = "horizontal dual view",
    },
    {
      "<C-t>",
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
  },
}
