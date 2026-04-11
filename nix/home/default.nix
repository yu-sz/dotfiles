{ ... }:
{
  imports = [
    ./shell.nix
    ./symlinks.nix
    ./darwin.nix
    ./linux.nix
    ./programs
    ./packages
  ];

  xdg.enable = true;

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
