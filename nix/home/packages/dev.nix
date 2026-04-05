{ pkgs, ... }:
{
  home.packages = with pkgs; [
    tree-sitter
    hadolint
    mkcert
    luarocks
    postgresql
    sqldiff
  ];
}
