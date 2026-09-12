{
  config,
  lib,
  pkgs,
  dotfilesRelPath,
  ...
}:
let
  dotfilesPath = "${config.home.homeDirectory}/${dotfilesRelPath}";
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${path}";
in
{
  xdg.configFile = {
    "btop".source = mkLink "config/btop";
    "nvim".source = mkLink "config/nvim";
    "herdr".source = mkLink "config/herdr";
    "hunk".source = mkLink "config/hunk";
    "lazydocker".source = mkLink "config/lazydocker";
    "zabrze".source = mkLink "config/zabrze";
    "vim".source = mkLink "config/vim";
    "mise".source = mkLink "config/mise";
    "zsh".source = mkLink "config/zsh";
    "wezterm".source = mkLink "config/wezterm";
    "starship.toml".source = mkLink "config/starship/starship.toml";
    "bat".source = mkLink "config/bat";
    "git/config".source = mkLink "config/git/config";
    "git/ignore".source = mkLink "config/git/ignore";
    "gh/config.yml".source = mkLink "config/gh/config.yml";
    "lazygit/config.yml".source = mkLink "config/lazygit/config.yml";
    "ghostty".source = mkLink "config/ghostty";
    "yazi/yazi.toml".source = mkLink "config/yazi/yazi.toml";
    "yazi/theme.toml".source = mkLink "config/yazi/theme.toml";
    "yazi/init.lua".source = mkLink "config/yazi/init.lua";
    "agents".source = mkLink "config/agents";
  }
  // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    "karabiner".source = mkLink "config/karabiner";
    "aerospace".source = mkLink "config/aerospace";
  };

  home.file = {
    # .claude/* は nix/home/agents/ が管理する（静的 symlink は claude-code.nix、
    # settings.json は sync.nix の agents-sync が実ファイルとして生成）
    ".zshenv".source = mkLink "config/zsh/.zshenv";
  };
}
