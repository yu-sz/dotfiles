-- manage session
return {
  "rmagatti/auto-session",
  event = "VimEnter",
  keys = {
    -- Will use Telescope if installed or a vim.ui.select picker otherwise
    { "<leader>wr", "<cmd>SessionRestore<CR>" },
    { "<leader>ws", "<cmd>SessionSave<CR>" },
    { "<leader>wa", "<cmd>SessionToggleAutoSave<CR>" },
  },
  ---enables autocomplete for opts
  ---@module "auto-session"
  ---@type AutoSession.Config
  opts = {
    auto_restore = false,
    suppressed_dirs = { "~/", "~/Dev", "~/Downloads", "~/Documents", "~/Desktop" },
  },
}
