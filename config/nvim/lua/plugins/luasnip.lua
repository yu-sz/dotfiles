-- extends snipet
return {
  "L3MON4D3/LuaSnip",
  lazy = true,
  config = function()
    require("luasnip").setup({})
    require("luasnip.loaders.from_lua").lazy_load()
    require("luasnip.loaders.from_vscode").lazy_load()
  end,
}
