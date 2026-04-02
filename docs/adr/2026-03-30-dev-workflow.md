# 開発ワークフロー（タスクランナー + Git Hooks）

Date: 2026-03-30
Status: Accepted

## Context

日常操作（switch, update, lint, clean）が散在し統一インターフェースがない。コミット前の品質チェックもなく、フォーマット崩れや lint 違反が混入しうる。

## Decision

### タスクランナー: Just を採用

| 観点                 | Just          | Makefile       | go-task       | nix run        |
| -------------------- | ------------- | -------------- | ------------- | -------------- |
| .PHONY 宣言          | 不要          | 全タスクに必要 | 不要          | N/A            |
| インデント           | スペース可    | **タブ必須**   | YAML          | N/A            |
| タスク一覧           | `just --list` | 標準機能なし   | `task --list` | なし           |
| Nix エコシステム採用 | **高い**      | 中             | **ほぼゼロ**  | ニッチ         |
| 起動速度             | 即時          | 即時           | 即時          | flake 評価あり |

- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/best-practices/simplify-nixos-related-commands) が明確に推奨。著者 ryan4yin が [nix-config](https://github.com/ryan4yin/nix-config/blob/main/Justfile) で 50+ レシピを運用
- Make はビルドシステム、Just はコマンドランナー（[公式](https://just.systems/man/en/)）。dotfiles の用途（switch, lint, clean）はコマンド実行であり、Just の設計意図に合致
- go-task は Nix コミュニティでの採用実績がほぼゼロ（GitHub 検索で `Taskfile.yml + nix + flake` = 0件）
- nix run（flake apps）は定義が冗長（1タスク 5-10行 vs Just 2-3行）で、起動に flake 評価コストがかかる

`just` は devShell に配置。dotfiles リポジトリ内でのみ使うため `home.packages` には入れない。

### Git Hooks: cachix/git-hooks.nix を採用

| 観点                           | cachix/git-hooks.nix | pre-commit.com                  | lefthook             |
| ------------------------------ | -------------------- | ------------------------------- | -------------------- |
| Stars                          | 792                  | 15,093                          | 7,869                |
| ランタイム依存                 | Nix のみ             | **Python 必須**                 | Go バイナリ          |
| `nix flake check` 統合         | **YES**              | NO                              | NO                   |
| `nix develop` 自動セットアップ | **YES**              | 手動                            | 手動                 |
| nixfmt/statix ビルトイン       | **YES**              | NO                              | NO                   |
| luacheck/stylua ビルトイン     | **YES**              | YES（独自 DL）                  | NO                   |
| バージョン管理                 | flake.lock 固定      | hook リポジトリ依存             | 自前                 |
| 設定の二重管理                 | なし                 | `.pre-commit-config.yaml` + Nix | `lefthook.yml` + Nix |

- `flake.lock` でバージョン固定、Nix の再現性と整合
- `nix develop` で自動セットアップ、`nix flake check` で CI と統一検証
- pre-commit: Python 依存、Nix と相性悪い
- lefthook: Nix 固有統合なし、設定二重管理
- Lua hooks も1行で追加可能（[ビルトイン hooks 一覧](https://github.com/cachix/git-hooks.nix#built-in-hooks)）

### Formatter: nixfmt-tree を採用

`nix fmt` の `formatter` output に `pkgs.nixfmt-tree` を使用する。

- `pkgs.nixfmt` 単体ではディレクトリ渡しが deprecated（[NixOS/nixfmt#273](https://github.com/NixOS/nixfmt/issues/273)）。`.gitignore` 非対応で `.direnv/` 等が対象になる
- `nixfmt-tree` は Nix Formatting Team 公式ラッパー（[nixpkgs PR #384857](https://github.com/NixOS/nixpkgs/pull/384857)）。treefmt + nixfmt を内包し `.gitignore` を自動尊重
- `treefmt-nix`（flake input 方式）は複数言語向け。Nix ファイルのみなら `nixfmt-tree` で十分

### Pre-commit（write）と CI（check）の棲み分け

git-hooks.nix の設計により、追加設定なしで自動的に棲み分けされる:

| 実行コンテキスト      | モード | 動作                                                 |
| --------------------- | ------ | ---------------------------------------------------- |
| ローカル `git commit` | write  | nixfmt がファイルを in-place 修正                    |
| CI `nix flake check`  | check  | Nix sandbox 内で読み取り専用。差分があればビルド失敗 |

## Consequences

- `nix develop` で自動的に pre-commit hooks が有効化。セットアップ手順ゼロ
- lint 違反（nixfmt, statix, deadnix, shellcheck）がコミット前に検出される
- 日常操作が `just switch`, `just update`, `just lint`, `just clean` で一元化。`just --list` で自己文書化
- 既存の `drs` エイリアスとは共存（`drs` は汎用エイリアス、`just switch` はリポジトリルート向け）
