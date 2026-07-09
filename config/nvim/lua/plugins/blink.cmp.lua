-- complations
return {
  "saghen/blink.cmp",
  version = "*",
  event = { "InsertEnter", "CmdLineEnter" },
  dependencies = {
    "L3MON4D3/LuaSnip",
  },
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = { preset = "enter" },
    appearance = {
      nerd_font_variant = "mono",
    },
    completion = { documentation = { auto_show = true } },
    sources = {
      default = { "snippets", "lsp", "path", "buffer", "dictionary" },
      providers = {
        dictionary = {
          module = "blink-cmp-dictionary",
          name = "Dict",
          min_keyword_length = 3,
          opts = {
            dictionary_files = { "/usr/share/dict/words" },
          },
        },
      },
    },
    snippets = {
      preset = "luasnip",
    },
    fuzzy = {
      -- versionを指定してないとバイナリが特定できずLuaにfallbackするwarningが表示される
      implementation = "prefer_rust_with_warning",
    },
  },
  opts_extend = { "sources.default" },
}
