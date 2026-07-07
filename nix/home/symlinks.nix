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
    "gomi".source = mkLink "config/gomi";
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
  }
  // lib.optionalAttrs pkgs.stdenv.isDarwin {
    "karabiner".source = mkLink "config/karabiner";
    "aerospace".source = mkLink "config/aerospace";
  };

  home.file = {
    ".claude/CLAUDE.md".source = mkLink "config/claude/CLAUDE.md";
    ".claude/agents".source = mkLink "config/claude/agents";
    ".claude/commands".source = mkLink "config/claude/commands";
    ".claude/file-suggestion.sh".source = mkLink "config/claude/file-suggestion.sh";
    ".claude/hooks".source = mkLink "config/claude/hooks";
    ".claude/keybindings.json".source = mkLink "config/claude/keybindings.json";
    ".claude/mcp".source = mkLink "config/claude/mcp";
    ".claude/rules".source = mkLink "config/claude/rules";
    ".claude/settings.json".source = mkLink "config/claude/settings.json";
    ".claude/skills".source = mkLink "config/claude/skills";
    ".claude/statusline.sh".source = mkLink "config/claude/statusline.sh";
    ".zshenv".source = mkLink "config/zsh/.zshenv";
  };
}
