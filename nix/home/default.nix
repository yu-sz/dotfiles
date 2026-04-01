{ pkgs, ... }:
{
  imports = [
    ./shell.nix
    ./symlinks.nix
    ./darwin.nix
    ./programs
  ];

  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    # base
    git
    neovim
    vim
    tmux

    # shell tools
    ripgrep
    fd
    gomi
    zoxide
    zabrze
    fzf

    # views
    starship
    gitmux

    # tui
    lazygit
    lazydocker
    yazi

    # yazi dependencies
    ffmpeg
    poppler-utils
    imagemagick
    resvg
    _7zz

    # cli
    awscli2
    gh
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
