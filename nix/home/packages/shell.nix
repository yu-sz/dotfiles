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
    gomi
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
