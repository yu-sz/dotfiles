{ pkgs, ... }:
{
  home.packages = with pkgs; [
    luarocks
    neovim
    tree-sitter
    vim
    vscode
  ];
}
