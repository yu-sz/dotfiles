{
  config,
  lib,
  pkgs,
  dotfilesRelPath,
  ...
}:
lib.mkIf pkgs.stdenv.isDarwin {
  programs.sketchybar = {
    enable = true;

    configType = "lua";
    sbarLuaPackage = pkgs.sbarlua;

    # HM の launchd agent は default PATH = /usr/bin:/bin:/usr/sbin:/sbin のみのため、
    # sbar.exec で aerospace / jq を呼ぶには wrapper の PATH に bin を追加する必要がある。
    extraPackages = [
      pkgs.aerospace
      pkgs.jq
    ];

    config = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${dotfilesRelPath}/config/sketchybar";
      recursive = true;
    };
  };
}
