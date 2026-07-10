-- blankline
return {
  "shellRaining/hlchunk.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    chunk = {
      enable = true,
      style = "#806d9c",
      use_treesitter = true,
      duration = 100,
      delay = 50,
    },
    indent = {
      enable = true,
      chars = {
        "┆",
      },
    },
    line_num = {
      enable = true,
      use_treesitter = true,
    },
    blank = {
      enable = false,
      chars = {
        " ",
      },
      style = {
        { bg = "#434437" },
        { bg = "#2f4440" },
        { bg = "#433054" },
        { bg = "#284251" },
      },
    },
  },
}
