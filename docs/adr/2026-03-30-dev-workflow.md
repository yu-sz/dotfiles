# 開発ワークフロー（タスクランナー + Git Hooks）

Date: 2026-03-30
Status: Accepted

## Context

日常操作（switch, update, lint, clean）が散在しており、統一的なインターフェースがない。コミット前の品質チェックもなく、フォーマット崩れや lint 違反が混入しうる。

## Decision

### タスクランナー: Just を採用

| 観点 | Just | Makefile | go-task | nix run |
|------|------|----------|---------|---------|
| .PHONY 宣言 | 不要 | 全タスクに必要 | 不要 | N/A |
| インデント | スペース可 | **タブ必須** | YAML | N/A |
| タスク一覧 | `just --list` | 標準機能なし | `task --list` | なし |
| Nix エコシステム採用 | **高い** | 中 | **ほぼゼロ** | ニッチ |
| 起動速度 | 即時 | 即時 | 即時 | flake 評価あり |

- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/best-practices/simplify-nixos-related-commands) が明確に推奨。著者 ryan4yin が [nix-config](https://github.com/ryan4yin/nix-config/blob/main/Justfile) で 50+ レシピを運用
- Make はビルドシステム、Just はコマンドランナー（[公式](https://just.systems/man/en/)）。dotfiles の用途（switch, lint, clean）はコマンド実行であり、Just の設計意図に合致
- go-task は Nix コミュニティでの採用実績がほぼゼロ（GitHub 検索で `Taskfile.yml + nix + flake` = 0件）
- nix run（flake apps）は定義が冗長（1タスク 5-10行 vs Just 2-3行）で、起動に flake 評価コストがかかる

`just` は devShell に配置。dotfiles リポジトリ内でのみ使うため `home.packages` には入れない。

### Git Hooks: cachix/git-hooks.nix を採用

| 観点 | cachix/git-hooks.nix | pre-commit.com | lefthook |
|------|---------------------|----------------|----------|
| Stars | 792 | 15,093 | 7,869 |
| ランタイム依存 | Nix のみ | **Python 必須** | Go バイナリ |
| `nix flake check` 統合 | **YES** | NO | NO |
| `nix develop` 自動セットアップ | **YES** | 手動 | 手動 |
| nixfmt/statix ビルトイン | **YES** | NO | NO |
| luacheck/stylua ビルトイン | **YES** | YES（独自 DL） | NO |
| バージョン管理 | flake.lock 固定 | hook リポジトリ依存 | 自前 |
| 設定の二重管理 | なし | `.pre-commit-config.yaml` + Nix | `lefthook.yml` + Nix |

- Hooks が Nix derivation として管理され、バージョンが `flake.lock` で完全固定。Nix の再現性哲学と整合
- `nix develop` で自動セットアップ → オンボーディングコストゼロ
- `nix flake check` で CI と hooks が統一的に検証される
- pre-commit framework は Python 依存。独自のツールダウンロード機構が Nix の再現性と衝突（`language: system` は公式で "unsupported" と命名 — 非推奨を示唆）
- lefthook は汎用的だが Nix 固有の統合がなく、設定の二重管理が発生
- 将来の Lua hooks（luacheck, stylua）も `hooks.luacheck.enable = true;` の1行で対応可能（[ビルトイン hooks 一覧](https://github.com/cachix/git-hooks.nix#built-in-hooks)）

旧名 `pre-commit-hooks.nix` → 2024年頃 `git-hooks.nix` にリネーム。flake-parts なしのスタンドアロン統合が可能（[README](https://github.com/cachix/git-hooks.nix#readme)）。

### Formatter: nixfmt-tree を採用

`nix fmt` の `formatter` output に `pkgs.nixfmt-tree` を使用する。

- `pkgs.nixfmt` 単体ではディレクトリ渡しが deprecated（[NixOS/nixfmt#273](https://github.com/NixOS/nixfmt/issues/273)）。`.gitignore` を尊重せず、ローカルの `.direnv/` 等が対象になる問題がある
- `nixfmt-tree` は Nix Formatting Team が導入した公式ラッパー（[nixpkgs PR #384857](https://github.com/NixOS/nixpkgs/pull/384857)）。内部で treefmt + nixfmt を組み合わせ、`.gitignore` を自動尊重する
- `treefmt-nix`（flake input として導入する方式）は複数言語フォーマッター統合向け。Nix ファイルのみなら `nixfmt-tree` で十分

### Pre-commit（write）と CI（check）の棲み分け

git-hooks.nix の設計により、追加設定なしで自動的に棲み分けされる:

- **ローカル `git commit`**: pre-commit hook が nixfmt を直接実行し、ファイルを **in-place 修正**（write モード）
- **CI `nix flake check`**: hooks が Nix sandbox 内で実行される → **読み取り専用**。差分があればビルド失敗（check モード）

## Consequences

- `nix develop` で自動的に pre-commit hooks が有効化される。セットアップ手順ゼロ
- lint 違反（nixfmt, statix, deadnix, shellcheck）がコミット前に検出される
- 日常操作が `just switch`, `just update`, `just lint`, `just clean` で一元化。`just --list` で自己文書化
- 既存の `drs` エイリアスとは共存（`drs` はシェルのどこからでも使える汎用エイリアス、`just switch` はリポジトリルートでの運用向け）
