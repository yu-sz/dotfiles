{ pkgs, lib, ... }:
lib.mkIf pkgs.stdenv.isLinux {
  targets.genericLinux.enable = lib.mkDefault true;

  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    # GUI
    code-cursor

    # Fonts
    hackgen-font
    hackgen-nf-font
    plemoljp
    plemoljp-nf
    plemoljp-hs
    moralerspace
    moralerspace-hw
  ];
}
