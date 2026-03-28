{ pkgs, lib, username, ... }:
{
  imports = [
    ./shell.nix
    ./symlinks.nix
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    ./darwin.nix
  ];

  home.username = username;
  home.homeDirectory =
    if pkgs.stdenv.isDarwin then "/Users/${username}"
    else "/home/${username}";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    # base
    git
    neovim
    vim
    tmux

    # shell tools
    ripgrep
    bat
    eza
    fd
    gomi
    zoxide
    fzf

    # views
    starship
    delta
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
    shellcheck
    luarocks
    libpq
    sqlite
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
