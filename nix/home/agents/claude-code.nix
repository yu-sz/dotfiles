{
  config,
  dotfilesRelPath,
  ...
}:
let
  dotfiles = "${config.home.homeDirectory}/${dotfilesRelPath}";
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  # skills の per-skill symlink は skills.nix が担当する。ここは静的ファイルのみ
  home.file = {
    ".claude/CLAUDE.md".source = mkLink "config/claude/CLAUDE.md";
    ".claude/agents".source = mkLink "config/claude/agents";
    ".claude/hooks".source = mkLink "config/claude/hooks";
    ".claude/keybindings.json".source = mkLink "config/claude/keybindings.json";
    ".claude/file-suggestion.sh".source = mkLink "config/claude/file-suggestion.sh";
    ".claude/statusline.sh".source = mkLink "config/claude/statusline.sh";
  };
}
