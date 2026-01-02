-- blankline
return {
  "shellRaining/hlchunk.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("hlchunk").setup({
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
      -- If you want to recreate the indent rainbow, uncomment the lines.
      --   style = {
      --     "#FF0000",
      --     "#FF7F00",
      --     "#FFFF00",
      --     "#00FF00",
      --     "#00FFFF",
      --     "#0000FF",
      --     "#8B00FF",
      --   },
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
    })
  end,
}
