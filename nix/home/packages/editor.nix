{ pkgs, ... }:
{
  home.packages = with pkgs; [
    claude-code
    herdr
    luarocks
    neovim
    tmux
    tree-sitter
    vim
    vscode
  ];
}
