-- dotfiles flake のパス (.zshenv の DOTFILES_DIR を参照)
local flake_path = vim.env.DOTFILES_DIR or vim.fn.expand("~/Projects/dotfiles")
-- flake.nix の darwinConfigurations キー (= scutil --get LocalHostName)
local config_name = vim.fn.hostname():gsub("%.local$", "")

---@type vim.lsp.Config
return {
  settings = {
    nixd = {
      nixpkgs = {
        expr = 'import (builtins.getFlake "' .. flake_path .. '").inputs.nixpkgs { }',
      },
      formatting = {
        command = { "nixfmt" },
      },
      options = {
        nix_darwin = {
          expr = '(builtins.getFlake "' .. flake_path .. '").darwinConfigurations."' .. config_name .. '".options',
        },
        home_manager = {
          expr = '(builtins.getFlake "'
            .. flake_path
            .. '").darwinConfigurations."'
            .. config_name
            .. '".options.home-manager.users.type.getSubOptions []',
        },
      },
    },
  },
}
