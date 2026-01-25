-- expand increment/decrement
return {
  "monaqa/dial.nvim",
  opts = {},
  config = function()
    local augend = require("dial.augend")
    require("dial.config").augends:register_group({
      default = {
        augend.integer.alias.decimal,
        augend.integer.alias.hex,
        augend.date.alias["%Y/%m/%d"],
        augend.constant.alias.bool,
        augend.semver.alias.semver,
        augend.case.new({
          types = { "camelCase", "snake_case", "kebab-case", "PascalCase", "SCREAMING_SNAKE_CASE" },
          cyclic = true,
        }),
        augend.constant.new({ elements = { "let", "const" } }),
      },
    })
    require("dial.config").augends:on_filetype({
      markdown = {
        augend.integer.alias.decimal,
        augend.constant.new({
          elements = { "[ ]", "[x]" },
          word = false,
          cyclic = true,
        }),
      },
    })
  end,
  keys = {
    {
      "<C-a>",
      function()
        return require("dial.map").inc_normal()
      end,
      expr = true,
      desc = "Increment",
    },
    {
      "<C-x>",
      function()
        return require("dial.map").dec_normal()
      end,
      expr = true,
      desc = "Decrement",
    },
  },
}
