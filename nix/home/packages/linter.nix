{ pkgs, ... }:
{
  home.packages = with pkgs; [
    shellcheck
    luaPackages.luacheck
    markdownlint-cli
  ];
}
