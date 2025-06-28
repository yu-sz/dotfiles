-- display signature
return {
  "ray-x/lsp_signature.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    hint_enable = true,
    toggle_key = "<C-p>",
  },
}
