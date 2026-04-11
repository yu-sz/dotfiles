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
    "nvim".source = mkLink "config/nvim";
    "tmux".source = mkLink "config/tmux";
    "gitmux".source = mkLink "config/gitmux";
    "gomi".source = mkLink "config/gomi";
    "lazydocker".source = mkLink "config/lazydocker";
    "zabrze".source = mkLink "config/zabrze";
    "vim".source = mkLink "config/vim";
    "mise".source = mkLink "config/mise";
    "zsh".source = mkLink "config/zsh";
    "wezterm".source = mkLink "config/wezterm";
  }
  // lib.optionalAttrs pkgs.stdenv.isDarwin {
    "karabiner".source = mkLink "config/karabiner";
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
