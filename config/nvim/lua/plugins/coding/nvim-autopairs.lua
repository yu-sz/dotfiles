-- autopair sorrounding charas
return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = true,
  opts = {
    check_ts = true,
    ts_config = {
      lua = { "string" },
      javasctipt = { "template_string" },
      java = false,
    },
    disabled_filetype = {
      "TelescopePrompt",
    },
  },
}
