{ pkgs, lib, ... }:
lib.mkIf pkgs.stdenv.isDarwin {
  home.packages = with pkgs; [
    ghostty-bin
    terminal-notifier
    macism
    darwin.trash
  ];
}
