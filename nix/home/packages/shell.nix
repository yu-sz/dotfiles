{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    btop
    cmatrix
    cowsay
    eza
    fd
    fzf
    hyperfine
    jq
    lolcat
    oha
    ripgrep
    sheldon
    starship
    termdown
    zabrze
    zoxide
    zsh
  ];
}
