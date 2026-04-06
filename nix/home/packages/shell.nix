{ pkgs, ... }:
{
  home.packages = with pkgs; [
    fd
    gitmux
    gomi
    hyperfine
    jq
    ripgrep
    sheldon
    zabrze
  ];
}
