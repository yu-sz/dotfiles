# Go 開発環境のツールチェーン選定

Date: 2026-04-06
Status: Accepted

## Context

Go のキャッチアップを始めるにあたり、dotfiles に Go 開発環境を新規構築する。Neovim + Claude Code で快適に開発できるよう、ランタイム管理・フォーマッター・リンター・デバッガの選定が必要。

既存の dotfiles は mise でランタイムを管理し、Nix で開発ツール（LSP サーバー、フォーマッター等）を宣言的に管理する構成を取っている。

## Decision

### Go ランタイム管理

| 観点                 | mise                                | Nix                     |
| -------------------- | ----------------------------------- | ----------------------- |
| バージョン切替       | **プロジェクト単位で `.mise.toml`** | flake.nix の input 固定 |
| 既存の採用           | **dev.nix に導入済み**              | 追加設定が必要          |
| チーム開発との親和性 | **`.mise.toml` 共有で統一**         | Nix 前提を強制          |

- mise は既に dotfiles に導入済みで、Node.js・Terraform 等と同じ方法で Go も管理できる
- Nix でランタイムを固定すると、プロジェクトごとのバージョン切替が煩雑になる

**決定**: Go ランタイムは mise で管理する。Nix には入れない。

### フォーマッター

| 観点               | goimports (conform.nvim)    | gofumpt (gopls 経由)           | 両方併用  |
| ------------------ | --------------------------- | ------------------------------ | --------- |
| 追加パッケージ     | gotools                     | **不要（gopls 内蔵）**         | gotools   |
| フォーマット厳格さ | gofmt 準拠                  | **gofmt の厳格スーパーセット** | 最も厳格  |
| import 整理        | **自動**                    | organizeImports が別途必要     | 自動      |
| 設定箇所           | conform.lua + lsp-tools.nix | **gopls.lua のみ**             | 3ファイル |
| モダン度           | 標準的                      | **近年の主流**                 | 最も充実  |

- [gofumpt](https://github.com/mvdan/gofumpt) は CockroachDB、Prometheus 等の主要 OSS で採用が進んでいる
- gopls の `gofumpt: true` 設定で追加バイナリ不要。conform.nvim の `lsp_format = "fallback"` と自然に連携
- import 整理は gopls の `source.organizeImports` code action を `BufWritePre` で自動実行して補完

**決定**: gofumpt を gopls 経由で使用 + organizeImports 自動実行を採用する。

### リンター

| 観点       | golangci-lint                    | gopls staticcheck のみ |
| ---------- | -------------------------------- | ---------------------- |
| 網羅性     | **50+ のリンターを集約**         | staticcheck のみ       |
| 設定柔軟性 | **`.golangci.yml` で細かく制御** | gopls 設定のみ         |
| CI 連携    | **GitHub Actions 公式サポート**  | なし                   |
| 負荷       | やや重い                         | **軽量**               |

- [golangci-lint](https://golangci-lint.run/) は Go コミュニティのデファクト標準メタリンター
- gopls の staticcheck も有効にして二重チェックとする（gopls はリアルタイム、golangci-lint は保存時）

**決定**: golangci-lint を nvim-lint で使用する。gopls の staticcheck も併用。

### デバッガ

**決定**: [Delve](https://github.com/go-delve/delve) を導入する。Go のデファクト標準デバッガであり、他に実用的な選択肢がない。

## Consequences

- gofumpt + organizeImports の組み合わせにより、保存時に自動フォーマット + import 整理が追加パッケージなしで完結する
- `after/lsp/gopls.lua` の `on_attach` で organizeImports を登録する方式は前例がないため、動作しない場合は `lsp/init.lua` への移動が必要になる可能性がある
- golangci-lint と gopls staticcheck の診断が一部重複するが、重複は軽微で実害はない
- Go ランタイムは mise 管理のため、初回は `mise use go@latest` を手動実行する必要がある
