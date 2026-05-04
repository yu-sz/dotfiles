{ pkgs, ... }:
{
  home.packages = with pkgs; [
    btop
    cmatrix
    cowsay
    fd
    gitmux
    gomi
    hyperfine
    jq
    lolcat
    oha
    ripgrep
    sheldon
    smug
    termdown
    wezterm
    zabrze
    zsh
  ];
}
