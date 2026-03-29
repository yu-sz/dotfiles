local flake_path = vim.fn.expand("~/Projects/dotfiles")
local config_name = "suta-ro"

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
