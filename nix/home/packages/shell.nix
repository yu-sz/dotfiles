{ pkgs, ... }:
{
  home.packages = with pkgs; [
    btop
    cmatrix
    cowsay
    fd
    gomi
    hyperfine
    jq
    lolcat
    oha
    ripgrep
    sheldon
    termdown
    zabrze
    zsh
  ];
}
