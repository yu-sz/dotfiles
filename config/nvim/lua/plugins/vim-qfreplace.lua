-- perform the replacement in quickfix
return {
  "thinca/vim-qfreplace",
  keys = {
    { "<Leader>qr", "<cmd>Qfreplace<CR>", desc = "Quickfix Replace" },
  },
}
