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

    config = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${dotfilesRelPath}/config/sketchybar";
      recursive = true;
    };
  };
}
