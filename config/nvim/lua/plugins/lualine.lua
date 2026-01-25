-- status line
return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = {
    options = {
      theme = "tokyonight",
      globalstatus = false,
    },
    sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {},
      lualine_x = { "diagnostics" },
      lualine_y = { "filetype" },
      lualine_z = { { "filename", file_status = true, path = 3 } },
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = { "encoding", "fileformat", "filetype" },
      lualine_z = { { "filename", file_status = true, path = 3 } },
    },
  },
}
