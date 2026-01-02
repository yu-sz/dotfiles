-- markdown preview on browser
return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  ft = { "markdown" },
  build = function()
    vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/lazy/markdown-preview.nvim")
    vim.fn["mkdp#util#install"]()
  end,
  keys = {
    { "<leader>mp", ":MarkdownPreviewToggle<CR>", { silent = true, desc = "toggle markdown preview" } },
  },
}
