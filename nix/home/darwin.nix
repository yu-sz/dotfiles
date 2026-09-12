{ pkgs, lib, ... }:
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.packages = with pkgs; [
    ghostty-bin
    terminal-notifier
    macism
    darwin.trash
  ];
}
