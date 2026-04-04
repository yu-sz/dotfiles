{ config, dotfilesRelPath, ... }:
{
  programs.nh = {
    enable = true;
    darwinFlake = "${config.home.homeDirectory}/${dotfilesRelPath}";
  };
}
