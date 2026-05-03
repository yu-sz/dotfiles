{ pkgs, ... }:
{
  home.packages = with pkgs; [
    btop
    fd
    gitmux
    gomi
    hyperfine
    jq
    ripgrep
    sheldon
    smug
    wezterm
    zabrze
    zsh
  ];
}
