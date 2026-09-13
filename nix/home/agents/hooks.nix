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
  # 3 エージェント共通の hook スクリプト。配線（イベント名・matcher）は各エージェントの base に書く
  home.file.".agents/hooks".source = mkLink "config/agents/hooks";
}
