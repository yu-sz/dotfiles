{ config, dotfilesRelPath, ... }:
{
  programs.nh = {
    enable = true;
    flake = "${config.home.homeDirectory}/${dotfilesRelPath}";
  };
}
