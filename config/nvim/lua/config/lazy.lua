local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
-- vim.loop is deprecated
if not (vim.loop or vim.uv).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "plugins.coding" },
    { import = "plugins.colorschema" },
    { import = "plugins.comp" },
    { import = "plugins.editor" },
    { import = "plugins.git" },
    { import = "plugins.lsp" },
    { import = "plugins.markdown" },
    { import = "plugins.treesitter" },
    { import = "plugins.ui" },
    { import = "plugins.util" }
  },
  default = {
    lazy = false,
    version = false,
  },
  checker = { enabled = true },
  performance = {
    cache = {
      enable = true,
    },
    --    rtp = {
    --      desabled_plagins = {
    --        -- "gzip",
    --      },
    --    }
  },
  debag = false,
})
