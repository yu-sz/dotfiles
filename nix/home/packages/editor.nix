{ pkgs, ... }:
{
  home.packages = with pkgs; [
    claude-code
    luarocks
    neovim
    tree-sitter
    vim
    vscode
  ];
}
