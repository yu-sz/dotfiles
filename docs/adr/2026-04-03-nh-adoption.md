# nh（nix helper）導入

Date: 2026-04-03
Status: Accepted

## Context

日常の `darwin-rebuild switch` はビルド出力が冗長で、何が変わったのか把握しづらい。`nix-collect-garbage -d` は全世代削除で粒度が粗い。

[nh](https://github.com/viperML/nh) は Rust 製の Nix ヘルパー CLI で、switch 時のパッケージ差分表示・nom によるビルドログ整形・世代数ベースの GC を提供する。nixpkgs に収録済みで、NixOS/nix-darwin ユーザーの間で急速に普及している（GitHub Stars ~1,200）。

## Decision

### nh を導入し、darwin-rebuild / nix-collect-garbage を置き換える

| 観点                | darwin-rebuild（現状）                 | nh darwin                                    |
| ------------------- | -------------------------------------- | -------------------------------------------- |
| switch 時の差分表示 | **なし**                               | **nvd で変更パッケージを一覧**               |
| ビルドログ          | 生の Nix 出力                          | **nom で整形**（進捗バー、並列ビルド可視化） |
| sudo 処理           | 手動で `sudo` 付与                     | **自動で必要時に sudo**                      |
| flake 検出          | `--flake .` 必須                       | **カレントディレクトリ自動検出**             |
| GC                  | `nix-collect-garbage -d`（全世代削除） | **`nh clean all --keep N`**（世代数ベース）  |

- nh は darwin-rebuild / home-manager / nixos-rebuild のラッパー。失敗時は直接コマンドにフォールバック可能
- nixpkgs に `pkgs.nh` として収録済み。[NixOS Wiki](https://wiki.nixos.org/wiki/Nh) でも紹介されている
- nix-output-monitor（nom）を内包しており、別途インストール不要

### エイリアスと Justfile の方針

既存の `drs` エイリアスと `just switch` を**両方残し、中身を nh に統一**する。

```
drs エイリアス → nh darwin switch ~/Projects/dotfiles  (どこからでも)
just switch   → nh darwin switch .                     (dotfiles 内)
ngc エイリアス → nh clean all --keep 5
just clean    → nh clean all --keep 5
```

- `drs` はシェルのどこからでも使える汎用エイリアスとして有用（[ADR: 開発ワークフロー](./2026-03-30-dev-workflow.md) で共存を確認済み）
- `just switch` は CI やドキュメントで参照されるインターフェースとして維持
- `ngc` も nh の `clean` に統一し、世代数ベースの管理に移行

### 比較候補

| 観点           | nh                   | nix-output-monitor 単体 | 素の darwin-rebuild |
| -------------- | -------------------- | ----------------------- | ------------------- |
| switch 差分    | **あり**             | なし                    | なし                |
| ビルドログ整形 | **あり（nom 内包）** | **あり**                | なし                |
| GC 改善        | **あり**             | なし                    | なし                |
| メンテナンス   | 活発（Rust）         | 活発（Haskell）         | Nix 本体            |

- nom 単体は `darwin-rebuild switch |& nom` で使えるが、差分表示と GC 改善がない
- nh は nom を内包しつつ、差分表示と GC を統合した上位互換

## Consequences

- `just switch` / `drs` で switch 時にパッケージの追加・削除・バージョン変更が一覧表示され、変更内容が一目で把握できる
- ビルドログが整形され、並列ビルドの進捗が見やすくなる
- `just clean` / `ngc` で世代数ベースの GC になり、「直近 5 世代は残す」という安全な運用が可能
- `home.packages` に `pkgs.nh` が追加される（devShell ではなくユーザーパッケージ。どこからでも使えるようにするため）
