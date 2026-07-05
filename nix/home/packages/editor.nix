{ pkgs, ... }:
{
  home.packages = with pkgs; [
    claude-code
    herdr
    luarocks
    neovim
    tree-sitter
    vim
    vscode
  ];
}
