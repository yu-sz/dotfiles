-- scrollbar
return {
  "petertriho/nvim-scrollbar",
  event = {
    "BufWinEnter",
    "CmdwinLeave",
    "TabEnter",
    "TermEnter",
    "TextChanged",
    "VimResized",
    "WinEnter",
    "WinScrolled",
  },
  config = function(_, opts)
    local colors = require("tokyonight.colors").setup()
    local scrollbar = require("scrollbar")

    opts.handle = {
      color = "gray",
    }
    opts.marks = {
      Search = { color = colors.orange },
      Error = { color = colors.error },
      Warn = { color = colors.warning },
      Info = { color = colors.info },
      Hint = { color = colors.hint },
      Misc = { color = colors.purple },
    }
    scrollbar.setup(opts)
  end,
}
