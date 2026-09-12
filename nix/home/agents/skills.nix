# ローカル skills（dotfiles、即時編集）と外部 skills（flake input、flake.lock で pin）を
# skill 単位で ~/.agents/skills（Codex / Gemini）と ~/.claude/skills（Claude）へ symlink する。
# ~/.agents/skills を Codex / Gemini が共有するため per-agent の絞り込みは構造的に不可能。
# ここに置く skill は 3 エージェント共通が前提で、特定エージェント専用は marketplace / extensions に置く
{
  config,
  inputs,
  lib,
  pkgs,
  dotfilesRelPath,
  ...
}:
let
  dotfiles = "${config.home.homeDirectory}/${dotfilesRelPath}";
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";

  # ローカル: flake は Git 追跡ファイルしか見えないので、新規 skill は git add + nrs が必要
  local = lib.mapAttrs (name: _: { src = mkLink "config/agents/skills/${name}"; }) (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../../../config/agents/skills)
  );

  # 外部: src は store パス（リポジトリ内の subdir を指す）。packages は skill のスクリプトが要する実行環境
  external = {
    natural-japanese = {
      src = "${inputs.natural-japanese}/skills/natural-japanese";
      packages = [ pkgs.uv ]; # scripts/*.py は uv run で依存を自己解決する
    };
  };

  # 同名はビルド時に検出する（silent drift の名前衝突を実行時に持ち込まない）
  skills = lib.attrsets.unionOfDisjoint local external;

  linksInto = dir: lib.concatMapAttrs (name: s: { "${dir}/${name}".source = s.src; }) skills;
in
{
  home.file = linksInto ".agents/skills" // linksInto ".claude/skills";

  home.packages = lib.concatMap (s: s.packages or [ ]) (builtins.attrValues skills);
}
