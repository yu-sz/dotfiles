{ pkgs, ... }:
{
  home.packages = with pkgs; [
    claude-code
    luarocks
    neovim
    tmux
    tree-sitter
    vim
  ];
}
