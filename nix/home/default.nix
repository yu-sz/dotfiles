{ pkgs, ... }:
{
  imports = [
    ./shell.nix
    ./symlinks.nix
    ./darwin.nix
    ./programs
  ];

  xdg.enable = true;

  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    # base
    neovim
    vim
    tmux

    # shell tools
    ripgrep
    fd
    gomi
    hyperfine
    zabrze

    # views
    gitmux

    # tui
    lazydocker

    # cli
    awscli2
    ghq
    jq
    pgcli
    google-cloud-sdk
    ssm-session-manager-plugin

    # dev
    hadolint
    nixd
    shellcheck
    luarocks
    postgresql
    sqldiff

    # package managers
    mise
    sheldon
    tenv

    # editor
    claude-code
  ];

  programs.home-manager.enable = true;
}
