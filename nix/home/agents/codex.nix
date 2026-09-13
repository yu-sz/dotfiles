{
  config,
  dotfilesRelPath,
  ...
}:
let
  mkLink =
    path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${dotfilesRelPath}/${path}";
in
{
  # config.toml は agents-sync が実ファイルとして生成する（Codex は symlink を実ファイルに置換するため）
  home.file = {
    ".codex/AGENTS.md".source = mkLink "config/agents/AGENTS.md";
    # execpolicy rules（コマンド単位の allow / prompt / forbidden）。起動時に ~/.codex/rules/*.rules を読む
    ".codex/rules".source = mkLink "config/codex/rules";
  };
}
