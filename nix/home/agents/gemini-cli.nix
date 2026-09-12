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
  # settings.json は agents-sync が実ファイルとして生成する
  home.file.".gemini/AGENTS.md".source = mkLink "config/agents/AGENTS.md";
}
