-- Show code context at the top of the window
return {
  "nvim-treesitter/nvim-treesitter-context",
  dependencies = "nvim-treesitter/nvim-treesitter",
  event = "VeryLazy",
  enabled = true,
  opts = { mode = "cursor", max_lines = 3 },
}
