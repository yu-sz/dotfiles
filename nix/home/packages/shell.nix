{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ripgrep
    fd
    gomi
    hyperfine
    zabrze
  ];
}
